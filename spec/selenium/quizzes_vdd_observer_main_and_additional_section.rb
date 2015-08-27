require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "quizzes attempts" do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'
  before :all do
    @student1 = user_with_pseudonym(:username => 'student1@example.com', :active_all => 1)
    @student2 = user_with_pseudonym(:username => 'student2@example.com', :active_all => 1)
    @observer1 = user_with_pseudonym(:username => 'observer1@example.com', :active_all => 1)
    @course1 = course_with_student_logged_in(:user => @student1, :active_all => 1, :course_name => 'course1').course
    @quiz = create_quiz_with_default_due_dates
    add_user_specific_due_date_override(@quiz, :due_at => Time.zone.now.advance(days: 3),
                                        :unlock_at => Time.zone.now.advance(days:1),
                                        :lock_at => Time.zone.now.advance(days:4))
  end

  it "should show the due dates for observer linked to both students", priority: "1", test_id: 114315 do
    # enroll student in additional section
    # link observer to the student in main section and to the student in additional section
    student_in_section(@new_section, :user => @student2)
    @course1.enroll_user(@observer1, 'ObserverEnrollment', :enrollment_state => 'active',
                         :associated_user_id => @student1.id)
    @course1.enroll_user(@observer1, 'ObserverEnrollment', :enrollment_state => 'active',
                         :allow_multiple_enrollments => true, :associated_user_id => @student2.id)
    user_session(@observer1)
    get "/courses/#{@course1.id}/quizzes"

    # expect to find 'Multiple due dates' to show in quiz index page
    lock_at_time = @quiz.lock_at.strftime('%b %-d')
    unlock_at_time = @override.unlock_at.strftime('%b %-d')
    driver.mouse.move_to fln('Multiple Dates')
    keep_trying_until do
      expect(f("#ui-tooltip-0")).to
      include_text("Everyone else\nAvailable until #{lock_at_time}\nNew Section\nNot available until #{unlock_at_time}")
    end
  end
end