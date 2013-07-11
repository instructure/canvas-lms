class QuizRegrade < ActiveRecord::Base
  attr_accessible :user_id, :quiz_id, :quiz_version
  belongs_to :quiz
  belongs_to :user
  has_many :quiz_regrade_runs
  has_many :quiz_question_regrades

  validates_presence_of :quiz_version
  validates_presence_of :quiz_id
  validates_presence_of :user_id

  delegate :teachers, to: :quiz
end
