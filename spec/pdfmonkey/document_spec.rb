RSpec.describe Pdfmonkey::Document do
  subject { described_class.new(adapter: adapter, **attributes) }

  let(:adapter) { double('adapter') }
  let(:attributes) {{
    app_id: 'app-id value',
    checksum: 'checksum value',
    created_at: 'created-at value',
    document_template_id: 'tpl-id value',
    download_url: 'download-url value',
    failure_cause: 'failure-cause value',
    generation_logs: [],
    meta: 'meta value',
    payload: 'payload value',
    preview_url: 'preview-url value',
    public_share_link: 'public-share-link value',
    status: 'status value',
    updated_at: 'updated-at value'
  }}

  describe '.delete' do
    let(:adapter) { double('adapter') }

    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call).and_return(true)
    end

    it 'deletes the document' do
      described_class.delete('xxx')

      expect(adapter)
        .to have_received(:call)
        .with(:delete, an_object_having_attributes(id: 'xxx'))
    end
  end

  describe '.fetch' do
    let(:adapter) { double('adapter') }
    let(:document) { described_class.fetch('xxx') }

    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:get, an_object_having_attributes(id: 'xxx'))
        .and_return(attributes.transform_keys(&:to_s))
    end

    it 'fetches the document' do
      expect(document).to have_attributes(attributes)
    end
  end

  describe '.generate!' do
    let(:adapter) { double('adapter') }
    let(:document) do
      described_class.generate!(document_template_id: 'test-template-id', payload: { test: 'test value' })
    end
    let(:statuses) {[
      { 'status' => 'pending' },
      { 'status' => 'generating' },
      { 'status' => 'generating' },
      { 'status' => 'success' }
    ]}

    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call).with(:post, anything).and_return('id' => 'new id')
      allow(adapter).to receive(:call).with(:get, anything).and_return(*statuses)
      allow_any_instance_of(described_class).to receive(:sleep)
    end

    it 'creates a new document and returns it' do
      expect(document).to be_a(described_class)
    end

    context 'when the meta parameter is provided' do
      let(:document) do
        described_class.generate!(
          document_template_id: 'test-template-id',
          payload: { payload_key: 'paylad value' },
          meta: { meta_key: 'meta value' })
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
        { 'status' => 'pending' },
        { 'status' => 'generating' },
        { 'status' => 'failure', 'failure_cause' => 'Template error' }
      ]}

      it 'raises a GenerationError with the failure cause' do
        expect { document }.to raise_error(
          Pdfmonkey::GenerationError, /Document generation failed: Template error/
        )
      end

      it 'includes the document on the error' do
        described_class.generate!(document_template_id: 'test-template-id', payload: { test: 'test value' })
      rescue Pdfmonkey::GenerationError => e
        expect(e.document).to be_a(described_class)
        expect(e.document.status).to eq('failure')
      end
    end

    context 'when the document eventually gets an error status' do
      let(:statuses) {[
        { 'status' => 'pending' },
        { 'status' => 'error' }
      ]}

      it 'raises a GenerationError' do
        expect { document }.to raise_error(
          Pdfmonkey::GenerationError, /Document generation failed/
        )
      end

      it 'includes the document on the error' do
        described_class.generate!(document_template_id: 'test-template-id', payload: { test: 'test value' })
      rescue Pdfmonkey::GenerationError => e
        expect(e.document).to be_a(described_class)
        expect(e.document.status).to eq('error')
      end
    end

    context 'without document_template_id' do
      it 'raises ArgumentError' do
        expect {
          described_class.generate!(payload: { test: 'value' })
        }.to raise_error(ArgumentError, /document_template_id is required/)
      end
    end

    context 'with blank document_template_id' do
      it 'raises ArgumentError' do
        expect {
          described_class.generate!(document_template_id: '  ', payload: { test: 'value' })
        }.to raise_error(ArgumentError, /document_template_id is required/)
      end
    end

    context 'with positional arguments (deprecated)' do
      it 'emits a deprecation warning' do
        expect {
          described_class.generate!('test-template-id', { test: 'test value' })
        }.to output(/Positional arguments for Document.generate! are deprecated/).to_stderr
      end
    end
  end

  describe '.generate' do
    let(:adapter) { double('adapter') }
    let(:document) do
      described_class.generate(document_template_id: 'test-template-id', payload: { test: 'test value' })
    end

    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:post, anything)
        .and_return(attributes.transform_keys(&:to_s).merge('id' => 'new id'))
    end

    it 'creates a new document and returns it' do
      expect(document).to be_a(described_class)
    end

    it 'sets the document attributes to the one returned by the API' do
      expect(document).to have_attributes(id: 'new id', payload: 'payload value')
    end

    context 'when the meta parameter is provided' do
      let(:document) do
        described_class.generate(
          document_template_id: 'test-template-id',
          payload: { payload_key: 'paylad value' },
          meta: { meta_key: 'meta value' })
      end

      before do
        allow(adapter).to receive(:call)
          .with(:post, anything)
          .and_return(attributes.transform_keys(&:to_s).merge('id' => 'new id', 'meta' => '{"meta_key":"meta value"}'))
      end

      it 'adds it to the document' do
        expect(document.meta).to eq('{"meta_key":"meta value"}')
      end
    end

    context 'without document_template_id' do
      it 'raises ArgumentError' do
        expect {
          described_class.generate(payload: { test: 'value' })
        }.to raise_error(ArgumentError, /document_template_id is required/)
      end
    end

    context 'with positional arguments (deprecated)' do
      it 'emits a deprecation warning' do
        expect {
          described_class.generate('test-template-id', { test: 'test value' })
        }.to output(/Positional arguments for Document.generate are deprecated/).to_stderr
      end
    end
  end

  describe '.create_draft' do
    let(:adapter) { double('adapter') }
    let(:document) do
      described_class.create_draft(document_template_id: 'test-template-id', payload: { test: 'test value' })
    end

    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:post, anything)
        .and_return(attributes.transform_keys(&:to_s).merge('id' => 'draft-id', 'status' => 'draft'))
    end

    it 'creates a draft document' do
      expect(document).to be_a(described_class)
      expect(document.status).to eq('draft')
    end

    it 'sets the document id from the API response' do
      expect(document.id).to eq('draft-id')
    end

    context 'without document_template_id' do
      it 'raises ArgumentError' do
        expect {
          described_class.create_draft(payload: { test: 'value' })
        }.to raise_error(ArgumentError, /document_template_id is required/)
      end
    end

    context 'with positional arguments (deprecated)' do
      it 'emits a deprecation warning' do
        expect {
          described_class.create_draft('test-template-id', { test: 'test value' })
        }.to output(/Positional arguments for Document.create_draft are deprecated/).to_stderr
      end
    end
  end

  describe '#delete!' do
    it 'sends a :delete request through the adapter' do
      expect(adapter).to receive(:call).with(:delete, subject).and_return(true)
      subject.delete!
    end

    it 'returns true' do
      allow(adapter).to receive(:call).with(:delete, subject).and_return(true)
      expect(subject.delete!).to be true
    end
  end

  describe '#generate' do
    let(:attributes) {{ id: 'draft-id', status: 'draft', document_template_id: 'tpl-id' }}

    before do
      allow(adapter).to receive(:call)
        .with(:put, subject)
        .and_return('id' => 'draft-id', 'status' => 'pending')
    end

    it 'updates the status to pending' do
      subject.generate
      expect(subject.status).to eq('pending')
    end

    it 'returns self' do
      expect(subject.generate).to be subject
    end
  end

  describe '#generate!' do
    let(:attributes) {{ id: 'draft-id', status: 'draft', document_template_id: 'tpl-id' }}
    let(:statuses) {[
      { 'status' => 'pending' },
      { 'status' => 'generating' },
      { 'status' => 'success' }
    ]}

    before do
      allow(adapter).to receive(:call)
        .with(:put, subject)
        .and_return('id' => 'draft-id', 'status' => 'pending')
      allow(adapter).to receive(:call)
        .with(:get, subject)
        .and_return(*statuses)
      allow(subject).to receive(:sleep)
    end

    it 'polls until the document is done' do
      subject.generate!
      expect(subject.status).to eq('success')
    end

    it 'returns self' do
      expect(subject.generate!).to be subject
    end

    it 'sleeps between polls' do
      subject.generate!
      expect(subject).to have_received(:sleep).with(0.5).exactly(3).times
    end

    context 'when generation fails' do
      let(:statuses) {[
        { 'status' => 'pending' },
        { 'status' => 'failure', 'failure_cause' => 'Template error' }
      ]}

      it 'raises a GenerationError' do
        expect { subject.generate! }.to raise_error(
          Pdfmonkey::GenerationError, /Document generation failed: Template error/
        )
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
    let(:new_attributes) { attributes.transform_keys(&:to_s).merge('status' => 'new value') }

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
        'failure_cause' => 'failure-cause value',
        'generation_logs' => [],
        'meta' => 'meta value',
        'payload' => 'payload value',
        'preview_url' => 'preview-url value',
        'public_share_link' => 'public-share-link value',
        'status' => 'status value',
        'updated_at' => 'updated-at value'
      })
    end
  end

  describe '.generate with string payload' do
    let(:adapter) { double('adapter') }

    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call).with(:post, anything).and_return('id' => 'new id')
    end

    it 'does not double-encode a string payload' do
      described_class.generate(
        document_template_id: 'tpl',
        payload: '{"already":"json"}'
      )

      expect(adapter).to have_received(:call).with(:post, an_object_having_attributes(
        payload: '{"already":"json"}'
      ))
    end

    it 'passes nil through without encoding' do
      described_class.generate(
        document_template_id: 'tpl',
        payload: nil
      )

      expect(adapter).to have_received(:call).with(:post, an_object_having_attributes(
        payload: nil
      ))
    end
  end

  describe '.list_cards' do
    it 'delegates to DocumentCard.list' do
      expect(Pdfmonkey::DocumentCard).to receive(:list).with(page: 2).and_return(:result)
      expect(described_class.list_cards(page: 2)).to eq(:result)
    end
  end

  describe '.fetch_card' do
    it 'delegates to DocumentCard.fetch' do
      expect(Pdfmonkey::DocumentCard).to receive(:fetch).with('doc-id').and_return(:card)
      expect(described_class.fetch_card('doc-id')).to eq(:card)
    end
  end

  describe '.fetch_full' do
    it 'delegates to .fetch' do
      expect(described_class).to receive(:fetch).with('doc-id').and_return(:document)
      expect(described_class.fetch_full('doc-id')).to eq(:document)
    end
  end

  describe '#update!' do
    before do
      allow(adapter).to receive(:call)
        .with(:put, subject)
        .and_return('status' => 'pending', 'app_id' => 'app-id value')
    end

    it 'sends a PUT request and updates attributes' do
      subject.update!(status: 'pending')
      expect(subject.status).to eq('pending')
    end

    it 'returns self' do
      expect(subject.update!(status: 'pending')).to be subject
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
  it_behaves_like 'providing reader method', :failure_cause, 'failure-cause value'
  it_behaves_like 'providing reader method', :generation_logs, []
  it_behaves_like 'providing reader method', :id, 'id value' do
    let(:attributes) {{ id: 'id value' }}
  end
  it_behaves_like 'providing reader method', :meta, 'meta value'
  it_behaves_like 'providing reader method', :payload, 'payload value'
  it_behaves_like 'providing reader method', :preview_url, 'preview-url value'
  it_behaves_like 'providing reader method', :public_share_link, 'public-share-link value'
  it_behaves_like 'providing reader method', :status, 'status value'
  it_behaves_like 'providing reader method', :updated_at, 'updated-at value'
end
