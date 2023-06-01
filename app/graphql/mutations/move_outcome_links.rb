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

class Mutations::MoveOutcomeLinks < Mutations::BaseMutation
  graphql_name "MoveOutcomeLinks"

  argument :outcome_link_ids, [ID], <<~MD, required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("ContentTag")
    A list of ContentTags that will be moved
  MD
  argument :group_id, ID, <<~MD, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("LearningOutcomeGroup")
    The id of the destination group
  MD

  field :moved_outcome_links, [Types::ContentTagType], <<~MD, null: false
    List of Outcome Links that were sucessfully moved to the group
  MD

  def resolve(input:)
    group = get_group!(input)
    outcome_links, missing_ids = get_outcome_links(input, group.context)

    errors = missing_ids.map do |id|
      [id, I18n.t("Could not find associated outcome in this context")]
    end

    outcome_links.find_each do |outcome_link|
      group.adopt_outcome_link(outcome_link, skip_parent_group_touch: true)
    end

    group.touch_parent_group if outcome_links.any?

    context[:group] = group

    {
      errors:,
      moved_outcome_links: ContentTag.where(id: outcome_links.pluck(:id))
    }
  end

  def self.moved_outcome_link_ids_log_entry(_ids, ctx)
    ctx[:group]
  end

  private

  def get_group!(input)
    LearningOutcomeGroup.active.find_by(id: input[:group_id]).tap do |group|
      raise GraphQL::ExecutionError, I18n.t("Group not found") unless group

      if group.context
        raise GraphQL::ExecutionError, I18n.t("Insufficient permission") unless
          group.context.grants_right?(current_user, session, :manage_outcomes)
      else
        raise GraphQL::ExecutionError, I18n.t("Insufficient permission") unless
          Account.site_admin.grants_right?(current_user, session, :manage_global_outcomes)
      end
    end
  end

  def get_outcome_links(input, context)
    ids = input[:outcome_link_ids].map(&:to_i).uniq
    links = if context
              ContentTag.active.learning_outcome_links.where(
                context:,
                id: ids
              )
            else
              ContentTag.active.learning_outcome_links.where(id: ids, context_type: "LearningOutcomeGroup")
            end
    missing_ids = ids - links.pluck(:id)
    [links, missing_ids]
  end
end
