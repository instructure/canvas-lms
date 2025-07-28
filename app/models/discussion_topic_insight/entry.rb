# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class DiscussionTopicInsight
  class Entry < ActiveRecord::Base
    belongs_to :root_account, class_name: "Account"
    belongs_to :discussion_topic_insight, inverse_of: :entries
    belongs_to :discussion_topic, inverse_of: :insight_entries
    belongs_to :discussion_entry, inverse_of: :discussion_topic_insight_entries
    belongs_to :discussion_entry_version, inverse_of: :discussion_topic_insight_entries
    belongs_to :ai_evaluation_human_reviewer, class_name: "User"

    has_one :user, through: :discussion_entry

    before_validation :set_root_account

    validates :locale, presence: true
    validates :dynamic_content_hash, presence: true
    validates :ai_evaluation, presence: true

    INFERENCE_CONFIG_VERSION = "insights-V3_A"

    def set_root_account
      self.root_account ||= discussion_topic_insight.root_account
    end

    def self.hash_for_dynamic_content(content:, pretty_locale:)
      Digest::SHA256.hexdigest({
        CONTENT: content,
        # TODO: inference config version that runs in Cedar (prompt, model, etc.)
        INFERENCE_CONFIG_VERSION:,
        LOCALE: pretty_locale,
      }.to_json)
    end
  end
end
