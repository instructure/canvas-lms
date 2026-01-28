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
  validate :unpublish_ok?, if: -> { will_save_change_to_workflow_state?(to: "unpublished") }

  scope :published, -> { where(workflow_state: "published") }
  scope :unpublished, -> { where(workflow_state: "unpublished") }
  scope :active, -> { where.not(workflow_state: "deleted") }
  scope :for_course, ->(course_id) { where(course_id:) }

  set_policy do
    # Students can read published experiences if they're enrolled in the course
    given do |user, session|
      published? && course.grants_right?(user, session, :read_as_member)
    end
    can :read

    # Teachers/TAs/admins can read any experience (published or unpublished)
    given do |user, session|
      course.grants_any_right?(user, session, :manage_assignments_add, :manage_assignments_edit, :manage_assignments_delete)
    end
    can :read and can :create and can :update and can :delete

    # Only teachers/TAs/admins can manage experiences
    given do |user, session|
      course.grants_any_right?(user, session, :manage_assignments_add, :manage_assignments_edit, :manage_assignments_delete)
    end
    can :manage
  end

  # Manage conversation_context lifecycle in llm-conversation service
  before_create :set_account_associations
  after_create :create_conversation_context
  after_update :update_conversation_context, if: :should_update_context?
  before_destroy :delete_conversation_context

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

  def can_unpublish?
    return true if new_record?
    return @can_unpublish unless @can_unpublish.nil?

    @can_unpublish = !student_conversations?
  end
  attr_writer :can_unpublish

  def student_conversations?
    # Single efficient query - checks if any conversations exist from students
    AiConversation
      .joins("INNER JOIN #{Enrollment.quoted_table_name} ON enrollments.user_id = ai_conversations.user_id")
      .where(ai_conversations: { ai_experience_id: id })
      .where.not(ai_conversations: { workflow_state: "deleted" })
      .where(enrollments: {
               course_id:,
               type: ["StudentEnrollment", "StudentViewEnrollment"]
             })
      .where.not(enrollments: { workflow_state: ["deleted", "rejected"] })
      .exists?
  end

  private

  def set_account_associations
    if course.present?
      self.root_account_id ||= course.root_account_id
      self.account_id ||= course.account_id
    end
  end

  def create_conversation_context
    LLMConversationContextManager.create_context(ai_experience: self)
  rescue LlmConversation::Errors::ConversationError => e
    Rails.logger.error("Failed to create conversation context for AiExperience #{id}: #{e.message}")
    # Don't fail the AiExperience creation if context creation fails
  end

  def should_update_context?
    llm_conversation_context_id.present? &&
      (saved_change_to_pedagogical_guidance? || saved_change_to_facts? || saved_change_to_learning_objective?)
  end

  def update_conversation_context
    LLMConversationContextManager.update_context(ai_experience: self)
  rescue LlmConversation::Errors::ConversationError => e
    Rails.logger.error("Failed to update conversation context for AiExperience #{id}: #{e.message}")
    # Don't fail the AiExperience update if context update fails
  end

  def delete_conversation_context
    LLMConversationContextManager.delete_context(ai_experience: self)
  rescue LlmConversation::Errors::ConversationError => e
    Rails.logger.error("Failed to delete conversation context for AiExperience #{id}: #{e.message}")
    # Don't fail the AiExperience deletion if context deletion fails
  end

  def unpublish_ok?
    return true if can_unpublish?

    errors.add :workflow_state, I18n.t("Can't unpublish if students have started conversations")
    false
  end
end
