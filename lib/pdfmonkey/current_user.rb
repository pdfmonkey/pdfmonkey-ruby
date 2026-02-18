# frozen_string_literal: true

module Pdfmonkey
  class CurrentUser < Resource
    ATTRIBUTES = %i[
      auth_token
      available_documents
      block_resources
      created_at
      current_plan
      current_plan_interval
      desired_name
      email
      errors
      id
      lang
      paying_customer
      share_links
      trial_ends_on
      updated_at
    ].freeze

    COLLECTION = 'current_users'
    MEMBER = 'current_user'

    def_delegators :attributes, *ATTRIBUTES

    def self.fetch
      adapter = Pdfmonkey::Adapter.new
      attrs = adapter.call(:get, self, path: 'current_user')
      resource_attrs = attrs.transform_keys(&:to_sym)
      resource_attrs.delete(:adapter)
      new(adapter: adapter, **resource_attrs)
    end
  end
end
