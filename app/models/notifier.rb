# frozen_string_literal: true

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
  def send_notification(record, dispatch, messages, to_list, data = nil)
    recipient_keys = (to_list || []).compact.map { |o| o.is_a?(String) ? o : o.asset_string }
    messages = DelayedNotification.delay_if_production(priority: 30)
                                  .process(record, messages, recipient_keys, data, **{})
    # RUBY 3.0 - **{} can go away, because data won't implicitly convert to kwargs

    messages ||= DelayedNotification.new(
      asset: record,
      notification: messages,
      recipient_keys:,
      data:
    )

    if Rails.env.test?
      record.messages_sent[dispatch] ||= []
      record.messages_sent[dispatch] += messages.is_a?(DelayedNotification) ? messages.process : messages
    end

    messages
  end
end
