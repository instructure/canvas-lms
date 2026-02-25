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
  has_many :ai_experience_context_files, dependent: :destroy
  # Excludes soft-deleted attachments. Note: if an attachment is deleted in Canvas
  # after being associated, the join record remains but the file is silently omitted
  # from context_data. The llm-conversation service JSONB will contain stale data
  # until the next explicit save of this AiExperience — this is intentional to avoid
  # synchronous service calls in destroy callbacks.
  has_many :context_files,
           -> { where.not(attachments: { file_state: "deleted" }) },
           through: :ai_experience_context_files,
           source: :attachment,
           class_name: "Attachment"

  validates :title, presence: true, length: { maximum: 255 }
  validates :learning_objective, presence: true
  validates :pedagogical_guidance, presence: true
  validates :workflow_state, presence: true, inclusion: { in: %w[unpublished published deleted] }
  validates :context_index_status, presence: true, inclusion: { in: %w[not_started in_progress completed failed] }
  validate :unpublish_ok?, if: -> { will_save_change_to_workflow_state?(to: "unpublished") }
  validate :publish_ok?, if: -> { will_save_change_to_workflow_state?(to: "published") }

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
  before_destroy :delete_conversation_context
  # sync_context_files must be defined before maybe_update_conversation_context so
  # files are persisted before the service is notified of changes.
  after_save :sync_context_files, if: :pending_context_file_ids?
  after_save :index_context_files_if_changed
  after_save :maybe_update_conversation_context

  def context_file_ids=(ids)
    @pending_context_file_ids = Array(ids).map(&:to_s)
  end

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

    @can_unpublish = !student_conversations? && indexing_allows_publish_changes?
  end

  def can_publish?
    return true if new_record?
    return @can_publish unless @can_publish.nil?

    # Publishing is only restricted by indexing status, not by student conversations
    @can_publish = indexing_allows_publish_changes?
  end

  attr_writer :can_unpublish, :can_publish

  def indexing_allows_publish_changes?
    # If feature flag is disabled, don't restrict based on indexing
    return true unless course.feature_enabled?(:ai_experiences_context_file_upload)

    # If no context files uploaded, don't restrict
    return true if llm_conversation_context_id.blank?

    # Only allow publish state changes when indexing is completed
    context_index_status == "completed"
  end

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

  def pending_context_file_ids?
    !@pending_context_file_ids.nil?
  end

  def sync_context_files
    incoming_ids = @pending_context_file_ids.map(&:to_i)
    current_ids = ai_experience_context_files.order(:position).pluck(:attachment_id)

    @context_files_changed = incoming_ids != current_ids

    if @context_files_changed
      ai_experience_context_files.destroy_all
      incoming_ids.each { |attachment_id| ai_experience_context_files.create!(attachment_id:) }
    end

    @pending_context_file_ids = nil
  end

  def index_context_files_if_changed
    return unless @context_files_changed
    return unless llm_conversation_context_id.present?
    return unless course.feature_enabled?(:ai_experiences_context_file_upload)

    LLMConversationContextManager.trigger_indexing(ai_experience: self)
  rescue LlmConversation::Errors::ConversationError => e
    Rails.logger.error("Failed to trigger document indexing for AiExperience #{id}: #{e.message}")
  end

  def maybe_update_conversation_context
    return if previously_new_record?
    return unless should_update_context?

    update_conversation_context
  end

  def should_update_context?
    return false unless llm_conversation_context_id.present?

    context_changed = saved_change_to_pedagogical_guidance? || saved_change_to_facts? || saved_change_to_learning_objective?

    if course.feature_enabled?(:ai_experiences_context_file_upload)
      context_changed ||= @context_files_changed.present?
      @context_files_changed = nil
    end

    context_changed
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

    if !indexing_allows_publish_changes?
      errors.add :workflow_state, I18n.t("Cannot unpublish while source files are still processing")
    elsif student_conversations?
      errors.add :workflow_state, I18n.t("Cannot unpublish if students have started conversations")
    end
    false
  end

  def publish_ok?
    return true if can_publish?

    errors.add :workflow_state, I18n.t("Cannot publish while source files are still processing")
    false
  end
end
