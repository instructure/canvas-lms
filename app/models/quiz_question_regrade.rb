class QuizQuestionRegrade < ActiveRecord::Base
  attr_accessible :quiz_question_id, :quiz_regrade_id, :regrade_option
  belongs_to :quiz_question
  belongs_to :quiz_regrade

  validates_presence_of :quiz_question_id
  validates_presence_of :quiz_regrade_id

  delegate :question_data, to: :quiz_question
end

