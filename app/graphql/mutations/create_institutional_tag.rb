# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# NOTE: Depends on InstitutionalTag and InstitutionalTagCategory models

module Mutations
  class CreateInstitutionalTag < BaseMutation
    argument :category_id,
             ID,
             required: true,
             prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("InstitutionalTagCategory")
    argument :description, String, required: true
    argument :name,        String, required: true

    field :institutional_tag, Types::InstitutionalTagType, null: true

    def resolve(input:)
      root_account = context[:domain_root_account]
      raise GraphQL::ExecutionError, "feature flag is disabled" unless root_account.feature_enabled?(:institutional_tags)
      raise GraphQL::ExecutionError, "not authorized" unless root_account.grants_right?(current_user, session, :manage_institutional_tags_create)

      category = root_account.institutional_tag_categories.where(workflow_state: "active").find_by(id: input[:category_id])
      raise GraphQL::ExecutionError, "not found" unless category

      max_tags = DynamicSettings.find("institutional_tags")["max_tags_per_category", failsafe: nil]&.to_i || 50
      if category.institutional_tags.where(workflow_state: "active").count >= max_tags
        raise GraphQL::ExecutionError, "category has reached the maximum number of tags"
      end

      tag = category.institutional_tags.new(
        name: input[:name],
        description: input[:description],
        root_account:
      )

      if tag.save
        { institutional_tag: tag }
      else
        errors_for(tag)
      end
    rescue ActiveRecord::RecordInvalid
      errors_for(tag)
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "not found"
    end
  end
end
