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
  class UpdateInstitutionalTag < BaseMutation
    argument :category_id,
             ID,
             required: false,
             prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("InstitutionalTagCategory")
    argument :description, String, required: false
    argument :id,
             ID,
             required: true,
             prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("InstitutionalTag")
    argument :name, String, required: false

    field :institutional_tag, Types::InstitutionalTagType, null: true

    def resolve(input:)
      root_account = context[:domain_root_account]
      raise GraphQL::ExecutionError, "feature flag is disabled" unless root_account.feature_enabled?(:institutional_tags)
      raise GraphQL::ExecutionError, "not authorized" unless root_account.grants_right?(current_user, session, :manage_institutional_tags_edit)

      tag = InstitutionalTag.where(root_account_id: root_account.id, workflow_state: "active").find_by(id: input[:id])
      raise GraphQL::ExecutionError, "not found" unless tag

      attrs = {}
      attrs[:name] = input[:name] if input.key?(:name)
      attrs[:description] = input[:description] if input.key?(:description)

      if input.key?(:category_id)
        category = root_account.institutional_tag_categories.where(workflow_state: "active").find_by(id: input[:category_id])
        raise GraphQL::ExecutionError, "not found" unless category

        attrs[:category_id] = category.id
      end

      if tag.update(attrs)
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
