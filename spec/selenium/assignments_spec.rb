require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments" do
  it_should_behave_like "in-process server selenium tests"

  context "as a teacher" do

    def manually_create_assignment(assignment_title = 'new assignment')
      get "/courses/#{@course.id}/assignments"
      f('.add_assignment_link').click
      wait_for_ajaximations
      replace_content(f('#assignment_title'), assignment_title)
      expect_new_page_load { f('.more_options_link').click }
      wait_for_ajaximations
    end

    def submit_assignment_form
      expect_new_page_load { f('.btn-primary[type=submit]').click }
      wait_for_ajaximations
    end

    def edit_assignment
      expect_new_page_load { f('.edit_assignment_link').click }
      wait_for_ajaximations
    end

    before(:each) do
      course_with_teacher_logged_in
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
      edit_assignment
      f('#assignment_toggle_advanced_options').click
      f('#assignment_group_id').should be_displayed
      click_option('#assignment_group_id', second_group.name)
      click_option('#assignment_grading_type', 'Letter Grade')

      #check grading levels dialog
      f('.edit_letter_grades_link').click
      wait_for_ajaximations
      f('#edit_letter_grades_form').should be_displayed
      close_visible_dialog

      #check peer reviews option
      form = f("#edit_assignment_form")
      form.find_element(:css, '#assignment_peer_reviews').click
      wait_for_ajaximations
      form.find_element(:css, '#assignment_automatic_peer_reviews').click
      wait_for_ajaximations
      f('#assignment_peer_review_count').send_keys('2')
      driver.execute_script "$('#assignment_peer_reviews_assign_at + .ui-datepicker-trigger').click()"
      wait_for_ajaximations
      datepicker = datepicker_next
      datepicker.find_element(:css, '.ui-datepicker-ok').click
      wait_for_ajaximations
      f('#assignment_name').send_keys(' edit')

      #save changes
      submit_assignment_form
      f('title').should include_text(assignment_name + ' edit')
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
        wait_for_ajaximations
      end
      day_id = '#day_' + due_date.year.to_s() + '_' + due_date.strftime('%m') + '_' + due_date.strftime('%d')
      day_div = f(day_id)
      wait_for_ajaximations
      sleep 1 # this is one of those cases where if we click too early, no subsequent clicks will work
      day_div.find_element(:link, assignment_name).click
      wait_for_ajaximations
      details_dialog = f('#event_details').find_element(:xpath, '..')
      details_dialog.should include_text(assignment_name)
      details_dialog.find_element(:css, '.edit_event_link').click
      wait_for_ajaximations
      details_dialog = f('#edit_event').find_element(:xpath, '..')
      details_dialog.find_element(:name, 'assignment[title]').should be_displayed
      details_dialog.find_element(:css, '#edit_assignment_form .more_options_link').click
      wait_for_ajaximations
      f('#assignment_name')['value'].should include_text(assignment_name)
    end

    it "should create an assignment" do
      assignment_name = 'first assignment'
      @course.assignment_groups.create!(:name => "first group")
      @course.assignment_groups.create!(:name => "second group")
      get "/courses/#{@course.id}/assignments"

      #create assignment
      click_option('#right-side select.assignment_groups_select', 'second group')
      f('.add_assignment_link').click
      wait_for_ajaximations
      f('#assignment_title').send_keys(assignment_name)
      f('.ui-datepicker-trigger').click
      wait_for_ajaximations
      datepicker = datepicker_next
      datepicker.find_element(:css, '.ui-datepicker-ok').click
      wait_for_ajaximations
      f('#assignment_points_possible').send_keys('5')
      submit_form('#add_assignment_form')

      #make sure assignment was added to correct assignment group
      wait_for_ajaximations
      first_group = f('#groups .assignment_group:nth-child(2)')
      first_group.should include_text('second group')
      first_group.should include_text(assignment_name)

      #click on assignment link
      f("#assignment_#{Assignment.last.id} .title").click
      wait_for_ajaximations
      f('h2.title').should include_text(assignment_name)
    end

    %w(points percent pass_fail letter_grade).each do |grading_option|
      it "should create assignment with #{grading_option} grading option" do
        assignment_title = 'grading options assignment'
        manually_create_assignment(assignment_title)
        f('#assignment_toggle_advanced_options').click
        wait_for_ajaximations
        click_option('#assignment_grading_type', grading_option, :value)
        submit_assignment_form
        f('.title').should include_text(assignment_title)
        Assignment.find_by_title(assignment_title).grading_type.should == grading_option
      end
    end

    it "should submit a due date successfully" do
      middle_number = '15'
      expected_date = (Time.now - 1.month).strftime("%b #{middle_number}")
      manually_create_assignment
      f('#assignment_due_date_controls .ui-datepicker-trigger').click
      wait_for_ajaximations
      f('.ui-datepicker-prev').click
      wait_for_ajaximations
      fj("#ui-datepicker-div a:contains(#{middle_number})").click
      expect_new_page_load { submit_form('#edit_assignment_form') }
      wait_for_ajaximations
      expect_new_page_load { f(".edit_assignment_link").click }
      wait_for_ajaximations
      f('#assignment_due_date').attribute(:value).should include_text(expected_date)
      Assignment.find_by_title('new assignment').due_at.strftime('%b %d').should == expected_date
    end

    it "only allows an assignment editor to edit points and title if assignment " +
           "if assignment has multiple due dates" do
      middle_number = '15'
      expected_date = (Time.now - 1.month).strftime("%b #{middle_number}")
      @assignment = @course.assignments.create!(
          :title => "VDD Test Assignment",
          :due_at => expected_date
      )
      @assignment.any_instantiation.expects(:overridden_for).at_least_once.
          returns @assignment
      @assignment.any_instantiation.expects(:multiple_due_dates?).at_least_once.
          returns true
      get "/courses/#{@course.id}/assignments"
      wait_for_animations
      driver.execute_script "$('.edit_assignment_link').first().hover().click()"
      # Assert input element is hidden to the user, but still present in the
      # form so the due date doesn't get changed to no due date.
      fj('.add_assignment_form .input-append').attribute('style').
          should contain 'display: none;'
      f('.vdd_no_edit').text.
          should == I18n.t("#assignments.multiple_due_dates", "Multiple Due Dates")
      assignment_title = f("#assignment_title")
      assignment_points_possible = f("#assignment_points_possible")
      assignment_title.clear
      assignment_title.send_keys("VDD Test Assignment Updated")
      assignment_points_possible.clear
      assignment_points_possible.send_keys("100")
      f("#add_assignment_form").submit
      wait_for_ajaximations
      @assignment.reload.points_possible.should == 100
      @assignment.title.should == "VDD Test Assignment Updated"
      # Assert the time didn't change
      @assignment.due_at.strftime('%b %d').should == expected_date
    end

    it "should create an assignment with more options" do
      enable_cache do
        expected_text = "Assignment 1"

        get "/courses/#{@course.id}/assignments"
        group = @course.assignment_groups.first
        AssignmentGroup.update_all({:updated_at => 1.hour.ago}, {:id => group.id})
        first_stamp = group.reload.updated_at.to_i
        f('.add_assignment_link').click
        wait_for_ajaximations
        expect_new_page_load { f('.more_options_link').click }
        submit_assignment_form
        @course.assignments.count.should == 1
        get "/courses/#{@course.id}/assignments"
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
      f('#assignment_toggle_advanced_options').click
      wait_for_ajaximations
      f('#assignment_has_group_category').click
      wait_for_ajaximations
      click_option('#assignment_group_category_id', 'new', :value)
      fj('.ui-dialog:visible .self_signup_help_link img').click
      wait_for_ajaximations
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
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      f('#assignment_toggle_advanced_options').click
      wait_for_ajaximations
      f('#assignment_has_group_category').click
      wait_for_ajaximations
      submit_dialog('#add_category_form')
      wait_for_ajaximations
      submit_assignment_form
      @assignment.reload
      @assignment.group_category_id.should_not be_nil
      @assignment.group_category.should_not be_nil

      edit_assignment
      f('#assignment_has_group_category').click
      wait_for_animations
      submit_assignment_form
      @assignment.reload
      @assignment.group_category_id.should be_nil
      @assignment.group_category.should be_nil
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
      edit_assignment
      f('#assignment_toggle_advanced_options').click
      f('#assignment_group_id').should be_displayed
      click_option('#assignment_group_id', second_group.name)
      click_option('#assignment_grading_type', 'Letter Grade')

      #check grading levels dialog
      f('.edit_letter_grades_link').click
      wait_for_ajaximations
      f('#edit_letter_grades_form').should be_displayed
      close_visible_dialog

      #check peer reviews option
      form = f("#edit_assignment_form")
      form.find_element(:css, '#assignment_peer_reviews').click
      wait_for_ajaximations
      form.find_element(:css, '#assignment_automatic_peer_reviews').click
      wait_for_ajaximations
      f('#assignment_peer_review_count').send_keys('2')
      driver.execute_script "$('#assignment_peer_reviews_assign_at + .ui-datepicker-trigger').click()"
      wait_for_ajaximations
      datepicker = datepicker_next
      datepicker.find_element(:css, '.ui-datepicker-ok').click
      wait_for_ajaximations
      f('#assignment_name').send_keys(' edit')

      #save changes
      submit_assignment_form
      f('title').should include_text(assignment_name + ' edit')
    end

    it "should not allow group assignment or peer review for mooc course assignment" do
      assignment_name = 'mooc test assignment'
      due_date = Time.now.utc + 2.days
      @course.update_attribute(:large_roster, true)
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
      edit_assignment

      #ensure group assignment and peer reviews options are disabled
      f('#assignment_toggle_advanced_options').click
      ff("fieldset#group_category_selector div").should == []
      ff("fieldset#assignment_peer_reviews_fields div").should == []
    end

    it "should show a more errors errorBox if any invalid fields are hidden" do
      assignment_name = 'first test assignment'
      @assignment = @course.assignments.create({
        :name => assignment_name,
        :assignment_group => @course.assignment_groups.create!(:name => "default")
      })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      f('#assignment_toggle_advanced_options').click # show advanced options
      click_option('#assignment_submission_type', "Online") # setup an error state (online with no types)
      f('#assignment_toggle_advanced_options').click # hide advanced options
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations

      errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
      errorBoxes.size.should == 2 # the inivisible one and the 'advanced options' one
      visBoxes, hidBoxes = errorBoxes.partition { |eb| eb.displayed? }
      visBoxes.first.text.should == "There were errors on one or more advanced options"

      f('#assignment_toggle_advanced_options').click
      wait_for_ajaximations
      errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
      errorBoxes.size.should == 1 # the more_options_link one has now been removed from the DOM
      errorBoxes.first.text.should == 'Please choose at least one submission type'
      errorBoxes.first.should be_displayed
    end

    it "should validate that a group category is selected" do
      assignment_name = 'first test assignment'
      @assignment = @course.assignments.create({
        :name => assignment_name,
        :assignment_group => @course.assignment_groups.create!(:name => "default")
      })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      f('#assignment_toggle_advanced_options').click # show advanced options
      f('#assignment_has_group_category').click
      close_visible_dialog
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations

      errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
      visBoxes, hidBoxes = errorBoxes.partition { |eb| eb.displayed? }
      visBoxes.first.text.should == "Please select a group set for this assignment"
    end

    it "should create an assignment with more options" do
      enable_cache do
        expected_text = "Assignment 1"

        get "/courses/#{@course.id}/assignments"
        group = @course.assignment_groups.first
        AssignmentGroup.update_all({:updated_at => 1.hour.ago}, {:id => group.id})
        first_stamp = group.reload.updated_at.to_i
        f('.add_assignment_link').click
        wait_for_ajaximations
        expect_new_page_load { f('.more_options_link').click }
        submit_assignment_form
        @course.assignments.count.should == 1
        get "/courses/#{@course.id}/assignments"
        f('.no_assignments_message').should_not be_displayed
        f('#groups').should include_text(expected_text)
        group.reload
        group.updated_at.to_i.should_not == first_stamp
      end
    end

    context "frozen assignments" do

      append_before(:each) do
        @att_map = {
            "assignment_group_id" => "true"
        }
        PluginSetting.stubs(:settings_for_plugin).returns(@att_map)

        @asmnt = @course.assignments.create!(
            :name => "frozen",
            :due_at => Time.now.utc + 2.days,
            :assignment_group => @course.assignment_groups.create!(:name => "default"),
            :freeze_on_copy => true
        )
        @asmnt.copied = true
        @asmnt.save!

        @course.assignment_groups.create!(:name => "other")
      end

      def run_assignment_edit
        orig_title = @asmnt.title

        get "/courses/#{@course.id}/assignments"

        expect_new_page_load { f("#assignment_#{@asmnt.id} .title").click }
        edit_assignment
        f('#assignment_toggle_advanced_options').try(:click)

        yield

        # title isn't locked, should allow editing
        f('#assignment_name').send_keys(' edit')

        #save changes
        submit_assignment_form
        f('h2.title').should include_text(orig_title + ' edit')
      end

      it "should not allow assignment group to be deleted by teacher if assignment group id frozen" do
        get "/courses/#{@course.id}/assignments"
        fj("#group_#{@asmnt.assignment_group_id} .delete_group_link").should be_nil
        fj("#assignment_#{@asmnt.id} .delete_assignment_link").should be_nil
      end

      it "should not be locked for admin" do
        course_with_admin_logged_in(:course => @course, :name => "admin user")

        run_assignment_edit do
          f('#assignment_group_id').attribute('disabled').should be_nil
          f('#assignment_peer_reviews').attribute('disabled').should be_nil
          f('#assignment_description').attribute('disabled').should be_nil
          click_option('#assignment_group_id', "other")
        end
        @asmnt.reload.assignment_group.name.should == "other"
      end

      it "should not allow assignment group to be deleted by teacher if "+
             "assignment group id frozen" do
        get "/courses/#{@course.id}/assignments"
        fj("#group_#{@asmnt.assignment_group_id} .delete_group_link").should be_nil
        fj("#assignment_#{@asmnt.id} .delete_assignment_link").should be_nil
      end
    end
  end
end
