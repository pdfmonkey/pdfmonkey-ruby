# frozen_string_literal: true

module Pdfmonkey
  class Document < Resource
    include Fetchable
    include Creatable
    include Updatable
    include Deletable

    ATTRIBUTES = %i[
      app_id
      checksum
      created_at
      document_template_id
      download_url
      errors
      failure_cause
      filename
      generation_logs
      id
      meta
      output_type
      payload
      preview_url
      public_share_link
      status
      updated_at
    ].freeze

    COMPLETE_STATUSES = %w[error failure success].freeze
    FAILURE_STATUSES = %w[error failure].freeze
    COLLECTION = 'documents'
    MEMBER = 'document'

    def_delegators :attributes, *ATTRIBUTES

    def self.generate!(*args, document_template_id: nil, payload: nil, meta: nil)
      document_template_id, payload, meta =
        resolve_document_args(args, document_template_id, payload, meta, __method__)
      validate_template_id!(document_template_id)

      generate(document_template_id: document_template_id, payload: payload, meta: meta)
        .send(:poll_until_done!)
    end

    def self.generate(*args, document_template_id: nil, payload: nil, meta: nil)
      create_document('pending', args, document_template_id, payload, meta, __method__)
    end

    def self.create_draft(*args, document_template_id: nil, payload: nil, meta: nil)
      create_document('draft', args, document_template_id, payload, meta, __method__)
    end

    private_class_method def self.create_document(status, args, document_template_id, payload, meta, method_name)
      document_template_id, payload, meta =
        resolve_document_args(args, document_template_id, payload, meta, method_name)
      validate_template_id!(document_template_id)

      new(
        document_template_id: document_template_id,
        meta: json_encode(meta),
        payload: json_encode(payload),
        status: status
      ).save
    end

    private_class_method def self.validate_template_id!(template_id)
      return unless template_id.nil? || template_id.to_s.strip.empty?

      raise ArgumentError, 'document_template_id is required'
    end

    private_class_method def self.json_encode(value)
      case value
      when nil then nil
      when String then value
      else value.to_json
      end
    end

    private_class_method def self.resolve_document_args(args, kw_template_id, kw_payload, meta, method_name)
      if args.any?
        warn "[PDFMonkey] Positional arguments for Document.#{method_name} are deprecated. " \
             'Use keyword arguments instead: ' \
             "Document.#{method_name}(document_template_id:, payload:, meta:)",
             uplevel: 2
        [args[0], args[1], args[2] || meta]
      else
        [kw_template_id, kw_payload, meta]
      end
    end

    def self.list_cards(**)
      Pdfmonkey::DocumentCard.list(**)
    end

    def self.fetch_card(id)
      Pdfmonkey::DocumentCard.fetch(id)
    end

    def self.fetch_full(id)
      fetch(id)
    end

    def generate
      update!(status: 'pending')
    end

    def generate!
      generate
      poll_until_done!
    end

    def done?
      COMPLETE_STATUSES.include?(status)
    end

    private def poll_until_done!
      until done?
        sleep(Pdfmonkey.configuration.poll_interval)
        reload!
      end

      if FAILURE_STATUSES.include?(status)
        message = 'Document generation failed'
        message += ": #{failure_cause}" if failure_cause
        raise Pdfmonkey::GenerationError.new(message, document: self)
      end

      self
    end
  end
end
