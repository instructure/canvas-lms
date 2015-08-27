require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignment_overrides')

describe 'viewing a quiz with variable due dates on the quiz show page' do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

  context 'as an observer linked to two students in different sections' do
    before(:all) { prepare_vdd_scenario_for_first_observer }

    before(:each) do
      user_session(@observer1)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    end

    it 'indicates multiple due dates', priority: "2", test_id: 315665 do
      validate_quiz_show_page('Due Multiple Due Dates')
    end

    it 'indicates various availability dates', priority: "2", test_id: 315668 do
      skip('Bug ticket created: CNVS-22549')
      validate_quiz_show_page('Available Various Availability Dates')
    end

    it 'prevents taking the quiz', priority: "2", test_id: 282398 do
      expect(f('.take_quiz_button')).to be_nil
    end
  end

  context 'as an observer linked to a single student' do
    before(:all) { prepare_vdd_scenario_for_second_observer }

    before(:each) do
      user_session(@observer2)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    end

    it 'shows the due dates for Section B', priority: "2", test_id: 315678 do
      validate_quiz_show_page("Due #{format_date_for_view(@due_at_b)}")
    end

    it 'shows the availability dates for Section B', priority: "2", test_id: 315680 do
      validate_quiz_show_page("Available #{format_time_for_view(@unlock_at_b)} - #{format_time_for_view(@lock_at_b)}")
    end

    it 'prevents taking the quiz', priority: "2", test_id: 282400 do
      expect(f('.take_quiz_button')).to be_nil
    end

    it 'indicates quiz is locked', priority: "2", test_id: 321949 do
      validate_quiz_show_page("This quiz is locked until #{format_time_for_view(@unlock_at_b)}")
    end
  end
end