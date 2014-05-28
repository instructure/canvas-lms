require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments" do
  include_examples "in-process server selenium tests"

  context "as a student" do

    def update_assignment_attributes(assignment, attribute, values, click_submit_link = true)
      assignment.update_attributes(attribute => values)
      get "/courses/#{@course.id}/assignments/#{assignment.id}"
      f('.submit_assignment_link').click if click_submit_link
    end

    def click_away_accept_alert
      f('#section-tabs .home').click
      driver.switch_to.alert.accept # doing this step and the step above to avoid the alert from failing other selenium specs
    end

    before (:each) do
      @due_date = Time.now.utc + 2.days
      course_with_student_logged_in
      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1', :due_at => @due_date)
      @second_assignment = @course.assignments.create!(:title => 'assignment 2', :name => 'assignment 2', :due_at => nil)
      @third_assignment = @course.assignments.create!(:title => 'assignment 3', :name => 'assignment 3', :due_at => nil)
      @fourth_assignment = @course.assignments.create!(:title => 'assignment 4', :name => 'assignment 4', :due_at => @due_date - 1.day)
    end

    it "should not sort undated assignments first and it should order them by title" do
      get "/courses/#{@course.id}/assignments"
      titles = ff('.title')
      titles[2].text.should == @second_assignment.title
      titles[3].text.should == @third_assignment.title
    end

    it "should order upcoming assignments starting with first due" do
      get "/courses/#{@course.id}/assignments"
      titles = ff('.title')
      titles[0].text.should == @fourth_assignment.title
      titles[1].text.should == @assignment.title
    end

    it "should expand the comments box on click" do
      @assignment = @course.assignments.create!(
          :name => 'test assignment',
          :due_at => Time.now.utc + 2.days,
          :submission_types => 'online_upload')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.submit_assignment_link').click
      wait_for_ajaximations
      driver.execute_script("return $('#submission_comment').height()").should == 20
      driver.execute_script("$('#submission_comment').focus()")
      wait_for_ajaximations
      driver.execute_script("return $('#submission_comment').height()").should == 72

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "should highlight mini-calendar dates where stuff is due" do
      get "/courses/#{@course.id}/assignments/syllabus"
      wait_for_ajaximations
      f(".mini_calendar_day.date_#{@due_date.strftime("%m_%d_%Y")}").should have_class('has_event')
    end

    it "should not show submission data when muted" do
      @assignment.update_attributes(:submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@student)
      @submission.submission_type = "online_url"
      @submission.save!

      @submission.add_comment(:author => @teacher, :comment => "comment before muting")
      @assignment.mute!
      @assignment.update_submission(@student, :hidden => true, :comment => "comment after muting")

      outcome_with_rubric
      @rubric.associate_with(@assignment, @course, :purpose => "grading")

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      details = f(".details")
      details.should include_text('comment before muting')
      details.should_not include_text('comment after muting')
    end

    it "should have group comment checkboxes for group assignments" do
      @u1 = @user
      student_in_course(:course => @course)
      @u2 = @user
      @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload,online_text_entry", :group_category => GroupCategory.create!(:name => "groups", :context => @course), :grade_group_students_individually => true)
      @group = @assignment.group_category.groups.create!(:name => 'g1', :context => @course)
      @group.users << @u1
      @group.users << @user

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      ffj('.formtable input[name="submission[group_comment]"]').size.should == 3
    end

    it "should not show assignments in an unpublished course" do
      new_course = Course.create!(:name => 'unpublished course')
      assignment = new_course.assignments.create!(:title => "some assignment")
      new_course.enroll_user(@user, 'StudentEnrollment')
      get "/courses/#{new_course.id}/assignments/#{assignment.id}"

      f('.ui-state-error').should be_displayed
      f('#assignment_show').should be_nil
    end

    it "should verify student creatable group creation" do
      new_group_name = 'student created group'
      get "/courses/#{@course.id}/groups"

      f('.add_group_link').click
      wait_for_ajaximations
      f('#group_name').send_keys(new_group_name)
      submit_form('#add_group_form')
      wait_for_ajaximations
      f('.group_list').should include_text(new_group_name)
      Group.find_by_name(new_group_name).should be_present
    end

    it "should verify lock until date is enforced" do
      assignment_name = 'locked assignment'
      unlock_time = 1.day.from_now
      locked_assignment = @course.assignments.create!(:name => assignment_name, :unlock_at => unlock_time)

      get "/courses/#{@course.id}/assignments/#{locked_assignment.id}"
      f('#content').should include_text(unlock_time.strftime("%b %-d"))
      locked_assignment.update_attributes(:unlock_at => Time.now)
      refresh_page # to show the updated assignment
      f('#content').should_not include_text('This assignment is locked until')
    end

    it "should verify due date is enforced" do
      due_date_assignment = @course.assignments.create!(:name => 'due date assignment', :due_at => 5.days.ago)
      driver.current_url
      get "/courses/#{@course.id}/assignments"
      ffj('.assignment_list:visible').last.should include_text(due_date_assignment.title)
      due_date_assignment.update_attributes(:due_at => 2.days.from_now)
      refresh_page # to show the updated assignment
      ffj('.assignment_list:visible').first.should include_text(due_date_assignment.title)
    end

    it "should validate an assignment created with the type of discussion" do
      @fourth_assignment.update_attributes(:submission_types => 'discussion_topic')
      get "/courses/#{@course.id}/assignments/#{@fourth_assignment.id}"

      driver.current_url.should match %r{/courses/\d+/discussion_topics/\d+}
      f('h1.discussion-title').should include_text(@fourth_assignment.title)
    end

    it "should validate an assignment created with the type of external tool" do
      t1 = factory_with_protected_attributes(@course.context_external_tools, :url => "http://www.example.com/", :shared_secret => 'test123', :consumer_key => 'test123', :name => 'tool 1')
      external_tool_assignment = assignment_model(:course => @course, :title => "test2", :submission_types => 'external_tool')
      external_tool_assignment.create_external_tool_tag(:url => t1.url)
      external_tool_assignment.external_tool_tag.update_attribute(:content_type, 'ContextExternalTool')
      get "/courses/#{@course.id}/assignments/#{external_tool_assignment.id}"

      f('#tool_content').should be_displayed
    end

    it "should validate an assignment created with the type of not graded" do
      @fourth_assignment.update_attributes(:submission_types => 'not_graded')
      get "/courses/#{@course.id}/assignments/#{@fourth_assignment.id}"

      f('.submit_assignment_link').should be_nil
    end

    it "should validate on paper submission assignment type" do
      update_assignment_attributes(@fourth_assignment, :submission_types, 'on_paper', false)
      f('.submit_assignment_link').should be_nil
    end

    it "should validate no submission assignment type" do
      update_assignment_attributes(@fourth_assignment, :submission_types, nil, false)
      f('.submit_assignment_link').should be_nil
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
        f('#content').should include_text "locked until #{expected_unlock}."
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

      it "should validate file upload restrictions" do
        filename_txt, fullpath_txt, data_txt, tempfile_txt = get_file("testfile4.txt")
        filename_zip, fullpath_zip, data_zip, tempfile_zip = get_file("testfile5.zip")
        @fourth_assignment.update_attributes(:submission_types => 'online_upload', :allowed_extensions => '.txt')
        get "/courses/#{@course.id}/assignments/#{@fourth_assignment.id}"
        f('.submit_assignment_link').click

        submit_file_button = f('#submit_file_button')
        submission_input = f('.submission_attachment input')
        ext_error = f('.bad_ext_msg')

        keep_trying_until do
        submission_input.send_keys(fullpath_txt)
        ext_error.should_not be_displayed
        submit_file_button['disabled'].should be_nil
        submission_input.send_keys(fullpath_zip)
        ext_error.should be_displayed
        submit_file_button.should have_attribute(:disabled, "true")
        end
      end

      it "should validate that website url submissions are allowed" do
        update_assignment_attributes(@fourth_assignment, :submission_types, 'online_url')
        f('#submission_url').should be_displayed
      end

      it "should validate that text entry submissions are allowed" do
        update_assignment_attributes(@fourth_assignment, :submission_types, 'online_text_entry')
        f('.submit_online_text_entry_option').should be_displayed
      end

      it "should allow an assignment with all 3 online submission types" do
        update_assignment_attributes(@fourth_assignment, :submission_types, 'online_text_entry, online_url, online_upload')
        f('.submit_online_text_entry_option').should be_displayed
        f('.submit_online_url_option').should be_displayed
        f('.submit_online_upload_option').should be_displayed
      end
    end

    context "draft state" do
      before do
        Account.default.enable_feature!(:draft_state)
        @domain_root_account = Account.default

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
      end

      it "should list the assignments" do
        ag = @course.assignment_groups.first
        f("#show_by_type").click
        ag_el = f("#assignment_group_#{ag.id}")
        ag_el.should be_present
        ag_el.text.should match @assignment.name
      end

      it "should not show add/edit/delete buttons" do
        ag = @course.assignment_groups.first
        f('.new_assignment').should be_nil
        f('#addGroup').should be_nil
        f('.add_assignment').should be_nil
        f("#show_by_type").click
        f("ag_#{ag.id}_manage_link").should be_nil
      end

      it "should default to grouping by date" do
        is_checked('#show_by_date').should be_true

        # assuming two undated and two future assignments created above
        f('#assignment_group_upcoming').should_not be_nil
        f('#assignment_group_undated').should_not be_nil
      end

      it "should allowing grouping by assignment group (and remember)" do
        ag = @course.assignment_groups.first
        f("#show_by_type").click
        is_checked('#show_by_type').should be_true
        f("#assignment_group_#{ag.id}").should_not be_nil

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        is_checked('#show_by_type').should be_true
      end

      it "should not show empty date groups" do
        # assuming two undated and two future assignments created above
        f('#assignment_group_overdue').should be_nil
        f('#assignment_group_past').should be_nil
      end

      it "should not show empty assignment groups" do
        empty_ag = @course.assignment_groups.create!(:name => "Empty")

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        f("#show_by_type").click
        f("#assignment_group_#{empty_ag.id}").should be_nil
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
        f("#assignment_group_#{empty_ag.id}").should_not be_nil
      end

      it "should correctly categorize assignments be date" do
        # assuming two undated and two future assignments created above
        undated, upcoming = @course.assignments.partition{ |a| a.due_date.nil? }

        undated.each do |a|
          f("#assignment_group_undated #assignment_#{a.id}").should_not be_nil
        end

        upcoming.each do |a|
          f("#assignment_group_upcoming #assignment_#{a.id}").should_not be_nil
        end
      end
    end
  end

  context "as observer" do
    before :each do
      @course   = course(:active_all => true)
      @student  = user(:active_all => true, :active_state => 'active')
      @observer = user(:active_all => true, :active_state => 'active')
      user_session(@observer)

      @due_date = Time.now.utc + 12.days
      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1', :due_at => @due_date)

      setup_sections_and_overrides_all_future
    end

    context "when not linked to student" do
      before :each do
        @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active')
      end

      it "should see own section's lock dates" do
        extend TextHelper
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
        expected_lock_at = datetime_string(@override.lock_at).gsub(/\s+/, ' ')
        f('#content').should include_text "locked until #{expected_unlock}."
      end

      context "with multiple section enrollments in same course" do
        it "should have the earliest 'lock until' date and the latest 'lock after' date" do
          @assignment.update_attributes :lock_at => @lock_at + 22.days
          @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section1, :enrollment_state => 'active')
          extend TextHelper
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
          expected_lock_at = datetime_string(@assignment.lock_at).gsub(/\s+/, ' ')   # later than section2
          f('#content').should include_text "locked until #{expected_unlock}."
        end
      end
    end

    context "when linked to student" do
      before :each do
        @student_enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :section => @section2)
        @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :section => @section2)
        @observer_enrollment.update_attribute(:associated_user_id, @student.id)
      end

      it "should return student's lock dates" do
        extend TextHelper
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
        expected_lock_at = datetime_string(@override.lock_at).gsub(/\s+/, ' ')
        f('#content').should include_text "locked until #{expected_unlock}."
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
          f('#content').should include_text "locked until #{expected_unlock}."
        end
      end
    end
  end
end

def setup_sections_and_overrides_all_future
  # All in the future by default
  @unlock_at = Time.now.utc + 6.days
  @due_at    = Time.now.utc + 10.days
  @lock_at   = Time.now.utc + 11.days

  @assignment.due_at    = @due_at
  @assignment.unlock_at = @unlock_at
  @assignment.lock_at   = @lock_at
  @assignment.save!
  # 2 course sections, student in second section.
  @section1 = @course.course_sections.create!(:name => 'Section A')
  @section2 = @course.course_sections.create!(:name => 'Section B')
  @course.student_enrollments.scoped.delete_all  # get rid of existing student enrollments, mess up section enrollment
  # Overridden lock dates for 2nd section - different dates, but still in future
  @override = assignment_override_model(:assignment => @assignment, :set => @section2,
                                        :lock_at => @lock_at + 12.days,
                                        :unlock_at => Time.now.utc + 3.days)
end
