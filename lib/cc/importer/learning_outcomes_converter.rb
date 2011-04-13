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
module CC::Importer
  module LearningOutcomesConverter
    include CC::Importer
    
    def convert_learning_outcomes(doc)
      outcomes = []
      return outcomes unless doc
      
      doc.at_css('learningOutcomes').children.each do |child|
        if child.name == 'learningOutcome'
          outcomes << process_learning_outcome(child)
        elsif child.name == 'learningOutcomeGroup'
          outcomes << process_outcome_group(child)
        end
      end
      
      outcomes
    end
    
    def process_outcome_group(node)
      group = {}
      group[:migration_id] = node['identifier']
      group[:title] = get_val_if_child(node, 'title')
      group[:type] = 'learning_outcome_group'
      group[:description] = get_val_if_child(node, 'description')
      group[:outcomes] = []
      
      node.css('learningOutcome').each do |out_node|
        group[:outcomes] << process_learning_outcome(out_node)
      end
      
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
      outcome[:ratings] = []
      
      node.css('rating').each do |r_node|
        rating = {}
        rating[:description] = get_node_val(r_node, 'description')
        rating[:points] = get_float_val(r_node, 'points')
        outcome[:ratings] << rating
      end
      
      outcome
    end
    
  end
end
