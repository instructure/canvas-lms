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
      driver.execute_script("return document.title").should include_text(assignment_name + ' edit')
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
        if grading_option == "percent"
          replace_content f('#assignment_points_possible'), ('1')
        end
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
      wait_for_ajaximations
      fj('#ui-datepicker-div .ui-datepicker-ok').click
      wait_for_ajaximations
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
        AssignmentGroup.where(:id => group).update_all(:updated_at => 1.hour.ago)
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
      driver.execute_script("return document.title").should include_text(assignment_name + ' edit')
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
        AssignmentGroup.where(:id => group).update_all(:updated_at => 1.hour.ago)
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

    it "should validate points for percentage grading (> 0)" do
      assignment_name = 'first test assignment'
      @assignment = @course.assignments.create({
        :name => assignment_name,
        :assignment_group => @course.assignment_groups.create!(:name => "default")
      })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      f('#assignment_toggle_advanced_options').click
      click_option('#assignment_grading_type', 'Percentage')
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations
      fj('.error_text div').text.should == "Points possible must be more than 0 for percentage grading"
    end

    it "should validate points for percentage grading (!= '')" do
      assignment_name = 'first test assignment'
      @assignment = @course.assignments.create({
        :name => assignment_name,
        :assignment_group => @course.assignment_groups.create!(:name => "default")
      })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      f('#assignment_toggle_advanced_options').click
      click_option('#assignment_grading_type', 'Percentage')
      replace_content f('#assignment_points_possible'), ('')
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations
      fj('.error_text div').text.should == "Points possible must be more than 0 for percentage grading"
    end

    it "should validate points for percentage grading (digits only)" do
      assignment_name = 'first test assignment'
      @assignment = @course.assignments.create({
        :name => assignment_name,
        :assignment_group => @course.assignment_groups.create!(:name => "default")
      })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      f('#assignment_toggle_advanced_options').click
      click_option('#assignment_grading_type', 'Percentage')
      replace_content f('#assignment_points_possible'), ('taco')
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations
      fj('.error_text div').text.should == "Points possible must be more than 0 for percentage grading"
    end


    it "should create an assignment with the correct date for keyboard entry (mm/dd/yy)" do
      get "/courses/#{@course.id}/assignments"
      f('.add_assignment_link').click
      wait_for_ajaximations
      replace_content(fj('#assignment_title'), "TACOS TACOS TACOS")
      replace_content(fj('#assignment_due_at'), '06/10/12')
      expect_new_page_load { f('.more_options_link').click }
      f('#assignment_due_date').attribute(:value).should == "Jun 10, 2012 at 12am"
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

    context "draft state" do
      before do
        @course.root_account.enable_draft!
        @course.require_assignment_group
      end

      it "should go to the new assignment page from 'Add Assignment'" do
        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        expect_new_page_load { f('.new_assignment').click }
        wait_for_ajaximations

        f('#edit_assignment_form').should be_present
      end

      it "should allow quick-adding an assignment to a group" do
        ag = @course.assignment_groups.first

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        f("#assignment_group_#{ag.id} .add_assignment").click
        wait_for_ajaximations

        replace_content(f("#ag_#{ag.id}_assignment_name"), "Do this")
        replace_content(f("#ag_#{ag.id}_assignment_points"), "13")
        fj('.create_assignment:visible').click
        wait_for_ajaximations

        a = ag.reload.assignments.first
        a.name.should == "Do this"
        a.points_possible.should == 13

        f("#assignment_group_#{ag.id} .ig-title").text.should match "Do this"
      end

      it "should allow quick-adding two assignments to a group (dealing with form re-render)" do
        ag = @course.assignment_groups.first

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        f("#assignment_group_#{ag.id} .add_assignment").click
        wait_for_ajaximations

        replace_content(f("#ag_#{ag.id}_assignment_name"), "Do this")
        replace_content(f("#ag_#{ag.id}_assignment_points"), "13")
        fj('.create_assignment:visible').click
        wait_for_ajaximations

        keep_trying_until do
          fj("#assignment_group_#{ag.id} .add_assignment").click
          wait_for_ajaximations
          fj("#ag_#{ag.id}_assignment_name").displayed?
        end

        get_value("#ag_#{ag.id}_assignment_name").should == ""
        get_value("#ag_#{ag.id}_assignment_points").should == "0"

        replace_content(fj("#ag_#{ag.id}_assignment_name"), "Another")
        replace_content(fj("#ag_#{ag.id}_assignment_points"), "3")
        fj('.create_assignment:visible').click
        wait_for_ajaximations

        ag.reload.assignments.count.should == 2
      end

      it "should remember entered settings when 'more options' is pressed" do
        ag2 = @course.assignment_groups.create!(:name => "blah")

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        f("#assignment_group_#{ag2.id} .add_assignment").click
        wait_for_ajaximations

        replace_content(f("#ag_#{ag2.id}_assignment_name"), "Do this")
        replace_content(f("#ag_#{ag2.id}_assignment_points"), "13")
        expect_new_page_load { fj('.more_options:visible').click }

        get_value("#assignment_name").should == "Do this"
        get_value("#assignment_points_possible").should == "13"
        get_value("#assignment_group_id").should == ag2.id.to_s
      end

      it "should delete assignments" do
        ag = @course.assignment_groups.first
        as = @course.assignments.create({:assignment_group => ag})

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        f("#assignment_#{as.id} .al-trigger").click
        wait_for_animations
        f("#assignment_#{as.id} .delete_assignment").click

        accept_alert
        wait_for_ajaximations
        element_exists("#assignment_#{as.id}").should be_false

        as.reload
        as.workflow_state.should == 'deleted'
      end

      it "should reorder assignments with drag and drop" do
        ag = @course.assignment_groups.first
        as = []
        4.times do |i|
          as << @course.assignments.create!(:name => "group_#{i}")
        end
        as.collect(&:position).should == [1,2,3,4]

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        sleep(5)
        drag_with_js("#assignment_group_#{ag.id}_assignments .ig-title:eq(1) .draggable-handle", 0, 50)
        sleep(5)
        wait_for_ajaximations

        as.each {|a| a.reload}
        as.collect(&:position).should == [1,3,2,4]
      end

      context "with modules" do
        before do
          @module = @course.context_modules.create!(:name => "module 1")
          @assignment = @course.assignments.create!(:name => 'assignment 1')
          @a2 = @course.assignments.create!(:name => 'assignment 2')
          @a3 = @course.assignments.create!(:name => 'assignment 3')
          @module.add_item :type => 'assignment', :id => @assignment.id
          @module.add_item :type => 'assignment', :id => @a2.id
          @module.add_item :type => 'assignment', :id => @a3.id
        end

        it "should show the new modules sequence footer" do
          get "/courses/#{@course.id}/assignments/#{@a2.id}"
          wait_for_ajaximations
          f("#sequence_footer .module-sequence-footer").should be_present
        end
      end

      context 'publishing' do
        before do
          ag = @course.assignment_groups.first
          @assignment = ag.assignments.create! :context => @course, :title => 'to publish'
          @assignment.unpublish
        end

        it "should allow publishing from the index page" do
          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          f("#assignment_#{@assignment.id} .publish-icon").click
          wait_for_ajaximations

          @assignment.reload.should be_published
          f("#assignment_#{@assignment.id} .publish-icon").text.should match "Published"
        end

        it "should allow publishing from the show page" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          wait_for_ajaximations

          def speedgrader_hidden?
            driver.execute_script(
              "return $('#assignment-speedgrader-link').hasClass('hidden')"
            )
          end

          speedgrader_hidden?.should == true

          f("#assignment_publish_button").click
          wait_for_ajaximations

          @assignment.reload.should be_published
          f("#assignment_publish_button").text.should match "Published"
          speedgrader_hidden?.should == false
        end

        it "should show publishing status on the edit page" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
          wait_for_ajaximations

          f("#edit_assignment_header").text.should match "Not Published"
        end

        context 'with overrides' do
          before do
            @course.course_sections.create! :name => "HI"
            @assignment.assignment_overrides.create! { |override|
              override.set = @course.course_sections.first
              override.due_at = 1.day.ago
              override.due_at_overridden = true
            }
          end

          it "should not overwrite overrides if published twice from the index page" do
            get "/courses/#{@course.id}/assignments"
            wait_for_ajaximations

            f("#assignment_#{@assignment.id} .publish-icon").click
            wait_for_ajaximations
            @assignment.reload.should be_published

            # need to make sure buttons
            keep_trying_until do
              driver.execute_script(
                "return !$('#assignment_#{@assignment.id} .publish-icon').hasClass('disabled')"
              )
            end

            f("#assignment_#{@assignment.id} .publish-icon").click
            wait_for_ajaximations
            @assignment.reload.should_not be_published

            @assignment.reload.active_assignment_overrides.count.should == 1
          end

          it "should not overwrite overrides if published twice from the show page" do
            get "/courses/#{@course.id}/assignments/#{@assignment.id}"
            wait_for_ajaximations

            f("#assignment_publish_button").click
            wait_for_ajaximations
            @assignment.reload.should be_published

            f("#assignment_publish_button").click
            wait_for_ajaximations
            @assignment.reload.should_not be_published

            @assignment.reload.active_assignment_overrides.count.should == 1
          end
        end
      end
    end
  end
end
