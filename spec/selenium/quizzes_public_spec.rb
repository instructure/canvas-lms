require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')

describe "quizzes for a public course" do
  include_context "in-process server selenium tests"
  include_context "public course as a logged out user"

  it "should display quizzes list", priority: "1", test_id: 270033 do
    course_quiz(active=true)
    get "/courses/#{public_course.id}/quizzes"
    validate_selector_displayed('#assignment-quizzes')
  end
end
