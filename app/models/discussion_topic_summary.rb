# frozen_string_literal: true

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

class DiscussionTopicSummary < ActiveRecord::Base
  belongs_to :root_account, class_name: "Account"
  belongs_to :user
  belongs_to :discussion_topic, inverse_of: :summaries
  belongs_to :parent, class_name: "DiscussionTopicSummary", optional: true

  has_many :feedback, class_name: "DiscussionTopicSummary::Feedback"

  validates :summary, presence: true
  validates :llm_config_version, presence: true
  validates :dynamic_content_hash, presence: true

  before_validation :set_root_account

  def set_root_account
    self.root_account ||= discussion_topic.root_account
  end
end
