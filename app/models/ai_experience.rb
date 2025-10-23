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

class AiExperience < ApplicationRecord
  belongs_to :root_account, class_name: "Account"
  belongs_to :account
  belongs_to :course

  has_many :ai_conversations, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :learning_objective, presence: true
  validates :pedagogical_guidance, presence: true
  validates :workflow_state, presence: true, inclusion: { in: %w[unpublished published deleted] }

  scope :published, -> { where(workflow_state: "published") }
  scope :unpublished, -> { where(workflow_state: "unpublished") }
  scope :active, -> { where.not(workflow_state: "deleted") }
  scope :for_course, ->(course_id) { where(course_id:) }

  def delete
    return false if deleted?

    update_column(:workflow_state, "deleted")
  end

  def publish!
    return false if deleted?

    update_column(:workflow_state, "published")
  end

  def unpublish!
    return false if deleted?

    update_column(:workflow_state, "unpublished")
  end

  def published?
    workflow_state == "published"
  end

  def unpublished?
    workflow_state == "unpublished"
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

  before_create :set_account_associations
end
