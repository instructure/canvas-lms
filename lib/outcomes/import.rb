# Copyright (C) 2013 - present Instructure, Inc.
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

module Outcomes
  module Import
    include OutcomeImporter

    class ParseError < RuntimeError
    end

    def import_object(object)
      type = object[:object_type]
      if type == 'outcome'
        import_outcome(object)
      elsif type == 'group'
        import_group(object)
      else
        raise ParseError, "Invalid object type: #{type}"
      end
    end

    def import_group(group)
      parents = find_parents(group)
      raise ParseError, "An outcome group can only have one parent" if parents.length > 1
      parent = parents.first

      # OUT-1885 : require title / vendor_guid fields

      LearningOutcomeGroup.create!(
        context: @context,
        vendor_guid: group[:vendor_guid],
        title: group[:title],
        description: group[:description] || '',
        workflow_state: group[:workflow_state] || 'active',
        learning_outcome_group: parent,
      )
    end

    def import_outcome(outcome)
      parents = find_parents(outcome)

      # OUT-1885 : require title / vendor_guid fields

      imported = LearningOutcome.new(
        context: @context,
        title: outcome[:title],
        vendor_guid: outcome[:vendor_guid],
        description: outcome[:description] || '',
        display_name: outcome[:display_name] || '',
        calculation_method: outcome[:calculation_method],
        calculation_int: outcome[:calculation_int],
        workflow_state: outcome[:workflow_state] || 'active',
      )

      imported.rubric_criterion = create_rubric(outcome[:ratings]) if outcome[:ratings].present?
      imported.save!

      parents.each { |parent| parent.add_outcome(imported) }
    end

    def create_rubric(ratings)
      rubric = {}
      rubric[:enable] = true
      rubric[:ratings] = ratings.map.with_index { |v, i| [i, v] }.to_h
      rubric
    end

    def root_parent
      @root ||= LearningOutcomeGroup.find_or_create_root(@context, true)
    end

    def find_parents(object)
      return [root_parent] if object[:parent_guids].nil? || object[:parent_guids].blank?

      guids = object[:parent_guids].strip.split
      # OUT-1885 : throw error on missing parents
      LearningOutcomeGroup.where(plural_vendor_clause(guids))
    end
  end

  # OUT-1885 : need lots of tests to verify that errors are thrown properly
end
