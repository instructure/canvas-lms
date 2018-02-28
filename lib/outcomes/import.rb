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

    OBJECT_ONLY_FIELDS = %i[calculation_method calculation_int ratings].freeze
    VALID_WORKFLOWS = ['', 'active', 'deleted'].freeze

    def check_object(object)
      raise ParseError, Messages.field_required('vendor_guid') if object[:vendor_guid].blank?
      raise ParseError, Messages.vendor_guid_no_spaces if object[:vendor_guid].include? ' '
      raise ParseError, Messages.field_required('title') if object[:title].blank?

      valid_workflow = VALID_WORKFLOWS.include? object[:workflow_state]
      raise ParseError, Messages.workflow_state_invalid unless valid_workflow
    end

    def import_object(object)
      check_object(object)

      type = object[:object_type]
      if type == 'outcome'
        import_outcome(object)
      elsif type == 'group'
        import_group(object)
      else
        raise ParseError, Messages.invalid_object_type(type)
      end
    end

    def import_group(group)
      invalid = group.keys.select do |k|
        group[k].present? && OBJECT_ONLY_FIELDS.include?(k)
      end
      raise ParseError, Messages.invalid_group_fields(invalid) if invalid.present?
      parents = find_parents(group)
      raise ParseError, Messages.group_single_parent if parents.length > 1
      parent = parents.first

      LearningOutcomeGroup.create!(
        context: context,
        vendor_guid: group[:vendor_guid],
        title: group[:title],
        description: group[:description] || '',
        workflow_state: group[:workflow_state] || 'active',
        learning_outcome_group: parent,
      )
    end

    def import_outcome(outcome)
      parents = find_parents(outcome)

      imported = LearningOutcome.new(
        context: context,
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
      @root ||= LearningOutcomeGroup.find_or_create_root(context, true)
    end

    def find_parents(object)
      return [root_parent] if object[:parent_guids].nil? || object[:parent_guids].blank?

      guids = object[:parent_guids].strip.split
      parents = LearningOutcomeGroup.where(plural_vendor_clause(guids)).to_a
      missing = guids - parents.map(&:vendor_guid)
      raise ParseError, Messages.missing_parents(missing) if missing.present?

      parents
    end

    module Messages
      def self.workflow_state_invalid
        I18n.t(
          '"%{field}" must be either "%{active}" or "%{deleted}"',
          field: 'workflow_state',
          active: 'active',
          deleted: 'deleted'
        )
      end

      def self.field_required(field)
        I18n.t('The "%{field}" field is required', field: field)
      end

      def self.vendor_guid_no_spaces
        I18n.t('The "%{field}" field must have no spaces', field: 'vendor_guid')
      end

      def self.invalid_object_type(type)
        I18n.t('Invalid %{field}: "%{type}"', field: 'object_type', type: type)
      end

      def self.invalid_group_fields(invalid)
        I18n.t('Invalid fields for a group: %{invalid}', invalid: invalid.map(&:to_s).inspect)
      end

      def self.group_single_parent
        I18n.t('An outcome group can only have one parent')
      end

      def self.missing_parents(missing)
        I18n.t('Missing parent groups: %{missing}', missing: missing.inspect)
      end
    end
  end
end
