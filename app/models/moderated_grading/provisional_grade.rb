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

  attr_writer :force_save

  belongs_to :submission, inverse_of: :provisional_grades
  belongs_to :scorer, class_name: 'User'

  has_many :rubric_assessments, as: :artifact
  has_one :selection,
    class_name: 'ModeratedGrading::Selection',
    foreign_key: :selected_provisional_grade_id

  belongs_to :source_provisional_grade, :class_name => 'ModeratedGrading::ProvisionalGrade'

  validates :scorer, presence: true
  validates :submission, presence: true

  before_create :must_be_final_or_student_in_need_of_provisional_grade
  before_create :must_have_non_final_provisional_grade_to_create_final

  after_create :touch_graders # to update grading counts
  after_save :touch_submission
  after_save :remove_moderation_ignores

  scope :scored_by, ->(scorer) { where(scorer_id: scorer) }
  scope :final, -> { where(:final => true)}
  scope :not_final, -> { where(:final => false)}

  def must_be_final_or_student_in_need_of_provisional_grade
    if !self.final && !self.submission.assignment.can_be_moderated_grader?(self.scorer)
      raise(Assignment::GradeError, "Student already has the maximum number of provisional grades")
    end
  end

  def must_have_non_final_provisional_grade_to_create_final
    if self.final && !self.submission.provisional_grades.not_final.exists?
      raise(Assignment::GradeError, "Cannot give a final mark for a student with no other provisional grades")
    end
  end

  def touch_graders
    submission.touch_graders
  end

  def touch_submission
    submission.touch
  end

  def remove_moderation_ignores
    submission.assignment.ignores.where(:purpose => 'moderation', :permanent => false).delete_all
  end

  def valid?(*)
    infer_grade
    set_graded_at if @force_save || grade_changed? || score_changed?
    super
  end

  def grade_attributes
    self.as_json(:only => ModeratedGrading::GRADE_ATTRIBUTES_ONLY,
                 :methods => [:provisional_grade_id, :grade_matches_current_submission, :entered_score, :entered_grade],
                 :include_root => false)
  end

  def entered_score
    score
  end

  def entered_grade
    grade
  end

  def grade_matches_current_submission
    submission.submitted_at.nil? || self.graded_at.nil? || submission.submitted_at <= self.graded_at
  end

  def provisional_grade_id
    self.id
  end

  def submission_comments
    if submission.all_submission_comments.loaded?
      submission.all_submission_comments.select { |c| c.provisional_grade_id == id || c.provisional_grade_id.nil?}
    else
      submission.all_submission_comments.where("provisional_grade_id = ? OR provisional_grade_id IS NULL", self.id)
    end
  end

  def student
    self.submission.student
  end

  def publish!
    submission.grade_posting_in_progress = true
    previously_graded = submission.grade.present? || submission.excused?
    submission.grade = grade
    submission.score = score
    submission.graded_anonymously = graded_anonymously
    submission.grader_id = scorer_id
    submission.graded_at = Time.now.utc
    submission.grade_matches_current_submission = true
    previously_graded ? submission.with_versioning(:explicit => true) { submission.save! } : submission.save!
    publish_submission_comments!
    publish_rubric_assessments!
  ensure
    submission.grade_posting_in_progress = false
  end

  def copy_to_final_mark!(scorer)
    final_mark = submission.find_or_create_provisional_grade!(
      scorer,
      score: self.score,
      grade: self.grade,
      force_save: true,
      graded_anonymously: self.graded_anonymously,
      final: true,
      source_provisional_grade: self
    )

    final_mark.submission_comments.destroy_all
    copy_submission_comments!(final_mark)

    final_mark.rubric_assessments.destroy_all
    copy_rubric_assessments!(final_mark)

    final_mark.reload
    final_mark
  end

  def attachment_info(user, attachment)
    annotators = [submission.user, scorer]
    annotators << source_provisional_grade.scorer if source_provisional_grade
    url_opts = {
      enable_annotations: true,
      moderated_grading_whitelist: annotators.map { |u| u.moderated_grading_ids(true) }
    }

    {
      :attachment_id => attachment.id,
      :crocodoc_url => attachment.crocodoc_available? &&
                       attachment.crocodoc_url(user, url_opts),
      :canvadoc_url => attachment.canvadoc_available? &&
                       attachment.canvadoc_url(user, url_opts)
    }
  end

  private

  def publish_submission_comments!
    copy_submission_comments!(nil)
  end

  def copy_submission_comments!(dest_provisional_grade)
    self.submission_comments.each do |prov_comment|
      pub_comment = prov_comment.dup
      pub_comment.provisional_grade_id = dest_provisional_grade && dest_provisional_grade.id
      pub_comment.save!
    end
  end

  def publish_rubric_assessments!
    copy_rubric_assessments!(submission)
  end

  def copy_rubric_assessments!(dest_artifact)
    self.rubric_assessments.each do |prov_assmt|
      assoc = prov_assmt.rubric_association

      pub_assmt = nil
      # see RubricAssociation#assess
      if dest_artifact.is_a?(Submission)
        if assoc.assessments_unique_per_asset?(prov_assmt.assessment_type)
          pub_assmt = assoc.rubric_assessments.where(artifact_id: dest_artifact.id, artifact_type: dest_artifact.class_name,
                                                     assessment_type: prov_assmt.assessment_type).first
        else
          pub_assmt = assoc.rubric_assessments.where(artifact_id: dest_artifact.id, artifact_type: dest_artifact.class_name,
                                                     assessment_type: prov_assmt.assessment_type, assessor_id: prov_assmt.assessor).first
        end
      end
      pub_assmt ||= assoc.rubric_assessments.build(:assessor => prov_assmt.assessor, :artifact => dest_artifact,
                                                   :user => self.student, :rubric => assoc.rubric, :assessment_type => prov_assmt.assessment_type)
      pub_assmt.score = prov_assmt.score
      pub_assmt.data = prov_assmt.data

      pub_assmt.save!
    end
  end

  def infer_grade
    if self.score.present? && self.grade.nil?
      self.grade = submission.assignment.score_to_grade(score)
    end
  end

  def set_graded_at
    self.graded_at = Time.zone.now
  end
end
