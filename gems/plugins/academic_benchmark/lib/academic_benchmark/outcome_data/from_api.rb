module AcademicBenchmark
  module OutcomeData
    class FromApi < Base
      def initialize(options={})
        super(options.merge(AcademicBenchmark.config))
        unless partner_id.present? && partner_key.present?
          raise Canvas::Migration::Error,
            'partner_id & partner_key are required'
        end
      end
      delegate :authority, :document, :partner_id, :partner_key, to: :@options

      def data
        @_data ||= api.standards.send(api_method, guid, include_obsolete_standards: false)
      end

      def error_message
        "Couldn't update standards for guid '#{guid}'"
      end

      private
      def api
        @_api ||= AcademicBenchmarks::Api::Handle.new(
          partner_id:  partner_id,
          partner_key: partner_key
        )
      end

      def api_method
        authority.present? ? :authority_tree : :document_tree
      end

      def guid
        authority || document
      end
    end
  end
end
