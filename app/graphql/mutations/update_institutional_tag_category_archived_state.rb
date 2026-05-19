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

# NOTE: Depends on InstitutionalTagCategory model (app/models/institutional_tag_category.rb)

module Mutations
  class UpdateInstitutionalTagCategoryArchivedState < BaseMutation
    argument :archived, Boolean, required: true
    argument :id,
             ID,
             required: true,
             prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("InstitutionalTagCategory")

    field :institutional_tag_category, Types::InstitutionalTagCategoryType, null: true

    def resolve(input:)
      root_account = context[:domain_root_account]
      raise GraphQL::ExecutionError, "feature flag is disabled" unless root_account.feature_enabled?(:institutional_tags)
      raise GraphQL::ExecutionError, "not authorized" unless root_account.grants_right?(current_user, session, :manage_institutional_tags_edit)

      category = root_account.institutional_tag_categories.find_by(id: input[:id])
      raise GraphQL::ExecutionError, "not found" unless category

      input[:archived] ? category.destroy : category.undestroy

      { institutional_tag_category: category }
    rescue ActiveRecord::RecordInvalid
      errors_for(category)
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "not found"
    end
  end
end
