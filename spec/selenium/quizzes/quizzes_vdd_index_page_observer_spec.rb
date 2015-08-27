require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignment_overrides')

describe 'viewing a quiz with variable due dates on the quizzes index page' do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

  context 'as an observer linked to two students in different sections' do
    before(:all) { prepare_vdd_scenario_for_first_observer }

    before(:each) do
      skip('Entire spec context is buggy. Bug tickets created: CNVS-22794 and CNVS-22793')
      user_session(@observer1)
      get "/courses/#{@course.id}/quizzes"
    end

    it 'shows the due dates for Section A', priority: "2", test_id: 282169 do
      skip('Bug ticket created: CNVS-22794')
      validate_quiz_dates('.date-due', "Everyone else\n#{format_date_for_view(@due_at_a)}")
    end

    it 'shows the due dates for Section B', priority: "2", test_id: 315666 do
      skip('Bug ticket created: CNVS-22794')
      validate_quiz_dates('.date-due', "#{@section_b.name}\n#{format_date_for_view(@due_at_b)}")
    end

    it 'shows the availability dates for Section A', priority: "2", test_id: 282397 do
      skip('Bug ticket created: CNVS-22793')
      validate_quiz_dates('.date-available', "Everyone else\nAvailable until #{format_date_for_view(@lock_at_a)}")
    end

    it 'shows the availability dates for Section B', priority: "2", test_id: 315669 do
      skip('Bug ticket created: CNVS-22793')
      validate_quiz_dates('.date-available', "#{@section_b.name}\nNot available until #{format_date_for_view(@unlock_at_b)}")
    end
  end

  context 'as an observer linked to a single student' do
    before(:all) { prepare_vdd_scenario_for_second_observer }

    before(:each) do
      user_session(@observer2)
      get "/courses/#{@course.id}/quizzes"
    end

    it 'shows the due dates for Section B', priority: "2", test_id: 282170 do
      expect(f('.date-due')).to include_text("Due #{format_time_for_view(@due_at_b)}")
    end

    it 'shows the availability dates for Section B', priority: "2", test_id: 282399 do
      expect(f('.date-available')).to include_text("Not available until #{format_date_for_view(@unlock_at_b)}")
    end
  end
end