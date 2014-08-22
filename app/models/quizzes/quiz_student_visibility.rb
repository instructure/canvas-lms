class Quizzes::QuizStudentVisibility < ActiveRecord::Base
  # necessary for general_model_spec
  attr_protected :user, :quiz, :course

  # create_or_update checks for !readonly? before persisting
  def readonly?
    true
  end

  # readonly? is not checked in destroy though
  before_destroy { |record| raise ActiveRecord::ReadOnlyRecord }
end