# frozen_string_literal: true

require 'net/http'

module Pdfmonkey
  class Adapter
    def initialize(config: Pdfmonkey.configuration)
      @config = config
    end

    def call(method, resource)
      response = send_request(method, resource)

      case response
      when Net::HTTPNoContent then true
      when Net::HTTPSuccess then extract_attributes(response, resource)
      else extract_errors(response)
      end
    rescue StandardError => e
      { errors: [e.message], status: 'error' }
    end

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

    private def extract_attributes(response, resource)
      member = resource.class.const_get('MEMBER')
      JSON.parse(response.body).fetch(member)
    end

    private def extract_errors(response)
      payload = JSON.parse(response.body)
      errors = payload['errors'].to_a.map { |error| error['detail'] }

      { errors: errors, status: 'error' }
    end

    private def headers
      {
        'Authorization' => "Bearer #{config.private_key}",
        'Content-Type' => 'application/json',
        'User-Agent' => 'Ruby'
      }
    end

    private def send_request(method, resource)
      uri = URI(url_for(resource))
      request = send("build_#{method}_request", uri, resource)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.request(request)
    end

    private def url_for(resource)
      collection = resource.class.const_get('COLLECTION')
      endpoint = "#{config.host}/#{config.namespace}/#{collection}"
      endpoint += "/#{resource.id}" if resource.id
      endpoint
    end

    private

    attr_reader :config
  end
end
