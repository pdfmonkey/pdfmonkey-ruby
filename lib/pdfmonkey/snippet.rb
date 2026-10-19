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
      snippet_folder_id
      updated_at
      updater_name
      workspace_id
    ].freeze

    COLLECTION = 'snippets'
    MEMBER = 'snippet'

    FILTERS = {
      workspace_id: 'q[workspace_id]',
      folders: 'q[folders]',
      search: 'q[search]'
    }.freeze

    def_delegators :attributes, *ATTRIBUTES

    def self.list(workspace_id:, **)
      super
    end
  end
end
