require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "quizzes attempts" do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'
  before :all do
    @student2 = user_with_pseudonym(:username => 'student2@example.com', :active_all => 1)
    @course1 = course_model
    @course1.offer!
    @quiz = create_quiz_with_default_due_dates
    add_user_specific_due_date_override(@quiz, :due_at => Time.zone.now.advance(days: 3),
                                        :unlock_at => Time.zone.now.advance(days:1),
                                        :lock_at => Time.zone.now.advance(days:4))
    student_in_section(@new_section, :user => @student2)
  end

  it "should not be accesible for student in the additional section", priority: "1",test_id: 114315 do
    skip('going to replace with better test coverage in subsequent commit')
    user_session(@student2)
    due_at_time = @override.due_at.strftime('%b %-d at %-l:%M') << @override.due_at.strftime('%p').downcase
    unlock_at_time = @override.unlock_at.strftime('%b %-d at %-l:%M') << @override.unlock_at.strftime('%p').downcase
    lock_at_time = @override.lock_at.strftime('%b %-d at %-l:%M') << @override.lock_at.strftime('%p').downcase
    get "/courses/#{@course1.id}/quizzes"
    expect_new_page_load { f("#summary_quiz_#{@quiz.id}").click }
    expect(f("#quiz_student_details").text).to include("Due #{due_at_time}")
    expect(f("#quiz_student_details").text).to include("Available #{unlock_at_time} - #{lock_at_time}")
    expect(f("#quiz_show").text).to include("This quiz is locked until #{unlock_at_time}")
  end

end
