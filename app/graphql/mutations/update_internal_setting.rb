# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

class Mutations::UpdateInternalSetting < Mutations::BaseMutation
  graphql_name "UpdateInternalSetting"

  argument :internal_setting_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("InternalSetting")
  argument :value, String, required: true

  field :internal_setting, Types::InternalSettingType, null: false
  def resolve(input:)
    if !Account.site_admin.grants_right?(current_user, :manage_internal_settings) || (internal_setting = Setting.find(input[:internal_setting_id])).secret
      raise GraphQL::ExecutionError, "insufficient permission"
    end

    unless input[:value].nil?
      internal_setting.update!(value: input[:value])
    end

    {
      internal_setting:
    }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
