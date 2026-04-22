# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
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
class AddSuspensionNotifications < ActiveRecord::Migration[8.0]
  tag :predeploy
  def up
    if Shard.current.default? && !::Rails.env.test?
      Canvas::MessageHelper.create_notification({
                                                  name: "Pseudonym Suspended After Failed Login",
                                                  delay_for: 0,
                                                  category: "Registration",
                                                  priority: true
                                                })
      Canvas::MessageHelper.create_notification({
                                                  name: "Pseudonym Suspended By Admin",
                                                  delay_for: 0,
                                                  category: "Registration",
                                                  priority: true
                                                })
    end
  end

  def down
    if Shard.current.default?
      Notification.where(name: "Pseudonym Suspended After Failed Login").delete_all
      Notification.where(name: "Pseudonym Suspended By Admin").delete_all
    end
  end
end
