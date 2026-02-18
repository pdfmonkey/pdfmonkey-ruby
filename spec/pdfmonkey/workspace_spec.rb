RSpec.describe Pdfmonkey::Workspace do
  let(:adapter) { double('adapter') }
  let(:workspace_attrs) {{
    'id' => 'ws-1',
    'identifier' => 'my-workspace',
    'invite_token' => 'abc123'
  }}

  describe '.list_cards' do
    let(:api_response) {{
      'workspaces' => [workspace_attrs],
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
      result = described_class.list_cards
      expect(result).to be_a(Pdfmonkey::Collection)
    end

    it 'contains Workspace items' do
      result = described_class.list_cards
      expect(result.first).to be_a(described_class)
      expect(result.first.identifier).to eq('my-workspace')
    end
  end

  describe '.fetch' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:get, anything)
        .and_return(workspace_attrs)
    end

    it 'returns a Workspace' do
      result = described_class.fetch('ws-1')
      expect(result).to be_a(described_class)
      expect(result.id).to eq('ws-1')
    end
  end

  describe 'unavailable methods' do
    it 'does not respond to .create' do
      expect { described_class.create(identifier: 'x') }.to raise_error(NoMethodError)
    end

    it 'does not respond to .delete' do
      expect { described_class.delete('ws-1') }.to raise_error(NoMethodError)
    end

    it 'does not respond to #update!' do
      workspace = described_class.new(adapter: adapter, id: 'ws-1')
      expect { workspace.update!(identifier: 'x') }.to raise_error(NoMethodError)
    end

    it 'does not respond to #save' do
      workspace = described_class.new(adapter: adapter, id: 'ws-1')
      expect { workspace.save }.to raise_error(NoMethodError)
    end

    it 'does not respond to #delete!' do
      workspace = described_class.new(adapter: adapter, id: 'ws-1')
      expect { workspace.delete! }.to raise_error(NoMethodError)
    end
  end
end
