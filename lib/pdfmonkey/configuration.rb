# frozen_string_literal: true

module Pdfmonkey
  class Configuration
    attr_accessor :host
    attr_accessor :namespace
    attr_accessor :private_key
    attr_accessor :user_agent

    def initialize
      @host = 'https://api.pdfmonkey.io'
      @namespace = 'api/v1'
      @private_key = ENV['PDFMONKEY_PRIVATE_KEY']
      @user_agent = 'Ruby'
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.configure
    yield configuration
  end
end
