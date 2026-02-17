# frozen_string_literal: true

require 'pdfmonkey/configuration'
require 'pdfmonkey/version'

module Pdfmonkey
  class Error < StandardError; end

  class ConnectionError < Error; end
  class GenerationError < Error
    attr_reader :document

    def initialize(message, document:)
      @document = document
      super(message)
    end
  end

  class ApiError < Error
    attr_reader :errors, :status_code

    def initialize(message, errors:, status_code:)
      @errors = errors
      @status_code = status_code
      super(message)
    end
  end

  ADAPTER_KEY = :pdfmonkey_adapter
  private_constant :ADAPTER_KEY

  def self.current_adapter
    Thread.current[ADAPTER_KEY]
  end

  def self.with_adapter(adapter)
    previous = Thread.current[ADAPTER_KEY]
    Thread.current[ADAPTER_KEY] = adapter
    yield
  ensure
    Thread.current[ADAPTER_KEY] = previous
  end
end

require 'pdfmonkey/adapter'
require 'pdfmonkey/collection'
require 'pdfmonkey/resource'
require 'pdfmonkey/current_user'
require 'pdfmonkey/document'
require 'pdfmonkey/document_card'
require 'pdfmonkey/engine'
require 'pdfmonkey/snippet'
require 'pdfmonkey/template'
require 'pdfmonkey/template_card'
require 'pdfmonkey/template_folder'
require 'pdfmonkey/webhook'
require 'pdfmonkey/workspace'
