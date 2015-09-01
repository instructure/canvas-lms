require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "quizzes attempts" do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'
  before :all do
    @student1 = user_with_pseudonym(:username => 'student1@example.com', :active_all => 1)
    @course1 = course_with_student_logged_in(:user => @student1, :active_all => 1, :course_name => 'course1').course
    @quiz = create_quiz_with_default_due_dates
    add_user_specific_due_date_override(@quiz, :due_at => Time.zone.now.advance(days: 3),
                                        :unlock_at => Time.zone.now.advance(days:1),
                                        :lock_at => Time.zone.now.advance(days:4))
  end

  it "should be accesible for student in the main section", priority: "1", test_id: 114315, priority: "1"  do
    skip('going to replace with better test coverage in subsequent commit')
    get "/courses/#{@course1.id}/quizzes"
    expect_new_page_load { f("#summary_quiz_#{@quiz.id}").click }
    due_at_time = @quiz.due_at.strftime('%b %-d at %-l:%M') << @quiz.due_at.strftime('%p').downcase
    unlock_at_time = @quiz.unlock_at.strftime('%b %-d at %-l:%M') << @quiz.unlock_at.strftime('%p').downcase
    lock_at_time = @quiz.lock_at.strftime('%b %-d at %-l:%M') << @quiz.lock_at.strftime('%p').downcase
    expect(f("#quiz_student_details").text).to include("Due #{due_at_time}")
    expect(f("#quiz_student_details").text).to include("Available #{unlock_at_time} - #{lock_at_time}")
  end
end

