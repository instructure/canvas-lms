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

module Types
  class AccountNotificationType < ApplicationObjectType
    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id
    field :account_id, ID, null: false
    field :account_name, String, null: true
    field :end_at, DateTimeType, null: false
    field :icon, String, null: true
    field :message, String, null: false
    field :notification_type, String, null: true
    field :site_admin, Boolean, null: false
    field :start_at, DateTimeType, null: false
    field :subject, String, null: false

    def account_name
      object.account.site_admin? ? nil : object.account.name
    end

    def site_admin
      object.account.site_admin?
    end

    def notification_type
      case object.icon
      when "calendar"
        "calendar"
      when "error"
        "error"
      when "question"
        "question"
      when "warning"
        "warning"
      else
        "info"
      end
    end
  end
end
