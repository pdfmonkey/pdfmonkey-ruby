RSpec.describe Pdfmonkey::Collection do
  let(:meta) {{
    'current_page' => 2,
    'total_pages' => 5,
    'next_page' => 3,
    'prev_page' => 1
  }}
  let(:items) { [double('item1'), double('item2')] }
  let(:page_fetcher) { double('page_fetcher') }

  subject do
    described_class.new(items: items, meta: meta, page_fetcher: page_fetcher)
  end

  describe '#each' do
    it 'iterates over items' do
      collected = []
      subject.each { |item| collected << item }
      expect(collected).to eq(items)
    end

    it 'is Enumerable' do
      expect(subject.count).to eq(2)
    end
  end

  describe '#current_page' do
    it 'returns the current page number' do
      expect(subject.current_page).to eq(2)
    end
  end

  describe '#total_pages' do
    it 'returns the total number of pages' do
      expect(subject.total_pages).to eq(5)
    end
  end

  describe '#next_page' do
    it 'fetches the next page' do
      next_collection = double('next_collection')
      allow(page_fetcher).to receive(:call).with(3).and_return(next_collection)

      expect(subject.next_page).to eq(next_collection)
    end

    context 'when there is no next page' do
      let(:meta) { super().merge('next_page' => nil) }

      it 'returns nil' do
        expect(subject.next_page).to be_nil
      end
    end
  end

  describe '#prev_page' do
    it 'fetches the previous page' do
      prev_collection = double('prev_collection')
      allow(page_fetcher).to receive(:call).with(1).and_return(prev_collection)

      expect(subject.prev_page).to eq(prev_collection)
    end

    context 'when there is no previous page' do
      let(:meta) { super().merge('prev_page' => nil) }

      it 'returns nil' do
        expect(subject.prev_page).to be_nil
      end
    end
  end
end
