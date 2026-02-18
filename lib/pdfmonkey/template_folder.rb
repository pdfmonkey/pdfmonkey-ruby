# frozen_string_literal: true

module Pdfmonkey
  class TemplateFolder < Resource
    include Fetchable
    include Creatable
    include Updatable
    include Deletable
    include Listable

    ATTRIBUTES = %i[
      app_id
      created_at
      errors
      id
      identifier
      updated_at
    ].freeze

    COLLECTION = 'template_folders'
    MEMBER = 'template_folder'

    def_delegators :attributes, *ATTRIBUTES
  end
end
