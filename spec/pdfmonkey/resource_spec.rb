RSpec.describe Pdfmonkey::Resource do
  let(:test_class) do
    Class.new(Pdfmonkey::Resource) do
      include Pdfmonkey::Resource::Fetchable
      include Pdfmonkey::Resource::Creatable
      include Pdfmonkey::Resource::Updatable
      include Pdfmonkey::Resource::Deletable

      const_set(:ATTRIBUTES, %i[id name status errors].freeze)
      const_set(:COLLECTION, 'test_resources')
      const_set(:MEMBER, 'test_resource')

      def_delegators :attributes, *self::ATTRIBUTES
    end
  end

  let(:adapter) { double('adapter') }
  let(:resource) { test_class.new(adapter: adapter, id: '123', name: 'Test') }

  describe '.fetch' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:get, anything)
        .and_return('id' => '123', 'name' => 'Fetched')
    end

    it 'returns a resource with fetched attributes' do
      result = test_class.fetch('123')
      expect(result.name).to eq('Fetched')
    end
  end

  describe '.delete' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:delete, anything)
        .and_return(true)
    end

    it 'deletes the resource' do
      expect(test_class.delete('123')).to be true
    end
  end

  describe '.create' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:post, anything)
        .and_return('id' => '456', 'name' => 'Created')
    end

    it 'creates and returns a resource' do
      result = test_class.create(name: 'Created')
      expect(result).to be_a(test_class)
      expect(result.id).to eq('456')
      expect(result.name).to eq('Created')
    end
  end

  describe '#reload!' do
    before do
      allow(adapter).to receive(:call)
        .with(:get, resource)
        .and_return('id' => '123', 'name' => 'Reloaded')
    end

    it 'updates attributes from the API' do
      resource.reload!
      expect(resource.name).to eq('Reloaded')
    end

    it 'returns self' do
      expect(resource.reload!).to be resource
    end
  end

  describe '#save' do
    context 'when the resource has an id and includes Updatable' do
      before do
        allow(adapter).to receive(:call)
          .with(:put, resource)
          .and_return('id' => '123', 'name' => 'Saved')
      end

      it 'sends a PUT and updates attributes' do
        resource.save
        expect(resource.id).to eq('123')
        expect(resource.name).to eq('Saved')
      end

      it 'returns self' do
        expect(resource.save).to be resource
      end
    end

    context 'when the resource has no id' do
      let(:new_resource) { test_class.new(adapter: adapter, name: 'New') }

      before do
        allow(adapter).to receive(:call)
          .with(:post, new_resource)
          .and_return('id' => '789', 'name' => 'Created')
      end

      it 'sends a POST' do
        new_resource.save
        expect(new_resource.id).to eq('789')
      end
    end

    context 'when the resource is Creatable-only (no Updatable)' do
      let(:creatable_only_class) do
        Class.new(Pdfmonkey::Resource) do
          include Pdfmonkey::Resource::Creatable

          const_set(:ATTRIBUTES, %i[id name errors].freeze)
          const_set(:COLLECTION, 'creatables')
          const_set(:MEMBER, 'creatable')

          def_delegators :attributes, *self::ATTRIBUTES
        end
      end

      it 'raises when id is present' do
        instance = creatable_only_class.new(adapter: adapter, id: '123', name: 'Test')
        expect { instance.save }.to raise_error(Pdfmonkey::Error, /updates are not supported/)
      end

      it 'sends a POST when id is nil' do
        instance = creatable_only_class.new(adapter: adapter, name: 'Test')
        allow(adapter).to receive(:call)
          .with(:post, instance)
          .and_return('id' => '456', 'name' => 'Test')

        instance.save
        expect(adapter).to have_received(:call).with(:post, instance)
      end
    end
  end

  describe '#update!' do
    before do
      allow(adapter).to receive(:call)
        .with(:put, resource)
        .and_return('id' => '123', 'name' => 'Updated')
    end

    it 'sends a PUT and updates attributes' do
      resource.update!(name: 'Updated')
      expect(resource.name).to eq('Updated')
    end

    it 'returns self' do
      expect(resource.update!(name: 'Updated')).to be resource
    end

    context 'when the API call fails' do
      before do
        allow(adapter).to receive(:call)
          .with(:put, resource)
          .and_raise(Pdfmonkey::ApiError.new('fail', errors: ['fail'], status_code: 422))
      end

      it 'rolls back local changes' do
        expect { resource.update!(name: 'New Name') }.to raise_error(Pdfmonkey::ApiError)
        expect(resource.name).to eq('Test')
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(adapter).to receive(:call)
          .with(:put, resource)
          .and_raise(RuntimeError, 'unexpected')
      end

      it 'rolls back local changes' do
        expect { resource.update!(name: 'New Name') }.to raise_error(RuntimeError)
        expect(resource.name).to eq('Test')
      end
    end
  end

  describe '#delete!' do
    it 'sends a delete request' do
      expect(adapter).to receive(:call).with(:delete, resource).and_return(true)
      expect(resource.delete!).to be true
    end
  end

  describe '#inspect' do
    it 'shows the class name and non-nil attributes' do
      result = resource.inspect
      expect(result).to include('id: "123"')
      expect(result).to include('name: "Test"')
      expect(result).not_to include('status:')
    end

    it 'does not expose the adapter' do
      expect(resource.inspect).not_to include('adapter')
    end

    it 'filters sensitive attributes' do
      sensitive_class = Class.new(Pdfmonkey::Resource) do
        const_set(:ATTRIBUTES, %i[id auth_token email errors].freeze)
        const_set(:COLLECTION, 'sensitives')
        const_set(:MEMBER, 'sensitive')

        def_delegators :attributes, *self::ATTRIBUTES
      end

      r = sensitive_class.new(adapter: adapter, id: '1', auth_token: 'sk_live_secret', email: 'user@example.com')
      result = r.inspect
      expect(result).to include('auth_token: [FILTERED]')
      expect(result).not_to include('sk_live_secret')
      expect(result).to include('email: "user@example.com"')
    end

    it 'includes attributes set to false' do
      bool_class = Class.new(Pdfmonkey::Resource) do
        const_set(:ATTRIBUTES, %i[id active errors].freeze)
        const_set(:COLLECTION, 'bools')
        const_set(:MEMBER, 'bool')

        def_delegators :attributes, *self::ATTRIBUTES
      end

      r = bool_class.new(adapter: adapter, id: '1', active: false)
      expect(r.inspect).to include('active: false')
    end
  end

  describe '#to_json' do
    it 'serializes under the MEMBER key' do
      data = JSON.parse(resource.to_json)
      expect(data).to have_key('test_resource')
      expect(data['test_resource']['name']).to eq('Test')
    end

    it 'excludes the errors attribute' do
      data = JSON.parse(resource.to_json)
      expect(data['test_resource']).not_to have_key('errors')
    end

    it 'excludes nil attributes' do
      r = test_class.new(adapter: adapter, name: 'Test')
      data = JSON.parse(r.to_json)
      expect(data['test_resource']).not_to have_key('id')
      expect(data['test_resource']).not_to have_key('status')
      expect(data['test_resource']['name']).to eq('Test')
    end
  end

  describe '#initialize' do
    it 'only sets known attributes' do
      r = test_class.new(adapter: adapter, name: 'Test', unknown: 'ignored')
      expect(r.name).to eq('Test')
    end

    it 'uses a Struct for attributes' do
      expect(resource.send(:attributes)).to be_a(Struct)
    end
  end

  describe '#==' do
    it 'is equal when class and id match' do
      a = test_class.new(adapter: adapter, id: '123', name: 'A')
      b = test_class.new(adapter: adapter, id: '123', name: 'B')
      expect(a).to eq(b)
    end

    it 'is not equal when ids differ' do
      a = test_class.new(adapter: adapter, id: '123')
      b = test_class.new(adapter: adapter, id: '456')
      expect(a).not_to eq(b)
    end

    it 'is not equal when id is nil' do
      a = test_class.new(adapter: adapter, name: 'A')
      b = test_class.new(adapter: adapter, name: 'A')
      expect(a).not_to eq(b)
    end

    it 'is not equal to a different class with the same id' do
      other_class = Class.new(Pdfmonkey::Resource) do
        const_set(:ATTRIBUTES, %i[id errors].freeze)
        const_set(:COLLECTION, 'others')
        const_set(:MEMBER, 'other')

        def_delegators :attributes, *self::ATTRIBUTES
      end

      a = test_class.new(adapter: adapter, id: '123')
      b = other_class.new(adapter: adapter, id: '123')
      expect(a).not_to eq(b)
    end
  end

  describe '#hash' do
    it 'is the same for equal resources' do
      a = test_class.new(adapter: adapter, id: '123')
      b = test_class.new(adapter: adapter, id: '123')
      expect(a.hash).to eq(b.hash)
    end

    it 'works as Hash keys' do
      a = test_class.new(adapter: adapter, id: '123')
      b = test_class.new(adapter: adapter, id: '123')
      hash = { a => 'found' }
      expect(hash[b]).to eq('found')
    end
  end

  describe '#to_h' do
    it 'returns all attributes as a hash' do
      result = resource.to_h
      expect(result).to eq(id: '123', name: 'Test', status: nil, errors: nil)
    end
  end

  describe 'module composition' do
    let(:minimal_class) do
      Class.new(Pdfmonkey::Resource) do
        const_set(:ATTRIBUTES, %i[id errors].freeze)
        const_set(:COLLECTION, 'minimals')
        const_set(:MEMBER, 'minimal')

        def_delegators :attributes, *self::ATTRIBUTES
      end
    end

    it 'does not have CRUD methods when no modules are included' do
      expect { minimal_class.fetch('id') }.to raise_error(NoMethodError)
      expect { minimal_class.create }.to raise_error(NoMethodError)
      expect { minimal_class.delete('id') }.to raise_error(NoMethodError)

      instance = minimal_class.new(adapter: adapter)
      expect { instance.save }.to raise_error(NoMethodError)
      expect { instance.reload! }.to raise_error(NoMethodError)
      expect { instance.update!(id: '1') }.to raise_error(NoMethodError)
      expect { instance.delete! }.to raise_error(NoMethodError)
    end
  end

  describe 'Listable filter validation' do
    let(:filtered_class) do
      Class.new(Pdfmonkey::Resource) do
        include Pdfmonkey::Resource::Listable

        const_set(:ATTRIBUTES, %i[id errors].freeze)
        const_set(:COLLECTION, 'filtereds')
        const_set(:MEMBER, 'filtered')
        const_set(:FILTERS, { status: 'q[status]' }.freeze)

        def_delegators :attributes, *self::ATTRIBUTES
      end
    end

    let(:unfiltered_class) do
      Class.new(Pdfmonkey::Resource) do
        include Pdfmonkey::Resource::Listable

        const_set(:ATTRIBUTES, %i[id errors].freeze)
        const_set(:COLLECTION, 'unfiltereds')
        const_set(:MEMBER, 'unfiltered')

        def_delegators :attributes, *self::ATTRIBUTES
      end
    end

    it 'raises ArgumentError for unknown filter keys' do
      expect { filtered_class.list(status: 'ok', bogus: 'x') }
        .to raise_error(ArgumentError, /Unknown filter\(s\): bogus/)
    end

    it 'raises ArgumentError when filters are passed to a non-filterable resource' do
      expect { unfiltered_class.list(foo: 'bar') }
        .to raise_error(ArgumentError, /does not support filters/)
    end
  end
end
