RSpec.describe Pdfmonkey::TemplateCard do
  let(:adapter) { double('adapter') }
  let(:card_attrs) {{
    'id' => 'tpl-1',
    'app_id' => 'app-1',
    'identifier' => 'my-template',
    'edition_mode' => 'html',
    'output_type' => 'pdf'
  }}

  describe '.list' do
    let(:api_response) {{
      'document_template_cards' => [card_attrs],
      'meta' => {
        'current_page' => 1,
        'total_pages' => 2,
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
      result = described_class.list(workspace_id: 'ws-1')
      expect(result).to be_a(Pdfmonkey::Collection)
    end

    it 'contains TemplateCard items' do
      result = described_class.list(workspace_id: 'ws-1')
      expect(result.first).to be_a(described_class)
      expect(result.first.identifier).to eq('my-template')
    end

    it 'requires workspace_id' do
      expect { described_class.list }.to raise_error(ArgumentError)
    end

    it 'passes workspace_id and page params' do
      described_class.list(workspace_id: 'ws-1', page: 2)

      expect(adapter).to have_received(:call).with(
        :get, anything,
        params: hash_including(
          'q[workspace_id]' => 'ws-1',
          'page[number]' => 2
        ),
        extract: :collection
      )
    end
  end

  describe 'undefined methods' do
    it 'does not respond to .create' do
      expect { described_class.create }.to raise_error(NoMethodError)
    end

    it 'does not respond to .delete' do
      expect { described_class.delete('id') }.to raise_error(NoMethodError)
    end

    it 'does not respond to .fetch' do
      expect { described_class.fetch('id') }.to raise_error(NoMethodError)
    end

    it 'does not respond to #save' do
      card = described_class.new(adapter: adapter, id: 'tpl-1')
      expect { card.save }.to raise_error(NoMethodError)
    end

    it 'does not respond to #update!' do
      card = described_class.new(adapter: adapter, id: 'tpl-1')
      expect { card.update!(identifier: 'x') }.to raise_error(NoMethodError)
    end

    it 'does not respond to #delete!' do
      card = described_class.new(adapter: adapter, id: 'tpl-1')
      expect { card.delete! }.to raise_error(NoMethodError)
    end

    it 'does not respond to #reload!' do
      card = described_class.new(adapter: adapter, id: 'tpl-1')
      expect { card.reload! }.to raise_error(NoMethodError)
    end
  end

  describe '#to_template' do
    let(:template) { double('template') }

    before do
      allow(Pdfmonkey::Template).to receive(:fetch)
        .with('tpl-1')
        .and_return(template)
    end

    subject { described_class.new(adapter: adapter, id: 'tpl-1') }

    it 'fetches the full Template' do
      expect(subject.to_template).to eq(template)
    end
  end
end
