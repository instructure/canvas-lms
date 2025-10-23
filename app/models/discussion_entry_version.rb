# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

class DiscussionEntryVersion < ActiveRecord::Base
  belongs_to :discussion_entry, inverse_of: :discussion_entry_versions
  belongs_to :root_account, class_name: "Account"
  belongs_to :user, inverse_of: :discussion_entry_versions
  has_many :discussion_topic_insight_entries, class_name: "DiscussionTopicInsight::Entry", inverse_of: :discussion_entry_version
  has_one :lti_asset, class_name: "Lti::Asset", inverse_of: :discussion_entry_version, dependent: :nullify

  MESSAGE_INTRO_TRUNCATE_LENGTH = 300

  def message_intro
    HtmlTextHelper.strip_tags(message)[0..MESSAGE_INTRO_TRUNCATE_LENGTH]
  end
end
