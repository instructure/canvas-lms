# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Mutations::ImportOutcomes < Mutations::BaseMutation
  graphql_name "ImportOutcomes"

  argument :group_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("LearningOutcomeGroup")
  argument :outcome_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("LearningOutcome")
  argument :source_context_id, ID, required: false
  argument :source_context_type, String, required: false
  # after Remove target_context attributes, the target_group_id should be required
  argument :target_group_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("LearningOutcomeGroup")
  argument :target_context_id, ID, required: false
  argument :target_context_type, String, required: false

  field :progress, Types::ProgressType, null: true

  VALID_CONTEXTS = %w[Account Course].freeze

  def resolve(input:)
    source_context = nil
    if input[:source_context_type].present?
      if input[:source_context_id].present?
        begin
          source_context = context_class(input[:source_context_type]).find_by(id: input[:source_context_id])
        rescue NameError
          return validation_error(
            I18n.t("invalid value"), attribute: "sourceContextType"
          )
        end

        if source_context.nil?
          raise GraphQL::ExecutionError, I18n.t("no such source context")
        end
      else
        return validation_error(
          I18n.t("sourceContextId required if sourceContextType provided"),
          attribute: "sourceContextId"
        )
      end
    elsif input[:source_context_id].present?
      return validation_error(
        I18n.t("sourceContextType required if sourceContextId provided"),
        attribute: "sourceContextType"
      )
    end

    target_context, target_group = get_target(input)

    verify_authorized_action!(target_context, :manage_outcomes)

    if (group_id = input[:group_id].presence)
      # Import the entire group into the given context
      group = LearningOutcomeGroup.active.find_by(id: group_id)
      if group.nil?
        raise GraphQL::ExecutionError, I18n.t("group not found")
      end

      # If optional source context provided, then check that
      # matches the group's context
      source_context ||= group.context
      if source_context && source_context != group.context
        raise GraphQL::ExecutionError, I18n.t("source context does not match group context")
      end

      # source has to be global or in an associated account
      unless !source_context || target_context.associated_accounts.include?(source_context)
        raise GraphQL::ExecutionError, I18n.t("invalid context for group")
      end

      # source can't be a root group
      if group.learning_outcome_group_id.nil?
        raise GraphQL::ExecutionError, I18n.t("cannot import a root group")
      end

      return process_job(
        source_context:, group:, target_group:
      )
    elsif (outcome_id = input[:outcome_id].presence)
      # Import the selected outcome into the given group

      # verify the outcome is eligible to be linked into the group's context
      unless target_context.available_outcome(outcome_id, allow_global: true)
        raise GraphQL::ExecutionError, I18n.t(
          "Outcome %{outcome_id} is not available in context %{context_type}#%{context_id}",
          outcome_id:,
          context_id: target_context.id.to_s,
          context_type: target_context.class.name
        )
      end

      return process_job(
        source_context:, outcome_id:, target_group:
      )
    end

    validation_error(
      I18n.t("Either groupId or outcomeId values are required")
    )
  end

  class << self
    def execute(progress, source_context, group, outcome_id, target_group)
      if outcome_id
        import_single_outcome(progress, source_context, outcome_id, target_group)
      else
        import_group(progress, group, target_group)
      end
    end

    private

    def import_single_outcome(progress, source_context, outcome_id, target_group)
      source_outcome_group = get_outcome_group(outcome_id, source_context)
      unless source_outcome_group
        progress.message = I18n.t(
          "Could not import Learning Outcome %{outcome_id} because it doesn't belong to any group",
          outcome_id: outcome_id.to_s
        )
        progress.save!
        progress.fail
        return
      end

      # if source group isn't root outcome group
      if source_outcome_group.learning_outcome_group_id
        # build the group structure
        target_group = make_group_structure(source_outcome_group, progress, target_group)
      end

      target_group.add_outcome(LearningOutcome.find(outcome_id))
    end

    def import_group(progress, group, target_group)
      target_group = make_group_structure(group, progress, target_group)
      target_group.sync_source_group
    end

    def make_group_structure(source_group, progress, target_group)
      source_context = source_group.context
      ancestors_to_be_imported_map = get_ancestors_to_be_imported_map(source_group, source_context, target_group)
      source_target_groups_map = import_groups(ancestors_to_be_imported_map, target_group, progress)
      source_target_groups_map[source_group.id]
    end

    def get_outcome_group(outcome_id, context)
      links = ContentTag.learning_outcome_links.active.where(content_id: outcome_id)
      link = context ? links.find_by(context:) : links.find_by(context_type: "LearningOutcomeGroup")
      link&.associated_asset
    end

    # returns a hash where the key is the id of the group that must be added
    # and the values are the ids of its ancestors that must be added as well
    # It also pushes the group id that was imported before
    def get_ancestors_to_be_imported_map(group, source_context, target_group)
      group_ids = [group.id]

      # In the target group, look for top-level groups that were previously imported
      # from the source context, excluding the current group being imported,
      # and then get their source group ids.
      group_ids_from_source_in_target = target_group
                                        .child_outcome_groups
                                        .active
                                        .where(
                                          source_outcome_group_id: LearningOutcomeGroup
                                            .active
                                            .where(context: source_context)
                                            .where.not(id: group_ids)
                                        )
                                        .pluck(:source_outcome_group_id)

      ancestors_map = get_group_ancestors(group_ids + group_ids_from_source_in_target)

      # now push to group_ids only groups that has the same ancestor as the
      # group that we're importing
      group_ids_from_source_in_target.each do |group_id_from_source_in_target|
        # if the first ancestor matches, they belong to the same ancestor
        if ancestors_map[group_id_from_source_in_target].first == ancestors_map[group.id].first
          group_ids << group_id_from_source_in_target
        end
      end

      ancestors_to_be_imported_map = ancestors_map.slice(*group_ids)

      # If only one group must be imported
      common_ancestors = if group_ids.size == 1
                           # duplicating here because we'll pop common_ancestors later and we don't want
                           # to pop in the ancestors_to_be_imported_map
                           ancestors_to_be_imported_map.values.first.dup
                         else
                           ancestors_to_be_imported_map.values.inject do |p1, p2|
                             p1 & p2
                           end
                         end

      # the first common ancestor must be imported
      common_ancestors.pop

      ancestors_to_be_imported_map.transform_values do |ancestors|
        ancestors - common_ancestors
      end
    end

    # Returns a hash with the group_id as the key and
    # an ancestor list as the value
    # Example: If you have this folder structure like
    #   Root Group -> Group A -> Group B
    #   Root Group -> Group A -> Group C
    # and call with [Group_B_ID, Group_C_ID] argument
    # will result in
    # {
    #   Group_B_ID: [Group_A_ID, Group_B_ID],
    #   Group_C_ID: [Group_A_ID, Group_C_ID],
    # }
    def get_group_ancestors(ids)
      LearningOutcomeGroup.where(id: ids).each_with_object({}) do |group, hash|
        hash[group.id] = group.ancestor_ids

        # remove nil and remove root outcome group
        hash[group.id].pop(2)

        hash[group.id].reverse!
      end
    end

    def import_groups(ancestors_to_be_imported_map, target_group, progress)
      source_target_groups_map = {}

      groups_hash = LearningOutcomeGroup.where(id: ancestors_to_be_imported_map.values.flatten.uniq).to_a.index_by(&:id)

      total = ancestors_to_be_imported_map.values.size
      i = 0
      ancestors_to_be_imported_map.each_value do |ancestors_ids|
        destination_parent_group = target_group
        ancestors_ids.each do |gid|
          unless source_target_groups_map[gid]
            source_group = groups_hash[gid]
            source_target_groups_map[gid] = copy_or_get_existing_group!(
              source_group, destination_parent_group, target_group
            )
          end

          destination_parent_group = source_target_groups_map[gid]

          progress.update_completion!(i * 50 / total)
          i += 1
        end
      end

      source_target_groups_map
    end

    def copy_or_get_existing_group!(source_group, destination_parent_group, target_group)
      # Use resolved_root_account_ids to find the root_account_id because if the
      # the target group's context is the Root Account, then root_account_id will return 0
      # which is incorrect! resolved_root_account_id method will return the Account.id if the
      # the context is the Root Account.

      # check if we have the group as a root group
      if (group = target_group.child_outcome_groups.find_by(source_outcome_group_id: source_group.id))
        group.root_account_id = target_group.context.resolved_root_account_id
        group.learning_outcome_group_id = destination_parent_group.id
        group.workflow_state = "active"
        group.save!
        return group
      end

      # check if we already have the group inside the destination parent group
      if (group = destination_parent_group.child_outcome_groups.find_by(source_outcome_group_id: source_group.id))
        unless group.workflow_state == "active"
          group.root_account_id = target_group.context.resolved_root_account_id
          group.workflow_state = "active"
          group.save!
        end
        return group
      end

      group = source_group.clone
      group.root_account_id = target_group.context.resolved_root_account_id
      group.learning_outcome_group_id = destination_parent_group.id
      group.source_outcome_group_id = source_group.id
      group.context = target_group.context
      group.save!

      group
    end
  end

  private

  def get_target(input)
    if input[:target_group_id]
      target_group = LearningOutcomeGroup.active.find_by(id: input[:target_group_id])
      if target_group.nil?
        raise GraphQL::ExecutionError, I18n.t("no such target group")
      end

      target_context = target_group.context

      [target_context, target_group]
    else
      if input[:target_context_type].blank? && input[:target_context_id].blank?
        raise GraphQL::ExecutionError, I18n.t(
          "You must provide targetGroupId or targetContextId and targetContextType"
        )
      elsif input[:target_context_type].blank? && input[:target_context_id].present?
        raise GraphQL::ExecutionError, I18n.t(
          "targetContextType required if targetContextId provided"
        )
      elsif input[:target_context_type].present? && input[:target_context_id].blank?
        raise GraphQL::ExecutionError, I18n.t(
          "targetContextId required if targetContextType provided"
        )
      end

      target_context =
        begin
          context_class(input[:target_context_type]).find_by(
            id: input[:target_context_id]
          )
        rescue NameError
          raise GraphQL::ExecutionError, I18n.t("Invalid targetContextType")
        end

      if target_context.nil?
        raise GraphQL::ExecutionError, I18n.t("no such target context")
      end

      [target_context, target_context.root_outcome_group]
    end
  end

  def context_class(context_type)
    raise NameError unless VALID_CONTEXTS.include? context_type

    context_type.constantize
  end

  def process_job(source_context:, target_group:, group: nil, outcome_id: nil)
    target_context = target_group.context
    progress = target_context.progresses.new(tag: "import_outcomes", user: current_user)

    if progress.save
      progress.process_job(
        self.class,
        :execute,
        {
          strand: "import_outcomes_#{target_context.class.name.downcase}_#{target_context.id}_#{context[:domain_root_account].global_id}"
        },
        source_context,
        group,
        outcome_id,
        target_group
      )

      { progress: }
    else
      raise GraphQL::ExecutionError, I18n.t("Error importing outcomes")
    end
  end
end
