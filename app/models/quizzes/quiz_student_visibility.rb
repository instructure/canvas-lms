class Quizzes::QuizStudentVisibility < ActiveRecord::Base
  # necessary for general_model_spec
  attr_protected :user, :quiz, :course

  include VisibilityPluckingHelper

  # create_or_update checks for !readonly? before persisting
  def readonly?
    true
  end

  def self.visible_quiz_ids_in_course_by_user(opts)
    visible_object_ids_in_course_by_user(:quiz_id, opts)
  end

  def self.users_with_visibility_by_quiz(opts)
    users_with_visibility_by_object_id(:quiz_id, opts)
  end

  # readonly? is not checked in destroy though
  before_destroy { |record| raise ActiveRecord::ReadOnlyRecord }
end