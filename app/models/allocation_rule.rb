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

class AllocationRule < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  resolves_root_account through: :course
  belongs_to :course
  belongs_to :assignment, class_name: "Assignment"
  belongs_to :assessor, class_name: "User"
  belongs_to :assessee, class_name: "User"

  validates :workflow_state, presence: true, inclusion: { in: %w[active deleted] }
  validate :course_matches_assignment_course
  validate :assessor_and_assessee_valid
  validate :rule_does_not_conflict_with_existing_rules

  after_initialize :set_defaults

  scope :for_user_in_course, lambda { |user_id, course_id|
    where(course_id:)
      .where(
        "(assessor_id = ?) OR " \
        "(assessee_id = ?)",
        user_id,
        user_id
      )
  }

  private

  def set_defaults
    self.must_review = true if must_review.nil?
    self.review_permitted = true if review_permitted.nil?
    self.applies_to_assessor = true if applies_to_assessor.nil?
    self.workflow_state ||= "active"
  end

  def course_matches_assignment_course
    return unless assignment && course

    unless course_id == assignment.context_id
      errors.add(:course_id, I18n.t("must match assignment's course"))
    end
  end

  def assessor_and_assessee_valid
    return unless assignment && course

    eligible_students = assignment.students_with_visibility(assignment.context.participating_students_by_date.not_fake_student).pluck(:id)

    unless eligible_students.include?(assessor_id)
      errors.add(:assessor_id, I18n.t("must be a student assigned to this assignment"))
    end

    unless course.student_enrollments.active.where(user_id: assessor_id).exists?
      errors.add(:assessor_id, I18n.t("must have an active enrollment in the course"))
    end

    unless eligible_students.include?(assessee_id)
      errors.add(:assessee_id, I18n.t("must be a student with visibility to this assignment"))
    end

    unless course.student_enrollments.active.where(user_id: assessee_id).exists?
      errors.add(:assessee_id, I18n.t("must have an active enrollment in the course"))
    end

    if assessor_id == assessee_id
      errors.add(:assessee_id, I18n.t("cannot be the same as the assessor"))
    end
  end

  def rule_does_not_conflict_with_existing_rules
    return unless assignment

    existing_rules = assignment.allocation_rules.where(
      assessor_id:,
      assessee_id:
    )
    existing_rules = existing_rules.where.not(id:) if persisted?

    if existing_rules.exists?
      conflicting_rule = existing_rules.first
      if review_permitted != conflicting_rule.review_permitted
        if review_permitted
          errors.add(:review_permitted, I18n.t("conflicts with existing rule that prohibits this review relationship"))
        else
          errors.add(:review_permitted, I18n.t("conflicts with existing rule that requires this review relationship"))
        end
      end

      if must_review != conflicting_rule.must_review
        if must_review
          errors.add(:must_review, I18n.t("conflicts with existing rule that makes this review optional"))
        else
          errors.add(:must_review, I18n.t("conflicts with existing rule that requires this review"))
        end
      end
    end

    if must_review && assignment.peer_review_count.present? && assignment.peer_review_count > 0
      must_review_count = assignment.allocation_rules.where(
        assessor_id:,
        must_review: true
      ).count

      # Add 1 if this is a new "must review" rule
      must_review_count += 1 unless persisted?

      if must_review_count > assignment.peer_review_count
        errors.add(:must_review, I18n.t("would exceed the maximum number of required peer reviews (%{count}) for this assessor", count: assignment.peer_review_count))
      end
    end

    check_completed_review_conflicts
  end

  def check_completed_review_conflicts
    completed_reviews = AssessmentRequest.joins(:submission)
                                         .where(
                                           assessor_id:,
                                           workflow_state: "completed",
                                           submissions: { assignment_id: assignment.id }
                                         )

    completed_assessee_ids = completed_reviews.pluck(:user_id)

    if !completed_assessee_ids.include?(assessee_id) && assignment.peer_review_count.present? && completed_assessee_ids.length >= assignment.peer_review_count && assignment.peer_review_count > 0
      reviewed_names = User.where(id: completed_assessee_ids).pluck(:name).join(", ")
      errors.add(:assessor_id, I18n.t("conflicts with completed peer reviews. %{assessor_name} has already completed %{count} peer review(s) for: %{reviewed_names}", assessor_name: User.find(assessor_id).name, count: assignment.peer_review_count, reviewed_names:))
    end

    if !review_permitted && completed_assessee_ids.include?(assessee_id)
      assessee_name = User.find(assessee_id).name
      assessor_name = User.find(assessor_id).name
      errors.add(:assessee_id, I18n.t("conflicts with completed peer review. %{assessor_name} has already reviewed %{assessee_name}", assessor_name:, assessee_name:))
    end
  end
end
