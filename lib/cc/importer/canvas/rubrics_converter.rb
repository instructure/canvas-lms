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
module CC::Importer::Canvas
  module RubricsConverter
    include CC::Importer

    def convert_rubrics(doc)
      rubrics = []
      return rubrics unless doc

      doc.css('rubric').each do |r_node|
        rubric = {}
        rubric[:migration_id] = r_node['identifier']
        rubric[:description] = get_val_if_child(r_node, 'description')
        rubric[:title] = get_node_val(r_node, 'title')
        rubric[:read_only] = get_bool_val(r_node, 'read_only')
        rubric[:reusable] = get_bool_val(r_node, 'reusable')
        rubric[:public] = get_bool_val(r_node, 'public')
        rubric[:hide_score_total] = get_bool_val(r_node, 'hide_score_total')
        rubric[:free_form_criterion_comments] = get_bool_val(r_node, 'free_form_criterion_comments')
        rubric[:points_possible] = get_float_val(r_node, 'points_possible')
        rubric[:external_identifier] = get_node_val(r_node, 'external_identifier')

        rubric[:data] = []
        r_node.css('criterion').each do |c_node|
          crit = {}
          crit[:id] = get_node_val(c_node, 'criterion_id')
          crit[:description] = get_node_val(c_node, 'description')
          crit[:long_description] = get_val_if_child(c_node, 'long_description')
          crit[:points] = get_float_val(c_node, 'points')
          crit[:mastery_points] = get_float_val(c_node, 'mastery_points')
          crit[:ignore_for_scoring] = get_bool_val(c_node, 'ignore_for_scoring')
          crit[:learning_outcome_migration_id] = get_node_val(c_node, 'learning_outcome_identifierref')
          crit[:learning_outcome_external_identifier] = get_node_val(c_node, 'learning_outcome_external_identifier')
          crit[:title] = get_node_val(c_node, 'description')
          crit[:criterion_use_range] = get_bool_val(c_node, 'criterion_use_range')
          crit[:ratings] = []
          c_node.css('rating').each do |rat_node|
            rating = {}
            rating[:description] = get_node_val(rat_node, 'description')
            rating[:long_description] = get_node_val(rat_node, 'long_description')
            rating[:id] = get_node_val(rat_node, 'id')
            rating[:criterion_id] = get_node_val(rat_node, 'criterion_id')
            rating[:points] = get_float_val(rat_node, 'points')
            crit[:ratings] << rating
          end

          rubric[:data] << crit
        end

        rubrics << rubric
      end

      rubrics
    end

  end
end
