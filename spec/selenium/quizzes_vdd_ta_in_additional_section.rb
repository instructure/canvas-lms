require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "quizzes attempts" do
  include AssignmentOverridesSeleniumHelper
  include_examples "quizzes selenium tests"
  before :all do
    @ta1 = user_with_pseudonym(:username => 'ta1@example.com', :active_all => 1)
    @course1 = course_model
    @course1.offer!
    @quiz = create_quiz_with_default_due_dates
    add_user_specific_due_date_override(@quiz, :due_at => Time.zone.now.advance(days: 3),
                                        :unlock_at => Time.zone.now.advance(days:1),
                                        :lock_at => Time.zone.now.advance(days:4))
    ta_in_section(@new_section, :user => @ta1)
  end

  it "should show the due dates for TA in the additional section", priority: "1", test_id: 114315 do
    user_session(@ta1)
    get "/courses/#{@course1.id}"
    expect_new_page_load{ f("#section-tabs .quizzes").click }
    lock_at_time = @quiz.lock_at.strftime('%b %-d')
    unlock_at_time = @override.unlock_at.strftime('%b %-d')
    hover_text = "Everyone else\nAvailable until #{lock_at_time}\nNew Section\nNot available until #{unlock_at_time}"
    driver.mouse.move_to fln('Multiple Dates')
    keep_trying_until do
      expect(f("#ui-tooltip-0").text).to eq(hover_text)
    end
  end
end