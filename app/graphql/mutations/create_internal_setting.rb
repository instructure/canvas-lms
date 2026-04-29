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
class Mutations::CreateInternalSetting < Mutations::BaseMutation
  graphql_name "CreateInternalSetting"

  argument :name, String, required: true
  argument :value, String, required: true

  field :internal_setting, Types::InternalSettingType, null: true
  def resolve(input:)
    unless Account.site_admin.grants_right?(current_user, :manage_internal_settings)
      raise GraphQL::ExecutionError, "insufficient permission"
    end

    Setting.set(input[:name], input[:value])
    internal_setting = Setting.find_by!(name: input[:name])

    { internal_setting: }
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  end
end
