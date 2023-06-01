# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "rake"

module NotificationsCommon
  def setup_comm_channel(user, path = "test@example.com", path_type = "email")
    @channel = communication_channel(user, { username: path, path_type:, active_cc: true })
  end

  def setup_notification(user, params = {})
    default_params = {
      name: "Conversation Message",
      category: "TestImmediately",
      frequency: "immediately",
      sms: false,
    }
    params = default_params.merge(params)

    n = Notification.create!(name: params[:name], category: params[:category])

    # we don't send notifications to sms channels automatically so will need a policy set up for that if sms is chosen
    if params[:sms] == true
      NotificationPolicy.create!(
        notification: n,
        communication_channel: user.communication_channel,
        frequency: params[:frequency]
      )
    end
  end

  def load_all_notifications
    load File.expand_path("../../../lib/tasks/db_load_data.rake", __dir__)
    Rake::Task.define_task(:environment)
    Rake::Task["db:load_notifications"].invoke
  end
end
