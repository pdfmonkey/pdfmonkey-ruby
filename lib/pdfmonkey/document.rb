# frozen_string_literal: true

require 'forwardable'
require 'json'
require 'ostruct'

module Pdfmonkey
  class Document
    extend Forwardable

    ATTRIBUTES = %i[
      app_id
      checksum
      created_at
      document_template_id
      download_url
      id
      meta
      payload
      preview_url
      status
      updated_at
    ].freeze

    COMPLETE_STATUSES = %w[failure success].freeze
    COLLECTION = 'documents'
    MEMBER = 'document'

    attr_reader :attributes
    def_delegators :attributes, *ATTRIBUTES

    def self.generate!(document_template_id, payload)
      document = generate(document_template_id, payload)
      document.reload! until COMPLETE_STATUSES.include?(document.status)
      document
    end

    def self.generate(template_id, payload)
      document = new(
        document_template_id: template_id,
        payload: payload.to_json,
        status: 'pending')

      document.send(:save)
    end

    def initialize(adapter: Pdfmonkey::Adapter.new, **attributes)
      @adapter = adapter
      @attributes = OpenStruct.new(ATTRIBUTES.zip([]).to_h)
      update(attributes)
    end

    def reload!
      attributes = adapter.call(:get, self)
      update(attributes)
      self
    end

    def to_json
      { document: attributes.to_h }.to_json
    end

    private def save
      attributes = adapter.call(:post, self)
      update(attributes)
      self
    end

    private def update(new_attributes)
      new_attributes.each do |key, value|
        sym_key = key.to_sym
        attributes[sym_key] = value if ATTRIBUTES.include?(sym_key)
      end
    end

    private

    attr_reader :adapter
  end
end
