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

module Mutations
  class DismissAccountNotification < BaseMutation
    argument :notification_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("AccountNotification")

    def resolve(input:, **)
      user = context[:current_user]
      raise GraphQL::ExecutionError, I18n.t("Must be logged in") unless user

      notification = AccountNotification.find_by(id: input[:notification_id])
      raise GraphQL::ExecutionError, I18n.t("Notification not found") unless notification

      closed_notifications = user.get_preference(:closed_notifications) || []
      closed_notifications << notification.id unless closed_notifications.include?(notification.id)
      user.set_preference(:closed_notifications, closed_notifications)

      {}
    end
  end
end
