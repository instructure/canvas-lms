require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments" do
  it_should_behave_like "in-process server selenium tests"

  context "as a teacher" do

    def manually_create_assignment(assignment_title = 'new assignment')
      get "/courses/#{@course.id}/assignments"
      f('.add_assignment_link').click
      replace_content(f('#assignment_title'), assignment_title)
      expect_new_page_load { f('.more_options_link').click }
    end

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
        f('#content .next_month_link').click
        wait_for_ajax_requests
      end
      day_id = '#day_' + due_date.year.to_s() + '_' + due_date.strftime('%m') + '_' + due_date.strftime('%d')
      day_div = f(day_id)
      sleep 1 # this is one of those cases where if we click too early, no subsequent clicks will work
      day_div.find_element(:link, assignment_name).click
      wait_for_animations
      details_dialog = f('#event_details').find_element(:xpath, '..')
      details_dialog.should include_text(assignment_name)
      details_dialog.find_element(:css, '.edit_event_link').click
      details_dialog = f('#edit_event').find_element(:xpath, '..')
      details_dialog.find_element(:name, 'assignment[title]').should be_displayed
      details_dialog.find_element(:css, '#edit_assignment_form .more_options_link').click
      #make sure user is taken to assignment details
      f('h2.title').should include_text(assignment_name)
    end

    it "should create an assignment" do
      assignment_name = 'first assignment'
      @course.assignment_groups.create!(:name => "first group")
      @course.assignment_groups.create!(:name => "second group")
      get "/courses/#{@course.id}/assignments"

      #create assignment
      click_option('#right-side select.assignment_groups_select', 'second group')
      f('.add_assignment_link').click
      f('#assignment_title').send_keys(assignment_name)
      f('.ui-datepicker-trigger').click
      datepicker = datepicker_next
      datepicker.find_element(:css, '.ui-datepicker-ok').click
      f('#assignment_points_possible').send_keys('5')
      submit_form('#add_assignment_form')

      #make sure assignment was added to correct assignment group
      wait_for_animations
      first_group = f('#groups .assignment_group:nth-child(2)')
      first_group.should include_text('second group')
      first_group.should include_text(assignment_name)

      #click on assignment link
      f("#assignment_#{Assignment.last.id} .title").click
      f('h2.title').should include_text(assignment_name)
    end

    %w(points percent pass_fail letter_grade).each do |grading_option|
      it "should create assignment with #{grading_option} grading option" do
        assignment_title = 'grading options assignment'
        manually_create_assignment(assignment_title)
        click_option('#assignment_grading_type', grading_option, :value)
        expect_new_page_load { submit_form('#edit_assignment_form') }
        f('.assignment_list').should include_text(assignment_title)
        Assignment.find_by_title(assignment_title).grading_type.should == grading_option
      end
    end

    %w(discussion_topic quiz external_tool not_graded).each do |assignment_type|
      it "should create an assignment with the type of #{assignment_type}" do
        assignment_title = 'assignment type assignment'
        lti_url = 'http://www.example.com/ims/lti'
        manually_create_assignment(assignment_title)
        click_option('.assignment_type', assignment_type, :value)
        if assignment_type != 'external_tool'
          expect_new_page_load { submit_form('#edit_assignment_form') }
        else
          f('#external_tool_create_url').send_keys(lti_url)
          submit_dialog('#select_context_content_dialog', '.add_item_button')
          expect_new_page_load { submit_form('#edit_assignment_form') }
        end
        f('.assignment_list').should include_text(assignment_title)
        assignment = Assignment.find_by_title(assignment_title)
        assignment_type == 'quiz' ? assignment.submission_types.should == 'online_quiz' : assignment.submission_types.should == assignment_type
      end
    end

    it "should validate lock submits after functionality" do
      middle_number = '15'
      expected_date = (Time.now - 1.month).strftime("%b #{middle_number}")
      manually_create_assignment
      f('.submission_content .ui-datepicker-trigger').click
      f('.ui-datepicker-prev').click
      fj("#ui-datepicker-div a:contains(#{middle_number})").click
      expect_new_page_load { submit_form('#edit_assignment_form') }
      assignment = Assignment.find_by_title('new assignment')
      expect_new_page_load { f("#assignment_#{assignment.id} .title").click }
      f('.lock_date').should include_text(expected_date)
      assignment.lock_at.strftime('%b %d').should == expected_date
    end

    it "should create an assignment with more options" do
      enable_cache do
        expected_text = "Assignment 1"

        get "/courses/#{@course.id}/assignments"
        group = @course.assignment_groups.first
        AssignmentGroup.update_all({:updated_at => 1.hour.ago}, {:id => group.id})
        first_stamp = group.reload.updated_at.to_i
        f('.add_assignment_link').click
        expect_new_page_load { f('.more_options_link').click }
        expect_new_page_load { submit_form('#edit_assignment_form') }
        @course.assignments.count.should == 1
        f('.no_assignments_message').should_not be_displayed
        f('#groups').should include_text(expected_text)
        group.reload
        group.updated_at.to_i.should_not == first_stamp
      end
    end

    it "should verify that self sign-up link works in more options" do
      get "/courses/#{@course.id}/assignments"
      f('.add_assignment_link').click
      expect_new_page_load { f('.more_options_link').click }
      f('#assignment_group_assignment').click
      click_option('#assignment_group_category_select', 'new', :value)
      fj('.ui-dialog:visible .self_signup_help_link img').click
      f('#self_signup_help_dialog').should be_displayed
    end

    it "should remove student group option" do
      assignment_name = 'first test assignment'
      due_date = Time.now.utc + 2.days
      group = @course.assignment_groups.create!(:name => "default")
      @course.assignments.create!(
          :name => assignment_name,
          :due_at => due_date,
          :assignment_group => group,
          :unlock_at => due_date - 1.day
      )
      @assignment = @course.assignments.last
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load { f("#assignment_#{@assignment.id} .title").click }
      f('.edit_full_assignment_link').click
      f('.more_options_link').click
      f('#assignment_group_assignment').click
      click_option('#assignment_group_category_select', 'new', :value)
      submit_dialog('div.ui-dialog')
      wait_for_ajaximations
      submit_form('#edit_assignment_form')
      wait_for_ajaximations
      @assignment.reload
      @assignment.group_category_id.should_not be_nil
      @assignment.group_category.should_not be_nil

      get "/courses/#{@course.id}/assignments"
      expect_new_page_load { f("#assignment_#{@assignment.id} .title").click }
      f('.edit_full_assignment_link').click
      f('.more_options_link').click
      f('#assignment_group_assignment').click
      submit_form('#edit_assignment_form')
      wait_for_ajaximations
      @assignment.reload
      @assignment.group_category_id.should be_nil
      @assignment.group_category.should be_nil
    end

    it "should allow creating a quiz assignment from 'more options'" do
      get "/courses/#{@course.id}/assignments"

      f(".assignment_group .add_assignment_link").click
      form = f("#add_assignment_form")
      form.find_element(:css, ".assignment_submission_types option[value='online_quiz']").click
      expect_new_page_load { form.find_element(:css, ".more_options_link").click }

      f(".submission_type_option option[value='none']").should be_selected
      f(".assignment_type option[value='assignment']").click
      f(".submission_type_option option[value='online']").click
      f(".assignment_type option[value='quiz']").click

      expect_new_page_load { submit_form('#edit_assignment_form') }
    end

    it "should edit an assignment" do
      assignment_name = 'first test assignment'
      due_date = Time.now.utc + 2.days
      group = @course.assignment_groups.create!(:name => "default")
      second_group = @course.assignment_groups.create!(:name => "second default")
      @assignment = @course.assignments.create!(
          :name => assignment_name,
          :due_at => due_date,
          :assignment_group => group,
          :unlock_at => due_date - 1.day
      )

      get "/courses/#{@course.id}/assignments"

      expect_new_page_load { f("#assignment_#{@assignment.id} .title").click }
      f('.edit_full_assignment_link').click
      f('.more_options_link').click
      f('#assignment_assignment_group_id').should be_displayed
      click_option('#assignment_assignment_group_id', second_group.name)
      click_option('#assignment_grading_type', 'Letter Grade')

      #check grading levels dialog
      wait_for_animations
      keep_trying_until { f('a.edit_letter_grades_link').should be_displayed }
      f('a.edit_letter_grades_link').click
      wait_for_animations
      f('#edit_letter_grades_form').should be_displayed
      close_visible_dialog

      #check peer reviews option
      form = f("#edit_assignment_form")
      form.find_element(:css, '#assignment_peer_reviews').click
      form.find_element(:css, '#auto_peer_reviews').click
      f('#assignment_peer_review_count').send_keys('2')
      f('#assignment_peer_reviews_assign_at + img').click
      datepicker = datepicker_next
      datepicker.find_element(:css, '.ui-datepicker-ok').click
      f('#assignment_title').send_keys(' edit')

      #save changes
      submit_form(form)
      wait_for_ajaximations
      ff('.loading_image_holder').length.should == 0
      f('h2.title').should include_text(assignment_name + ' edit')
    end

    context "frozen assignments" do

      append_before (:each) do
        @att_map = {"lock_at" => "yes",
                    "assignment_group" => "yes",
                    "title" => "no",
                    "assignment_group_id" => "yes",
                    "submission_types" => "yes",
                    "points_possible" => "yes",
                    "description" => "yes",
                    "peer_reviews" => "yes",
                    "grading_type" => "yes"}
        PluginSetting.stubs(:settings_for_plugin).returns(@att_map)

        @asmnt = @course.assignments.create!(
            :name => "frozen",
            :due_at => Time.now.utc + 2.days,
            :assignment_group => @course.assignment_groups.create!(:name => "default"),
            :freeze_on_copy => true
        )
        @asmnt.copied = true
        @asmnt.save!
      end

      def run_assignment_edit
        orig_title = @asmnt.title

        get "/courses/#{@course.id}/assignments"

        expect_new_page_load { f("#assignment_#{@asmnt.id} .title").click }
        f('.edit_full_assignment_link').click
        f('.more_options_link').click

        yield

        # title isn't locked, should allow editing
        f('#assignment_title').send_keys(' edit')

        #save changes
        submit_form('#edit_assignment_form')
        wait_for_ajaximations
        ff('.loading_image_holder').length.should == 0
        f('h2.title').should include_text(orig_title + ' edit')
      end

      it "should respect frozen attributes for teacher" do
        run_assignment_edit do
          f('#assignment_assignment_group_id').should be_nil
          f('#edit_assignment_form #assignment_peer_reviews').should be_nil
          f('#edit_assignment_form #assignment_description').should be_nil
        end
      end

      it "should not be locked for admin" do
        course_with_admin_logged_in(:course => @course, :name => "admin user")

        run_assignment_edit do
          f('#assignment_assignment_group_id').should_not be_nil
          f('#edit_assignment_form #assignment_peer_reviews').should_not be_nil
          f('#edit_assignment_form #assignment_description').should_not be_nil
        end
      end

      it "should not allow assignment group to be deleted" do
        get "/courses/#{@course.id}/assignments"

        f("#group_#{@asmnt.assignment_group_id} .delete_group_link").should be_nil
        f("#assignment_#{@asmnt.id} .delete_assignment_link").should be_nil
      end
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
      f("a.edit_full_assignment_link").click
      submit_form('#edit_assignment_form')

      wait_for_animations
      errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
      errorBoxes.size.should == 2
      errorBoxes.first.should_not be_displayed # .text just gives us an empty string since it's hidden
      errorBoxes.last.text.should == "There were errors on one or more advanced options"
      errorBoxes.last.should be_displayed

      f('a.more_options_link').click
      wait_for_animations
      errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
      errorBoxes.size.should == 1 # the more_options_link one has now been removed from the DOM
      errorBoxes.first.text.should == "The assignment shouldn't be locked again until after the due date"
      errorBoxes.first.should be_displayed
    end
  end
end
