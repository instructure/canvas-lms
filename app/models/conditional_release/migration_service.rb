# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module ConditionalRelease
  class MigrationService
    class << self
      def applies_to_course?(course)
        ConditionalRelease::Service.enabled_in_context?(course)
      end

      def begin_export(course, opts)
        assignment_ids = nil
        if opts[:selective]
          assignment_ids = opts[:exported_assets].filter_map { |asset| (match = asset.match(/assignment_(\d+)/)) && match[1] }
          return unless assignment_ids.any?
        end

        # just pretend like we started an export even if we're not actually hitting a service anymore
        { native: true, course:, assignment_ids: }
      end

      def export_completed?(export_data)
        export_data[:native]
      end

      def retrieve_export(export_data)
        generate_native_export(export_data[:course], export_data[:assignment_ids])
      end

      def generate_native_export(course, assignment_ids)
        data = { "native" => true }
        rules_scope = course.conditional_release_rules.active.order(:id).preload(ConditionalRelease::Rule.preload_associations)
        rules_scope = rules_scope.where(trigger_assignment_id: assignment_ids) if assignment_ids
        rules = rules_scope.to_a
        return unless rules.any? # nothing needs to be saved

        data["rules"] = rules.map do |rule|
          {
            "trigger_assignment_id" => { "$canvas_assignment_id" => rule.trigger_assignment_id }, # this tells canvas to translate this id on re-import
            "scoring_ranges" => rule.scoring_ranges.map do |range|
              {
                "lower_bound" => range.lower_bound,
                "upper_bound" => range.upper_bound,
                "assignment_sets" => range.assignment_sets.map do |set|
                  {
                    "assignment_set_associations" => set.assignment_set_associations.map do |assoc|
                      { "$canvas_assignment_id" => assoc.assignment_id }
                    end
                  }
                end
              }
            end
          }
        end
        data
      end

      def send_imported_content(course, _cm, imported_content)
        all_successful = true
        is_native = imported_content["native"]
        imported_content["rules"]&.each do |rule_hash|
          trigger_key = is_native ? "trigger_assignment_id" : "trigger_assignment"
          trigger_id = rule_hash[trigger_key]["$canvas_assignment_id"]
          next unless valid_id?(trigger_id)

          rule = course.conditional_release_rules.active.where(trigger_assignment_id: trigger_id).first
          # TODO: yes this is lazy as hell but mostly blame the jerk that originally wrote the conditional_release importer
          # if it becomes an issue, someday we could make these first-class migration objects (and even include some blueprint logic)
          # but today is not that day
          rule&.scoring_ranges&.destroy_all
          rule ||= course.conditional_release_rules.new(trigger_assignment_id: trigger_id)

          ranges = rule_hash["scoring_ranges"].map do |range_hash|
            range_hash["assignment_sets_attributes"] = range_hash.delete("assignment_sets").map do |set_hash|
              associations = []
              association_key = is_native ? "assignment_set_associations" : "assignments"
              set_hash.delete(association_key).each do |assoc_hash|
                assignment_id = assoc_hash["$canvas_assignment_id"]
                next unless valid_id?(assignment_id)

                associations << ({ assignment_id: })
              end
              set_hash["assignment_set_associations_attributes"] = associations
              set_hash
            end
            range_hash
          end
          all_successful = false unless rule.update(scoring_ranges_attributes: ranges)
        end
        if all_successful
          { native: true }
        else
          raise "not all rules were able to be saved"
        end
      end

      def valid_id?(id)
        id != Canvas::Migration::ExternalContent::Translator::NOT_FOUND
      end

      def import_completed?(import_data)
        import_data[:native]
      end
    end
  end
end
