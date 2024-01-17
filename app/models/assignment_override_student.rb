# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

class AssignmentOverrideStudent < ActiveRecord::Base
  include Canvas::SoftDeletable
  belongs_to :assignment, class_name: "AbstractAssignment"
  belongs_to :assignment_override
  belongs_to :user
  belongs_to :quiz, class_name: "Quizzes::Quiz"
  belongs_to :context_module
  belongs_to :wiki_page
  belongs_to :discussion_topic
  belongs_to :attachment

  before_create :set_root_account_id
  after_save :destroy_override_if_needed
  after_create :update_cached_due_dates
  after_destroy :update_cached_due_dates
  after_destroy :destroy_override_if_needed
  before_validation :default_values
  before_validation :clean_up_assignment_if_override_student_orphaned

  validates :assignment_override, :user, presence: true
  validates :user_id, uniqueness: { scope: %i[assignment_id quiz_id context_module_id wiki_page_id discussion_topic_id attachment_id],
                                    conditions: -> { where.not(workflow_state: "deleted") },
                                    message: -> { t("already belongs to an assignment override") } }

  validate :assignment_override, if: :active? do |record|
    if record.assignment_override && record.assignment_override.set_type != "ADHOC"
      record.errors.add :assignment_override, "is not adhoc"
    end
  end

  validate :assignment, if: :active? do |record|
    if record.assignment_override && record.assignment_id != record.assignment_override.assignment_id
      record.errors.add :assignment, "doesn't match assignment_override"
    end
  end

  validate :user, if: :active? do |record|
    if no_enrollment?(record)
      record.errors.add :user, "is not in the assignment's course"
    end
  end

  validate do |record|
    if record.active? && [record.assignment, record.quiz, record.context_module, record.wiki_page, record.discussion_topic, record.attachment].all?(&:nil?)
      record.errors.add :base, "requires assignment, quiz, module, page, discussion, or file"
    end
  end

  def context_id
    if quiz
      quiz.reload if quiz.id != quiz_id
      quiz.context_id
    elsif assignment
      assignment.reload if assignment.id != assignment_id
      assignment.context_id
    elsif context_module
      context_module.reload if context_module.id != context_module_id
      context_module.context_id
    elsif wiki_page
      wiki_page.reload if wiki_page.id != wiki_page_id
      wiki_page.context_id
    elsif discussion_topic
      discussion_topic.reload if discussion_topic.id != discussion_topic_id
      discussion_topic.context_id
    elsif attachment
      attachment.reload if attachment.id != attachment_id
      attachment.context_id
    end
  end

  def default_values
    if assignment_override
      self.assignment_id = assignment_override.assignment_id
      self.quiz_id = assignment_override.quiz_id
      self.context_module_id = assignment_override.context_module_id
      self.wiki_page_id = assignment_override.wiki_page_id
      self.discussion_topic_id = assignment_override.discussion_topic_id
      self.attachment_id = assignment_override.attachment_id
    end
  end
  protected :default_values

  def destroy_override_if_needed
    assignment_override.destroy_if_empty_set
  end
  protected :destroy_override_if_needed

  def self.clean_up_for_assignment(assignment)
    return unless assignment.context_type == "Course"
    return if assignment.new_record?

    valid_student_ids = Enrollment
                        .active
                        .where(course_id: assignment.context_id)
                        .pluck(:user_id)

    AssignmentOverrideStudent
      .where(assignment:)
      .where.not(user_id: valid_student_ids)
      .each do |aos|
      aos.assignment_override.skip_broadcasts = true
      aos.destroy
    end
  end

  attr_writer :no_enrollment

  private

  def clean_up_assignment_if_override_student_orphaned
    if no_enrollment? && persisted? && assignment_id && active?
      self.class.clean_up_for_assignment(assignment)
      @no_enrollment = false
      # return something other than false to avoid halting the callback chain
      nil
    end
  end

  def no_enrollment?(record = self)
    return @no_enrollment if defined?(@no_enrollment)

    return false unless record.user_id && record.context_id

    @no_enrollment = !record.user.student_enrollments.shard(record.shard).where(course_id: record.context_id).exists?
  end

  def update_cached_due_dates
    if assignment.present?
      assignment.clear_cache_key(:availability)
      SubmissionLifecycleManager.recompute_users_for_course(user_id, assignment.context, [assignment])
    end
    quiz&.clear_cache_key(:availability)
  end

  def set_root_account_id
    self.root_account_id ||= assignment&.root_account_id || quiz&.root_account_id || context_module&.root_account_id || wiki_page&.root_account_id || discussion_topic&.root_account_id || attachment&.root_account_id
  end
end
