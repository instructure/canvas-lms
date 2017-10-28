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
    attr_reader :asset, :notification_name
    def initialize(asset, name)
      @asset = asset
      @notification_name = name
    end

    def from_name
      return nil unless asset && has_named_source?
      CanvasTextHelper.truncate_text(anonymized_user_name, :max_length => 50)
    end

    def reply_to_name
      return nil unless asset && has_named_source?
      I18n.t(:reply_from_name, "%{name} via Canvas Notifications", name: from_name)
    end

    private

    def anonymized_user_name
      if is_anonymized_asset?
        asset.can_read_author?(asset.recipient, nil) ? source_user.short_name : I18n.t(:anonymous_user, 'Anonymous User')
      else
        source_user.short_name
      end
    end

    def source_user
      if is_author_asset?
        asset.author
      elsif is_user_asset?
        asset.user
      end
    end

    def has_named_source?
      is_author_asset? || is_user_asset?
    end

    SOURCE_AUTHOR_NOTIFICATIONS = [
      "Conversation Message",
      "Submission Comment",
      "Submission Comment For Teacher"
    ]

    SOURCE_USER_NOTIFICATIONS = [
      "New Discussion Entry",
      "Assignment Submitted",
      "Assignment Resubmitted"
    ]

    ANONYMIZED_NOTIFICATIONS = [
      "Submission Comment"
    ]

    def is_anonymized_asset?
      ANONYMIZED_NOTIFICATIONS.include?(notification_name) && asset.respond_to?(:recipient)
    end

    def is_author_asset?
      SOURCE_AUTHOR_NOTIFICATIONS.include?(notification_name)
    end

    def is_user_asset?
      SOURCE_USER_NOTIFICATIONS.include?(notification_name)
    end

  end
end
