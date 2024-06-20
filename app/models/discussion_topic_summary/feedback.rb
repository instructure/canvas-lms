# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class DiscussionTopicSummary
  class Feedback < ActiveRecord::Base
    belongs_to :root_account, class_name: "Account"
    belongs_to :discussion_topic_summary, inverse_of: :feedback
    belongs_to :user

    before_validation :set_root_account

    self.ignored_columns += ["regenerated"]

    def set_root_account
      self.root_account ||= discussion_topic_summary.root_account
    end

    def like
      update!(liked: true, disliked: false)
    end

    def dislike
      update!(liked: false, disliked: true)
    end

    def reset_like
      update!(liked: false, disliked: false)
    end

    def disable_summary
      update!(summary_disabled: true)
    end
  end
end
