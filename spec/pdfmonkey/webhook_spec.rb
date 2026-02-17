RSpec.describe Pdfmonkey::Webhook do
  let(:adapter) { double('adapter') }
  let(:webhook_attrs) {{
    'id' => 'hook-1',
    'url' => 'https://example.com/webhook',
    'event' => 'document.generation.completed',
    'workspace_id' => 'ws-1',
    'document_template_ids' => ['tpl-1'],
    'platform' => nil,
    'custom_channel' => nil
  }}

  describe '.create' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:post, anything)
        .and_return(webhook_attrs)
    end

    it 'creates and returns a Webhook' do
      result = described_class.create(
        url: 'https://example.com/webhook',
        event: 'document.generation.completed',
        workspace_id: 'ws-1'
      )
      expect(result).to be_a(described_class)
      expect(result.id).to eq('hook-1')
      expect(result.url).to eq('https://example.com/webhook')
    end
  end

  describe '.delete' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:delete, anything)
        .and_return(true)
    end

    it 'deletes the webhook' do
      expect(described_class.delete('hook-1')).to be true
    end
  end

  describe '#delete!' do
    subject { described_class.new(adapter: adapter, id: 'hook-1') }

    it 'sends a delete request' do
      expect(adapter).to receive(:call).with(:delete, subject).and_return(true)
      expect(subject.delete!).to be true
    end
  end

  describe 'unavailable methods' do
    it 'does not respond to .fetch' do
      expect { described_class.fetch('id') }.to raise_error(NoMethodError)
    end

    it 'does not respond to .list' do
      expect { described_class.list }.to raise_error(NoMethodError)
    end

    it 'does not respond to #update!' do
      webhook = described_class.new(adapter: adapter, id: 'hook-1')
      expect { webhook.update!(url: 'x') }.to raise_error(NoMethodError)
    end

    it 'does not respond to #reload!' do
      webhook = described_class.new(adapter: adapter, id: 'hook-1')
      expect { webhook.reload! }.to raise_error(NoMethodError)
    end
  end

  describe 'COLLECTION and MEMBER' do
    it 'uses rest_hooks as the API resource name' do
      expect(described_class::COLLECTION).to eq('rest_hooks')
      expect(described_class::MEMBER).to eq('rest_hook')
    end
  end
end
