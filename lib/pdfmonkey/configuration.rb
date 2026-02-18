# frozen_string_literal: true

module Pdfmonkey
  class Configuration
    attr_accessor :host, :keep_alive_timeout, :namespace,
                  :open_timeout, :poll_interval, :private_key, :read_timeout

    def initialize
      @host = 'https://api.pdfmonkey.io'
      @keep_alive_timeout = 30
      @namespace = 'api/v1'
      @open_timeout = 30
      @poll_interval = 0.5
      @private_key = ENV.fetch('PDFMONKEY_PRIVATE_KEY', nil)
      @read_timeout = 30
    end

    def user_agent
      "pdfmonkey-ruby/#{Pdfmonkey::VERSION}"
    end

    def inspect
      "#<#{self.class} host=#{host.inspect} namespace=#{namespace.inspect}>"
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
