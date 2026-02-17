RSpec.describe Pdfmonkey::Adapter do
  let(:http) { double('http', request: response).as_null_object }
  let(:resource_class) do
    Class.new(Pdfmonkey::Resource) do
      include Pdfmonkey::Resource::Fetchable
      include Pdfmonkey::Resource::Creatable
      include Pdfmonkey::Resource::Deletable

      const_set(:ATTRIBUTES, %i[id test errors].freeze)
      const_set(:COLLECTION, 'resources')
      const_set(:MEMBER, 'resource')

      def_delegators :attributes, *self::ATTRIBUTES
    end
  end
  let(:resource) { resource_class.new(id: 'test') }
  let(:response) { double('response', body: response_body) }
  let(:response_body) { '{"resource":{"test":"value"}}' }

  before do
    allow(Net::HTTP).to receive(:new).and_return(http)

    allow(Net::HTTPSuccess).to receive(:===).with(response).and_return(true)
    allow(Net::HTTPNoContent).to receive(:===).with(response).and_return(false)
  end

  describe '#inspect' do
    it 'does not expose the API key' do
      result = described_class.new.inspect
      expect(result).not_to include(Pdfmonkey.configuration.private_key)
      expect(result).to eq("#<Pdfmonkey::Adapter>")
    end
  end

  describe '#close' do
    it 'finishes an active connection' do
      adapter = described_class.new
      adapter.instance_variable_set(:@connection, http)
      allow(http).to receive(:finish)

      adapter.close

      expect(http).to have_received(:finish)
      expect(adapter.instance_variable_get(:@connection)).to be_nil
    end

    it 'does not raise when no connection exists' do
      adapter = described_class.new
      expect { adapter.close }.not_to raise_error
    end

    it 'does not raise when finish raises' do
      adapter = described_class.new
      failing_http = double('http')
      allow(failing_http).to receive(:finish).and_raise(IOError, 'closed stream')
      adapter.instance_variable_set(:@connection, failing_http)

      expect { adapter.close }.not_to raise_error
      expect(adapter.instance_variable_get(:@connection)).to be_nil
    end
  end

  describe '#call' do
    context 'when calling :get for a resource' do
      it 'returns the attributes hash returned by the API' do
        attributes = subject.call(:get, resource)
        expect(attributes).to eq('test' => 'value')
      end
    end

    context 'when calling :post for a resource' do
      it 'returns the attributes hash returned by the API' do
        attributes = subject.call(:post, resource)
        expect(attributes).to eq('test' => 'value')
      end
    end

    context 'when calling :put for a resource' do
      it 'returns the attributes hash returned by the API' do
        attributes = subject.call(:put, resource)
        expect(attributes).to eq('test' => 'value')
      end
    end

    context 'when calling :delete for a resource' do
      let(:response_body) { nil }
      let(:response_class) { Net::HTTPNoContent }

      before do
        allow(Net::HTTPSuccess).to receive(:===).with(response).and_return(false)
        allow(Net::HTTPNoContent).to receive(:===).with(response).and_return(true)
      end

      it 'returns true' do
        result = subject.call(:delete, resource)
        expect(result).to be true
      end
    end

    context 'when using query params' do
      it 'appends them to the URL' do
        subject.call(:get, resource, params: { page: 2, status: 'success' })

        expect(Net::HTTP)
          .to have_received(:new)
          .with('api.pdfmonkey.io', 443)

        expect(http)
          .to have_received(:request) do |request|
            expect(request.path).to include('page=2')
            expect(request.path).to include('status=success')
          end
      end
    end

    context 'when using a path override' do
      it 'uses the path instead of the collection' do
        subject.call(:get, resource, path: 'current_users')

        expect(http)
          .to have_received(:request) do |request|
            expect(request.path).to eq('/api/v1/current_users')
          end
      end
    end

    context 'when using extract: :collection' do
      let(:response_body) { '{"resource_cards":[{"id":"1"}],"meta":{"current_page":1}}' }

      it 'returns the full parsed body' do
        result = subject.call(:get, resource, extract: :collection)
        expect(result).to eq(
          'resource_cards' => [{ 'id' => '1' }],
          'meta' => { 'current_page' => 1 }
        )
      end
    end

    context 'when a Class is passed as resource' do
      let(:response_body) { '{"resources":[{"id":"1"}],"meta":{"current_page":1}}' }

      it 'builds the URL from the Class constants' do
        subject.call(:get, resource_class, extract: :collection)

        expect(http)
          .to have_received(:request) do |request|
            expect(request.path).to eq('/api/v1/resources')
          end
      end
    end

    context 'when a success response has invalid JSON' do
      let(:response_body) { 'not json at all' }

      before { allow(response).to receive(:code).and_return('200') }

      it 'raises an ApiError' do
        expect { subject.call(:get, resource) }
          .to raise_error(Pdfmonkey::ApiError) { |e|
            expect(e.errors).to eq(['not json at all'])
            expect(e.status_code).to eq(200)
          }
      end
    end

    context 'when the request fails at the HTTP level' do
      before do
        allow(http).to receive(:request).and_raise(SocketError, 'test failed')
      end

      it 'raises a ConnectionError' do
        expect { subject.call(:get, resource) }
          .to raise_error(Pdfmonkey::ConnectionError, 'test failed')
      end
    end

    context 'when the connection is stale' do
      let(:stale_http) { double('stale_http', started?: false) }
      let(:fresh_http) { double('fresh_http', request: response).as_null_object }

      before do
        allow(Net::HTTP).to receive(:new).and_return(fresh_http)
        allow(stale_http).to receive(:finish)
      end

      it 'finishes the stale connection and creates a new one' do
        adapter = described_class.new

        # First call sets up the stale connection
        adapter.instance_variable_set(:@connection, stale_http)

        adapter.call(:get, resource)

        expect(stale_http).to have_received(:finish)
        expect(fresh_http).to have_received(:request)
      end
    end

    context 'when using an unsupported HTTP method' do
      it 'raises an ArgumentError' do
        expect { subject.call(:patch, resource) }
          .to raise_error(ArgumentError, /Unsupported HTTP method: :patch/)
      end
    end

    context 'when using an unknown extract mode' do
      it 'raises an ArgumentError' do
        expect { subject.call(:get, resource, extract: :unknown) }
          .to raise_error(ArgumentError, /Unknown extract mode: :unknown/)
      end
    end

    context 'when the response is missing the expected member key' do
      let(:response_body) { '{"wrong_key":{"test":"value"}}' }

      before { allow(response).to receive(:code).and_return('200') }

      it 'raises an ApiError' do
        expect { subject.call(:get, resource) }
          .to raise_error(Pdfmonkey::ApiError, /Missing 'resource' key in response/)
      end
    end

    context 'when no API key is configured' do
      before do
        Pdfmonkey.configuration.private_key = nil
      end

      it 'raises a Pdfmonkey::Error' do
        expect { subject.call(:get, resource) }
          .to raise_error(Pdfmonkey::Error, /No API key configured/)
      end
    end

    context 'when API key is an empty string' do
      before do
        Pdfmonkey.configuration.private_key = ''
      end

      it 'raises a Pdfmonkey::Error' do
        expect { subject.call(:get, resource) }
          .to raise_error(Pdfmonkey::Error, /No API key configured/)
      end
    end

    context 'when API key is whitespace only' do
      before do
        Pdfmonkey.configuration.private_key = '   '
      end

      it 'raises a Pdfmonkey::Error' do
        expect { subject.call(:get, resource) }
          .to raise_error(Pdfmonkey::Error, /No API key configured/)
      end
    end

    context 'when the error response has a nil body' do
      let(:nil_body_response) { double('response', body: nil, code: '500') }

      before do
        allow(http).to receive(:request).and_return(nil_body_response)
        allow(Net::HTTPSuccess).to receive(:===).with(nil_body_response).and_return(false)
        allow(Net::HTTPNoContent).to receive(:===).with(nil_body_response).and_return(false)
      end

      it 'raises an ApiError without crashing' do
        expect { subject.call(:get, resource) }
          .to raise_error(Pdfmonkey::ApiError) { |e|
            expect(e.status_code).to eq(500)
          }
      end
    end

    context 'when a success response has a nil body' do
      let(:nil_body_response) { double('response', body: nil, code: '200') }

      before do
        allow(http).to receive(:request).and_return(nil_body_response)
        allow(Net::HTTPSuccess).to receive(:===).with(nil_body_response).and_return(true)
        allow(Net::HTTPNoContent).to receive(:===).with(nil_body_response).and_return(false)
      end

      it 'raises an ApiError for invalid JSON' do
        expect { subject.call(:get, resource) }
          .to raise_error(Pdfmonkey::ApiError, /Invalid JSON/)
      end
    end

    context 'when the request fails on the API side' do
      before do
        allow(Net::HTTPSuccess).to receive(:===).with(response).and_return(false)
        allow(Net::HTTPNoContent).to receive(:===).with(response).and_return(false)
        allow(response).to receive(:code).and_return('422')
      end

      context 'with an "error" response' do
        let(:response_body) { '{ "error": "test failed" }' }

        it 'raises an ApiError with the error message' do
          expect { subject.call(:get, resource) }
            .to raise_error(Pdfmonkey::ApiError) { |e|
              expect(e.errors).to eq(['test failed'])
              expect(e.status_code).to eq(422)
            }
        end
      end

      context 'with an "errors" response' do
        let(:response_body) { '{ "errors": [{ "detail": "test failed" }]}' }

        it 'raises an ApiError with the error message' do
          expect { subject.call(:get, resource) }
            .to raise_error(Pdfmonkey::ApiError) { |e|
              expect(e.errors).to eq(['test failed'])
            }
        end
      end

      context 'with an "errors" response of plain strings' do
        let(:response_body) { '{ "errors": ["Something went wrong", "Another error"] }' }

        it 'raises an ApiError preserving the string messages' do
          expect { subject.call(:get, resource) }
            .to raise_error(Pdfmonkey::ApiError) { |e|
              expect(e.errors).to eq(['Something went wrong', 'Another error'])
              expect(e.message).to eq('Something went wrong, Another error')
            }
        end
      end

      context 'with an "errors" response lacking a "detail" key' do
        let(:response_body) { '{ "errors": [{ "code": "not_found", "title": "Not Found" }] }' }

        it 'raises an ApiError with the hash JSON as fallback' do
          expect { subject.call(:get, resource) }
            .to raise_error(Pdfmonkey::ApiError) { |e|
              expect(e.errors).to eq(['{"code":"not_found","title":"Not Found"}'])
            }
        end
      end

      context 'with an "errors" response containing a "message" key' do
        let(:response_body) { '{ "errors": [{ "message": "Rate limited" }] }' }

        it 'raises an ApiError using the message key' do
          expect { subject.call(:get, resource) }
            .to raise_error(Pdfmonkey::ApiError) { |e|
              expect(e.errors).to eq(['Rate limited'])
            }
        end
      end

      context 'with an "errors" response for validation errors' do
        let(:response_body) { '{"errors":{"status":["Quota error message"]}}' }

        it 'raises an ApiError with the error messages' do
          expect { subject.call(:post, resource) }
            .to raise_error(Pdfmonkey::ApiError) { |e|
              expect(e.message).to eq('status: Quota error message')
              expect(e.errors).to eq('status' => ['Quota error message'])
            }
        end
      end

      context 'with a non-JSON response body' do
        let(:response_body) { '<html>Internal Server Error</html>' }

        before { allow(response).to receive(:code).and_return('500') }

        it 'raises an ApiError with the raw body' do
          expect { subject.call(:get, resource) }
            .to raise_error(Pdfmonkey::ApiError) { |e|
              expect(e.errors).to eq(['<html>Internal Server Error</html>'])
              expect(e.status_code).to eq(500)
            }
        end
      end
    end
  end
end
