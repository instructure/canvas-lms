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

# NOTE: Depends on InstitutionalTag, InstitutionalTagAssociation models

module Mutations
  class ApplyInstitutionalTag < BaseMutation
    argument :tag_id,
             ID,
             required: true,
             prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("InstitutionalTag")
    argument :user_id,
             ID,
             required: true,
             prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("User")

    field :institutional_tag_association, Types::InstitutionalTagAssociationType, null: true

    def resolve(input:) # rubocop:disable GraphQL/UnusedArgument
      root_account = context[:domain_root_account]
      raise GraphQL::ExecutionError, "feature flag is disabled" unless root_account.feature_enabled?(:institutional_tags)
      raise GraphQL::ExecutionError, "not authorized" unless root_account.grants_right?(current_user, session, :manage_institutional_tags_edit)

      tag = InstitutionalTag.where(root_account_id: root_account.id, workflow_state: "active").find_by(id: input[:tag_id])
      raise GraphQL::ExecutionError, "not found" unless tag

      user = root_account.all_users.find_by(id: input[:user_id])
      raise GraphQL::ExecutionError, "not found" unless user

      assoc = InstitutionalTagAssociation.find_or_initialize_by(
        institutional_tag: tag,
        context: user,
        root_account:
      )
      assoc.workflow_state = "active"

      if assoc.save
        { institutional_tag_association: assoc }
      else
        errors_for(assoc)
      end
    end
  end
end
