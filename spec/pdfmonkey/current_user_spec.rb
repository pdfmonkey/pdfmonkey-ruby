RSpec.describe Pdfmonkey::CurrentUser do
  let(:adapter) { double('adapter') }
  let(:user_attrs) {{
    'id' => 'user-1',
    'email' => 'test@example.com',
    'desired_name' => 'Test User',
    'current_plan' => 'pro',
    'available_documents' => 1000
  }}

  describe '.fetch' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:get, described_class, path: 'current_user')
        .and_return(user_attrs)
    end

    it 'returns a CurrentUser' do
      result = described_class.fetch
      expect(result).to be_a(described_class)
      expect(result.email).to eq('test@example.com')
      expect(result.current_plan).to eq('pro')
    end

    it 'uses the singular current_user path' do
      described_class.fetch

      expect(adapter).to have_received(:call)
        .with(:get, described_class, path: 'current_user')
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
      user = described_class.new(adapter: adapter)
      expect { user.save }.to raise_error(NoMethodError)
    end

    it 'does not respond to #update!' do
      user = described_class.new(adapter: adapter)
      expect { user.update!(email: 'x') }.to raise_error(NoMethodError)
    end

    it 'does not respond to #delete!' do
      user = described_class.new(adapter: adapter)
      expect { user.delete! }.to raise_error(NoMethodError)
    end

    it 'does not respond to #reload!' do
      user = described_class.new(adapter: adapter)
      expect { user.reload! }.to raise_error(NoMethodError)
    end
  end
end
