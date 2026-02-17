# frozen_string_literal: true

module Pdfmonkey
  class TemplateCard < Resource
    include Listable

    ATTRIBUTES = %i[
      app_id
      auth_token
      created_at
      edition_mode
      errors
      id
      identifier
      is_draft
      output_type
      pdf_engine_deprecated_on
      pdf_engine_name
      template_folder_id
      template_folder_identifier
      updated_at
    ].freeze

    COLLECTION = 'document_template_cards'
    MEMBER = 'document_template_card'

    FILTERS = {
      workspace_id: 'q[workspace_id]',
      folders: 'q[folders]',
      sort: 'sort'
    }.freeze

    def_delegators :attributes, *ATTRIBUTES

    def self.list(workspace_id:, **)
      super
    end

    def to_template
      Pdfmonkey::Template.fetch(id)
    end
  end
end
