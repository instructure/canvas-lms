require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments" do

  # note: due date testing can be found in assignments_overrides_spec

  include_examples "in-process server selenium tests"

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

    def run_assignment_edit(assignment)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"

      yield

      submit_assignment_form
    end

    def stub_freezer_plugin(frozen_atts = nil)
      frozen_atts ||= {
        "assignment_group_id" => "true"
      }
      PluginSetting.stubs(:settings_for_plugin).returns(frozen_atts)
    end

    def frozen_assignment(group)
      group ||= @course.assignment_groups.first
      assign = @course.assignments.create!(
          :name => "frozen",
          :due_at => Time.now.utc + 2.days,
          :assignment_group => group,
          :freeze_on_copy => true
      )
      assign.copied = true
      assign.save!
      assign
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

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      wait_for_ajaximations

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
      keep_trying_until do
        first_group = f('#groups .assignment_group:nth-child(2)')
        first_group.should include_text('second group')
        first_group.should include_text(assignment_name)
      end

      #click on assignment link
      f("#assignment_#{Assignment.last.id} .title").click
      wait_for_ajaximations
      f('h2.title').should include_text(assignment_name)
    end

    %w(points percent pass_fail letter_grade gpa_scale).each do |grading_option|
      it "should create assignment with #{grading_option} grading option" do
        assignment_title = 'grading options assignment'
        manually_create_assignment(assignment_title)
        wait_for_ajaximations
        click_option('#assignment_grading_type', grading_option, :value)
        if grading_option == "percent"
          replace_content f('#assignment_points_possible'), ('1')
        end
        click_option('#assignment_submission_type', 'No Submission')
        submit_assignment_form
        f('.title').should include_text(assignment_title)
        Assignment.find_by_title(assignment_title).grading_type.should == grading_option
      end
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
      wait_for_ajaximations
      driver.execute_script "$('.edit_assignment_link').first().hover().click()"
      # Assert input element is hidden to the user, but still present in the
      # form so the due date doesn't get changed to no due date.
      fj('.add_assignment_form .input-append').attribute('style').
          should include 'display: none;'
      f('.vdd_no_edit').text.
          should == I18n.t("#assignments.multiple_due_dates", "Multiple Due Dates")
      assignment_title = f("#assignment_title")
      assignment_points_possible = f("#assignment_points_possible")
      replace_content(assignment_title, "VDD Test Assignment Updated")
      replace_content(assignment_points_possible, "100")
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
        click_option('#assignment_submission_type', 'No Submission')
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
      wait_for_ajaximations
      f('#assignment_has_group_category').click
      wait_for_ajaximations
      click_option('#assignment_group_category_id', 'new', :value)
      fj('.ui-dialog:visible .self_signup_help_link img').click
      wait_for_ajaximations
      f('#self_signup_help_dialog').should be_displayed
    end


    it "should validate that a group category is selected" do
      assignment_name = 'first test assignment'
      @assignment = @course.assignments.create({
         :name => assignment_name,
         :assignment_group => @course.assignment_groups.create!(:name => "default")
      })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
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
        click_option('#assignment_submission_type', 'No Submission')
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
      click_option('#assignment_grading_type', 'Percentage')
      replace_content f('#assignment_points_possible'), ('taco')
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations
      fj('.error_text div').text.should == "Points possible must be more than 0 for percentage grading"
    end

    context "frozen assignment_group_id" do
      before do
        stub_freezer_plugin
        default_group = @course.assignment_groups.create!(:name => "default")
        @frozen_assign = frozen_assignment(default_group)
      end

      it "should not allow assignment group to be deleted by teacher if assignment group id frozen" do
        get "/courses/#{@course.id}/assignments"
        fj("#group_#{@frozen_assign.assignment_group_id} .delete_group_link").should be_nil
        fj("#assignment_#{@frozen_assign.id} .delete_assignment_link").should be_nil
      end

      it "should not be locked for admin" do
        @course.assignment_groups.create!(:name => "other")
        course_with_admin_logged_in(:course => @course, :name => "admin user")
        orig_title = @frozen_assign.title

        run_assignment_edit(@frozen_assign) do
          # title isn't locked, should allow editing
          f('#assignment_name').send_keys(' edit')

          f('#assignment_group_id').attribute('disabled').should be_nil
          f('#assignment_peer_reviews').attribute('disabled').should be_nil
          f('#assignment_description').attribute('disabled').should be_nil
          click_option('#assignment_group_id', "other")
        end

        f('h2.title').should include_text(orig_title + ' edit')
        @frozen_assign.reload.assignment_group.name.should == "other"
      end
    end

    context "draft state" do
      before do
        @course.root_account.enable_feature!(:draft_state)
        @course.require_assignment_group
      end

      #Per selenium guidelines, we should not test buttons navigating to a page
      # We could test that the page loads with the correct info from the params elsewhere
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

      # This should be part of a spec that follows a critical path through
      #  the draft state index page, but does not need to be a lone wolf
      it "should delete assignments" do
        ag = @course.assignment_groups.first
        as = @course.assignments.create({:assignment_group => ag})

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        f("#assignment_#{as.id} .al-trigger").click
        wait_for_ajaximations
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
          as << @course.assignments.create!(:name => "assignment_#{i}", :assignment_group => ag)
        end
        as.collect(&:position).should == [1, 2, 3, 4]

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        drag_with_js("#assignment_#{as[0].id}", 0, 50)
        wait_for_ajaximations

        as.each { |a| a.reload }
        as.collect(&:position).should == [2, 1, 3, 4]
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

      context "frozen assignment_group_id" do
        before do
          stub_freezer_plugin
          default_group = @course.assignment_groups.create!(:name => "default")
          @frozen_assign = frozen_assignment(default_group)
        end

      end

      context 'publishing' do
        before do
          ag = @course.assignment_groups.first
          @assignment = ag.assignments.create! :context => @course, :title => 'to publish'
          @assignment.unpublish
        end

        it "shows submission scores for students on index page" do
          @assignment.update_attributes(points_possible: 15)
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student,grade: 14)
          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations
          f("#assignment_#{@assignment.id} .js-score .non-screenreader").
            text.should match "14/15 pts"
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
            get("/courses/#{@course.id}/assignments",false)
            wait_for_ajaximations

            f("#assignment_#{@assignment.id} .publish-icon").click
            wait_for_ajaximations
            keep_trying_until { @assignment.reload.published? }

            # need to make sure buttons
            keep_trying_until do
              driver.execute_script(
                  "return !$('#assignment_#{@assignment.id} .publish-icon').hasClass('disabled')"
              )
            end

            f("#assignment_#{@assignment.id} .publish-icon").click
            wait_for_ajaximations
            keep_trying_until { !@assignment.reload.published? }

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
