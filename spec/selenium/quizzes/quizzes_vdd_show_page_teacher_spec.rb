require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignment_overrides')

describe 'viewing a quiz with variable due dates on the quiz show page' do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

  before(:all) do
    prepare_multiple_due_dates_scenario_for_teacher
  end

  context 'with a teacher in both sections' do
    before(:each) do
      user_session(@teacher1)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    end

    it 'shows the due dates for Section A', priority: "1", test_id: 315658 do
      expect(obtain_due_date(@section_a)).to include_text("#{format_time_for_view(@due_at_a)}")
    end

    it 'shows the due dates for Section B', priority: "1", test_id: 315660 do
      expect(obtain_due_date(@section_b)).to include_text("#{format_time_for_view(@due_at_b)}")
    end

    it 'shows the availability dates for Section A', priority: "1", test_id: 315662 do
      expect(obtain_availability_start_date(@section_a)).to include_text("#{format_time_for_view(@unlock_at_a)}")
      expect(obtain_availability_end_date(@section_a)).to include_text("#{format_time_for_view(@lock_at_a)}")
    end

    it 'shows the availability dates for Section B', priority: "1", test_id: 315664 do
      expect(obtain_availability_start_date(@section_b)).to include_text("#{format_time_for_view(@unlock_at_b)}")
      expect(obtain_availability_end_date(@section_b)).to include_text("#{format_time_for_view(@lock_at_b)}")
    end

    it 'allows taking the quiz', priority: "1", test_id: 282394 do
      expect(f('.take_quiz_button')).to be_displayed
    end
  end
end