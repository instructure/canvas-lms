require_relative "../../common"
require_relative "../../helpers/quizzes_common"
require_relative "../../helpers/assignment_overrides"

describe 'viewing a quiz with variable due dates on the quiz show page' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  context 'as an observer linked to two students in different sections' do
    before(:once) { prepare_vdd_scenario_for_first_observer }

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
      expect(f("#content")).not_to contain_css('.take_quiz_button')
    end
  end

  context 'as an observer linked to a single student' do
    before(:once) { prepare_vdd_scenario_for_second_observer }

    before(:each) do
      user_session(@observer2)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    end

    it 'shows the due dates for Section B', priority: "2", test_id: 315678 do
      validate_quiz_show_page("Due #{format_date_for_view(@due_at_b)}")
    end

    it 'shows the availability dates for Section B', priority: "2", test_id: 315680 do
      validate_quiz_show_page("Available #{format_time_for_view(@unlock_at_b)} "\
        "- #{format_time_for_view(@lock_at_b)}")
    end

    it 'prevents taking the quiz', priority: "2", test_id: 282400 do
      expect(f("#content")).not_to contain_css('.take_quiz_button')
    end

    it 'indicates quiz is locked', priority: "2", test_id: 321949 do
      validate_quiz_show_page("This quiz is locked until #{format_time_for_view(@unlock_at_b)}")
    end
  end
end
