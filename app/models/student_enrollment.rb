# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class StudentEnrollment < Enrollment
  belongs_to :student, foreign_key: :user_id, class_name: "User"

  has_many :course_paces, through: :student

  after_save :evaluate_modules, if: proc { |e|
    # if enrollment switches sections or is created
    e.saved_change_to_course_section_id? || e.saved_change_to_course_id? ||
      # or if an enrollment is deleted and they are in another section of the course
      (e.saved_change_to_workflow_state? && e.workflow_state == "deleted" &&
       e.user.enrollments.where.not(id: e.id).active.where(course_id: e.course_id).exists?)
  }
  after_save :restore_submissions_and_scores
  after_save :republish_course_pace_if_needed
  after_save :republish_base_pace_if_needed

  def student?
    true
  end

  def evaluate_modules
    ContextModuleProgression.for_user(user_id).for_course(course_id).each(&:mark_as_outdated!)
  end

  def update_override_score(override_score:, grading_period_id: nil, updating_user:, record_grade_change: true)
    score_params = { grading_period_id: } if grading_period_id.present?
    score = find_score(score_params)

    raise ActiveRecord::RecordNotFound if score.blank?

    old_score = score[:override_score]
    old_grade = score.override_grade
    score.update!(override_score:)

    return score unless score.saved_change_to_override_score?

    Canvas::LiveEvents.grade_override(score, old_score, self, course)
    if record_grade_change && updating_user.present?
      override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
        grader: updating_user,
        old_grade:,
        old_score:,
        score:
      )
      Auditors::GradeChange.record(override_grade_change:)
    end

    score
  end

  def update_override_status(custom_grade_status:, grading_period_id: nil)
    score_params = { grading_period_id: } if grading_period_id.present?
    score = find_score(score_params)

    score.update!(custom_grade_status:)
  end

  class << self
    def restore_submissions_and_scores_for_enrollments(enrollments)
      raise ArgumentError, "Cannot call with more than 1000 enrollments" if enrollments.count > 1_000

      restore_deleted_submissions_for_enrollments(enrollments)
      restore_deleted_scores_for_enrollments(enrollments)
    end

    def restore_deleted_submissions_for_enrollments(student_enrollments)
      raise ArgumentError, "Cannot call with more than 1000 enrollments" if student_enrollments.count > 1_000

      student_enrollments.group_by(&:course_id).each do |course_id, students|
        Submission
          .joins(:assignment)
          .where(user_id: students.map(&:user_id), workflow_state: "deleted", assignments: { context_id: course_id })
          .merge(Assignment.active)
          .in_batches
          .update_all("workflow_state = #{SubmissionLifecycleManager.infer_submission_workflow_state_sql}")
      end
    end

    def restore_deleted_scores_for_enrollments(student_enrollments)
      raise ArgumentError, "Cannot call with more than 1000 enrollments" if student_enrollments.count > 1_000

      student_enrollments.group_by(&:course_id).each_value do |students|
        course = students.first.course
        assignment_groups = course.assignment_groups.active.except(:order)
        grading_periods = GradingPeriod.for(course)

        Score.where(course_score: true).or(
          Score.where(assignment_group: assignment_groups)
        ).or(
          Score.where(grading_period: grading_periods)
        ).where(enrollment_id: students.map(&:id), workflow_state: "deleted")
             .update_all(workflow_state: "active")
      end
    end
  end

  private

  def restore_submissions_and_scores
    return unless being_restored?(to_state: "completed")

    # running in an n_strand to handle situations where a SIS import could
    # update a ton of enrollments from "deleted" to "completed".
    delay_if_production(n_strand: "Enrollment#restore_submissions_and_scores#{root_account.global_id}",
                        priority: Delayed::LOW_PRIORITY)
      .restore_submissions_and_scores_now
  end

  def restore_submissions_and_scores_now
    restore_deleted_submissions
    restore_deleted_scores
  end

  def restore_deleted_submissions
    StudentEnrollment.restore_deleted_submissions_for_enrollments([self])
  end

  def restore_deleted_scores
    StudentEnrollment.restore_deleted_scores_for_enrollments([self])
  end

  def republish_course_pace_if_needed
    return unless saved_change_to_id? || saved_change_to_start_at? || (saved_change_to_workflow_state? && workflow_state != "deleted")
    return unless course.enable_course_paces?

    pace = course.course_paces.published.where(course_section_id:).last
    pace ||= course.course_paces.published.for_user(user).take || course.course_paces.published.primary.take
    pace&.create_publish_progress
    track_multiple_section_paces
  end

  def republish_base_pace_if_needed
    return unless course.enable_course_paces? && course_section_id && workflow_state == "deleted"

    student_section_ids = user.enrollments.where(course:).where.not(workflow_state: "deleted").pluck(:course_section_id)
    pace = course.course_paces.published.where(course_section_id: student_section_ids).last
    pace ||= course.course_paces.published.primary.take
    pace&.create_publish_progress
  end

  def track_multiple_section_paces
    section_ids_the_student_is_enrolled_in = user.student_enrollments.where.not(workflow_state: "deleted")
                                                 .where(course_section: course.course_sections.pluck(:id))
                                                 .pluck(:course_section_id)
    if section_ids_the_student_is_enrolled_in.count > 1 && course.course_paces.published.for_section(section_ids_the_student_is_enrolled_in).size > 1
      InstStatsd::Statsd.increment("course_pacing.student_with_multiple_sections_with_paces")
    end
  end
end
