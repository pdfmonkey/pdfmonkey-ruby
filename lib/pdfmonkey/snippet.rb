# frozen_string_literal: true

module Pdfmonkey
  class Snippet < Resource
    include Fetchable
    include Creatable
    include Updatable
    include Deletable
    include Listable

    ATTRIBUTES = %i[
      code
      created_at
      creator_name
      errors
      id
      identifier
      updated_at
      updater_name
      workspace_id
    ].freeze

    COLLECTION = 'snippets'
    MEMBER = 'snippet'

    def_delegators :attributes, *ATTRIBUTES
  end
end
