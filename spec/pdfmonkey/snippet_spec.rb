RSpec.describe Pdfmonkey::Snippet do
  let(:adapter) { double('adapter') }
  let(:snippet_attrs) {{
    'id' => 'snip-1',
    'identifier' => 'header',
    'code' => '<div>Header</div>',
    'workspace_id' => 'ws-1'
  }}

  describe '.list' do
    let(:api_response) {{
      'snippets' => [snippet_attrs],
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

    it 'contains Snippet items' do
      result = described_class.list
      expect(result.first).to be_a(described_class)
      expect(result.first.identifier).to eq('header')
    end
  end

  describe '.fetch' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:get, anything)
        .and_return(snippet_attrs)
    end

    it 'returns a Snippet' do
      result = described_class.fetch('snip-1')
      expect(result).to be_a(described_class)
      expect(result.code).to eq('<div>Header</div>')
    end
  end

  describe '.create' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:post, anything)
        .and_return(snippet_attrs)
    end

    it 'creates and returns a Snippet' do
      result = described_class.create(
        identifier: 'header',
        code: '<div>Header</div>',
        workspace_id: 'ws-1'
      )
      expect(result).to be_a(described_class)
      expect(result.id).to eq('snip-1')
    end
  end

  describe '.delete' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:delete, anything)
        .and_return(true)
    end

    it 'deletes the snippet' do
      expect(described_class.delete('snip-1')).to be true
    end
  end

  describe '#update!' do
    subject { described_class.new(adapter: adapter, id: 'snip-1', code: '<div>Old</div>') }

    before do
      allow(adapter).to receive(:call)
        .with(:put, subject)
        .and_return('id' => 'snip-1', 'code' => '<div>New</div>')
    end

    it 'sends a PUT request and updates attributes' do
      subject.update!(code: '<div>New</div>')
      expect(subject.code).to eq('<div>New</div>')
    end

    it 'returns self' do
      expect(subject.update!(code: '<div>New</div>')).to be subject
    end
  end

  describe '#delete!' do
    subject { described_class.new(adapter: adapter, id: 'snip-1') }

    it 'sends a delete request' do
      expect(adapter).to receive(:call).with(:delete, subject).and_return(true)
      expect(subject.delete!).to be true
    end
  end
end
