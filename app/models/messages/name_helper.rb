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

module Messages
  class NameHelper
    attr_reader :asset, :message_recipient, :notification_name

    def initialize(asset:, message_recipient:, notification_name:)
      @asset = asset
      @message_recipient = message_recipient
      @notification_name = notification_name
    end

    def from_name
      return nil unless asset && named_source?

      CanvasTextHelper.truncate_text(anonymized_user_name, max_length: 50)
    end

    def reply_to_name
      return nil unless asset && named_source?

      I18n.t(:reply_from_name, "%{name} via Canvas Notifications", name: from_name)
    end

    private

    def anonymized_name?(assignment)
      (author_asset? && !asset.can_read_author?(message_recipient, nil)) || (assignment.anonymize_students? && source_user != message_recipient)
    end

    def anonymized_user_name
      # for anonymous discussions, just return the author name, since that is already anonymized
      return asset.author_name if asset.is_a?(DiscussionEntry) && asset.discussion_topic.anonymous?

      return source_user&.short_name unless anonymized_asset?

      anonymous_name = I18n.t("Anonymous User")

      assignment = if user_asset?
                     asset.assignment
                   else
                     asset.submission.assignment
                   end

      if anonymized_name?(assignment)
        anonymous_name
      else
        source_user&.short_name
      end
    end

    def source_user
      if author_asset?
        asset.author
      elsif user_asset?
        asset.user
      end
    end

    def named_source?
      author_asset? || user_asset?
    end

    SOURCE_AUTHOR_NOTIFICATIONS = [
      "Conversation Message",
      "Submission Comment",
      "Submission Comment For Teacher"
    ].freeze

    SOURCE_USER_NOTIFICATIONS = [
      "Assignment Submitted",
      "Assignment Resubmitted",
      "Discussion Mention",
      "New Discussion Entry"
    ].freeze

    ANONYMIZED_NOTIFICATIONS = [
      "Submission Comment",
      "Submission Comment For Teacher",
      "Assignment Submitted",
      "Assignment Resubmitted"
    ].freeze

    def anonymized_asset?
      ANONYMIZED_NOTIFICATIONS.include?(notification_name) && (asset.respond_to?(:user) || asset.respond_to?(:recipient))
    end

    def author_asset?
      SOURCE_AUTHOR_NOTIFICATIONS.include?(notification_name)
    end

    def user_asset?
      SOURCE_USER_NOTIFICATIONS.include?(notification_name)
    end
  end
end
