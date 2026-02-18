RSpec.describe Pdfmonkey::DocumentCard do
  let(:adapter) { double('adapter') }
  let(:card_attrs) {{
    'id' => 'card-1',
    'app_id' => 'app-1',
    'document_template_id' => 'tpl-1',
    'status' => 'success',
    'filename' => 'test.pdf'
  }}

  describe '.list' do
    let(:api_response) {{
      'document_cards' => [card_attrs],
      'meta' => {
        'current_page' => 1,
        'total_pages' => 3,
        'next_page' => 2,
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

    it 'contains DocumentCard items' do
      result = described_class.list
      expect(result.first).to be_a(described_class)
      expect(result.first.id).to eq('card-1')
    end

    it 'passes page parameter' do
      described_class.list(page: 2)

      expect(adapter).to have_received(:call).with(
        :get, anything,
        params: hash_including('page[number]' => 2),
        extract: :collection
      )
    end

    it 'passes filter parameters' do
      described_class.list(
        document_template_id: 'tpl-1',
        status: 'success',
        workspace_id: 'ws-1'
      )

      expect(adapter).to have_received(:call).with(
        :get, anything,
        params: hash_including(
          'q[document_template_id]' => 'tpl-1',
          'q[status]' => 'success',
          'q[workspace_id]' => 'ws-1'
        ),
        extract: :collection
      )
    end

    it 'has pagination metadata' do
      result = described_class.list
      expect(result.current_page).to eq(1)
      expect(result.total_pages).to eq(3)
      expect(result.next_page_number).to eq(2)
      expect(result.prev_page_number).to be_nil
    end
  end

  describe 'pagination chaining' do
    let(:page1_response) {{
      'document_cards' => [card_attrs],
      'meta' => {
        'current_page' => 1,
        'total_pages' => 2,
        'next_page' => 2,
        'prev_page' => nil
      }
    }}
    let(:page2_response) {{
      'document_cards' => [{ 'id' => 'card-2', 'status' => 'pending' }],
      'meta' => {
        'current_page' => 2,
        'total_pages' => 2,
        'next_page' => nil,
        'prev_page' => 1
      }
    }}

    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:get, anything, params: hash_including('page[number]' => 1), extract: :collection)
        .and_return(page1_response)
      allow(adapter).to receive(:call)
        .with(:get, anything, params: hash_including('page[number]' => 2), extract: :collection)
        .and_return(page2_response)
    end

    it 'fetches the next page via next_page' do
      page1 = described_class.list(page: 1)
      page2 = page1.next_page

      expect(page2).to be_a(Pdfmonkey::Collection)
      expect(page2.first.id).to eq('card-2')
      expect(page2.current_page).to eq(2)
      expect(page2.next_page).to be_nil
    end

    it 'fetches the previous page via prev_page' do
      page2 = described_class.list(page: 2)

      allow(adapter).to receive(:call)
        .with(:get, anything, params: hash_including('page[number]' => 2), extract: :collection)
        .and_return(page2_response)

      page2 = described_class.list(page: 2)
      page1 = page2.prev_page

      expect(page1).to be_a(Pdfmonkey::Collection)
      expect(page1.first.id).to eq('card-1')
      expect(page1.current_page).to eq(1)
    end
  end

  describe 'undefined methods' do
    it 'does not respond to .create' do
      expect { described_class.create }.to raise_error(NoMethodError)
    end

    it 'does not respond to .delete' do
      expect { described_class.delete('id') }.to raise_error(NoMethodError)
    end

    it 'does not respond to #save' do
      card = described_class.new(adapter: adapter, id: 'card-1')
      expect { card.save }.to raise_error(NoMethodError)
    end

    it 'does not respond to #update!' do
      card = described_class.new(adapter: adapter, id: 'card-1')
      expect { card.update!(status: 'x') }.to raise_error(NoMethodError)
    end

    it 'does not respond to #delete!' do
      card = described_class.new(adapter: adapter, id: 'card-1')
      expect { card.delete! }.to raise_error(NoMethodError)
    end
  end

  describe '.fetch' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:get, anything)
        .and_return(card_attrs)
    end

    it 'returns a DocumentCard' do
      result = described_class.fetch('card-1')
      expect(result).to be_a(described_class)
      expect(result.id).to eq('card-1')
    end
  end

  describe '#reload!' do
    subject { described_class.new(adapter: adapter, id: 'card-1', status: 'pending') }

    before do
      allow(adapter).to receive(:call)
        .with(:get, subject)
        .and_return(card_attrs.merge('status' => 'success'))
    end

    it 'reloads the document card' do
      subject.reload!
      expect(subject.status).to eq('success')
    end

    it 'returns self' do
      expect(subject.reload!).to be subject
    end
  end

  describe '#to_document' do
    let(:document) { double('document') }

    before do
      allow(Pdfmonkey::Document).to receive(:fetch)
        .with('card-1')
        .and_return(document)
    end

    subject { described_class.new(adapter: adapter, id: 'card-1') }

    it 'fetches the full Document' do
      expect(subject.to_document).to eq(document)
    end
  end
end
