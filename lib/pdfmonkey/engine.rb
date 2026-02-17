# frozen_string_literal: true

module Pdfmonkey
  class Engine < Resource
    include Listable

    ATTRIBUTES = %i[
      deprecated_on
      errors
      id
      name
    ].freeze

    COLLECTION = 'pdf_engines'
    MEMBER = 'pdf_engine'

    def_delegators :attributes, *ATTRIBUTES
  end
end
