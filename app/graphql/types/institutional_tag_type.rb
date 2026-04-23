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

# NOTE: Depends on InstitutionalTag model (app/models/institutional_tag.rb)

class Types::InstitutionalTagType < Types::ApplicationObjectType
  implements GraphQL::Types::Relay::Node
  implements Interfaces::LegacyIDInterface
  implements Interfaces::TimestampInterface

  connection_type_class Types::TotalCountConnection
  global_id_field :id
  field :associations_count, Integer, null: false
  field :description,        String,  null: false
  field :name,               String,  null: false
  field :workflow_state,     String,  null: false
  def associations_count
    Loaders::InstitutionalTagAssociationsCountLoader.load(object)
  end

  field :category, Types::InstitutionalTagCategoryType, null: true
  def category
    load_association(:category)
  end

  field :users_connection, Types::UserType.connection_type, null: true do
    argument :filter, Types::AccountUsersFilterInputType, required: false
    argument :sort, Types::InstitutionalTagUsersSortInputType, required: false
  end
  def users_connection(filter: {}, sort: {})
    root_account = context[:domain_root_account]
    return unless root_account&.feature_enabled?(:institutional_tags)
    return unless root_account.grants_right?(current_user, session, :manage_institutional_tags_view)

    users = User.joins(:institutional_tag_associations)
                .where(institutional_tag_associations: { institutional_tag_id: object.id, workflow_state: "active" })
                .distinct

    search_term = filter[:search_term].presence
    options = { sort: sort[:field], order: sort[:direction] }.compact

    if search_term
      UserSearch.for_user_in_context(search_term, root_account, current_user, session, options)
                .where(users: { id: users.select(:id) })
    else
      UserSearch.scope_for(root_account, current_user, options)
                .where(users: { id: users.select(:id) })
    end
  end
end
