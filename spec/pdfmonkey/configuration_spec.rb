RSpec.describe Pdfmonkey do
  describe '.configuration' do
    it 'returns the Configuration object' do
      expect(described_class.configuration).to be_a(Pdfmonkey::Configuration)
    end

    it 'returns the same Configuration object upon multiple calls' do
      first_object_id = described_class.configuration.object_id
      second_object_id = described_class.configuration.object_id
      expect(first_object_id).to eq(second_object_id)
    end
  end

  describe 'configuration=' do
    it 'sets the Configuration object' do
      begin
        described_class.configuration = 'Something'
        expect(described_class.configuration).to eq('Something')
      ensure
        described_class.configuration = nil
      end
    end
  end

  describe '.configure' do
    it 'yields the Configuration to the provided block' do
      expect { |b|
        described_class.configure(&b)
      }.to yield_with_args(Pdfmonkey::Configuration)
    end
  end
end
