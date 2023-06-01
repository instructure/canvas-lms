# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class ContentShare < ActiveRecord::Base
  TYPE_TO_CLASS = {
    "assignment" => Assignment,
    "attachment" => Attachment,
    "discussion_topic" => DiscussionTopic,
    "page" => WikiPage,
    "quiz" => Quizzes::Quiz,
    "module" => ContextModule,
    "module_item" => ContentTag
  }.freeze

  CLASS_NAME_TO_TYPE = TYPE_TO_CLASS.transform_values(&:to_s).invert.freeze

  belongs_to :user
  belongs_to :content_export
  has_one :course, through: :content_export, source: :context, source_type: "Course"
  has_one :group, through: :content_export, source: :context, source_type: "Group"
  has_one :context_user, through: :content_export, source: :context, source_type: "User"

  belongs_to :sender, class_name: "User"
  belongs_to :root_account, class_name: "Account"

  validates :read_state, inclusion: { in: %w[read unread] }

  before_create :set_root_account_id

  scope :by_date, -> { order(created_at: :desc) }

  def clone_for(receiver)
    receiver.received_content_shares.create!(sender: user,
                                             content_export:,
                                             name:,
                                             read_state: "unread")
  end

  def set_root_account_id
    self.root_account_id = content_export&.context&.root_account_id if content_export&.context.respond_to?(:root_account_id)
  end
end
