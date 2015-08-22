class ModeratedGrading::ProvisionalGrade < ActiveRecord::Base
  include Canvas::GradeValidations

  attr_accessible :grade, :score
  attr_writer :force_save

  belongs_to :submission
  belongs_to :scorer, class_name: 'User'

  validates :scorer, presence: true
  validates :submission, presence: true

  def valid?(*)
    set_graded_at if @force_save || grade_changed? || score_changed?
    super
  end

  def grade_attributes
    self.as_json(:only => [:grade, :score, :graded_at, :scorer_id],
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

  private
  def set_graded_at
    self.graded_at = Time.zone.now
  end
end

class ModeratedGrading::NullProvisionalGrade
  def initialize(scorer_id)
    @scorer_id = scorer_id
  end

  def grade_attributes
    {
      'provisional_grade_id' => nil,
      'grade' => nil,
      'score' => nil,
      'graded_at' => nil,
      'scorer_id' => @scorer_id,
      'grade_matches_current_submission' => true
    }
  end

  def submission_comments
    SubmissionComment.none
  end
end