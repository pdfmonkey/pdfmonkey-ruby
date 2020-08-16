require 'securerandom'

RSpec.describe Pdfmonkey::Document do
  subject { described_class.new(adapter: adapter, **attributes) }

  let(:adapter) { double }
  let(:attributes) {{
    app_id: 'app-id value',
    checksum: 'checksum value',
    created_at: 'created-at value',
    document_template_id: 'tpl-id value',
    download_url: 'download-url value',
    meta: 'meta value',
    payload: 'payload value',
    preview_url: 'preview-url value',
    status: 'status value',
    updated_at: 'updated-at value'
  }}

  describe '.fetch' do
    let(:document) { described_class.fetch('xxx') }

    before do
      allow_any_instance_of(Pdfmonkey::Adapter)
        .to receive(:call)
        .with(:get, an_object_having_attributes(id: 'xxx'))
        .and_return(attributes)
    end

    it 'fetches the document' do
      expect(document).to have_attributes(attributes)
    end
  end

  describe '.generate!' do
    let(:adapter) { double }
    let(:document) { described_class.generate!('test-tempalte-id', test: 'test value') }
    let(:statuses) {[
      { status: 'pending' },
      { status: 'generating' },
      { status: 'generating' },
      { status: 'success' }
    ]}

    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call).with(:post, anything).and_return(id: 'new id')
      allow(adapter).to receive(:call).with(:get, anything).and_return(*statuses)
    end

    it 'creates a new document and returns it' do
      expect(document).to be_a(described_class)
    end

    context 'when the meta parameter is provided' do
      let(:document) do
        described_class.generate!(
          'test-tempalte-id',
          { payload_key: 'paylad value' },
          { meta_key: 'meta value' })
      end

      it 'adds it to the document' do
        expect(document.meta).to eq('{"meta_key":"meta value"}')
      end
    end

    context 'when the document eventually gets a success status' do
      it 'waits for the success status before returning the document' do
        expect(document.status).to eq('success')
      end
    end

    context 'when the document eventually gets a failure status' do
      let(:statuses) {[
        { status: 'pending' },
        { status: 'generating' },
        { status: 'generating' },
        { status: 'failure' }
      ]}

      it 'waits for the failure status before returning the document' do
        expect(document.status).to eq('failure')
      end
    end
  end

  describe '.generate' do
    let(:adapter) { ->(_meth, document) { document.attributes.to_h.merge(id: 'new id') } }
    let(:document) { described_class.generate('test-tempalte-id', test: 'test value') }

    before { allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter) }

    it 'creates a new document and returns it' do
      expect(document).to be_a(described_class)
    end

    it 'sets the document attributes to the one returned by the API' do
      expect(document).to have_attributes(id: 'new id', payload: '{"test":"test value"}')
    end

    context 'when the meta parameter is provided' do
      let(:document) do
        described_class.generate(
          'test-tempalte-id',
          { payload_key: 'paylad value' },
          { meta_key: 'meta value' })
      end

      it 'adds it to the document' do
        expect(document.meta).to eq('{"meta_key":"meta value"}')
      end
    end
  end

  describe '#done?' do
    shared_examples 'detecting "done" states' do |state, expected_result|
      let(:attributes) {{ status: state }}
      specify { expect(subject.done?).to be expected_result }
    end

    it_behaves_like 'detecting "done" states', 'error', true
    it_behaves_like 'detecting "done" states', 'failure', true
    it_behaves_like 'detecting "done" states', 'success', true

    it_behaves_like 'detecting "done" states', 'draft', false
    it_behaves_like 'detecting "done" states', 'generating', false
    it_behaves_like 'detecting "done" states', 'pending', false
  end

  describe '#reload!' do
    let(:new_attributes) { attributes.merge(status: 'new value') }

    before { allow(adapter).to receive(:call).with(:get, subject).and_return(new_attributes) }

    it 'reloads the document through the adapter' do
      subject.reload!
      expect(subject.status).to eq('new value')
    end

    it 'returns the updated document' do
      expect(subject.reload!).to be subject
    end
  end

  describe '#to_json' do
    it 'returns the attributes list as a JSON string' do
      data = JSON.parse(subject.to_json)
      expect(data).to match('document' => {
        'app_id' => 'app-id value',
        'checksum' => 'checksum value',
        'created_at' => 'created-at value',
        'document_template_id' => 'tpl-id value',
        'download_url' => 'download-url value',
        'filename' => nil,
        'id' => nil,
        'meta' => 'meta value',
        'payload' => 'payload value',
        'preview_url' => 'preview-url value',
        'status' => 'status value',
        'updated_at' => 'updated-at value'
      })
    end
  end

  shared_examples 'providing reader method' do |attr, expected_value|
    specify "for #{attr}" do
      expect(subject.public_send(attr)).to eq(expected_value)
    end
  end

  it_behaves_like 'providing reader method', :app_id, 'app-id value'
  it_behaves_like 'providing reader method', :checksum, 'checksum value'
  it_behaves_like 'providing reader method', :created_at, 'created-at value'
  it_behaves_like 'providing reader method', :document_template_id, 'tpl-id value'
  it_behaves_like 'providing reader method', :download_url, 'download-url value'
  it_behaves_like 'providing reader method', :id, 'id value' do
    let(:attributes) {{ id: 'id value' }}
  end
  it_behaves_like 'providing reader method', :meta, 'meta value'
  it_behaves_like 'providing reader method', :payload, 'payload value'
  it_behaves_like 'providing reader method', :preview_url, 'preview-url value'
  it_behaves_like 'providing reader method', :status, 'status value'
  it_behaves_like 'providing reader method', :updated_at, 'updated-at value'
end
