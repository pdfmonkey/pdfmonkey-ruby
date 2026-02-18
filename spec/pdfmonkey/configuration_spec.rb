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

  describe 'Configuration#inspect' do
    it 'does not expose the private key' do
      config = Pdfmonkey::Configuration.new
      config.private_key = 'sk_live_secret_key'
      result = config.inspect
      expect(result).not_to include('sk_live_secret_key')
      expect(result).to include('host=')
      expect(result).to include('namespace=')
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
