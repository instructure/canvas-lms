require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "assignment groups" do
  include AssignmentOverridesSeleniumHelper
  include_examples "in-process server selenium tests"

  context "as a teacher" do

    let(:due_at) { Time.zone.now + 3.days}
    let(:unlock_at) { Time.zone.now + 1.day}
    let(:lock_at) { Time.zone.now + 5.days }

    before(:each) do
      make_full_screen
      course_with_teacher_logged_in
    end

    it "should create an assignment with default dates" do
      visit_new_assignment_page
      fill_assignment_title 'vdd assignment'
      fill_assignment_overrides
      click_option('#assignment_submission_type', 'No Submission')
      update_assignment!
      a = Assignment.find_by_title('vdd assignment')
      compare_assignment_times(a)
    end

    it "should load existing due data into the form" do
      assignment = create_assignment!
      visit_assignment_edit_page(assignment)

      expect(first_due_at_element.attribute(:value)).
        to match due_at.strftime('%b %-d')
      expect(first_unlock_at_element.attribute(:value)).
        to match unlock_at.strftime('%b %-d')
      expect(first_lock_at_element.attribute(:value)).
        to match lock_at.strftime('%b %-d')
    end

    it "should edit a due date" do
      assignment = create_assignment!
      visit_assignment_edit_page(assignment)

      # set due_at, lock_at, unlock_at
      first_due_at_element.clear
      first_due_at_element.send_keys(due_at.strftime('%b %-d, %y'))
      update_assignment!

      expect(assignment.reload.due_at.strftime('%b %-d, %y')).
        to eq due_at.to_date.strftime('%b %-d, %y')
    end

    it "should clear a due date" do
      assign = @course.assignments.create!(:title => "due tomorrow", :due_at => Time.zone.now + 2.days)
      get "/courses/#{@course.id}/assignments/#{assign.id}/edit"

      f('.due-date-overrides [name="due_at"]').clear
      expect_new_page_load { submit_form('#edit_assignment_form') }

      expect(assign.reload.due_at).to be_nil
    end

    it "should allow setting overrides" do
      default_section = @course.course_sections.first
      other_section = @course.course_sections.create!(:name => "other section")
      default_section_due = Time.zone.now + 2.days
      other_section_due = Time.zone.now + 3.days

      assign = create_assignment!
      visit_assignment_edit_page(assign)

      wait_for_ajaximations
      click_option('.due-date-row:first select', default_section.name)
      first_due_at_element.clear
      first_due_at_element.
      send_keys(default_section_due.strftime('%b %-d, %y'))

      add_override

      select_last_override_section(other_section.name)
      last_due_at_element.
        send_keys(other_section_due.strftime('%b %-d, %y'))

      update_assignment!
      overrides = assign.reload.assignment_overrides
      expect(overrides.count).to eq 2
      default_override = overrides.detect{ |o| o.set_id == default_section.id }
      expect(default_override.due_at.strftime('%b %-d, %y')).
        to eq default_section_due.to_date.strftime('%b %-d, %y')
      other_override = overrides.detect{ |o| o.set_id == other_section.id }
      expect(other_override.due_at.strftime('%b %-d, %y')).
        to eq other_section_due.to_date.strftime('%b %-d, %y')
    end

    it "should show a vdd tooltip summary on the course assignments page" do
      assignment = create_assignment!
      get "/courses/#{@course.id}/assignments"
      expect(f('.assignment_list .assignment_due')).not_to include_text "Multiple Due Dates"
      add_due_date_override(assignment)

      get "/courses/#{@course.id}/assignments"
      expect(f('.assignment_list .assignment_due')).to include_text "Multiple Due Dates"
      driver.mouse.move_to f(".assignment_list .assignment_due a")
      wait_for_ajaximations

      tooltip = fj('.vdd_tooltip_content:visible')
      expect(tooltip).to include_text 'New Section'
      expect(tooltip).to include_text 'Everyone else'
    end
  end
end
