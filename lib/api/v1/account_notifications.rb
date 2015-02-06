#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

module Api::V1::AccountNotifications
  include Api::V1::Json

  def account_notifications_json(account_notifications, user, session)
    account_notifications.map {|n| account_notification_json(n, user, session) }
  end

  def account_notification_json(account_notification, user, session)
    json = api_json(account_notification, user, session, :only => %w(id subject start_at end_at icon message))
    json['role_ids'] = account_notification.account_notification_roles.map(&:role_id)
    json['roles'] = account_notification.account_notification_roles.map(&:role_name)
    json
  end

end

