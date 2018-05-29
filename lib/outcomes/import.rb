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

    class InvalidDataError < RuntimeError; end
    class DataFormatError < RuntimeError; end

    OBJECT_ONLY_FIELDS = %i[calculation_method calculation_int ratings].freeze
    VALID_WORKFLOWS = [nil, '', 'active', 'deleted'].freeze

    def check_object(object)
      %i[vendor_guid title].each do |field|
        next if object[field].present?
        raise InvalidDataError, I18n.t(
          'The "%{field}" field is required', field: field
        )
      end
      if object[:vendor_guid].match?(/\s/)
        raise InvalidDataError, I18n.t(
          'The "%{field}" field must have no spaces',
          field: 'vendor_guid'
        )
      end
      unless VALID_WORKFLOWS.include? object[:workflow_state]
        raise InvalidDataError, I18n.t(
          '"%{field}" must be either "%{active}" or "%{deleted}"',
          field: 'workflow_state',
          active: 'active',
          deleted: 'deleted'
        )
      end
    end

    def import_object(object)
      check_object(object)

      type = object[:object_type]
      if type == 'outcome'
        import_outcome(object)
      elsif type == 'group'
        import_group(object)
      else
        raise InvalidDataError, I18n.t(
          'Invalid %{field}: "%{type}"',
          field: 'object_type',
          type: type
        )
      end
    end

    def import_group(group)
      invalid = group.keys.select do |k|
        group[k].present? && OBJECT_ONLY_FIELDS.include?(k)
      end
      if invalid.present?
        raise InvalidDataError, I18n.t(
          'Invalid fields for a group: %{invalid}',
          invalid: invalid.map(&:to_s).inspect
        )
      end

      parents = find_parents(group)
      raise InvalidDataError, I18n.t("An outcome group can only have one parent") if parents.length > 1
      parent = parents.first

      model = find_prior_group(group)
      unless model.context == context
        raise InvalidDataError, I18n.t(
          'Group "%{guid}" exists in incorrect context',
          guid: group[:vendor_guid]
        )
      end
      if model.outcome_import_id == outcome_import_id
        raise InvalidDataError, I18n.t(
          'Group "%{guid}" has already appeared in this import',
          guid: group[:vendor_guid]
        )
      end
      model.vendor_guid = group[:vendor_guid]
      model.title = group[:title]
      model.description = group[:description] || ''
      model.workflow_state = group[:workflow_state].presence || 'active'
      model.learning_outcome_group = parent
      model.outcome_import_id = outcome_import_id
      model.save!

      if model.workflow_state == 'deleted'
        model.destroy!
      end

      model
    end

    def import_outcome(outcome)
      parents = find_parents(outcome)

      model = find_prior_outcome(outcome)
      model.context = context if model.new_record?
      unless context_visible?(model.context)
        raise InvalidDataError, I18n.t(
          'Outcome "%{guid}" not in visible context',
          guid: outcome[:vendor_guid]
        )
      end
      if model.outcome_import_id == outcome_import_id
        raise InvalidDataError, I18n.t(
          'Outcome "%{guid}" has already appeared in this import',
          guid: outcome[:vendor_guid]
        )
      end

      model.vendor_guid = outcome[:vendor_guid]
      model.title = outcome[:title]
      model.description = infer_nil_value(model, :description, outcome)
      model.display_name = infer_nil_value(model, :display_name, outcome)
      model.calculation_method = outcome[:calculation_method].presence || 'highest'
      model.calculation_int = outcome[:calculation_int]
      # let removing the outcome_links content tags delete the underlying outcome
      model.workflow_state = 'active' if outcome[:workflow_state] == 'active'

      prior_rubric = model.rubric_criterion || {}
      changed = ->(k) { outcome[k].present? && outcome[k] != prior_rubric[k] }
      rubric_change = changed.call(:ratings) || changed.call(:mastery_points)
      model.rubric_criterion = create_rubric(outcome[:ratings], outcome[:mastery_points]) if rubric_change

      if model.context == context
        model.outcome_import_id = outcome_import_id
        model.save!
      elsif non_vendor_guid_changes?(model)
        raise InvalidDataError, I18n.t(
          'Cannot modify outcome from another context: %{changes}; outcome must be modified in %{context}',
          changes: model.changes.keys.inspect,
          context: if model.context.present?
                     I18n.t('"%{name}"', name: model.context.name)
                   else
                     I18n.t('the global context')
                   end
        )
      end

      parents = [] if outcome[:workflow_state] == 'deleted'
      update_outcome_parents(model, parents)

      model
    end

    private

    # There is no representation for `nil` in the export format. All nil values
    # are seen as "" when re-imported. We don't want to change those values when
    # we re-import (and we want to be able to link to those values from other
    # contexts), so we infer cases where `nil` was probably exported as ""
    def infer_nil_value(model, key, outcome)
      prior = model.send(key)
      current = outcome[key]
      if current.blank? && prior.blank?
        prior
      else
        current
      end
    end

    def non_vendor_guid_changes?(model)
      model.has_changes_to_save? && !(model.changes_to_save.length == 1 &&
        model.changes_to_save.key?(
          AcademicBenchmark.use_new_guid_columns? ? 'vendor_guid_2' : 'vendor_guid'
        ))
    end

    def find_prior_outcome(outcome)
      match = /canvas_outcome:(\d+)/.match(outcome[:vendor_guid])
      if match
        canvas_id = match[1]
        begin
          LearningOutcome.find(canvas_id)
        rescue ActiveRecord::RecordNotFound
          raise InvalidDataError, I18n.t(
            'Outcome with canvas id "%{id}" not found',
            id: outcome[:canvas_id]
          )
        end
      else
        vendor_guid = outcome[:vendor_guid]
        prior = LearningOutcome.find_by(vendor_clause(vendor_guid))
        return prior if prior
        LearningOutcome.new(vendor_guid: vendor_guid)
      end
    end

    def find_prior_group(group)
      vendor_guid = group[:vendor_guid]
      clause = vendor_clause(group[:vendor_guid])

      prior = LearningOutcomeGroup.where(clause).find_by(context: context)
      return prior if prior

      match = /canvas_outcome_group:(\d+)/.match(group[:vendor_guid])
      if match
        canvas_id = match[1]
        begin
          by_id = LearningOutcomeGroup.find(canvas_id)
          return by_id if by_id.context == context
        rescue ActiveRecord::RecordNotFound
          raise InvalidDataError, I18n.t(
            'Outcome group with canvas id %{id} not found',
            id: group[:canvas_id]
          )
        end
      end

      LearningOutcomeGroup.new(vendor_guid: vendor_guid, context: context)
    end

    def create_rubric(ratings, mastery_points)
      rubric = {}
      rubric[:enable] = true
      rubric[:mastery_points] = mastery_points
      rubric[:ratings] = ratings.map.with_index { |v, i| [i, v] }.to_h
      rubric
    end

    def root_parent
      @root ||= LearningOutcomeGroup.find_or_create_root(context, true)
    end

    def find_parents(object)
      return [root_parent] if object[:parent_guids].nil? || object[:parent_guids].blank?

      guids = object[:parent_guids].strip.split
      LearningOutcomeGroup.where(context: context, outcome_import_id: outcome_import_id).
        where(plural_vendor_clause(guids)).
        tap do |parents|
          if parents.length < guids.length
            missing = guids - parents.map(&:vendor_guid)
            raise InvalidDataError, I18n.t(
              'Parent references not found prior to this row: %{missing}',
              missing: missing.inspect,
            )
          end
        end
    end

    def context_visible?(other_context)
      return true if other_context.nil?
      other_context == context || context.account_chain.include?(other_context)
    end

    def update_outcome_parents(outcome, parents)
      existing_links = ContentTag.learning_outcome_links.where(context: context, content: outcome)

      next_parent_ids = parents.map(&:id)
      resurrect = existing_links.
        where(associated_asset_id: next_parent_ids).
        where(associated_asset_type: 'LearningOutcomeGroup').
        where(workflow_state: 'deleted')
      resurrect.update_all(workflow_state: 'active')

      kill = existing_links.
        where.not(associated_asset_id: next_parent_ids).
        where(associated_asset_type: 'LearningOutcomeGroup').
        where(workflow_state: 'active')
      kill.destroy_all

      existing_parent_ids = existing_links.pluck(:associated_asset_id)
      new_parents = parents.reject { |p| existing_parent_ids.include?(p.id) }
      new_parents.each { |p| p.add_outcome(outcome) }
    end

    def outcome_import_id
      @outcome_import_id ||= @import&.id || SecureRandom.random_number(2**32)
    end
  end
end
