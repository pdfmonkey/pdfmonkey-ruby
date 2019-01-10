RSpec.describe Pdfmonkey::Adapter do
  let(:http) { double('http', request: response).as_null_object }
  let(:resource_class) { double('resource class') }
  let(:resource) { double('resource', class: resource_class, id: 'test') }
  let(:response) { double('response', body: response_body) }
  let(:response_body) { '{"resource":{"test":"value"}}' }

  before do
    allow(Net::HTTP).to receive(:new).and_return(http)

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
  end
end
