# frozen_string_literal: true

module Pdfmonkey
  class Template < Resource
    include Fetchable
    include Creatable
    include Updatable
    include Deletable

    ATTRIBUTES = %i[
      app_id
      auth_token
      body
      body_draft
      checksum
      created_at
      deleted_at
      edition_mode
      errors
      id
      identifier
      output_type
      pdf_engine_draft_id
      pdf_engine_id
      preview_url
      sample_data
      sample_data_draft
      scss_style
      scss_style_draft
      settings
      settings_draft
      template_folder_id
      ttl
      updated_at
    ].freeze

    DRAFT_MAPPING = {
      body: :body_draft,
      scss_style: :scss_style_draft,
      settings: :settings_draft,
      sample_data: :sample_data_draft,
      pdf_engine_id: :pdf_engine_draft_id
    }.freeze

    COLLECTION = 'document_templates'
    MEMBER = 'document_template'

    def_delegators :attributes, *ATTRIBUTES

    def self.create(**attrs)
      super(**remap_to_draft(attrs))
    end

    def self.list_cards(**)
      Pdfmonkey::TemplateCard.list(**)
    end

    def self.fetch_full(id)
      fetch(id)
    end

    def update!(**new_attrs)
      super(**self.class.send(:remap_to_draft, new_attrs))
    end

    def publish!
      DRAFT_MAPPING.each do |published_key, draft_key|
        attributes[published_key] = attributes[draft_key]
      end

      response_attrs = adapter.call(:put, self)
      update(response_attrs)
      self
    end

    private_class_method def self.remap_to_draft(attrs)
      attrs.transform_keys { |k| DRAFT_MAPPING.fetch(k, k) }
    end
  end
end
