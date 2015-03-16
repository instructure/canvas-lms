require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')

describe "assignments" do
  include_examples "in-process server selenium tests"

  context "as a student" do

    before (:each) do
      course_with_student_logged_in
    end

    before do
      @due_date = Time.now.utc + 2.days
      @assignment = @course.assignments.create!(:title => 'default assignment', :name => 'default assignment', :due_at => @due_date)
    end

    it "should order undated assignments by title and dated assignments by first due" do
      @second_assignment = @course.assignments.create!(:title => 'assignment 2', :name => 'assignment 2', :due_at => nil)
      @third_assignment = @course.assignments.create!(:title => 'assignment 3', :name => 'assignment 3', :due_at => nil)
      @fourth_assignment = @course.assignments.create!(:title => 'assignment 4', :name => 'assignment 4', :due_at => @due_date - 1.day)

      get "/courses/#{@course.id}/assignments"
      titles = ff('.ig-title')
      expect(titles[0].text).to eq @fourth_assignment.title
      expect(titles[1].text).to eq @assignment.title
      expect(titles[2].text).to eq @second_assignment.title
      expect(titles[3].text).to eq @third_assignment.title
    end

    it "should highlight mini-calendar dates where stuff is due" do
      @course.assignments.create!(:title => 'test assignment', :name => 'test assignment', :due_at => @due_date)

      get "/courses/#{@course.id}/assignments/syllabus"
      wait_for_ajaximations
      expect(f(".mini_calendar_day.date_#{@due_date.strftime("%m_%d_%Y")}")).to have_class('has_event')
    end

    it "should not show submission data when muted" do
      assignment = @course.assignments.create!(:title => 'test assignment', :name => 'test assignment')

      assignment.update_attributes(:submission_types => "online_url,online_upload")
      submission = assignment.submit_homework(@student)
      submission.submission_type = "online_url"
      submission.save!

      submission.add_comment(:author => @teacher, :comment => "comment before muting")
      assignment.mute!
      assignment.update_submission(@student, :hidden => true, :comment => "comment after muting")

      outcome_with_rubric
      @rubric.associate_with(assignment, @course, :purpose => "grading")

      get "/courses/#{@course.id}/assignments/#{assignment.id}"
      details = f(".details")
      expect(details).to include_text('comment before muting')
      expect(details).not_to include_text('comment after muting')
    end

    it "should have group comment checkboxes for group assignments" do
      u1 = @user
      student_in_course(:course => @course)
      u2 = @user
      assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload,online_text_entry", :group_category => GroupCategory.create!(:name => "groups", :context => @course), :grade_group_students_individually => true)
      group = assignment.group_category.groups.create!(:name => 'g1', :context => @course)
      group.users << u1
      group.users << @user

      get "/courses/#{@course.id}/assignments/#{assignment.id}"

      acceptable_tabs = ffj('#submit_online_upload_form,#submit_online_text_entry_form,#submit_online_url_form')
      expect(acceptable_tabs.size).to be 3
      acceptable_tabs.each { |tabby| expect(ffj('.formtable input[name="submission[group_comment]"]', tabby).size).to be 1 }
    end

    it "should not show assignments in an unpublished course" do
      new_course = Course.create!(:name => 'unpublished course')
      assignment = new_course.assignments.create!(:title => "some assignment")
      new_course.enroll_user(@user, 'StudentEnrollment')
      get "/courses/#{new_course.id}/assignments/#{assignment.id}"

      expect(f('.ui-state-error')).to be_displayed
      expect(f('#assignment_show')).to be_nil
    end

    it "should verify lock until date is enforced" do
      assignment_name = 'locked assignment'
      unlock_time = 1.day.from_now
      locked_assignment = @course.assignments.create!(:name => assignment_name, :unlock_at => unlock_time)

      get "/courses/#{@course.id}/assignments/#{locked_assignment.id}"
      expect(f('#content')).to include_text(unlock_time.strftime("%b %-d"))
      locked_assignment.update_attributes(:unlock_at => Time.now)
      refresh_page # to show the updated assignment
      expect(f('#content')).not_to include_text('This assignment is locked until')
    end

    it "should verify due date is enforced" do
      due_date_assignment = @course.assignments.create!(:name => 'due date assignment', :due_at => 5.days.ago)
      driver.current_url
      get "/courses/#{@course.id}/assignments"
      expect(f("#assignment_group_past #assignment_#{due_date_assignment.id}")).to be_displayed
      due_date_assignment.update_attributes(:due_at => 2.days.from_now)
      refresh_page # to show the updated assignment
      expect(f("#assignment_group_upcoming #assignment_#{due_date_assignment.id}")).to be_displayed
    end

    context "overridden lock_at" do
      before :each do
        setup_sections_and_overrides_all_future
        @course.enroll_user(@student, 'StudentEnrollment', :section => @section2, :enrollment_state => 'active')
      end

      it "should show overridden lock dates for student" do
        extend TextHelper
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
        expected_lock_at = datetime_string(@override.lock_at).gsub(/\s+/, ' ')
        expect(f('#content')).to include_text "locked until #{expected_unlock}."
      end

      it "should allow submission when within override locks" do
        @assignment.update_attributes(:submission_types => 'online_text_entry')
        # Change unlock dates to be valid for submission
        @override.unlock_at = Time.now.utc - 1.days   # available now
        @override.save!

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.submit_assignment_link').click
        wait_for_ajaximations
        assignment_form = f('#submit_online_text_entry_form')
        wait_for_tiny(assignment_form)
        wait_for_ajaximations
        expect {
          type_in_tiny('#submission_body', 'something to submit')
          wait_for_ajaximations
          submit_form(assignment_form)
          wait_for_ajaximations
        }.to change(Submission, :count).by(1)
      end
    end

    context "click_away_accept_alert" do #this context exits to handle the click_away_accept_alert method call after each spec that needs it even if it fails early to prevent other specs from failing
      after(:each) do
        click_away_accept_alert
      end

      it "should expand the comments box on click" do
        @assignment.update_attributes(:submission_types => 'online_upload')

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f('.submit_assignment_link').click
        wait_for_ajaximations
        expect(driver.execute_script("return $('#submission_comment').height()")).to eq 20
        driver.execute_script("$('#submission_comment').focus()")
        wait_for_ajaximations
        expect(driver.execute_script("return $('#submission_comment').height()")).to eq 72
      end

      it "should validate file upload restrictions" do
        filename_txt, fullpath_txt, data_txt, tempfile_txt = get_file("testfile4.txt")
        filename_zip, fullpath_zip, data_zip, tempfile_zip = get_file("testfile5.zip")
        @assignment.update_attributes(:submission_types => 'online_upload', :allowed_extensions => '.txt')
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.submit_assignment_link').click

        submit_file_button = f('#submit_file_button')
        submission_input = f('.submission_attachment input')
        ext_error = f('.bad_ext_msg')

        keep_trying_until do
          submission_input.send_keys(fullpath_txt)
          expect(ext_error).not_to be_displayed
          expect(submit_file_button['disabled']).to be_nil
          submission_input.send_keys(fullpath_zip)
          expect(ext_error).to be_displayed
          expect(submit_file_button).to have_attribute(:disabled, "true")
        end
      end
    end

    it "should list the assignments" do
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      f("#show_by_type").click
      ag_el = f("#assignment_group_#{ag.id}")
      expect(ag_el).to be_present
      expect(ag_el.text).to match @assignment.name
    end

    it "should not show add/edit/delete buttons" do
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      expect(f('.new_assignment')).to be_nil
      expect(f('#addGroup')).to be_nil
      expect(f('.add_assignment')).to be_nil
      f("#show_by_type").click
      expect(f("ag_#{ag.id}_manage_link")).to be_nil
    end

    it "should default to grouping by date" do
      @course.assignments.create!(:title => 'undated assignment', :name => 'undated assignment')

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      expect(is_checked('#show_by_date')).to be_truthy

      # assuming two undated and two future assignments created above
      expect(f('#assignment_group_upcoming')).not_to be_nil
      expect(f('#assignment_group_undated')).not_to be_nil
    end

    it "should allowing grouping by assignment group (and remember)" do
      ag = @course.assignment_groups.first

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      f("#show_by_type").click
      expect(is_checked('#show_by_type')).to be_truthy
      expect(f("#assignment_group_#{ag.id}")).not_to be_nil

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      expect(is_checked('#show_by_type')).to be_truthy
    end

    it "should not show empty groups" do
      # assuming two undated and two future assignments created above
      empty_ag = @course.assignment_groups.create!(:name => "Empty")

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      expect(f('#assignment_group_overdue')).to be_nil
      expect(f('#assignment_group_past')).to be_nil

      f("#show_by_type").click
      expect(f("#assignment_group_#{empty_ag.id}")).to be_nil
    end

    it "should show empty assignment groups if they have a weight" do
      @course.group_weighting_scheme = "percent"
      @course.save!

      ag = @course.assignment_groups.first
      ag.group_weight = 90
      ag.save!

      empty_ag = @course.assignment_groups.create!(:name => "Empty", :group_weight => 10)

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      f("#show_by_type").click
      expect(f("#assignment_group_#{empty_ag.id}")).not_to be_nil
    end

    it "should correctly categorize assignments by date" do
      # assuming two undated and two future assignments created above
      undated, upcoming = @course.assignments.partition{ |a| a.due_date.nil? }

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      undated.each do |a|
        expect(f("#assignment_group_undated #assignment_#{a.id}")).not_to be_nil
      end

      upcoming.each do |a|
        expect(f("#assignment_group_upcoming #assignment_#{a.id}")).not_to be_nil
      end
    end
  end
end
