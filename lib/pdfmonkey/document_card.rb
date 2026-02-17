# frozen_string_literal: true

module Pdfmonkey
  class DocumentCard < Resource
    include Fetchable
    include Listable

    ATTRIBUTES = %i[
      app_id
      created_at
      document_template_id
      document_template_identifier
      download_url
      errors
      failure_cause
      filename
      id
      meta
      output_type
      preview_url
      public_share_link
      status
      updated_at
    ].freeze

    COLLECTION = 'document_cards'
    MEMBER = 'document_card'

    FILTERS = {
      document_template_id: 'q[document_template_id]',
      status: 'q[status]',
      workspace_id: 'q[workspace_id]',
      updated_since: 'q[updated_since]'
    }.freeze

    def_delegators :attributes, *ATTRIBUTES

    def self.list(page: 1, **)
      super
    end

    def to_document
      Pdfmonkey::Document.fetch(id)
    end
  end
end
