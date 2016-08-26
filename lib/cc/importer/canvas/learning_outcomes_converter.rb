#
# Copyright (C) 2011 Instructure, Inc.
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
module CC::Importer::Canvas
  module LearningOutcomesConverter
    include CC::Importer

    def convert_learning_outcomes(doc)
      return [] unless doc

      process_outcome_children(doc.at_css('learningOutcomes'))
    end

    def process_outcome_children(node, list=[])
      return list unless node

      node.children.each do |child|
        if child.name == 'learningOutcome'
          list << process_learning_outcome(child)
        elsif child.name == 'learningOutcomeGroup'
          list << process_outcome_group(child)
        end
      end

      list
    end

    def process_outcome_group(node)
      group = {}
      group[:migration_id] = node['identifier']
      group[:title] = get_val_if_child(node, 'title')
      group[:type] = 'learning_outcome_group'
      group[:description] = get_val_if_child(node, 'description')
      group[:outcomes] = process_outcome_children(node.at_css('learningOutcomes'))

      group
    end

    def process_learning_outcome(node)
      outcome = {}
      outcome[:migration_id] = node['identifier']
      outcome[:title] = get_node_val(node, 'title')
      outcome[:type] = 'learning_outcome'
      outcome[:description] = get_val_if_child(node, 'description')
      outcome[:mastery_points] = get_float_val(node, 'mastery_points')
      outcome[:points_possible] = get_float_val(node, 'points_possible')
      outcome[:calculation_method] = get_node_val(node, 'calculation_method')
      outcome[:calculation_int] = get_int_val(node, 'calculation_int')
      outcome[:is_global_outcome] = get_bool_val(node, 'is_global_outcome')
      outcome[:external_identifier] = get_node_val(node, 'external_identifier')

      outcome[:ratings] = []
      node.css('rating').each do |r_node|
        rating = {}
        rating[:description] = get_node_val(r_node, 'description')
        rating[:points] = get_float_val(r_node, 'points')
        outcome[:ratings] << rating
      end

      outcome[:alignments] = []
      node.css('alignments alignment').each do |align_node|
        alignment = {}
        alignment[:content_type] = get_node_val(align_node, 'content_type')
        alignment[:content_id] = get_node_val(align_node, 'content_id')
        alignment[:mastery_type] = get_node_val(align_node, 'mastery_type')
        alignment[:mastery_score] = get_float_val(align_node, 'mastery_score')
        alignment[:position] = get_int_val(align_node, 'position')
        outcome[:alignments] << alignment
      end

      outcome
    end

  end
end
