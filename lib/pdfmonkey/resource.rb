# frozen_string_literal: true

require 'forwardable'
require 'json'

module Pdfmonkey
  class Resource
    extend Forwardable

    module Fetchable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def fetch(id)
          new(id: id).reload!
        end
      end

      def reload!
        new_attrs = adapter.call(:get, self)
        update(new_attrs)
        self
      end
    end

    module Creatable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def create(**attrs)
          new(**attrs).save
        end
      end

      def save
        if attributes[:id] && !is_a?(Updatable)
          raise Pdfmonkey::Error, "Cannot save an existing #{self.class.name} (updates are not supported)"
        end

        method = attributes[:id] ? :put : :post
        new_attrs = adapter.call(method, self)
        update(new_attrs)
        self
      end
    end

    module Updatable
      def update!(**new_attrs)
        previous = {}
        new_attrs.each_key do |key|
          sym_key = key.to_sym
          previous[sym_key] = attributes[sym_key] if self.class::ATTRIBUTES.include?(sym_key)
        end

        update(new_attrs)
        response_attrs = adapter.call(:put, self)
        update(response_attrs)
        self
      rescue StandardError
        update(previous)
        raise
      end
    end

    module Deletable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def delete(id)
          new(id: id).delete!
        end
      end

      def delete!
        adapter.call(:delete, self)
      end
    end

    module Listable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def list(page: 'all', **filters)
          if const_defined?(:FILTERS, false)
            unknown = filters.keys - self::FILTERS.keys
            raise ArgumentError, "Unknown filter(s): #{unknown.join(', ')}" if unknown.any?
          elsif filters.any?
            raise ArgumentError, "#{name} does not support filters"
          end

          adapter = Pdfmonkey.current_adapter || Pdfmonkey::Adapter.new
          fetch_page(adapter, page: page, **filters)
        end

        private def fetch_page(adapter, page:, **filters)
          params = { 'page[number]' => page }

          if const_defined?(:FILTERS, false)
            self::FILTERS.each do |kwarg, api_param|
              params[api_param] = filters[kwarg] unless filters[kwarg].nil?
            end
          end

          body = adapter.call(:get, self, params: params, extract: :collection)

          collection_key = self::COLLECTION
          items = body.fetch(collection_key, []).map do |attrs|
            resource_attrs = attrs.transform_keys(&:to_sym)
            resource_attrs.delete(:adapter)
            new(adapter: adapter, **resource_attrs)
          end

          page_fetcher = lambda do |page_number|
            fetch_page(adapter, page: page_number, **filters)
          end

          Collection.new(
            items: items,
            meta: body.fetch('meta', {}),
            page_fetcher: page_fetcher
          )
        end
      end
    end

    def initialize(adapter: Pdfmonkey.current_adapter || Pdfmonkey::Adapter.new, **attrs)
      @adapter = adapter
      @attributes = self.class.attributes_struct.new
      update(attrs)
    end

    def ==(other)
      other.is_a?(self.class) && !attributes[:id].nil? && attributes[:id] == other.send(:attributes)[:id]
    end
    alias eql? ==

    def hash
      [self.class, attributes[:id] || object_id].hash
    end

    SENSITIVE_ATTRIBUTES = %i[auth_token].freeze

    def inspect
      attrs = self.class::ATTRIBUTES
              .filter_map do |key|
                next if attributes[key].nil?

                value = SENSITIVE_ATTRIBUTES.include?(key) ? '[FILTERED]' : attributes[key].inspect
                "#{key}: #{value}"
              end
              .join(', ')

      "#<#{self.class} #{attrs}>"
    end

    def to_h
      attributes.to_h
    end

    def to_json(state = nil)
      attrs = attributes.to_h.compact
      attrs.delete(:errors)

      member = self.class::MEMBER
      { member => attrs }.to_json(state)
    end

    ATTRIBUTES_STRUCT_MUTEX = Mutex.new
    private_constant :ATTRIBUTES_STRUCT_MUTEX

    def self.attributes_struct
      return @attributes_struct if @attributes_struct

      ATTRIBUTES_STRUCT_MUTEX.synchronize do
        @attributes_struct ||= Struct.new(*self::ATTRIBUTES, keyword_init: true)
      end
    end

    private attr_reader :adapter, :attributes

    private def update(new_attributes)
      valid_attrs = self.class::ATTRIBUTES
      new_attributes.each do |key, value|
        sym_key = key.to_sym
        attributes[sym_key] = value if valid_attrs.include?(sym_key)
      end
    end
  end
end
