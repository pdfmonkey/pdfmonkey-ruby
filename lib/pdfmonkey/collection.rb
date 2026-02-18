# frozen_string_literal: true

module Pdfmonkey
  class Collection
    include Enumerable

    attr_reader :items, :current_page, :total_pages,
                :next_page_number, :prev_page_number

    def initialize(items:, meta:, page_fetcher:)
      @items = items.dup.freeze
      @current_page = meta['current_page']
      @total_pages = meta['total_pages']
      @next_page_number = meta['next_page']
      @prev_page_number = meta['prev_page']
      @page_fetcher = page_fetcher
    end

    def each(&)
      items.each(&)
    end

    def next_page
      return unless next_page_number

      page_fetcher.call(next_page_number)
    end

    def prev_page
      return unless prev_page_number

      page_fetcher.call(prev_page_number)
    end

    private attr_reader :page_fetcher
  end
end
