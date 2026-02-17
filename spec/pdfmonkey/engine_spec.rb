RSpec.describe Pdfmonkey::Engine do
  let(:adapter) { double('adapter') }

  describe '.list' do
    let(:api_response) {{
      'pdf_engines' => [
        { 'id' => 'eng-1', 'name' => 'Chromium', 'deprecated_on' => nil },
        { 'id' => 'eng-2', 'name' => 'Legacy', 'deprecated_on' => '2024-01-01' }
      ],
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

    it 'contains Engine items' do
      result = described_class.list
      expect(result.count).to eq(2)
      expect(result.first).to be_a(described_class)
      expect(result.first.name).to eq('Chromium')
    end

    it 'has a working page_fetcher' do
      result = described_class.list
      expect(result.next_page).to be_nil
    end
  end

  describe 'unavailable methods' do
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
      engine = described_class.new(adapter: adapter, id: 'eng-1')
      expect { engine.save }.to raise_error(NoMethodError)
    end

    it 'does not respond to #update!' do
      engine = described_class.new(adapter: adapter, id: 'eng-1')
      expect { engine.update!(name: 'x') }.to raise_error(NoMethodError)
    end

    it 'does not respond to #delete!' do
      engine = described_class.new(adapter: adapter, id: 'eng-1')
      expect { engine.delete! }.to raise_error(NoMethodError)
    end

    it 'does not respond to #reload!' do
      engine = described_class.new(adapter: adapter, id: 'eng-1')
      expect { engine.reload! }.to raise_error(NoMethodError)
    end
  end
end
