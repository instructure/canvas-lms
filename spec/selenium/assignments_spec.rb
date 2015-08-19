require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

describe "assignments" do

  # note: due date testing can be found in assignments_overrides_spec

  include_context "in-process server selenium tests"

  context "as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
      @course.start_at = nil
      @course.save!
      @course.require_assignment_group
    end

    context "save and publish button" do

      def create_assignment(publish = true, params = {name: "Test Assignment"})
        @assignment = @course.assignments.create(params)
        @assignment.unpublish unless publish
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      end

      it "can save and publish an assignment", priority: "1", test_id: 193784 do
        create_assignment false

        expect(f("#assignment-draft-state")).to be_displayed

        expect_new_page_load {f(".save_and_publish").click}
        expect(f("#assignment_publish_button.btn-published")).to be_displayed

        # Check that the list of quizzes is also updated
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_#{@assignment.id} .icon-publish")).to be_displayed
      end

      it "should not exist in a published assignment", priority: "1", test_id: 140648 do
        create_assignment

        expect(f(".save_and_publish")).to be_nil
      end

      context "moderated grading assignments" do

        before do
          @course.root_account.allow_feature! :moderated_grading
          @course.enable_feature! :moderated_grading
          @assignment = @course.assignments.create({name: "Test Moderated Assignment"})
          @assignment.update_attribute(:moderated_grading, true)
          @assignment.unpublish
        end

        it "should show the moderate button when the assignment is published" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          f('#assignment_publish_button').click()
          wait_for_ajaximations
          expect(f('#moderated_grading_button')).to be_displayed
        end

        it "should remove the moderate button when the assignment is unpublished" do
          @assignment.publish
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          f('#assignment_publish_button').click()
          wait_for_ajaximations
          expect(f('#moderated_grading_button')).not_to be_displayed
        end
      end
    end

    it "should insert a file using RCE in the assignment", priority: "1", test_id: 126671 do
      @assignment = @course.assignments.create(name: 'Test Assignment')
      file = @course.attachments.create!(display_name: 'some test file', uploaded_data: default_uploaded_data)
      file.context = @course
      file.save!
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      insert_file_from_rce
    end

    it "should edit an assignment", priority: "1", test_id: 56012 do
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


    it "should create an assignment using main add button", priority: "1", test_id: 132582 do
      assignment_name = 'first assignment'
      # freeze for a certain time, so we don't get unexpected ui complications
      time = Timecop.freeze(2015,1,7,2,13)
      due_at = time.strftime('%b %-d at %-l:%M') << time.strftime('%p').downcase

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      #create assignment
      f(".new_assignment").click
      wait_for_ajaximations
      f('#assignment_name').send_keys(assignment_name)
      f('#assignment_points_possible').send_keys('10')
      ['#assignment_text_entry', '#assignment_online_url', '#assignment_online_upload'].each do |element|
        f(element).click
      end

      fj(".datePickerDateField[data-date-type='due_at']").send_keys(due_at)

      submit_assignment_form
      #confirm all our settings were saved and are now displayed
      wait_for_ajaximations
      expect(f('h1.title')).to include_text(assignment_name)
      expect(fj('#assignment_show .points_possible')).to include_text('10')
      expect(f('#assignment_show fieldset')).to include_text('a text entry box, a website url, or a file upload')

      expect(f('.assignment_dates')).to include_text(due_at)
      # unfreeze time
      Timecop.return
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
        # freeze time to avoid ui complications
        time = Timecop.freeze(2015,1,7,2,13)
        due_at = time.strftime('%b %-d at %-l:%M') << time.strftime('%p').downcase
        points = '25'

        get "/courses/#{@course.id}/assignments"
        group = @course.assignment_groups.first
        AssignmentGroup.where(:id => group).update_all(:updated_at => 1.hour.ago)
        first_stamp = group.reload.updated_at.to_i
        f('.add_assignment').click
        wait_for_ajaximations
        replace_content(f("#ag_#{group.id}_assignment_name"), expected_text)
        replace_content(f("#ag_#{group.id}_assignment_due_at"), due_at)
        replace_content(f("#ag_#{group.id}_assignment_points"), points)
        expect_new_page_load { f('.more_options').click }
        expect(f('#assignment_name').attribute(:value)).to include_text(expected_text)
        expect(f('#assignment_points_possible').attribute(:value)).to include_text(points)
        due_at_field = fj(".date_field:first[data-date-type='due_at']")
        expect(due_at_field.attribute(:value)).to eq due_at
        click_option('#assignment_submission_type', 'No Submission')
        submit_assignment_form
        expect(@course.assignments.count).to eq 1
        get "/courses/#{@course.id}/assignments"
        expect(f('.assignment')).to include_text(expected_text)
        group.reload
        expect(group.updated_at.to_i).not_to eq first_stamp
        # unfreeze time
        Timecop.return
      end
    end

    it "should keep erased field on more options click" do
      enable_cache do
        middle_number = '15'
        expected_date = (Time.now - 1.month).strftime("%b #{middle_number}")
        @assignment = @course.assignments.create!(
            :title => "Test Assignment",
            :points_possible => 10,
            :due_at => expected_date
        )
        section = @course.course_sections.create!(:name => "new section")
        @assignment.assignment_overrides.create! do |override|
          override.set = section
          override.title = "All"
        end

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        driver.execute_script "$('.edit_assignment').first().hover().click()"
        assignment_title = f("#assign_#{@assignment.id}_assignment_name")
        assignment_points_possible = f("#assign_#{@assignment.id}_assignment_points")
        replace_content(assignment_title, "")
        replace_content(assignment_points_possible, "")
        wait_for_ajaximations
        expect_new_page_load { fj('.more_options:eq(1)').click }
        expect(f("#assignment_name").text).to match ""
        expect(f("#assignment_points_possible").text).to match ""

        first_input_val = driver.execute_script("return $('.DueDateInput__Container:first input').val();")
        expect(first_input_val).to match expected_date
        second_input_val = driver.execute_script("return $('.DueDateInput__Container:last input').val();")
        expect(second_input_val).to match ""
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

    it "shows assignment details, un-editable, for concluded teachers" do
      @teacher.enrollments.first.conclude
      @assignment = @course.assignments.create({
        :name => "assignment after concluded",
        :assignment_group => @course.assignment_groups.create!(:name => "default")
      })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(f(".description.teacher-version")).to be_present
      expect(ff(".edit_assignment_link")).to be_empty
    end

    context "group assignments" do
      before(:each) do
        ag = @course.assignment_groups.first
        @assignment1, @assignment2 = [1,2].map do |i|
          gc = GroupCategory.create(:name => "gc#{i}", :context => @course)
          group = @course.groups.create!(:group_category => gc)
          group.users << student_in_course(:course => @course, :active_all => true).user
          ag.assignments.create! :context => @course, :name => "assignment#{i}", :group_category => gc, :submission_types => 'online_text_entry'
        end
        submission = @assignment1.submit_homework(@student)
        submission.submission_type = "online_text_entry"
        submission.save!
      end

      it "should not allow group set to be changed if there are submissions" do
        get "/courses/#{@course.id}/assignments/#{@assignment1.id}/edit"
        wait_for_ajaximations
        expect(f("#assignment_group_category_id").attribute('disabled')).to be_present
      end

      it "should still show deleted group set only on an attached assignment with " +
        "submissions" do
        @assignment1.group_category.destroy
        @assignment2.group_category.destroy

        # ensure neither deleted group shows up on an assignment with no submissions
        get "/courses/#{@course.id}/assignments/#{@assignment2.id}/edit"
        wait_for_ajaximations

        expect(f("#assignment_group_category_id")).not_to include_text @assignment1.group_category.name
        expect(f("#assignment_group_category_id")).not_to include_text @assignment2.group_category.name

        # ensure an assignment attached to a deleted group shows the group it's attached to,
        # but no other deleted groups, and that the dropdown is disabled
        get "/courses/#{@course.id}/assignments/#{@assignment1.id}/edit"
        wait_for_ajaximations

        expect(get_value("#assignment_group_category_id")).to eq @assignment1.group_category.id.to_s
        expect(f("#assignment_group_category_id")).not_to include_text @assignment2.group_category.name
        expect(f("#assignment_group_category_id").attribute('disabled')).to be_present
      end

      it "should revert to [ New Group Category ] if original group is deleted with no submissions" do
        @assignment2.group_category.destroy
        get "/courses/#{@course.id}/assignments/#{@assignment2.id}/edit"
        wait_for_ajaximations

        expect(f("#assignment_group_category_id option[selected]")).to include_text "New Group Category"
      end
    end

    context "frozen assignment" do
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
          replace_content(fj(".datePickerDateField[data-date-type='due_at']"), 'Sep 20, 2012')
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

      it "should allow publishing from the index page", priority: "2" do
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
          get "/courses/#{@course.id}/assignments"

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

    context 'save to sis' do
      it 'should not show when no passback configured', priority: "1", test_id: 244956 do
        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f('#assignment_post_to_sis')).to be_nil
      end

      it 'should show when powerschool is enabled', priority: "1", test_id: 244913 do
        Account.default.set_feature_flag!('post_grades', 'on')
        @course.sis_source_id = 'xyz'
        @course.save

        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f('#assignment_post_to_sis')).to_not be_nil
      end

      it 'should show when post_grades lti tool installed', priority: "1", test_id: 244957 do
        create_post_grades_tool

        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f('#assignment_post_to_sis')).to_not be_nil
      end

      it 'should not show when post_grades lti tool not installed', priority: "1", test_id: 250261 do
        Account.default.set_feature_flag!('post_grades', 'off')

        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f('#assignment_post_to_sis')).to be_nil
      end
    end

    it 'should go to the assignment index page from left nav', priority: "1", test_id: 108724 do
      get "/courses/#{@course.id}"
      f('#wrapper .assignments').click
      wait_for_ajaximations
      expect(f('.header-bar-right .new_assignment')).to include_text('Assignment')
    end
  end

  context "when a public course is accessed" do
    include_context "public course as a logged out user"

    it "should display assignments", priority: "1", test_id: 269811 do
      public_course.assignments.create!(:name => 'assignment 1')
      get "/courses/#{public_course.id}/assignments"
      validate_selector_displayed('.assignment.search_show')
    end
  end

  context "moderated grading" do

    before do
      course_with_teacher_logged_in
      @course.start_at = nil
      @course.save!
      @course.root_account.allow_feature! :moderated_grading
      @course.enable_feature! :moderated_grading
      @assignment = @course.assignments.create({name: "Test Moderated Assignment"})
      @assignment.update_attribute(:moderated_grading, true)
      @assignment.publish
    end

    it "should show the moderated grading page for moderated grading assignments" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/moderate"
      expect(f('#assignment_moderation')).to be_displayed
    end

    it "should deny access for a regular student to the moderation page" do
      course_with_student_logged_in({course: @course})
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/moderate"
      expect(f('#unauthorized_message')).to be_displayed
    end

    it "should not show the moderation page if it is not a moderated assignment " do
      @assignment.update_attribute(:moderated_grading, false)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/moderate"
      expect(f('#content h2').text).to eql "Page Not Found"
    end
  end
end
