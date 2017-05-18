#
# Copyright (C) 2011 - present Instructure, Inc.
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
#
module CC
  module LearningOutcomes
    def create_learning_outcomes(document=nil)
      return nil unless @course.has_outcomes?
      root_group = @course.root_outcome_group(false)
      return nil unless root_group

      if document
        outcomes_file = nil
        rel_path = nil
      else
        outcomes_file = File.new(File.join(@canvas_resource_dir, CCHelper::LEARNING_OUTCOMES), 'w')
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::LEARNING_OUTCOMES)
        document = Builder::XmlMarkup.new(:target=>outcomes_file, :indent=>2)
      end

      document.instruct!
      document.learningOutcomes(
          "xmlns" => CCHelper::CANVAS_NAMESPACE,
          "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
          "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |outs_node|
        @exported_outcome_ids = []

        process_outcome_group_content(outs_node, root_group)

        unless export_object?(LearningOutcome.new, 'learning_outcomes')
          # copy straggler outcomes that should be brought in implicitly
          @course.linked_learning_outcomes.where.not(:id => @exported_outcome_ids).each do |item|
            if export_object?(item, 'learning_outcomes')
              process_learning_outcome(outs_node, item)
            end
          end
        end
      end

      outcomes_file.close if outcomes_file
      rel_path
    end

    def process_outcome_group(node, group)
      migration_id = create_key(group)
      node.learningOutcomeGroup(:identifier=>migration_id) do |group_node|
        group_node.title group.title unless group.title.blank?
        group_node.description @html_exporter.html_content(group.description) unless group.description.blank?
        group_node.learningOutcomes do |lo_node|
          process_outcome_group_content(lo_node, group)
        end
      end
    end

    def process_outcome_group_content(node, group)
      group.child_outcome_groups.active.each do |item|
        next unless export_object?(item, 'learning_outcomes') || export_object?(item, 'learning_outcome_groups')
        process_outcome_group(node, item)
      end
      group.child_outcome_links.active.each do |item|
        item = item.content
        next unless export_object?(item, 'learning_outcomes')
        process_learning_outcome(node, item)
      end
    end

    def process_learning_outcome(node, item)
      @exported_outcome_ids << item.id

      add_exported_asset(item)

      migration_id = create_key(item)
      node.learningOutcome(:identifier=>migration_id) do |out_node|
        out_node.title item.short_description if item.short_description.present?
        out_node.description @html_exporter.html_content(item.description) if item.description.present?
        out_node.calculation_method item.calculation_method if item.calculation_method.present?
        out_node.calculation_int item.calculation_int if item.calculation_int.present?

        if item.context != @course
          out_node.is_global_outcome !item.context
          out_node.external_identifier item.id
        end

        if item.alignments.exists?
          out_node.alignments do |alignments_node|
            item.alignments.each do |alignment|
              alignments_node.alignment do |alignment_node|
                alignment_node.content_type alignment.content_type
                alignment_node.content_id create_key(alignment.content)
                alignment_node.mastery_type alignment.tag
                alignment_node.mastery_score alignment.mastery_score
                alignment_node.position alignment.position
              end
            end
          end
        end

        if item.data && criterion = item.data[:rubric_criterion]
          out_node.points_possible criterion[:points_possible] if criterion[:points_possible]
          out_node.mastery_points criterion[:mastery_points] if criterion[:mastery_points]
          if criterion[:ratings] && criterion[:ratings].length > 0
            out_node.ratings do |ratings_node|
              criterion[:ratings].each do |rating|
                ratings_node.rating do |rating_node|
                  rating_node.description rating[:description]
                  rating_node.points rating[:points]
                end
              end
            end
          end
        end
      end
    end
  end
end
