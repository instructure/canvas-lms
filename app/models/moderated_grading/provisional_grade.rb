class ModeratedGrading::ProvisionalGrade < ActiveRecord::Base
  include Canvas::GradeValidations

  attr_accessible :grade, :score, :final
  attr_writer :force_save

  belongs_to :submission, inverse_of: :provisional_grades
  belongs_to :scorer, class_name: 'User'

  has_many :rubric_assessments, as: :artifact
  has_one :selection,
    class_name: 'ModeratedGrading::Selection',
    foreign_key: :selected_provisional_grade_id

  validates :scorer, presence: true
  validates :submission, presence: true

  after_create :touch_graders # to update grading counts
  after_save :remove_moderation_ignores

  scope :scored_by, ->(scorer) { where(scorer_id: scorer) }
  scope :final, -> { where(:final => true)}
  scope :not_final, -> { where(:final => false)}

  def touch_graders
    submission.touch_graders
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
    self.as_json(:only => [:grade, :score, :graded_at, :scorer_id, :final],
                 :methods => [:provisional_grade_id, :grade_matches_current_submission],
                 :include_root => false)
  end

  def grade_matches_current_submission
    submission.submitted_at.nil? || self.graded_at.nil? || submission.submitted_at <= self.graded_at
  end

  def provisional_grade_id
    self.id
  end

  def submission_comments
    if submission.all_submission_comments.loaded?
      submission.all_submission_comments.select { |c| c.provisional_grade_id == id }
    else
      submission.all_submission_comments.where(provisional_grade_id: id)
    end
  end

  def student
    self.submission.student
  end

  def publish!
    previously_graded = submission.grade.present? || submission.excused?
    submission.grade = grade
    submission.score = score
    submission.grader_id = scorer_id
    submission.graded_at = Time.now.utc
    submission.grade_matches_current_submission = true
    previously_graded ? submission.with_versioning(:explicit => true) { submission.save! } : submission.save!
    publish_submission_comments!
    publish_rubric_assessments!
  end

  def copy_to_final_mark!(scorer)
    final_mark = submission.find_or_create_provisional_grade!(scorer: scorer,
                                                              score: self.score,
                                                              grade: grade,
                                                              force_save: true,
                                                              final: true)
    final_mark.submission_comments.destroy_all
    copy_submission_comments!(final_mark)

    final_mark.rubric_assessments.destroy_all
    copy_rubric_assessments!(final_mark)

    final_mark.reload
    final_mark
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
