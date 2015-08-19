class ModeratedGrading::ProvisionalGrade < ActiveRecord::Base
  include Canvas::GradeValidations

  attr_accessible :grade, :score, :position

  belongs_to :submission
  belongs_to :scorer, class_name: 'User'

  validates :scorer, presence: true
  validates :submission, presence: true

  def valid?(*)
    set_graded_at if grade_changed? || score_changed?
    super
  end

  private
  def set_graded_at
    self.graded_at = Time.zone.now
  end
end
