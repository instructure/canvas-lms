require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignment_overrides')

describe 'viewing a quiz with variable due dates on the quiz show page' do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

  context 'as a student in Section A' do
    before(:all) { prepare_vdd_scenario_for_first_student }

    before(:each) do
      user_session(@student1)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    end

    it 'shows the due dates for Section A', priority: "1", test_id: 315649 do
      validate_quiz_show_page("Due #{format_time_for_view(@due_at_a)}")
    end

    it 'shows the availability dates for Section A', priority: "1", test_id: 315856 do
      validate_quiz_show_page("Available #{format_time_for_view(@unlock_at_a)} - #{format_time_for_view(@lock_at_a)}")
    end

    it 'allows taking the quiz', priority: "1", test_id: 282390 do
      expect(f('.take_quiz_button')).to be_displayed
    end
  end

  context 'as a student in Section B' do
    before(:all) { prepare_vdd_scenario_for_second_student }

    before(:each) do
      user_session(@student2)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    end

    it 'shows its due date', priority: "1", test_id: 315857 do
      validate_quiz_show_page("Due #{format_time_for_view(@due_at_b)}")
    end

    it 'shows its availability dates', priority: "1", test_id: 315859 do
      validate_quiz_show_page("Available #{format_time_for_view(@unlock_at_b)} - #{format_time_for_view(@lock_at_b)}")
    end

    it 'prevents taking the quiz', priority: "1", test_id: 324918 do
      expect(f('.take_quiz_button')).to be_nil
    end

    it 'indicates quiz is locked', priority: "1", test_id: 282392 do
      validate_quiz_show_page("This quiz is locked until #{format_time_for_view(@unlock_at_b)}")
    end
  end
end