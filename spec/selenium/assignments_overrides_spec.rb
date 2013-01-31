require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignment groups" do
  it_should_behave_like "in-process server selenium tests"

  context "as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
    end

    it "should create an assignment with default dates" do
      get "/courses/#{@course.id}/assignments/new"

      replace_content(f('#assignment_name'), 'vdd assignment')
      f('#assignment_toggle_advanced_options').click

      due_at = Time.zone.now + 3.days
      unlock_at = Time.zone.now + 2.days
      lock_at = Time.zone.now + 4.days

      # set due_at, lock_at, unlock_at
      f('.due-date-overrides [name="due_at"]').send_keys(due_at.strftime('%b %-d, %y'))
      f('.due-date-overrides [name="unlock_at"]').send_keys(unlock_at.strftime('%b %-d, %y'))
      f('.due-date-overrides [name="lock_at"]').send_keys(lock_at.strftime('%b %-d, %y'))
      expect_new_page_load { submit_form('#edit_assignment_form') }

      a = Assignment.find_by_title('vdd assignment')
      a.due_at.strftime('%b %-d, %y').should == due_at.to_date.strftime('%b %-d, %y')
      a.unlock_at.strftime('%b %-d, %y').should == unlock_at.to_date.strftime('%b %-d, %y')
      a.lock_at.strftime('%b %-d, %y').should == lock_at.to_date.strftime('%b %-d, %y')
    end

    it "should load existing due data into the form" do
      due_at = Time.zone.now + 3.days
      unlock_at = Time.zone.now + 2.days
      lock_at = Time.zone.now + 4.days

      assign = @course.assignments.create!(:title => "due tomorrow", :due_at => due_at, :unlock_at => unlock_at, :lock_at => lock_at)
      get "/courses/#{@course.id}/assignments/#{assign.id}/edit"

      f('#assignment_toggle_advanced_options').click
      f('.due-date-overrides [name="due_at"]').attribute(:value).should match due_at.strftime('%b %-d')
      f('.due-date-overrides [name="unlock_at"]').attribute(:value).should match unlock_at.strftime('%b %-d')
      f('.due-date-overrides [name="lock_at"]').attribute(:value).should match lock_at.strftime('%b %-d')
    end

    it "should edit a due date" do
      assign = @course.assignments.create!(:title => "due tomorrow", :due_at => Time.zone.now + 2.days)
      get "/courses/#{@course.id}/assignments/#{assign.id}/edit"

      f('#assignment_toggle_advanced_options').click

      due_at = Time.zone.now + 1.days

      # set due_at, lock_at, unlock_at
      f('.due-date-overrides [name="due_at"]').clear
      f('.due-date-overrides [name="due_at"]').send_keys(due_at.strftime('%b %-d, %y'))
      expect_new_page_load { submit_form('#edit_assignment_form') }

      assign.reload.due_at.strftime('%b %-d, %y').should == due_at.to_date.strftime('%b %-d, %y')
    end

    it "should allow setting overrides" do
      default_section = @course.course_sections.first
      other_section = @course.course_sections.create!(:name => "other section")
      default_section_due = Time.zone.now + 1.days
      other_section_due = Time.zone.now + 2.days

      assign = @course.assignments.create!(:title => "due tomorrow")
      get "/courses/#{@course.id}/assignments/#{assign.id}/edit"

      f('#assignment_toggle_advanced_options').click

      click_option('.due-date-row:first select', default_section.name)
      fj('.due-date-row:first [name="due_at"]').send_keys(default_section_due.strftime('%b %-d, %y'))

      f('#add_due_date').click
      wait_for_ajaximations

      click_option('.due-date-row:last select', other_section.name)
      fj('.due-date-row:last [name="due_at"]').send_keys(other_section_due.strftime('%b %-d, %y'))

      expect_new_page_load { submit_form('#edit_assignment_form') }

      overrides = assign.reload.assignment_overrides
      overrides.count.should == 2
      default_override = overrides.detect{ |o| o.set_id == default_section.id }
      default_override.due_at.strftime('%b %-d, %y').should == default_section_due.to_date.strftime('%b %-d, %y')
      other_override = overrides.detect{ |o| o.set_id == other_section.id }
      other_override.due_at.strftime('%b %-d, %y').should == other_section_due.to_date.strftime('%b %-d, %y')
    end
  end
end
