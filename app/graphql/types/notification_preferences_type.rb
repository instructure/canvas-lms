# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
  class NotificationPreferencesType < ApplicationObjectType
    graphql_name "NotificationPreferences"

    field :channels, [CommunicationChannelType], null: true do
      argument :channel_id, ID, required: false, default_value: nil
    end
    def channels(channel_id:)
      channels = object[:channels]

      # if they queried a specific ID, return it regardless of whether it
      # is enabled at the account level (ex: push being disabled)
      if channel_id
        channels = channels.select { |cc| cc.id == channel_id.to_i }

        return channels
      end

      # remove push notifications, if the account disabled them
      unless context[:domain_root_account].enable_push_notifications?
        channels = channels.reject { |cc| cc.path_type == CommunicationChannel::TYPE_PUSH }
      end

      # remove Twitter notification types
      channels.reject { |cc| cc.path_type == CommunicationChannel::TYPE_TWITTER }
    end

    field :send_scores_in_emails, Boolean, null: true do
      argument :course_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
    end
    def send_scores_in_emails(course_id: nil)
      user = object[:user]

      if course_id
        course = Course.find(course_id)
        return user.send_scores_in_emails?(course)
      end

      # send_scores_in_emails can be nil and we want the default to be false if unset
      user.preferences[:send_scores_in_emails] == true
    end

    field :send_observed_names_in_notifications, Boolean, null: true
    def send_observed_names_in_notifications
      user = object[:user]
      (user.observer_enrollments.any? || user.as_observer_observation_links.any?) ? user.send_observed_names_in_notifications? : nil
    end

    field :read_privacy_notice_date, String, null: true
    def read_privacy_notice_date
      user = object[:user]
      user.preferences[:read_notification_privacy_info]
    end
  end
end
