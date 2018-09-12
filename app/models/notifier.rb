#
# Copyright (C) 2014 - present Instructure, Inc.
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

class Notifier
  def send_notification(record, dispatch, messages, to_list, data=nil)
    messages = DelayedNotification.send_later_if_production_enqueue_args(
        :process,
        {:priority => 30, :max_attempts => 1},
        record,
        messages,
        (to_list || []).compact.map(&:asset_string),
        data
    )

    messages ||= DelayedNotification.new(
          :asset => record,
          :notification => messages,
          :recipient_keys => (to_list || []).compact.map(&:asset_string),
          :data => data
      )

    if Rails.env.test?
      record.messages_sent[dispatch] = messages.is_a?(DelayedNotification) ? messages.process : messages
    end

    messages
  end
end
