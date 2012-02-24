require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments" do
  it_should_behave_like "in-process server selenium tests"

  context "teacher view" do
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should display assignment on calendar and link to assignment" do
      assignment_name = 'first assignment'
      current_date = Time.now.utc
      due_date = current_date + 2.days
      @assignment = @course.assignments.create(:name => assignment_name, :due_at => due_date)

      get "/calendar"

      #click on assignment in calendar
      if due_date.month > current_date.month
        driver.find_element(:css, '#content .next_month_link').click
        wait_for_ajax_requests
      end
      day_id = 'day_' + due_date.year.to_s() + '_' + due_date.strftime('%m') + '_' + due_date.strftime('%d')
      day_div = driver.find_element(:id, day_id)
      sleep 1 # this is one of those cases where if we click too early, no subsequent clicks will work
      day_div.find_element(:link, assignment_name).click
      wait_for_animations
      details_dialog = driver.find_element(:id, 'event_details').find_element(:xpath, '..')
      details_dialog.should include_text(assignment_name)
      details_dialog.find_element(:css, '.edit_event_link').click
      details_dialog = driver.find_element(:id, 'edit_event').find_element(:xpath, '..')
      details_dialog.find_element(:name, 'assignment[title]').should be_displayed
      details_dialog.find_element(:css, '#edit_assignment_form .more_options_link').click
      #make sure user is taken to assignment details
      driver.find_element(:css, 'h2.title').should include_text(assignment_name)
    end

    it "should create an assignment" do
      assignment_name = 'first assignment'
      @course.assignment_groups.create!(:name => "first group")
      @course.assignment_groups.create!(:name => "second group")
      get "/courses/#{@course.id}/assignments"

      #create assignment
      click_option('#right-side select.assignment_groups_select', 'second group')
      driver.find_element(:css, '.add_assignment_link').click
      driver.find_element(:id, 'assignment_title').send_keys(assignment_name)
      driver.find_element(:css, '.ui-datepicker-trigger').click
      datepicker = datepicker_next
      datepicker.find_element(:css, '.ui-datepicker-ok').click
      driver.find_element(:id, 'assignment_points_possible').send_keys('5')
      driver.
          find_element(:id, 'add_assignment_form').submit

      #make sure assignment was added to correct assignment group
      wait_for_animations
      first_group = driver.find_element(:css, '#groups .assignment_group:nth-child(2)')
      first_group.should include_text('second group')
      first_group.should include_text(assignment_name)

      #click on assignment link
      driver.find_element(:link, assignment_name).click
      driver.find_element(:css, 'h2.title').should include_text(assignment_name)
    end

    it "should create an assignment with more options" do
      enable_cache do
        expected_text = "Assignment 1"

        get "/courses/#{@course.id}/assignments"
        group = @course.assignment_groups.first
        AssignmentGroup.update_all({:updated_at => 1.hour.ago}, {:id => group.id})
        first_stamp = group.reload.updated_at.to_i
        driver.find_element(:css, '.add_assignment_link').click
        expect_new_page_load { driver.find_element(:css, '.more_options_link').click }
        expect_new_page_load { driver.find_element(:css, '#edit_assignment_form').submit }
        @course.assignments.count.should == 1
        driver.find_element(:css, '.no_assignments_message').should_not be_displayed
        driver.find_element(:css, '#groups').should include_text(expected_text)
        group.reload
        group.updated_at.to_i.should_not == first_stamp
      end
    end

    it "should allow creating a quiz assignment from 'more options'" do
      skip_if_ie("Out of memory")
      get "/courses/#{@course.id}/assignments"

      driver.find_element(:css, ".assignment_group .add_assignment_link").click
      form = driver.find_element(:css, "#add_assignment_form")
      form.find_element(:css, ".assignment_submission_types option[value='online_quiz']").click
      expect_new_page_load { form.find_element(:css, ".more_options_link").click }

      driver.find_element(:css, ".submission_type_option option[value='none']").should be_selected
      driver.find_element(:css, ".assignment_type option[value='assignment']").click
      driver.find_element(:css, ".submission_type_option option[value='online']").click
      driver.find_element(:css, ".assignment_type option[value='quiz']").click

      expect_new_page_load { driver.find_element(:id, 'edit_assignment_form').submit }
    end

    it "should edit an assignment" do
      skip_if_ie('Out of memory')
      assignment_name = 'first test assignment'
      due_date = Time.now.utc + 2.days
      group = @course.assignment_groups.create!(:name => "default")
      second_group = @course.assignment_groups.create!(:name => "second default")
      @course.assignments.create!(
          :name => assignment_name,
          :due_at => due_date,
          :assignment_group => group,
          :unlock_at => due_date - 1.day
      )

      get "/courses/#{@course.id}/assignments"

      expect_new_page_load { driver.find_element(:link, assignment_name).click }
      driver.find_element(:css, '.edit_full_assignment_link').click
      driver.find_element(:css, '.more_options_link').click
      driver.find_element(:id, 'assignment_assignment_group_id').should be_displayed
      click_option('#assignment_assignment_group_id', second_group.name)
      click_option('#assignment_grading_type', 'Letter Grade')

      #check grading levels dialog
      wait_for_animations
      keep_trying_until { driver.find_element(:css, 'a.edit_letter_grades_link').should be_displayed }
      driver.find_element(:css, 'a.edit_letter_grades_link').click
      wait_for_animations
      driver.find_element(:id, 'edit_letter_grades_form').should be_displayed
      close_visible_dialog

      #check peer reviews option
      driver.find_element(:css, '#edit_assignment_form #assignment_peer_reviews').click
      driver.find_element(:css, '#edit_assignment_form #auto_peer_reviews').click
      driver.find_element(:css, '#edit_assignment_form #assignment_peer_review_count').send_keys('2')
      driver.find_element(:css, '#edit_assignment_form #assignment_peer_reviews_assign_at + img').click
      datepicker = datepicker_next
      datepicker.find_element(:css, '.ui-datepicker-ok').click
      driver.find_element(:id, 'assignment_title').send_keys(' edit')

      #save changes
      driver.find_element(:id, 'edit_assignment_form').submit
      wait_for_ajaximations
      driver.find_elements(:css, '.loading_image_holder').length.should eql 0
      driver.find_element(:css, 'h2.title').should include_text(assignment_name + ' edit')
    end

    it "should show a \"more errors\" errorBox if any invalid fields are hidden" do
      assignment_name = 'first test assignment'
      @group = @course.assignment_groups.create!(:name => "default")
      @assignment = @course.assignments.create(
          :name => assignment_name,
          :assignment_group => @group,
          :points_possible => 2,
          :due_at => Time.now,
          :lock_at => 1.month.ago # this will trigger the client-side validation error
      )

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      driver.find_element(:css, "a.edit_full_assignment_link").click
      driver.find_element(:id, 'edit_assignment_form').submit

      wait_for_animations
      errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
      errorBoxes.size.should eql 2
      errorBoxes.first.should_not be_displayed # .text just gives us an empty string since it's hidden
      errorBoxes.last.text.should eql "There were errors on one or more advanced options"
      errorBoxes.last.should be_displayed

      driver.find_element(:css, 'a.more_options_link').click
      wait_for_animations
      errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
      errorBoxes.size.should eql 1 # the more_options_link one has now been removed from the DOM
      errorBoxes.first.text.should eql "The assignment shouldn't be locked again until after the due date"
      errorBoxes.first.should be_displayed
    end
  end

  context "student view" do
    DUE_DATE = Time.now.utc + 2.days
    before (:each) do
      course_with_student_logged_in
      @assignment = @course.assignments.create(:name => 'assignment', :due_at => DUE_DATE)
    end

    it "should highlight mini-calendar dates where stuff is due" do
      get "/courses/#{@course.id}/assignments/syllabus"

      driver.find_element(:css, ".mini_calendar_day.date_#{DUE_DATE.strftime("%m_%d_%Y")}").
          attribute('class').should match /has_event/
    end

    it "should not show submission data when muted" do
      @assignment.update_attributes(:submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@student)
      @submission.submission_type = "online_url"
      @submission.save!

      @submission.add_comment :author => @teacher, :comment => "comment before muting"
      @assignment.mute!
      @assignment.update_submission(@student, :hidden => true, :comment => "comment after muting")

      outcome_with_rubric
      @rubric.associate_with @assignment, @course, :purpose => "grading"

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      driver.find_element(:css, ".details").text.should =~ /comment before muting/
      driver.find_element(:css, ".details").text.should_not =~ /comment after muting/
    end

    it "should submit an assignment and validate confirmation information" do
      pending "BUG 6783 - Coming Up assignments update error" do
        @assignment.update_attributes(:submission_types => 'online_url')
        @submission = @assignment.submit_homework(@student)
        @submission.submission_type = "online_url"
        @submission.save!

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        driver.find_element(:css, '.details .header').should include_text('Turned In!')
        get "/courses/#{@course.id}"
        driver.execute_script("$('.tooltip_text').css('visibility', 'visible')")
        tooltip_text_elements = driver.find_elements(:css, '.tooltip_text > span')
        driver.find_element(:css, '.tooltip_text').should be_displayed
        tooltip_text_elements[1].text.should == 'submitted'
      end
    end

    it "should not allow blank submissions for text entry" do
      pending('bug #7228 - Dont allow blank submissions in Text Entry field') do
        @assignment.update_attributes(:submission_types => "online_text_entry")
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        driver.find_element(:css, '.submit_assignment_link').click
        assignment_form = driver.find_element(:id, 'submit_online_text_entry_form')
        wait_for_tiny(assignment_form)
        assignment_form.submit
        Submission.count.should == 0
      end
      #TODO - when a fix goes in for this bug, need to finish writing this spec
      #the spec should check that the assignment is not submitted
      #it should also check that there was some sort of error message
    end

    it "should not allow a submission with only comments" do
      pending("bug 7463 - Assignments page shows assignment turned in when only a comment has been made") do
        #Note once this bug is fixed it will also fix bug #7464
        @assignment.update_attributes(:submission_types => "online_text_entry")
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        driver.find_element(:css, '.submit_assignment_link').click
        assignment_form = driver.find_element(:id, 'submit_online_text_entry_form')
        replace_content(assignment_form.find_element(:id, 'submission_comment'), 'this should not be able to be submitted for grading')
        assignment_form.find_element(:css, "#submit_online_text_entry_form button[type=submit]").click
        #TODO - when this bug is fixed we should also check that some error was raised for trying to submit only a comment
        Submission.count.should == 0
      end
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

      find_all_with_jquery('table.formtable input[name="submission[group_comment]"]').size.should eql 3
    end
  end
end
