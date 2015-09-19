require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignment_overrides')

describe 'viewing a quiz with variable due dates on the quizzes index page' do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

  before(:all) do
    prepare_multiple_due_dates_scenario_for_ta
  end

  context 'with a TA in both sections' do
    before(:each) do
      user_session(@ta1)
      get "/courses/#{@course.id}/quizzes"
    end

    it 'shows the due dates for Section A', priority: "2", test_id: 282168 do
      validate_quiz_dates('.date-due', "Everyone else\n#{format_date_for_view(@due_at_a)}")
    end

    it 'shows the due dates for Section B', priority: "2", test_id: 315651 do
      validate_quiz_dates('.date-due', "#{@section_b.name}\n#{format_date_for_view(@due_at_b)}")
    end

    it 'shows the availability dates for Section A', priority: "2", test_id: 282395 do
      validate_quiz_dates('.date-available', "Everyone else\nAvailable until #{format_date_for_view(@lock_at_a)}")
    end

    it 'shows the availability dates for Section B', priority: "2", test_id: 315653 do
      validate_quiz_dates('.date-available', "#{@section_b.name}\nNot available until #{format_date_for_view(@unlock_at_b)}")
    end
  end
end