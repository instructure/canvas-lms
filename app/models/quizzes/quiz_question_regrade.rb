class Quizzes::QuizQuestionRegrade < ActiveRecord::Base
  self.table_name = 'quiz_question_regrades'

  belongs_to :quiz_question, :class_name => 'Quizzes::QuizQuestion'
  belongs_to :quiz_regrade, class_name: 'Quizzes::QuizRegrade'

  validates_presence_of :quiz_question_id
  validates_presence_of :quiz_regrade_id

  delegate :question_data, to: :quiz_question
end
