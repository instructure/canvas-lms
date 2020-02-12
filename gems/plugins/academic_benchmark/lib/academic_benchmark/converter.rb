#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require 'academic_benchmarks'

module AcademicBenchmark
  class Converter < Canvas::Migration::Migrator
    COMMON_CORE_GUID = 'A83297F2-901A-11DF-A622-0C319DFF4B22'.freeze

    def initialize(settings={})
      super(settings, "academic_benchmark")
      @ratings_overrides = settings[:migration_options] || {}
      @course[:learning_outcomes] = []
      @partner_id = settings[:partner_id]
      @partner_key = settings[:partner_key]
    end

    def export
      unless content_migration
        raise Canvas::Migration::Error,
          "Missing required content_migration settings"
      end
      unless Account.site_admin.grants_right?(content_migration.user, :manage_global_outcomes)
        raise Canvas::Migration::Error,
          "User isn't allowed to edit global outcomes"
      end
      unless @archive_file
        unless @partner_id.present? || AcademicBenchmark.ensure_partner_id.nil?
          raise Canvas::Migration::Error, I18n.t("A partner ID is required to use Academic Benchmarks")
        end
        unless @partner_key.present? || AcademicBenchmark.ensure_partner_key.nil?
          raise Canvas::Migration::Error, I18n.t("A partner key is required to use Academic Benchmarks")
        end
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
    end

    def post_process; end

    private
    def outcome_data
      unless @_outcome_data
        begin
          if !@archive_file.nil? && settings[:archive_file].nil?
            settings[:archive_file] = @archive_file
          end
          fetcher = OutcomeData.load_data(settings)
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

SafeYAML.whitelist_class!(AcademicBenchmark::Converter)
