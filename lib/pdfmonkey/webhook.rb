# frozen_string_literal: true

module Pdfmonkey
  class Webhook < Resource
    include Creatable
    include Deletable

    ATTRIBUTES = %i[
      created_at
      custom_channel
      document_template_ids
      errors
      event
      id
      platform
      updated_at
      url
      workspace_id
    ].freeze

    COLLECTION = 'rest_hooks'
    MEMBER = 'rest_hook'

    def_delegators :attributes, *ATTRIBUTES
  end
end
