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

class Mutations::DeleteOutcomeLinks < Mutations::BaseMutation
  graphql_name 'DeleteOutcomeLinks'

  argument :ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func('ContentTag')

  field :deleted_outcome_link_ids, [ID], null: false

  def self.deleted_outcome_link_ids_log_entry(entry, context)
    context[:deleted_models][:outcome_links][entry]
  end

  def resolve(input:)
    @errors = []
    @deleted_outcome_link_ids = []
    context[:deleted_models] = { outcome_links: {} }
    outcome_links, not_found_ids = get_outcome_links(input)

    generate_not_found_errors(not_found_ids)

    outcome_links.find_each do |outcome_link|
      destroy(outcome_link) if user_has_permissions?(outcome_link)
    end

    {
      deleted_outcome_link_ids: @deleted_outcome_link_ids,
      errors: @errors
    }
  end

  private

  def get_outcome_links(input)
    ids = input[:ids].map(&:to_i).uniq
    links = ContentTag.active.learning_outcome_links.where(id: ids)
    not_found_ids = ids - links.pluck(:id)
    [links, not_found_ids]
  end

  def generate_not_found_errors(ids)
    @errors = ids.map do |id|
      [id, "Could not find outcome link"]
    end
  end

  def can_manage_outcomes?(outcome_link)
    if outcome_link.context.is_a?(LearningOutcomeGroup)
      Account.site_admin.grants_right?(current_user, session, :manage_global_outcomes)
    else
      outcome_link.context.grants_right?(current_user, session, :manage_outcomes)
    end
  end

  def user_has_permissions?(outcome_link)
    can_manage_outcomes?(outcome_link).tap do |can_manage|
      @errors << [outcome_link.id, "Insufficient permissions"] unless can_manage
    end
  end

  def destroy(outcome_link)
    outcome_link.destroy
    @deleted_outcome_link_ids << outcome_link.id
    context[:deleted_models][:outcome_links][outcome_link.id] = outcome_link
  rescue ContentTag::LastLinkToOutcomeNotDestroyed => e
    @errors << [outcome_link.id, e.message]
  rescue ActiveRecord::RecordNotSaved
    @errors << [outcome_link.id, "Unable to delete outcome link"]
  end
end
