# frozen_string_literal: true

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
    class InvalidDataError < RuntimeError; end

    class DataFormatError < RuntimeError; end

    GROUP_ONLY_FIELDS = %i[course_id].freeze
    OBJECT_ONLY_FIELDS = %i[calculation_method calculation_int ratings].freeze
    VALID_WORKFLOWS = [nil, "", "active", "deleted"].freeze

    def check_object(object)
      %i[vendor_guid title].each do |field|
        next if object[field].present?

        raise InvalidDataError, I18n.t(
          'The "%{field}" field is required', field:
        )
      end
      if object[:vendor_guid].match?(/\s/)
        raise InvalidDataError, I18n.t(
          'The "%{field}" field must have no spaces',
          field: "vendor_guid"
        )
      end
      unless VALID_WORKFLOWS.include? object[:workflow_state]
        raise InvalidDataError, I18n.t(
          '"%{field}" must be either "%{active}" or "%{deleted}"',
          field: "workflow_state",
          active: "active",
          deleted: "deleted"
        )
      end
    end

    def import_object(object)
      check_object(object)

      type = object[:object_type]
      case type
      when "outcome"
        import_outcome(object)
      when "group"
        import_group(object)
      else
        raise InvalidDataError, I18n.t(
          'Invalid %{field}: "%{type}"',
          field: "object_type",
          type:
        )
      end
    end

    def import_group(group)
      invalid = group.keys.select do |k|
        group[k].present? && OBJECT_ONLY_FIELDS.include?(k)
      end
      if invalid.present?
        raise InvalidDataError, I18n.t(
          "Invalid fields for a group: %{invalid}",
          invalid: invalid.map(&:to_s).inspect
        )
      end

      group_context = context

      if group[:course_id].present?
        raise InvalidDataError, I18n.t("Cannot import to other courses") unless context.is_a?(Account)

        group_context = Course.find_by(id: group[:course_id])

        if group_context.nil?
          raise InvalidDataError, I18n.t(
            "Course with canvas id %{id} not found",
            id: group[:course_id]
          )
        end

        unless child_context?(group_context)
          raise InvalidDataError, I18n.t(
            "Target course %{course_id} is not a child of current account (%{name})",
            course_id: group[:course_id],
            name: context.name
          )
        end
      end

      model = find_prior_group(group, group_context)
      unless model.context == group_context
        raise InvalidDataError, I18n.t(
          "Group with ID %{guid} already exists in another unrelated course or account (%{name})",
          guid: group[:vendor_guid],
          name: model.context.name
        )
      end

      parents = find_parents(group, group_context, model:)
      raise InvalidDataError, I18n.t("An outcome group can only have one parent") if parents.length > 1

      parent = parents.first

      if model.outcome_import_id == outcome_import_id
        raise InvalidDataError, I18n.t(
          'Group "%{guid}" has already appeared in this import',
          guid: group[:vendor_guid]
        )
      end
      model.vendor_guid = group[:vendor_guid]
      model.title = group[:title]
      model.description = group[:description] || ""
      model.workflow_state = group[:workflow_state].presence || "active"
      model.learning_outcome_group = parent
      model.outcome_import_id = outcome_import_id
      model.save!

      if model.workflow_state == "deleted"
        model.destroy!
      end

      model
    end

    def import_outcome(outcome)
      invalid = outcome.keys.select do |k|
        outcome[k].present? && GROUP_ONLY_FIELDS.include?(k)
      end
      if invalid.present?
        raise InvalidDataError, I18n.t(
          "Invalid fields for an outcome: %{invalid}",
          invalid: invalid.map(&:to_s).inspect
        )
      end

      model = find_prior_outcome(outcome)
      model.context = context if model.new_record?

      unless child_context?(context, of: model.context)
        raise InvalidDataError, I18n.t(
          "Outcome with ID %{guid} already exists in another unrelated course or account (%{name})",
          guid: outcome[:vendor_guid],
          name: model.context.name
        )
      end

      allow_indirect = outcome.key?(:course_id)
      parents = find_parents(outcome, context, allow_indirect:)

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
      model.calculation_method = outcome[:calculation_method].presence || model.default_calculation_method
      model.calculation_int = outcome[:calculation_int].presence || model.default_calculation_int
      # let removing the outcome_links content tags delete the underlying outcome
      model.workflow_state = "active" unless outcome[:workflow_state] == "deleted"

      prior_rubric = model.rubric_criterion || {}
      changed = ->(k) { outcome[k].present? && outcome[k] != prior_rubric[k] }
      rubric_change = changed.call(:ratings) || changed.call(:mastery_points)
      model.rubric_criterion = create_rubric(outcome[:ratings], outcome[:mastery_points]) if rubric_change

      if model.context == context
        model.outcome_import_id = outcome_import_id
        model.save!
      elsif non_vendor_guid_changes?(model)
        raise InvalidDataError, I18n.t(
          "Cannot modify outcome from another context: %{changes}; outcome must be modified in %{context}",
          changes: model.changes.keys.inspect,
          context: if model.context.present?
                     I18n.t('"%{name}"', name: model.context.name)
                   else
                     I18n.t("the global context")
                   end
        )
      end

      parents = [] if outcome[:workflow_state] == "deleted"
      update_outcome_parents(model, parents, allow_indirect:)

      if outcome[:friendly_description].present?
        fd = OutcomeFriendlyDescription.find_or_create_by(context: model.context, learning_outcome: model)
        fd.update(description: outcome[:friendly_description])
        fd.update(workflow_state: "active")
      else
        fd = OutcomeFriendlyDescription.find_by(context: model.context, learning_outcome: model)
        fd&.update(workflow_state: "deleted")
      end

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
        model.changes_to_save.key?("vendor_guid"))
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
        prior = LearningOutcome.where(vendor_guid:).active_first.first
        return prior if prior

        LearningOutcome.new(vendor_guid:)
      end
    end

    def find_prior_group(group, group_context)
      vendor_guid = group[:vendor_guid]
      prior = LearningOutcomeGroup.where(context: group_context).where(vendor_guid:).active_first.first
      return prior if prior

      match = /canvas_outcome_group:(\d+)/.match(vendor_guid)
      if match
        canvas_id = match[1]
        begin
          by_id = LearningOutcomeGroup.find(canvas_id)
          return by_id if by_id.context == group_context
        rescue ActiveRecord::RecordNotFound
          raise InvalidDataError, I18n.t(
            "Outcome group with canvas id %{id} not found",
            id: group[:canvas_id]
          )
        end
      end

      LearningOutcomeGroup.new(vendor_guid:, context: group_context)
    end

    def create_rubric(ratings, mastery_points)
      rubric = {}
      rubric[:enable] = true
      rubric[:mastery_points] = mastery_points
      rubric[:ratings] = ratings.map.with_index { |v, i| [i, v] }.to_h
      rubric
    end

    def root_parent(given_context)
      @root_parents ||= {}
      @root_parents[given_context] ||= LearningOutcomeGroup.find_or_create_root(given_context, true)
    end

    def find_parents(object, given_context, allow_indirect: false, model: nil)
      if !model.nil? && !model.new_record? && object[:learning_outcome_group_id]
        parent_group = LearningOutcomeGroup.find(object[:learning_outcome_group_id])
        if parent_group.ancestor_ids.member?(model.id)
          raise InvalidDataError, I18n.t(
            "Cyclic reference detected when importing: %{vendor_guid}",
            vendor_guid: object[:vendor_guid]
          )
        end
      end
      if object[:parent_guids].nil? || object[:parent_guids].blank?
        group = [LearningOutcomeGroup.find(object[:learning_outcome_group_id])] if object[:learning_outcome_group_id]
        group ||= [root_parent(given_context)]

        return group
      end

      guids = object[:parent_guids].strip.split.uniq
      possible_parents = LearningOutcomeGroup.where(outcome_import_id:, vendor_guid: guids)

      # If allow_indirect is true, we could `filter{|g| child_context?(g.context) }`, but it is costly and
      # redundant (since outcome_import_id matching is already enforced)
      possible_parents = possible_parents.where(context: given_context) unless allow_indirect

      found_guids = possible_parents.distinct.pluck(:vendor_guid)
      if found_guids.length < guids.length
        missing = guids - found_guids
        raise InvalidDataError, I18n.t(
          "Parent references not found prior to this row: %{missing}",
          missing: missing.inspect
        )
      end

      possible_parents
    end

    def child_context?(child, of: context)
      return true if of.nil?

      of == child || child.account_chain.include?(of)
    end

    def update_outcome_parents(outcome, parents, allow_indirect: false)
      next_parent_ids = parents.pluck(:id)
      existing_links = ContentTag.learning_outcome_links.where(content: outcome)
      existing_parent_ids = existing_links.pluck(:associated_asset_id)

      resurrect = existing_links
                  .where(associated_asset_id: next_parent_ids)
                  .where(associated_asset_type: "LearningOutcomeGroup")
                  .where(workflow_state: "deleted")
      resurrect.update_all(workflow_state: "active")

      # add new parents before removing old to avoid deleting last link
      # to an aligned outcome
      new_parent_ids = Set.new(next_parent_ids) - existing_parent_ids
      new_parent_ids.each_slice(1000) do |batch|
        LearningOutcomeGroup.bulk_link_outcome(outcome, LearningOutcomeGroup.where(id: batch), root_account_id:)
      end

      kill = existing_links
             .where.not(associated_asset_id: next_parent_ids)
             .where(associated_asset_type: "LearningOutcomeGroup")
             .where(workflow_state: "active")

      # The kill list needs additional scoping logic because (unlike the above cases) it can't leverage the scoping of next_parent_ids
      if allow_indirect && context.is_a?(Account)
        subaccount_ids = Account.sub_account_ids_recursive(context.id)
        kill = kill.where(context: [Account.where(id: [context.id, subaccount_ids]), Course.where(account_id: subaccount_ids)])
      else
        kill = kill.where(context: outcome.context)
      end

      found_keeper = false
      kill.in_batches(of: 1000) do |kill_batch|
        undeletable_ids = kill_batch.joins(<<~SQL.squish).pluck(:id)
          INNER JOIN #{ContentTag.quoted_table_name} associations
            ON associations.tag_type = 'learning_outcome'
            AND associations.learning_outcome_id = content_tags.content_id
            AND associations.context_id = content_tags.context_id
            AND associations.context_type = content_tags.context_type
        SQL
        found_keeper ||= undeletable_ids.present?
        kill_batch.where.not(id: undeletable_ids).update_all(workflow_state: "deleted", updated_at: Time.now.utc)
      end

      unless found_keeper || new_parent_ids.present? || ContentTag.learning_outcome_links.active.where(content: outcome).present?
        outcome.destroy
      end
    end

    def outcome_import_id
      @outcome_import_id ||= @import&.id || SecureRandom.random_number(2**32)
    end

    def root_account_id
      case context
      when Account
        context.resolved_root_account_id
      else
        context&.root_account_id
      end
    end
  end
end
