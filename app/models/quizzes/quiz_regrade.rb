class Quizzes::QuizRegrade < ActiveRecord::Base
  self.table_name = 'quiz_regrades'

  attr_accessible :user_id, :quiz_id, :quiz_version
  belongs_to :quiz, class_name: 'Quizzes::Quiz'
  belongs_to :user
  has_many :quiz_regrade_runs, class_name: 'Quizzes::QuizRegradeRun'
  has_many :quiz_question_regrades, class_name: 'Quizzes::QuizQuestionRegrade'

  EXPORTABLE_ATTRIBUTES = [:id, :user_id, :quiz_id, :quiz_version, :created_at, :updated_at]
  EXPORTABLE_ASSOCIATIONS = [:quiz, :user, :quiz_regrade_runs, :queiz_question_regrades]

  validates_presence_of :quiz_version
  validates_presence_of :quiz_id
  validates_presence_of :user_id

  delegate :teachers, to: :quiz
end
