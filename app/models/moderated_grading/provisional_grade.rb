class ModeratedGrading::ProvisionalGrade < ActiveRecord::Base
  include Canvas::GradeValidations

  attr_accessible :grade, :score, :final
  attr_writer :force_save

  belongs_to :submission
  belongs_to :scorer, class_name: 'User'

  has_many :rubric_assessments, as: :artifact
  has_one :selection,
    class_name: 'ModeratedGrading::Selection',
    foreign_key: :selected_provisional_grade_id

  validates :scorer, presence: true
  validates :submission, presence: true

  after_create :touch_graders # to update grading counts

  scope :scored_by, ->(scorer) { where(scorer_id: scorer) }
  scope :final, -> { where(:final => true)}
  scope :not_final, -> { where(:final => false)}

  def touch_graders
    submission.touch_graders
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
    submission.all_submission_comments.for_provisional_grade(self.id)
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

  private

  def publish_submission_comments!
    self.submission_comments.each do |prov_comment|
      pub_comment = prov_comment.dup
      pub_comment.provisional_grade_id = nil
      pub_comment.save!
    end
  end

  def publish_rubric_assessments!
    self.rubric_assessments.each do |prov_assmt|
      assoc = prov_assmt.rubric_association

      pub_assmt = nil
      # see RubricAssociation#assess
      if assoc.assessments_unique_per_asset?(prov_assmt.assessment_type)
        pub_assmt = assoc.rubric_assessments.where(artifact_id: self.submission_id, artifact_type: 'Submission',
          assessment_type: prov_assmt.assessment_type).first
      else
        pub_assmt = assoc.rubric_assessments.where(artifact_id: self.submission_id, artifact_type: 'Submission',
          assessment_type: prov_assmt.assessment_type, assessor_id: prov_assmt.assessor).first
      end
      pub_assmt ||= assoc.rubric_assessments.build(:assessor => prov_assmt.assessor, :artifact => self.submission,
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
