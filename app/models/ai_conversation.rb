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

class AiConversation < ApplicationRecord
  belongs_to :root_account, class_name: "Account"
  belongs_to :account
  belongs_to :course
  belongs_to :user
  belongs_to :ai_experience

  validates :llm_conversation_id, presence: true, uniqueness: true
  validates :workflow_state, presence: true, inclusion: { in: %w[active completed deleted] }

  scope :for_user, ->(user_id) { where(user_id:) }
  scope :for_course, ->(course_id) { where(course_id:) }
  scope :for_account, ->(account_id) { where(account_id:) }
  scope :for_ai_experience, ->(ai_experience_id) { where(ai_experience_id:) }
  scope :active, -> { where(workflow_state: "active") }
  scope :completed, -> { where(workflow_state: "completed") }
  scope :deleted, -> { where(workflow_state: "deleted") }

  before_create :set_account_associations

  def delete
    return false if deleted?

    update_column(:workflow_state, "deleted")
  end

  def complete!
    return false if deleted?

    update_column(:workflow_state, "completed")
  end

  def active?
    workflow_state == "active"
  end

  def completed?
    workflow_state == "completed"
  end

  def deleted?
    workflow_state == "deleted"
  end

  private

  def set_account_associations
    if course.present?
      self.root_account_id ||= course.root_account_id
      self.account_id ||= course.account_id
    end
  end
end
