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

  scope :active, -> { where.not(workflow_state: "deleted") }
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
      errors.add(:assessor_id, I18n.t("assessor (%{assessor_id}) must be a student assigned to this assignment", assessor_id: assessor_id.to_s))
    end

    unless course.student_enrollments.active.where(user_id: assessor_id).exists?
      errors.add(:assessor_id, I18n.t("assessor (%{assessor_id}) must have an active enrollment in the course", assessor_id: assessor_id.to_s))
    end

    unless eligible_students.include?(assessee_id)
      errors.add(:assessee_id, I18n.t("assessee (%{assessee_id}) must be a student with visibility to this assignment", assessee_id: assessee_id.to_s))
    end

    unless course.student_enrollments.active.where(user_id: assessee_id).exists?
      errors.add(:assessee_id, I18n.t("assessee (%{assessee_id}) must have an active enrollment in the course", assessee_id: assessee_id.to_s))
    end

    if assessor_id == assessee_id
      errors.add(:assessee_id, I18n.t("assessee (%{assessee_id}) cannot be the same as the assessor", assessee_id: assessee_id.to_s))
    end
  end

  def rule_does_not_conflict_with_existing_rules
    return unless assignment

    existing_rules = assignment.allocation_rules.active.where(
      assessor_id:,
      assessee_id:
    )
    existing_rules = existing_rules.where.not(id:) if persisted?

    if existing_rules.exists?
      errors.add(applies_to_assessor ? :assessee_id : :assessor_id, I18n.t("This rule conflicts with rule \"%{rule_text}\"", rule_text: format_rule_text(existing_rules.first)))
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

    if !review_permitted && completed_assessee_ids.include?(assessee_id)
      assessee_name = assessee.name
      assessor_name = assessor.name
      errors.add(:assessee_id, I18n.t("This rule conflicts with completed peer review. %{assessor_name} has already reviewed %{assessee_name}", assessor_name:, assessee_name:))
    end
  end

  def format_rule_text(rule)
    assessee_name = assessee.name
    assessor_name = assessor.name
    if rule.must_review
      if rule.review_permitted
        if rule.applies_to_assessor
          I18n.t("%{assessor_name} must review %{assessee_name}", assessor_name:, assessee_name:)
        else
          I18n.t("%{assessee_name} must be reviewed by %{assessor_name}", assessor_name:, assessee_name:)
        end
      elsif rule.applies_to_assessor
        I18n.t("%{assessor_name} must not review %{assessee_name}", assessor_name:, assessee_name:)
      else
        I18n.t("%{assessee_name} must not be reviewed by %{assessor_name}", assessor_name:, assessee_name:)
      end
    elsif rule.review_permitted
      if rule.applies_to_assessor
        I18n.t("%{assessor_name} should review %{assessee_name}", assessor_name:, assessee_name:)
      else
        I18n.t("%{assessee_name} should be reviewed by %{assessor_name}", assessor_name:, assessee_name:)
      end
    elsif rule.applies_to_assessor
      I18n.t("%{assessor_name} should not review %{assessee_name}", assessor_name:, assessee_name:)
    else
      I18n.t("%{assessee_name} should not be reviewed by %{assessor_name}", assessor_name:, assessee_name:)
    end
  end
end
