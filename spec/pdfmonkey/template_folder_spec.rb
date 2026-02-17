RSpec.describe Pdfmonkey::TemplateFolder do
  let(:adapter) { double('adapter') }
  let(:folder_attrs) {{
    'id' => 'folder-1',
    'app_id' => 'app-1',
    'identifier' => 'invoices',
    'created_at' => '2024-01-01',
    'updated_at' => '2024-01-01'
  }}

  describe '.list' do
    let(:api_response) {{
      'template_folders' => [folder_attrs],
      'meta' => {
        'current_page' => 1,
        'total_pages' => 1,
        'next_page' => nil,
        'prev_page' => nil
      }
    }}

    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:get, anything, params: anything, extract: :collection)
        .and_return(api_response)
    end

    it 'returns a Collection' do
      result = described_class.list
      expect(result).to be_a(Pdfmonkey::Collection)
    end

    it 'contains TemplateFolder items' do
      result = described_class.list
      expect(result.first).to be_a(described_class)
      expect(result.first.identifier).to eq('invoices')
    end
  end

  describe '.fetch' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:get, anything)
        .and_return(folder_attrs)
    end

    it 'returns a TemplateFolder' do
      result = described_class.fetch('folder-1')
      expect(result).to be_a(described_class)
      expect(result.id).to eq('folder-1')
    end
  end

  describe '.create' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:post, anything)
        .and_return(folder_attrs)
    end

    it 'creates and returns a TemplateFolder' do
      result = described_class.create(identifier: 'invoices')
      expect(result).to be_a(described_class)
      expect(result.id).to eq('folder-1')
    end
  end

  describe '.delete' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:delete, anything)
        .and_return(true)
    end

    it 'deletes the folder' do
      expect(described_class.delete('folder-1')).to be true
    end
  end

  describe '#update!' do
    subject { described_class.new(adapter: adapter, id: 'folder-1', identifier: 'old') }

    before do
      allow(adapter).to receive(:call)
        .with(:put, subject)
        .and_return('id' => 'folder-1', 'identifier' => 'new-name')
    end

    it 'sends a PUT request and updates attributes' do
      subject.update!(identifier: 'new-name')
      expect(subject.identifier).to eq('new-name')
    end

    it 'returns self' do
      expect(subject.update!(identifier: 'new-name')).to be subject
    end
  end

  describe '#delete!' do
    subject { described_class.new(adapter: adapter, id: 'folder-1') }

    it 'sends a delete request' do
      expect(adapter).to receive(:call).with(:delete, subject).and_return(true)
      expect(subject.delete!).to be true
    end
  end
end
