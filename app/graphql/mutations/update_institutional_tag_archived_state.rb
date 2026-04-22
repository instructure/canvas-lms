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

# NOTE: Depends on InstitutionalTag and InstitutionalTagAssociation models

module Mutations
  class UpdateInstitutionalTagArchivedState < BaseMutation
    argument :archived, Boolean, required: true
    argument :id,
             ID,
             required: true,
             prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("InstitutionalTag")

    field :institutional_tag, Types::InstitutionalTagType, null: true

    def resolve(input:)
      root_account = context[:domain_root_account]
      raise GraphQL::ExecutionError, "feature flag is disabled" unless root_account.feature_enabled?(:institutional_tags)
      raise GraphQL::ExecutionError, "not authorized" unless root_account.grants_right?(current_user, session, :manage_institutional_tags_edit)

      tag = InstitutionalTag.where(root_account_id: root_account.id).find_by(id: input[:id])
      raise GraphQL::ExecutionError, "not found" unless tag

      input[:archived] ? tag.destroy : tag.undestroy

      { institutional_tag: tag }
    rescue ActiveRecord::RecordInvalid
      errors_for(tag)
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "not found"
    end
  end
end
