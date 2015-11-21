require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe 'quizzes with draft state' do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

  before(:each) do
    course_with_teacher_logged_in
    @course.update_attributes(name: 'teacher course')
    @course.save!
    @course.reload
    create_quiz_with_due_date
  end

  context 'when there is a single due date' do
    it 'doesn\'t display "Multiple Dates"' do
      get "/courses/#{@course.id}/quizzes"
      expect(f('.ig-details .date-due')).not_to include_text 'Multiple Dates'
      expect(f('.ig-details .date-available')).not_to include_text 'Multiple Dates'
    end
  end

  context 'when there are multiple due dates' do
    before(:each) { add_due_date_override(@quiz) }

    it 'shows a due date summary', priority: "2", test_id: 210053 do
      # verify page
      get "/courses/#{@course.id}/quizzes"
      expect(f('.ig-details .date-due')).to include_text 'Multiple Dates'
      expect(f('.ig-details .date-available')).to include_text 'Multiple Dates'

      # verify tooltips
      driver.mouse.move_to f('.ig-details .date-available a')
      wait_for_ajaximations
      tooltip = fj('.ui-tooltip:visible')
      expect(tooltip).to include_text 'New Section'
      expect(tooltip).to include_text 'Everyone else'

      driver.mouse.move_to f('.ig-details .date-due a')
      wait_for_ajaximations
      tooltip = fj('.ui-tooltip:visible')
      expect(tooltip).to include_text 'New Section'
      expect(tooltip).to include_text 'Everyone else'
    end
  end
end