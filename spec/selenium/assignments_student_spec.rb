require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments" do
  it_should_behave_like "in-process server selenium tests"

  context "as a student" do
    DUE_DATE = Time.now.utc + 2.days

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
      course_with_student_logged_in
      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1', :due_at => DUE_DATE)
      @second_assignment = @course.assignments.create!(:title => 'assignment 2', :name => 'assignment 2', :due_at => nil)
      @third_assignment = @course.assignments.create!(:title => 'assignment 3', :name => 'assignment 3', :due_at => nil)
      @fourth_assignment = @course.assignments.create!(:title => 'assignment 4', :name => 'assignment 4', :due_at => DUE_DATE - 1.day)
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
      driver.execute_script("return $('#submission_comment').height()").should == 14
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

      f(".mini_calendar_day.date_#{DUE_DATE.strftime("%m_%d_%Y")}").should have_class('has_event')
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
      f('#full_assignment_holder').should be_nil
    end

    it "should verify student creatable group creation" do
      new_group_name = 'student created group'
      get "/courses/#{@course.id}/groups"

      f('.add_group_link').click
      wait_for_animations
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
      t1 = factory_with_protected_attributes(@course.context_external_tools, :url => "http://www.example.com/tool1", :shared_secret => 'test123', :consumer_key => 'test123', :name => 'tool 1')
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

    context "click_away_accept_alert" do #this context exits to handle the click_away_accept_alert method call after each spec that needs it even if it fails early to prevent other specs from failing
      after(:each) do
        click_away_accept_alert
      end

      it "should validate file upload restrictions" do
        filename_txt, fullpath_txt, data_txt = get_file("testfile4.txt")
        filename_zip, fullpath_zip, data_zip = get_file("testfile5.zip")
        @fourth_assignment.update_attributes(:submission_types => 'online_upload', :allowed_extensions => '.txt')
        get "/courses/#{@course.id}/assignments/#{@fourth_assignment.id}"
        f('.submit_assignment_link').click

        submit_file_button = f('#submit_file_button')
        submission_input = f('.submission_attachment input')
        ext_error = f('.bad_ext_msg')

        keep_trying_until do
        submission_input.send_keys(fullpath_txt)
        ext_error.should_not be_displayed
        submit_file_button.should_not have_class('disabled')
        submission_input.send_keys(fullpath_zip)
        ext_error.should be_displayed
        submit_file_button.should have_class('disabled')
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
  end
end
