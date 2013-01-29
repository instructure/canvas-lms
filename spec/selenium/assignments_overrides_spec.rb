require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "assignment groups" do
  include AssignmentOverridesSeleniumHelper
  it_should_behave_like "in-process server selenium tests"

  context "as a teacher" do

    let(:due_at) { Time.zone.now + 3.days }
    let(:unlock_at) { Time.zone.now + 2.days }
    let(:lock_at) { Time.zone.now + 4.days }

    before(:each) do
      course_with_teacher_logged_in
    end

    it "should create an assignment with default dates" do
      visit_new_assignment_page
      fill_assignment_title 'vdd assignment'
      toggle_advanced_options
      fill_assignment_overrides
      update_assignment!
      a = Assignment.find_by_title('vdd assignment')
      compare_assignment_times(a)
    end

    it "should load existing due data into the form" do
      assignment = create_assignment!
      visit_assignment_edit_page(assignment)
      toggle_advanced_options

      first_due_at_element.attribute(:value).
        should match due_at.strftime('%b %-d')
      first_unlock_at_element.attribute(:value).
        should match unlock_at.strftime('%b %-d')
      first_lock_at_element.attribute(:value).
        should match lock_at.strftime('%b %-d')
    end

    it "should edit a due date" do
      assignment = create_assignment!
      visit_assignment_edit_page(assignment)
      toggle_advanced_options
      due_at = Time.zone.now + 1.days

      # set due_at, lock_at, unlock_at
      first_due_at_element.clear
      first_due_at_element.send_keys(due_at.strftime('%b %-d, %y'))
      update_assignment!

      assignment.reload.due_at.strftime('%b %-d, %y').
        should == due_at.to_date.strftime('%b %-d, %y')
    end

    it "should allow setting overrides" do
      default_section = @course.course_sections.first
      other_section = @course.course_sections.create!(:name => "other section")
      default_section_due = Time.zone.now + 1.days
      other_section_due = Time.zone.now + 2.days

      assign = create_assignment!
      visit_assignment_edit_page(assign)
      toggle_advanced_options

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
      overrides.count.should == 2
      default_override = overrides.detect{ |o| o.set_id == default_section.id }
      default_override.due_at.strftime('%b %-d, %y').
        should == default_section_due.to_date.strftime('%b %-d, %y')
      other_override = overrides.detect{ |o| o.set_id == other_section.id }
      other_override.due_at.strftime('%b %-d, %y').
        should == other_section_due.to_date.strftime('%b %-d, %y')
    end
  end
end
