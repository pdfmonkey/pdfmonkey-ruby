# frozen_string_literal: true

module Pdfmonkey
  class Workspace < Resource
    include Fetchable
    include Listable

    ATTRIBUTES = %i[
      errors
      id
      identifier
      invite_token
    ].freeze

    COLLECTION = 'workspaces'
    MEMBER = 'workspace'

    def_delegators :attributes, *ATTRIBUTES

    def self.list_cards(**)
      list(**)
    end
  end
end
