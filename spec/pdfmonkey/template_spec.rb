RSpec.describe Pdfmonkey::Template do
  let(:adapter) { double('adapter') }
  let(:template_attrs) {{
    'id' => 'tpl-1',
    'app_id' => 'app-1',
    'identifier' => 'my-template',
    'body' => '<h1>Hello</h1>',
    'body_draft' => '<h1>Hello Draft</h1>',
    'output_type' => 'pdf'
  }}

  describe '.fetch' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:get, anything)
        .and_return(template_attrs)
    end

    it 'returns a Template' do
      result = described_class.fetch('tpl-1')
      expect(result).to be_a(described_class)
      expect(result.id).to eq('tpl-1')
      expect(result.identifier).to eq('my-template')
    end
  end

  describe '.create' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:post, anything)
        .and_return(template_attrs)
    end

    it 'creates and returns a Template' do
      result = described_class.create(
        identifier: 'my-template',
        body: '<h1>Hello</h1>'
      )
      expect(result).to be_a(described_class)
      expect(result.id).to eq('tpl-1')
    end

    it 'remaps body to body_draft' do
      sent_resource = nil
      allow(adapter).to receive(:call).with(:post, anything) do |_, resource|
        sent_resource = JSON.parse(resource.to_json)
        template_attrs
      end

      described_class.create(identifier: 'my-template', body: '<h1>Hello</h1>')

      expect(sent_resource['document_template']).to include('body_draft' => '<h1>Hello</h1>')
      expect(sent_resource['document_template']).not_to have_key('body')
    end

    it 'remaps scss_style to scss_style_draft' do
      sent_resource = nil
      allow(adapter).to receive(:call).with(:post, anything) do |_, resource|
        sent_resource = JSON.parse(resource.to_json)
        template_attrs
      end

      described_class.create(identifier: 'x', scss_style: '.red { color: red }')

      expect(sent_resource['document_template']).to include('scss_style_draft' => '.red { color: red }')
    end

    it 'remaps pdf_engine_id to pdf_engine_draft_id' do
      sent_resource = nil
      allow(adapter).to receive(:call).with(:post, anything) do |_, resource|
        sent_resource = JSON.parse(resource.to_json)
        template_attrs
      end

      described_class.create(identifier: 'x', pdf_engine_id: 'engine-1')

      expect(sent_resource['document_template']).to include('pdf_engine_draft_id' => 'engine-1')
    end
  end

  describe '.delete' do
    before do
      allow(Pdfmonkey::Adapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:call)
        .with(:delete, anything)
        .and_return(true)
    end

    it 'deletes the template' do
      expect(described_class.delete('tpl-1')).to be true
    end
  end

  describe '.list_cards' do
    it 'delegates to TemplateCard.list' do
      expect(Pdfmonkey::TemplateCard).to receive(:list).with(workspace_id: 'ws-1').and_return(:result)
      expect(described_class.list_cards(workspace_id: 'ws-1')).to eq(:result)
    end
  end

  describe '.fetch_full' do
    it 'delegates to .fetch' do
      expect(described_class).to receive(:fetch).with('tpl-1').and_return(:template)
      expect(described_class.fetch_full('tpl-1')).to eq(:template)
    end
  end

  describe '#update!' do
    subject { described_class.new(adapter: adapter, id: 'tpl-1', body_draft: '<h1>Old</h1>') }

    before do
      allow(adapter).to receive(:call)
        .with(:put, subject)
        .and_return('id' => 'tpl-1', 'body_draft' => '<h1>New</h1>')
    end

    it 'remaps body to body_draft and sends a PUT request' do
      subject.update!(body: '<h1>New</h1>')
      expect(subject.body_draft).to eq('<h1>New</h1>')
    end

    it 'returns self' do
      expect(subject.update!(body: '<h1>New</h1>')).to be subject
    end
  end

  describe '#publish!' do
    subject do
      described_class.new(
        adapter: adapter,
        id: 'tpl-1',
        body_draft: '<h1>Draft</h1>',
        scss_style_draft: '.draft {}',
        settings_draft: '{}',
        sample_data_draft: '{"x":1}',
        pdf_engine_draft_id: 'engine-1'
      )
    end

    before do
      allow(adapter).to receive(:call)
        .with(:put, subject)
        .and_return(
          'id' => 'tpl-1',
          'body' => '<h1>Draft</h1>',
          'body_draft' => '<h1>Draft</h1>',
          'scss_style' => '.draft {}',
          'scss_style_draft' => '.draft {}',
          'settings' => '{}',
          'settings_draft' => '{}',
          'sample_data' => '{"x":1}',
          'sample_data_draft' => '{"x":1}',
          'pdf_engine_id' => 'engine-1',
          'pdf_engine_draft_id' => 'engine-1'
        )
    end

    it 'copies draft fields to published fields' do
      subject.publish!
      expect(subject.body).to eq('<h1>Draft</h1>')
      expect(subject.scss_style).to eq('.draft {}')
      expect(subject.settings).to eq('{}')
      expect(subject.sample_data).to eq('{"x":1}')
      expect(subject.pdf_engine_id).to eq('engine-1')
    end

    it 'sends a PUT request' do
      subject.publish!
      expect(adapter).to have_received(:call).with(:put, subject)
    end

    it 'returns self' do
      expect(subject.publish!).to be subject
    end
  end

  describe '#reload!' do
    subject { described_class.new(adapter: adapter, id: 'tpl-1') }

    before do
      allow(adapter).to receive(:call)
        .with(:get, subject)
        .and_return(template_attrs)
    end

    it 'reloads the template' do
      subject.reload!
      expect(subject.body).to eq('<h1>Hello</h1>')
    end
  end

  describe '#delete!' do
    subject { described_class.new(adapter: adapter, id: 'tpl-1') }

    it 'sends a delete request' do
      expect(adapter).to receive(:call).with(:delete, subject).and_return(true)
      expect(subject.delete!).to be true
    end
  end
end
