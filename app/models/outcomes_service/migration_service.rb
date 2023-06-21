# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module OutcomesService
  class MigrationService
    class << self
      def applies_to_course?(course)
        course.root_account.feature_enabled?(:outcome_alignments_course_migration) &&
          OutcomesService::Service.enabled_in_context?(course)
      end

      def begin_export(course, opts)
        artifacts = export_artifacts(course, opts)
        return nil if artifacts.empty?

        data = {
          context_type: "course",
          context_id: course.id.to_s,
          export_settings: {
            format: "canvas",
            artifacts:
          }
        }
        content_exports_url = "#{OutcomesService::Service.url(course)}/api/content_exports"
        response = CanvasHttp.post(
          content_exports_url,
          headers_for(course, "content_migration.export", context_type: "course", context_id: course.id.to_s),
          body: data.to_json,
          content_type: "application/json"
        )
        if /^2/.match?(response.code.to_s)
          json = JSON.parse(response.body)
          { export_id: json["id"], course: }
        else
          raise "Error queueing export for Outcomes Service: #{response.body}"
        end
      end

      def export_completed?(export_data)
        content_export_url = "#{OutcomesService::Service.url(export_data[:course])}/api/content_exports/#{export_data[:export_id]}"
        response = CanvasHttp.get(
          content_export_url,
          headers_for(export_data[:course], "content_migration.export", id: export_data[:export_id])
        )
        if /^2/.match?(response.code.to_s)
          json = JSON.parse(response.body)
          case json["state"]
          when "completed"
            true
          when "failed"
            raise "Content Export for Outcomes Service failed"
          else
            false
          end
        else
          raise "Error retrieving export state for Outcomes Service: #{response.body}"
        end
      end

      def retrieve_export(export_data)
        content_export_url = "#{OutcomesService::Service.url(export_data[:course])}/api/content_exports/#{export_data[:export_id]}"
        response = CanvasHttp.get(
          content_export_url,
          headers_for(export_data[:course], "content_migration.export", id: export_data[:export_id])
        )
        if /^2/.match?(response.code.to_s)
          json = JSON.parse(response.body)
          json["data"]
        else
          raise "Error retrieving export for Outcomes Service: #{response.body}"
        end
      end

      def send_imported_content(course, content_migration, imported_content)
        content_imports_url = "#{OutcomesService::Service.url(course)}/api/content_imports"
        data = imported_content.merge(
          context_type: "course",
          context_id: course.id.to_s,
          external_migration_id: content_migration.id
        )
        extractor = OutcomesService::MigrationExtractor.new(content_migration)
        data = data.merge(
          outcomes: extractor.learning_outcomes(course),
          groups: extractor.learning_outcome_groups(course),
          edges: extractor.learning_outcome_links
        )
        response = CanvasHttp.post(
          content_imports_url,
          headers_for(course, "content_migration.import", context_type: "course", context_id: course.id.to_s),
          body: data.to_json,
          content_type: "application/json"
        )
        if /^2/.match?(response.code.to_s)
          json = JSON.parse(response.body)
          { import_id: json["id"], course:, content_migration: }
        else
          raise "Error sending import for Outcomes Service: #{response.body}"
        end
      end

      def import_completed?(import_data)
        content_import_url = "#{OutcomesService::Service.url(import_data[:course])}/api/content_imports/#{import_data[:import_id]}"
        response = CanvasHttp.get(
          content_import_url,
          headers_for(import_data[:course], "content_migration.import", id: import_data[:import_id])
        )
        if /^2/.match?(response.code.to_s)
          json = JSON.parse(response.body)
          json["missing_alignments"]&.each do |missing_alignment|
            page = lookup_artifact(missing_alignment["artifact_type"],
                                   missing_alignment["artifact_id"],
                                   import_data[:course])
            if page.nil?
              import_data[:content_migration].add_warning(I18n.t("Unable to align some outcomes to a page"))
            else
              import_data[:content_migration].add_warning(I18n.t('Unable to align some outcomes to "%{title}"',
                                                                 { title: page.title }))
            end
          end
          case json["state"]
          when "completed"
            true
          when "failed"
            failure_desc = "Content Import for Outcomes Service failed"
            add_failed_import_warning(import_data, failure_desc, json.to_s)
          else
            false
          end
        else
          failure_desc = "Error retrieving import state for Outcomes Service: #{response.body}"
          add_failed_import_warning(import_data, failure_desc)
        end
      end

      private

      def add_failed_import_warning(data, description, additional_info = "")
        data[:content_migration].add_warning(I18n.t("%{desc}", desc: description)) if data.key?(:content_migration)
        if additional_info.present?
          raise "#{description}: #{additional_info}"
        else
          raise description
        end
      end

      def lookup_artifact(artifact_type, artifact_id, course)
        case artifact_type
        when "canvas.page"
          course.wiki_pages.where(id: artifact_id).first
        end
      end

      def headers_for(course, scope, overrides = {})
        {
          "Authorization" => OutcomesService::Service.jwt(course, scope, overrides:)
        }
      end

      def export_artifacts(course, opts)
        page_ids = if opts[:selective]
                     opts[:exported_assets].filter_map { |asset| (match = asset.match(/wiki_page_(\d+)/)) && match[1] }
                   else
                     course.wiki_pages.pluck(:id)
                   end
        return [] unless page_ids.any?

        [{
          external_type: "canvas.page",
          external_id: page_ids
        }]
      end
    end
  end
end
