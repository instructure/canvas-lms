#
# Copyright (C) 2011 Instructure, Inc.
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


module AccountNotificationHelper
  # map the actual notification type to a type that we know how to handle
  def notification_icon_type(account_notification)
    case account_notification.icon
    when "help"
      "warning"
    when "people", "file", "group"
      "information"
    when "calendar_icon"
      "calendar"
    else
      account_notification.icon || "warning"
    end
  end

  # Return a valid icon font classname for a given notification type
  def notification_icon_classname(account_notification)
    icon_prefix = 'icon-'
    icon_type = notification_icon_type(account_notification)
    case icon_type
    when "information"
      icon_prefix + "info"
    when "calendar"
      icon_prefix + "calendar-month"
    when "question"
      icon_prefix + icon_type
    else
      icon_prefix + "warning"
    end
  end

  # Return a valid account notification color scheme class for a given notification type
  def notification_container_classname(account_notification)
    case notification_icon_type(account_notification)
    when "error"
      "danger"
    when "question", "calendar", "information"
      "info"
    else
      "alert"
    end
  end

  def accessible_message_icon_text(icon_type)
    case icon_type
    when "information"
      I18n.t('#global_message_icons.information', "information")
    when "error"
      I18n.t('#global_message_icons.error', "error")
    when "question"
      I18n.t('#global_message_icons.question', "question")
    when "calendar"
      I18n.t('#global_message_icons.calendar', "calendar")
    when "announcement"
      I18n.t('#global_message_icons.announcement', "announcement")
    when "invitation"
      I18n.t('#global_message_icons.invitation', "invitation")
    else
      I18n.t('#global_message_icons.warning', "warning")
    end
  end
end
