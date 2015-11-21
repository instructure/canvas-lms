require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/selective_release_module')

shared_context 'selective release' do
  include SelectiveRelease
  include_context 'in-process server selenium tests'

  before(:once) { SelectiveRelease.setup }

  def login_as_first_student
    user_session(SelectiveRelease::Users.first_student)
  end

  def login_as_second_student
    user_session(SelectiveRelease::Users.second_student)
  end

  def login_as_third_student
    user_session(SelectiveRelease::Users.third_student)
  end

  def login_as_fourth_student
    user_session(SelectiveRelease::Users.fourth_student)
  end

  def login_as_teacher
    user_session(SelectiveRelease::Users.teacher)
  end

  def login_as_ta
    user_session(SelectiveRelease::Users.ta)
  end

  def login_as_first_observer
    user_session(SelectiveRelease::Users.first_observer)
  end

  def login_as_third_observer
    user_session(SelectiveRelease::Users.third_observer)
  end

  def go_to_quizzes_index_page
    get "/courses/#{SelectiveRelease.sr_course.id}/quizzes"
  end

  def go_to_assignments_index_page
    get "/courses/#{SelectiveRelease.sr_course.id}/assignments"
  end

  def go_to_discussions_index_page
    get "/courses/#{SelectiveRelease.sr_course.id}/discussions"
  end
end