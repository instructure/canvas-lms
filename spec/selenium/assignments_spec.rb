require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')

describe "assignments" do

  # note: due date testing can be found in assignments_overrides_spec

  include_examples "in-process server selenium tests"

  context "as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
      @course.start_at = nil
      @course.save!
      set_course_draft_state
      @course.require_assignment_group
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

      expect(f('#assignment_group_id')).to be_displayed
      click_option('#assignment_group_id', second_group.name)
      click_option('#assignment_grading_type', 'Letter Grade')

      #check grading levels dialog
      f('.edit_letter_grades_link').click
      wait_for_ajaximations
      expect(f('#edit_letter_grades_form')).to be_displayed
      close_visible_dialog

      #check peer reviews option
      form = f("#edit_assignment_form")
      assignment_points_possible = f("#assignment_points_possible")
      replace_content(assignment_points_possible, "5")
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
      expect(driver.execute_script("return document.title")).to include_text(assignment_name + ' edit')
    end


    it "should create an assignment using main add button" do
      assignment_name = 'first assignment'

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      #create assignment
      f(".new_assignment").click
      wait_for_ajaximations
      f('#assignment_name').send_keys(assignment_name)
      f('#assignment_text_entry').click
      submit_assignment_form

      #make sure assignment was added to correct assignment group
      keep_trying_until do
        expect(f('h1.title')).to include_text(assignment_name)
      end
    end

    it "should display assignment on calendar and link to assignment" do
      assignment_name = 'first assignment'
      due_date = Time.now + 2.days
      @assignment = @course.assignments.create(:name => assignment_name, :due_at => due_date)

      get "/calendar2#view_name=month&view_start=#{due_date.to_date.to_s}"

      wait_for_ajaximations
      f('.assignment').click
      wait_for_ajaximations
      f('.edit_event_link').click
      wait_for_ajaximations
      f('.more_options_link').click
      wait_for_ajaximations
      expect(f('#assignment_name')['value']).to include_text(assignment_name)
    end

    it "only allows an assignment editor to edit points and title if assignment " +
           "if assignment has multiple due dates" do
      middle_number = '15'
      expected_date = (Time.now - 1.month).strftime("%b #{middle_number}")
      @assignment = @course.assignments.create!(
          :title => "VDD Test Assignment",
          :due_at => expected_date
      )
      section = @course.course_sections.create!(:name => "new section")
      @assignment.assignment_overrides.create! do |override|
        override.set = section
        override.title = "All"
        override.due_at = 1.day.ago
        override.due_at_overridden = true
      end

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      driver.execute_script "$('.edit_assignment').first().hover().click()"

      expect(fj('.form-dialog .ui-datepicker-trigger:visible')).to be_nil
      expect(f('.multiple_due_dates input').attribute('disabled')).to be_present
      assignment_title = f("#assign_#{@assignment.id}_assignment_name")
      assignment_points_possible = f("#assign_#{@assignment.id}_assignment_points")
      replace_content(assignment_title, "VDD Test Assignment Updated")
      replace_content(assignment_points_possible, "100")
      submit_form(fj('.form-dialog:visible'))
      wait_for_ajaximations
      expect(@assignment.reload.points_possible).to eq 100
      expect(@assignment.title).to eq "VDD Test Assignment Updated"
      # Assert the time didn't change
      expect(@assignment.due_at.strftime('%b %d')).to eq expected_date
    end

    it "should create an assignment with more options" do
      enable_cache do
        expected_text = "Assignment 1"

        get "/courses/#{@course.id}/assignments"
        group = @course.assignment_groups.first
        AssignmentGroup.where(:id => group).update_all(:updated_at => 1.hour.ago)
        first_stamp = group.reload.updated_at.to_i
        f('.add_assignment').click
        wait_for_ajaximations
        expect_new_page_load { f('.more_options').click }
        f("#assignment_name").send_keys(expected_text)
        click_option('#assignment_submission_type', 'No Submission')

        assignment_points_possible = f("#assignment_points_possible")
        replace_content(assignment_points_possible, "5")
        submit_assignment_form
        expect(@course.assignments.count).to eq 1
        get "/courses/#{@course.id}/assignments"
        expect(f('.assignment')).to include_text(expected_text)
        group.reload
        expect(group.updated_at.to_i).not_to eq first_stamp
      end
    end

    it "should verify that self sign-up link works in more options" do
      get "/courses/#{@course.id}/assignments"
      manually_create_assignment
      f('#has_group_category').click
      wait_for_ajaximations
      click_option('#assignment_group_category_id', 'new', :value)
      fj('.ui-dialog:visible .self_signup_help_link img').click
      wait_for_ajaximations
      expect(f('#self_signup_help_dialog')).to be_displayed
    end


    it "should validate that a group category is selected" do
      assignment_name = 'first test assignment'
      @assignment = @course.assignments.create({
                                                   :name => assignment_name,
                                                   :assignment_group => @course.assignment_groups.create!(:name => "default")
                                               })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      f('#has_group_category').click
      close_visible_dialog
      f('.btn-primary[type=submit]').click
      wait_for_ajaximations

      errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
      visBoxes, hidBoxes = errorBoxes.partition { |eb| eb.displayed? }
      expect(visBoxes.first.text).to eq "Please select a group set for this assignment"
    end

    context "frozen assignment", :priority => "2" do
      before do
        stub_freezer_plugin Hash[Assignment::FREEZABLE_ATTRIBUTES.map { |a| [a, "true"] }]
        default_group = @course.assignment_groups.create!(:name => "default")
        @frozen_assign = frozen_assignment(default_group)
      end

      it "should not allow assignment group to be deleted by teacher if assignments are frozen" do
        get "/courses/#{@course.id}/assignments"
        fj("#ag_#{@frozen_assign.assignment_group_id}_manage_link").click
        wait_for_ajaximations
        expect(element_exists("div#assignment_group_#{@frozen_assign.assignment_group_id} a.delete_group")).to be_falsey
      end

      it "should not allow deleting a frozen assignment from index page" do
        get "/courses/#{@course.id}/assignments"
        fj("div#assignment_#{@frozen_assign.id} a.al-trigger").click
        wait_for_ajaximations
        expect(element_exists("div#assignment_#{@frozen_assign.id} a.delete_assignment:visible")).to be_falsey
      end

      it "should allow editing the due date even if completely frozen" do
        old_due_at = @frozen_assign.due_at
        run_assignment_edit(@frozen_assign) do
          replace_content(fj('.due-date-overrides form:first input[name=due_at]'), 'Sep 20, 2012')
        end

        expect(f('.assignment_dates').text).to match /Sep 20, 2012/
        #some sort of time zone issue is occurring with Sep 20, 2012 - it rolls back a day and an hour locally.
        expect(@frozen_assign.reload.due_at.to_i).not_to eq old_due_at.to_i
      end
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
      expect(element_exists("#assignment_#{as.id}")).to be_falsey

      as.reload
      expect(as.workflow_state).to eq 'deleted'
    end

    it "should reorder assignments with drag and drop" do
      ag = @course.assignment_groups.first
      as = []
      4.times do |i|
        as << @course.assignments.create!(:name => "assignment_#{i}", :assignment_group => ag)
      end
      expect(as.collect(&:position)).to eq [1, 2, 3, 4]

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      drag_with_js("#assignment_#{as[0].id}", 0, 50)
      wait_for_ajaximations

      as.each { |a| a.reload }
      expect(as.collect(&:position)).to eq [2, 1, 3, 4]
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
        expect(f("#sequence_footer .module-sequence-footer")).to be_present
      end
    end

    context 'publishing' do
      before do
        ag = @course.assignment_groups.first
        @assignment = ag.assignments.create! :context => @course, :title => 'to publish'
        @assignment.unpublish
      end

      it "should allow publishing from the index page", :priority => "2" do
        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        f("#assignment_#{@assignment.id} .publish-icon").click
        wait_for_ajaximations
        expect(@assignment.reload).to be_published
        keep_trying_until { expect(f("#assignment_#{@assignment.id} .publish-icon").attribute('aria-label')).to include_text("Published") }
      end

      it "shows submission scores for students on index page" do
        @assignment.update_attributes(points_possible: 15)
        @assignment.publish
        course_with_student_logged_in(active_all: true, course: @course)
        @assignment.grade_student(@student, grade: 14)
        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").
            text).to match "14/15 pts"
      end

      it "should allow publishing from the show page" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        def speedgrader_hidden?
          driver.execute_script(
              "return $('#assignment-speedgrader-link').hasClass('hidden')"
          )
        end

        expect(speedgrader_hidden?).to eq true

        f("#assignment_publish_button").click
        wait_for_ajaximations

        expect(@assignment.reload).to be_published
        expect(f("#assignment_publish_button").text).to match "Published"
        expect(speedgrader_hidden?).to eq false
      end

      it "should show publishing status on the edit page" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
        wait_for_ajaximations

        expect(f("#edit_assignment_header").text).to match "Not Published"
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
          get("/courses/#{@course.id}/assignments", false)
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

          expect(@assignment.reload.active_assignment_overrides.count).to eq 1
        end

        it "should not overwrite overrides if published twice from the show page" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          wait_for_ajaximations

          f("#assignment_publish_button").click
          wait_for_ajaximations
          expect(@assignment.reload).to be_published

          f("#assignment_publish_button").click
          wait_for_ajaximations
          expect(@assignment.reload).not_to be_published

          expect(@assignment.reload.active_assignment_overrides.count).to eq 1
        end
      end
    end
  end
end
