RSpec.describe Pdfmonkey do
  describe '.with_adapter' do
    let(:custom_adapter) { double('custom adapter') }

    it 'makes the adapter available via .current_adapter inside the block' do
      described_class.with_adapter(custom_adapter) do
        expect(described_class.current_adapter).to eq(custom_adapter)
      end
    end

    it 'restores the previous adapter after the block' do
      described_class.with_adapter(custom_adapter) { }
      expect(described_class.current_adapter).to be_nil
    end

    it 'restores the previous adapter even on exception' do
      described_class.with_adapter(custom_adapter) { raise 'boom' } rescue nil
      expect(described_class.current_adapter).to be_nil
    end

    it 'supports nesting' do
      outer = double('outer')
      inner = double('inner')

      described_class.with_adapter(outer) do
        described_class.with_adapter(inner) do
          expect(described_class.current_adapter).to eq(inner)
        end
        expect(described_class.current_adapter).to eq(outer)
      end
      expect(described_class.current_adapter).to be_nil
    end
  end

  describe '.current_adapter' do
    it 'returns nil when no adapter is set' do
      expect(described_class.current_adapter).to be_nil
    end
  end
end
