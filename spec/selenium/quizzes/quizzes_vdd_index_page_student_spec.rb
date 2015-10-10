require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignment_overrides')

describe 'viewing a quiz with variable due dates on the quizzes index page' do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

  context 'as a student in Section A' do
    before(:all) { prepare_vdd_scenario_for_first_student }

    before(:each) do
      user_session(@student1)
      get "/courses/#{@course.id}/quizzes"
    end

    it 'shows the due dates for Section A', priority: "1", test_id: 282165 do
      expect(f('.date-due')).to include_text("Due #{format_time_for_view(@due_at_a)}")
    end

    it 'shows the availability dates for Section A', priority: "1", test_id: 282389 do
      expect(f('.date-available')).to include_text("Available until #{format_date_for_view(@lock_at_a)}")
    end
  end

  context 'as a student in Section B' do
    before(:all) { prepare_vdd_scenario_for_second_student }

    before(:each) do
      user_session(@student2)
      get "/courses/#{@course.id}/quizzes"
    end

    it 'shows the due dates for Section B', priority: "1", test_id: 282166 do
      expect(f('.date-due')).to include_text("Due #{format_time_for_view(@due_at_b)}")
    end

    it 'shows the availability dates for Section B', priority: "1", test_id: 282391 do
      expect(f('.date-available')).to include_text("Not available until #{format_date_for_view(@unlock_at_b)}")
    end
  end
end