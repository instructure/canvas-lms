# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class ModeratedGrading::ProvisionalGrade < ActiveRecord::Base
  include Canvas::GradeValidations

  AUDITABLE_ATTRIBUTES = %w[
    score grade graded_at final source_provisional_grade_id graded_anonymously scorer_id
  ].freeze

  attr_writer :force_save, :current_user

  belongs_to :submission, inverse_of: :provisional_grades
  belongs_to :scorer, class_name: "User"

  has_many :rubric_assessments, as: :artifact
  has_one :selection,
          class_name: "ModeratedGrading::Selection",
          foreign_key: :selected_provisional_grade_id

  belongs_to :source_provisional_grade, class_name: "ModeratedGrading::ProvisionalGrade"

  validates :scorer, presence: true
  validates :submission, presence: true

  before_create :must_be_final_or_student_in_need_of_provisional_grade,
                :must_have_non_final_provisional_grade_to_create_final

  after_create :touch_graders # to update grading counts
  after_save :touch_submission, :remove_moderation_ignores

  with_options if: :auditable? do
    after_create :create_provisional_grade_created_event
    after_update :create_provisional_grade_updated_event
  end

  scope :scored_by, ->(scorer) { where(scorer_id: scorer) }
  scope :final, -> { where(final: true) }
  scope :not_final, -> { where(final: false) }
  scope :graded, -> { where.not(graded_at: nil) }

  def must_be_final_or_student_in_need_of_provisional_grade
    if final.blank? && !submission.assignment_can_be_moderated_grader?(scorer)
      raise(Assignment::GradeError, "Student already has the maximum number of provisional grades")
    end
  end

  def must_have_non_final_provisional_grade_to_create_final
    if final.present? && submission.provisional_grades.not_final.empty?
      raise(Assignment::GradeError, "Cannot give a final mark for a student with no other provisional grades")
    end
  end

  delegate :touch_graders, to: :submission

  def touch_submission
    submission.touch
  end

  def remove_moderation_ignores
    submission.assignment.ignores.where(purpose: "moderation", permanent: false).delete_all
  end

  def valid?(*)
    infer_grade
    set_graded_at if @force_save || grade_changed? || score_changed?
    super
  end

  def grade_attributes
    as_json(only: ModeratedGrading::GRADE_ATTRIBUTES_ONLY,
            methods: %i[provisional_grade_id grade_matches_current_submission entered_score entered_grade],
            include_root: false)
  end

  def entered_score
    score
  end

  def entered_grade
    grade
  end

  def grade_matches_current_submission
    submission.submitted_at.nil? || graded_at.nil? || submission.submitted_at <= graded_at
  end

  def provisional_grade_id
    id
  end

  def submission_comments
    if submission.all_submission_comments.loaded?
      submission.all_submission_comments.select { |c| c.provisional_grade_id == id || c.provisional_grade_id.nil? }
    else
      submission.all_submission_comments.where("provisional_grade_id = ? OR provisional_grade_id IS NULL", id)
    end
  end

  delegate :student, to: :submission

  def publish!(skip_grade_calc: false)
    original_skip_grade_calc = submission.skip_grade_calc
    previously_graded = submission.grade.present? || submission.excused?
    submission.skip_grade_calc = skip_grade_calc
    submission.grade_posting_in_progress = true
    submission.grade = grade
    submission.score = score
    submission.graded_anonymously = graded_anonymously
    submission.grader_id = scorer_id
    submission.graded_at = Time.now.utc
    submission.grade_matches_current_submission = true
    previously_graded ? submission.with_versioning(explicit: true) { submission.save! } : submission.save!
    publish_submission_comments!
    publish_rubric_assessments!
  ensure
    submission.grade_posting_in_progress = false
    submission.skip_grade_calc = original_skip_grade_calc
  end

  def attachment_info(user, attachment)
    annotators = [submission.user, scorer]
    annotators << source_provisional_grade.scorer if source_provisional_grade
    url_opts = {
      enable_annotations: true,
      moderated_grading_allow_list: annotators.map { |u| u.moderated_grading_ids(true) }
    }

    {
      attachment_id: attachment.id,
      crocodoc_url: attachment.crocodoc_available? &&
        attachment.crocodoc_url(user, url_opts),
      canvadoc_url: attachment.canvadoc_available? &&
        attachment.canvadoc_url(user, url_opts)
    }
  end

  def auditable?
    @current_user.present? &&
      (destroyed? || saved_auditable_changes.present? || auditable_changes.present?) &&
      submission.assignment_auditable?
  end

  private

  def publish_submission_comments!
    submission_comments.select(&:provisional_grade_id).each do |provisional_comment|
      comment = provisional_comment.dup
      comment.grade_posting_in_progress = true
      comment.provisional_grade_id = nil
      comment.save!
    ensure
      comment.grade_posting_in_progress = false
    end
  end

  def copy_submission_comments!(dest_provisional_grade)
    submission_comments.each do |prov_comment|
      pub_comment = prov_comment.dup
      pub_comment.provisional_grade_id = dest_provisional_grade && dest_provisional_grade.id
      pub_comment.save!
    end
  end

  def publish_rubric_assessments!
    rubric_assessments.each do |provisional_assessment|
      rubric_association = provisional_assessment.active_rubric_association? ? provisional_assessment.rubric_association : nil
      # This case arises when a rubric is deleted.
      next if rubric_association.nil?

      params = {
        artifact: submission,
        assessment_type: provisional_assessment.assessment_type
      }

      unless rubric_association.assessments_unique_per_asset?(provisional_assessment.assessment_type)
        params = params.merge({ assessor_id: provisional_assessment.assessor })
      end

      rubric_assessment = rubric_association.rubric_assessments.find_by(params)
      rubric_assessment ||= rubric_association.rubric_assessments.build(
        params.merge(
          assessor: provisional_assessment.assessor,
          user: student,
          rubric: rubric_association.rubric
        )
      )

      rubric_assessment.score = provisional_assessment.score
      rubric_assessment.data = provisional_assessment.data
      rubric_assessment.submission.grade_posting_in_progress = submission.grade_posting_in_progress

      rubric_assessment.save!
    end
  end

  def infer_grade
    if score.present? && grade.nil?
      self.grade = submission.assignment.score_to_grade(score)
    end
  end

  def set_graded_at
    self.graded_at = Time.zone.now
  end

  def create_provisional_grade_created_event
    create_audit_event(event_type: :provisional_grade_created, payload: slice([:id].concat(AUDITABLE_ATTRIBUTES)))
  end

  def create_provisional_grade_updated_event
    create_audit_event(event_type: :provisional_grade_updated, payload: saved_auditable_changes.merge({ id: }))
  end

  def create_audit_event(event_type:, payload:)
    AnonymousOrModerationEvent.create!(
      assignment: submission.assignment,
      submission:,
      user: @current_user,
      event_type:,
      payload:
    )
  end

  def saved_auditable_changes
    saved_changes.slice(*AUDITABLE_ATTRIBUTES)
  end

  def auditable_changes
    changes.slice(*AUDITABLE_ATTRIBUTES)
  end
end
