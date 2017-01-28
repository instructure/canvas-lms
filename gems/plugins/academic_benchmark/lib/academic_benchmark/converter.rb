require 'academic_benchmarks'

require 'academic_benchmark/ab_gem_extensions/standard'
require 'academic_benchmark/ab_gem_extensions/authority'
require 'academic_benchmark/ab_gem_extensions/document'

module AcademicBenchmark
  class Converter < Canvas::Migration::Migrator
    def initialize(settings={})
      super(settings, "academic_benchmark")
      @ratings_overrides = settings[:migration_options] || {}
      @course[:learning_outcomes] = []
      @converter_v1 = ConverterV1.new(settings)
      @partner_id = settings[:partner_id]
      @partner_key = settings[:partner_key]
    end

    def export
      if AcademicBenchmark.v3?
        unless content_migration
          raise Canvas::Migration::Error,
            "Missing required content_migration settings"
        end
        unless Account.site_admin.grants_right?(content_migration.user, :manage_global_outcomes)
          raise Canvas::Migration::Error,
            "User isn't allowed to edit global outcomes"
        end
        unless @partner_id.present? || AcademicBenchmark.ensure_partner_id.nil?
          raise Canvas::Migration::Error, I18n.t("A partner ID is required to use Academic Benchmarks")
        end
        unless @partner_key.present? || AcademicBenchmark.ensure_partner_key.nil?
          raise Canvas::Migration::Error, I18n.t("A partner key is required to use Academic Benchmarks")
        end
        if outcome_data.present?
          if outcome_data.instance_of? AcademicBenchmarks::Standards::StandardsForest
            outcome_data.trees.each do |t|
              @course[:learning_outcomes] << t.root.build_outcomes(@ratings_overrides)
            end
          else
            @course[:learning_outcomes] << outcome_data.root.build_outcomes(@ratings_overrides)
          end
        end
        save_to_file
        @course
      else
        @converter_v1.export
      end
    end

    def post_process
      unless AcademicBenchmark.v3?
        @converter_v1.post_process
      end
    end

    private
    def outcome_data
      unless @_outcome_data
        begin
          if !@archive_file.nil? && settings[:archive_file].nil?
            settings[:archive_file] = @archive_file
          end
          fetcher = Data.load_data(settings)
          @_outcome_data = fetcher.data
        rescue EOFError, APIError => e
          add_error(
            fetcher.error_message,
            { exception: e, error_message: e.message }
          )
        end
      end
      @_outcome_data
    end
  end
end
