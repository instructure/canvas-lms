class Quizzes::QuizRegrade < ActiveRecord::Base
  self.table_name = 'quiz_regrades'

  attr_accessible :user_id, :quiz_id, :quiz_version, :user, :quiz
  belongs_to :quiz, class_name: 'Quizzes::Quiz'
  belongs_to :user
  has_many :quiz_regrade_runs, class_name: 'Quizzes::QuizRegradeRun'
  has_many :quiz_question_regrades, class_name: 'Quizzes::QuizQuestionRegrade'

  validates_presence_of :quiz_version
  validates_presence_of :quiz_id
  validates_presence_of :user_id

  delegate :teachers, :context, to: :quiz
end
