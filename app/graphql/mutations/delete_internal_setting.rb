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
class Mutations::DeleteInternalSetting < Mutations::BaseMutation
  graphql_name "DeleteInternalSetting"

  argument :internal_setting_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("InternalSetting")

  field :internal_setting_id, ID, null: false

  def resolve(input:)
    if !Account.site_admin.grants_right?(current_user, :manage_internal_settings) || (internal_setting = Setting.find(input[:internal_setting_id])).secret
      raise GraphQL::ExecutionError, "insufficient permission"
    end

    context[:deleted_models] = { internal_setting: }
    internal_setting.destroy

    { internal_setting_id: CanvasSchema.id_from_object(internal_setting, Types::InternalSettingType, nil) }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end

  def self.internal_setting_id_log_entry(_topic, context)
    context[:deleted_models][:internal_setting]
  end
end
