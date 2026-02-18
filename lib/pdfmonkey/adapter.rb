# frozen_string_literal: true

require 'json'
require 'net/http'

module Pdfmonkey
  class Adapter
    HTTP_METHODS = %i[delete get post put].freeze

    NETWORK_ERRORS = [
      IOError,
      SocketError,
      Net::OpenTimeout,
      Net::ReadTimeout,
      Net::WriteTimeout,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::EPIPE,
      Errno::ETIMEDOUT,
      OpenSSL::SSL::SSLError
    ].freeze

    def initialize(config: Pdfmonkey.configuration)
      @config = config
      @connection = nil
    end

    def call(method, resource, params: {}, path: nil, extract: :member)
      response = send_request(method, resource, params: params, path: path)

      case response
      when Net::HTTPNoContent then true
      when Net::HTTPSuccess then extract_data(response, resource, extract)
      else raise_api_error(response)
      end
    rescue *NETWORK_ERRORS => e
      reset_connection
      raise ConnectionError, e.message
    end

    def close
      close_connection
    end

    def inspect
      "#<#{self.class}>"
    end

    private attr_reader :config

    private def build_delete_request(uri, _resource)
      Net::HTTP::Delete.new(uri, headers)
    end

    private def build_get_request(uri, _resource)
      Net::HTTP::Get.new(uri, headers)
    end

    private def build_post_request(uri, resource)
      request = Net::HTTP::Post.new(uri, headers)
      request.body = resource.to_json
      request
    end

    private def build_put_request(uri, resource)
      request = Net::HTTP::Put.new(uri, headers)
      request.body = resource.to_json
      request
    end

    private def close_connection
      @connection&.finish
    rescue StandardError
      nil
    ensure
      @connection = nil
    end

    private def connection
      return @connection if @connection&.started?

      close_connection

      host_uri = URI(config.host)
      http = Net::HTTP.new(host_uri.host, host_uri.port)
      http.use_ssl = host_uri.scheme == 'https'
      http.open_timeout = config.open_timeout
      http.read_timeout = config.read_timeout
      http.keep_alive_timeout = config.keep_alive_timeout
      http.start
      @connection = http
    end

    private def extract_data(response, resource, extract)
      body = JSON.parse(response.body.to_s)

      case extract
      when :member
        resource_class = resource.is_a?(Class) ? resource : resource.class
        member = resource_class::MEMBER
        body.fetch(member) do
          raise ApiError.new(
            "Missing '#{member}' key in response",
            errors: [response.body],
            status_code: response.code.to_i
          )
        end
      when :collection
        body
      else
        raise ArgumentError, "Unknown extract mode: #{extract.inspect}"
      end
    rescue JSON::ParserError
      raise ApiError.new(
        'Invalid JSON in response body',
        errors: [response.body],
        status_code: response.code.to_i
      )
    end

    private def format_error_message(errors)
      case errors
      when Array then errors.join(', ')
      when Hash
        errors.map { |field, messages| "#{field}: #{Array(messages).join(', ')}" }.join('; ')
      else errors.to_s
      end
    end

    private def headers
      if config.private_key.nil? || config.private_key.to_s.strip.empty?
        raise Pdfmonkey::Error,
              'No API key configured. Set ENV["PDFMONKEY_PRIVATE_KEY"] or ' \
              'use Pdfmonkey.configure { |c| c.private_key = "..." }'
      end

      {
        'Authorization' => "Bearer #{config.private_key}",
        'Content-Type' => 'application/json',
        'User-Agent' => config.user_agent
      }
    end

    private def parse_error_body(response)
      payload = JSON.parse(response.body.to_s)

      if payload['error']
        [payload['error']]
      elsif payload['errors'].is_a?(Array)
        extract_error_messages(payload['errors'])
      elsif payload['errors'].is_a?(Hash)
        payload['errors']
      else
        [response.body]
      end
    rescue JSON::ParserError
      [response.body]
    end

    private def extract_error_messages(errors)
      errors.filter_map do |error|
        next error.to_s unless error.is_a?(Hash)

        error['detail'] || error['message'] || error.to_json
      end
    end

    private def raise_api_error(response)
      errors = parse_error_body(response)

      raise ApiError.new(
        format_error_message(errors),
        errors: errors,
        status_code: response.code.to_i
      )
    end

    private def reset_connection
      close_connection
    end

    private def send_request(method, resource, params: {}, path: nil)
      raise ArgumentError, "Unsupported HTTP method: #{method.inspect}" unless HTTP_METHODS.include?(method)

      uri = URI(url_for(resource, params: params, path: path))
      request = send("build_#{method}_request", uri, resource)
      connection.request(request)
    end

    private def url_for(resource, params: {}, path: nil)
      if path
        endpoint = "#{config.host}/#{config.namespace}/#{path}"
      else
        resource_class = resource.is_a?(Class) ? resource : resource.class
        collection = resource_class::COLLECTION
        endpoint = "#{config.host}/#{config.namespace}/#{collection}"
        endpoint += "/#{resource.id}" if !resource.is_a?(Class) && resource.id
      end

      endpoint += "?#{URI.encode_www_form(params)}" unless params.empty?

      endpoint
    end
  end
end
