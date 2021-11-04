RSpec.describe Pdfmonkey::Adapter do
  let(:http) { double('http', request: response).as_null_object }
  let(:resource_class) { double('resource class') }
  let(:resource) { double('resource', class: resource_class, id: 'test') }
  let(:response) { double('response', body: response_body) }
  let(:response_body) { '{"resource":{"test":"value"}}' }

  before do
    allow(Net::HTTP).to receive(:new).and_return(http)

    allow(Net::HTTPSuccess).to receive(:===).with(response).and_return(true)
    allow(Net::HTTPNoContent).to receive(:===).with(response).and_return(false)

    allow(resource_class)
      .to receive(:const_get).with('COLLECTION').and_return('resources')
    allow(resource_class)
      .to receive(:const_get).with('MEMBER').and_return('resource')
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

    context 'when the request fails at the HTTP level' do
      before do
        allow(http).to receive(:request).and_raise(SocketError, 'test failed')
      end

      it 'returns a hash containing the exception message' do
        attributes = subject.call(:get, resource)
        expect(attributes).to eq(status: 'error', errors: ['test failed'])
      end
    end

    context 'when the request fails on the API side' do
      before do
        allow(Net::HTTPSuccess).to receive(:===).with(response).and_return(false)
        allow(Net::HTTPNoContent).to receive(:===).with(response).and_return(false)
      end

      context 'with an "error" response' do
        let(:response_body) { '{ "error": "test failed" }' }

        it 'returns a hash containing the error message' do
          attributes = subject.call(:get, resource)
          expect(attributes).to eq(status: 'error', errors: ['test failed'])
        end
      end

      context 'with an "errors" response' do
        let(:response_body) { '{ "errors": [{ "detail": "test failed" }]}' }

        it 'returns a hash containing the error message' do
          attributes = subject.call(:get, resource)
          expect(attributes).to eq(status: 'error', errors: ['test failed'])
        end
      end
    end
  end
end
