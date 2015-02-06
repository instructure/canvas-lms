require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "gradebook2" do
  include_examples "in-process server selenium tests"

  context "as a teacher" do
    before(:each) do
      gradebook_data_setup
    end

    it "hides unpublished/shows published assignments" do
      assignment = @course.assignments.create! title: 'unpublished'
      assignment.unpublish
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(f('#gradebook_grid .container_1 .slick-header')).not_to include_text(assignment.title)

      @first_assignment.publish
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(f('#gradebook_grid .container_1 .slick-header')).to include_text(@first_assignment.title)
    end

    it "should not show 'not-graded' assignments" do
      get "/courses/#{@course.id}/gradebook2"

      expect(f('.slick-header-columns')).not_to include_text(@ungraded_assignment.title)
    end

    def filter_student(text)
      f('.gradebook_filter input').send_keys text
      sleep 1 # InputFilter has a delay
    end

    def get_visible_students
      ff('.student-name')
    end

    it 'should filter students' do
      get "/courses/#{@course.id}/gradebook2"
      expect(get_visible_students.length).to eq @all_students.size
      filter_student 'student 1'
      visible_students = get_visible_students
      expect(visible_students.length).to eq 1
      expect(visible_students[0].text).to eq 'student 1'
    end

    it "should not show not-graded assignments" do
      expect(f('#gradebook_grid .slick-header')).not_to include_text(@ungraded_assignment.title)
    end

    it "should validate correct number of students showing up in gradebook" do
      get "/courses/#{@course.id}/gradebook2"

      expect(ff('.student-name').count).to eq @course.students.count
    end

    it "should not show concluded enrollments in active courses by default" do
      @student_1.enrollments.where(course_id: @course).first.conclude

      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size

      get "/courses/#{@course.id}/gradebook2"

      expect(ff('.student-name').count).to eq @course.students.count

      # select the option and we'll now show concluded
      expect_new_page_load { open_gradebook_settings(f('label[for="show_concluded_enrollments"]')) }
      wait_for_ajaximations

      expect(driver.find_elements(:css, '.student-name').count).to eq @course.all_students.count
    end

    it "should show concluded enrollments in concluded courses by default" do
      @course.complete!

      expect(@course.students.count).to eq 0
      expect(@course.all_students.count).to eq @all_students.size

      get "/courses/#{@course.id}/gradebook2"
      expect(driver.find_elements(:css, '.student-name').count).to eq @course.all_students.count

      # the checkbox should fire an alert rather than changing to not showing concluded
      expect_fired_alert { open_gradebook_settings(f('label[for="show_concluded_enrollments"]')) }
      expect(driver.find_elements(:css, '.student-name').count).to eq @course.all_students.count
    end

    it "should show students sorted by their sortable_name" do
      get "/courses/#{@course.id}/gradebook2"
      dom_names = ff('.student-name').map(&:text)
      expect(dom_names).to eq @all_students.map(&:name)
    end

    it "should not show student avatars until they are enabled" do
      get "/courses/#{@course.id}/gradebook2"

      expect(ff('.student-name').length).to eq @all_students.size
      expect(ff('.avatar img').length).to eq 0

      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      expect(ff('.student-name').length).to eq @all_students.size
      expect(ff('.avatar').length).to eq @all_students.size
    end


    it "should allow showing only a certain section" do
      get "/courses/#{@course.id}/gradebook2"
      # grade the first assignment
      edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2', 0)
      edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(2) .l2', 1)

      choose_section = ->(name) do
        fj('.section-select-button:visible').click
        wait_for_js
        ffj('.section-select-menu:visible a').find { |a| a.text.include? name }.click
        wait_for_js
      end

      choose_section.call "All Sections"
      expect(fj('.section-select-button:visible')).to include_text("All Sections")

      choose_section.call @other_section.name
      expect(fj('.section-select-button:visible')).to include_text(@other_section.name)

      validate_cell_text(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2'), '1')

      # verify that it remembers the section to show across page loads
      get "/courses/#{@course.id}/gradebook2"
      expect(fj('.section-select-button:visible')).to include_text @other_section.name
      validate_cell_text(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2'), '1')

      # now verify that you can set it back

      fj('.section-select-button:visible').click
      wait_for_ajaximations
      keep_trying_until { expect(fj('.section-select-menu:visible')).to be_displayed }
      fj("label[for='section_option_#{''}']").click
      keep_trying_until { expect(fj('.section-select-button:visible')).to include_text "All Sections" }

      # validate all grades (i.e. submissions) were loaded
      validate_cell_text(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2'), '0')
      validate_cell_text(f('#gradebook_grid .container_1 .slick-row:nth-child(2) .l2'), '1')
    end


    it "should handle muting/unmuting correctly" do
      get "/courses/#{@course.id}/gradebook2"

      toggle_muting(@second_assignment)
      expect(fj(".container_1 .slick-header-column[id*='assignment_#{@second_assignment.id}'] .muted")).to be_displayed
      expect(@second_assignment.reload).to be_muted

      # reload the page and make sure it remembered the setting
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(fj(".container_1 .slick-header-column[id*='assignment_#{@second_assignment.id}'] .muted")).to be_displayed

      # make sure you can un-mute
      toggle_muting(@second_assignment)
      expect(fj(".container_1 .slick-header-column[id*='assignment_#{@second_assignment.id}'] .muted")).to be_nil
      expect(@second_assignment.reload).not_to be_muted
    end

    context "concluded course" do
      before do
        @course.complete!
        get "/courses/#{@course.id}/gradebook2"
      end

      it "should not allow editing grades" do
        cell = f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2')
        expect(cell.text).to eq '10'
        cell.click
        expect(ff('.grade', cell)).to be_blank
      end

      it "should hide mutable actions from the menu" do
        open_gradebook_settings do |menu|
          expect(ff("a.gradebook_upload_link", menu)).to be_blank
          expect(ff("a.set_group_weights", menu)).to be_blank
        end
      end
    end

    it "should validate that gradebook settings is displayed when button is clicked" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      open_gradebook_settings
    end

    it "should validate posting a comment to a graded assignment" do
      comment_text = "This is a new comment!"

      get "/courses/#{@course.id}/gradebook2"

      dialog = open_comment_dialog
      set_value(dialog.find_element(:id, "add_a_comment"), comment_text)
      f("form.submission_details_add_comment_form.clearfix > button.btn").click
      wait_for_ajaximations

      #make sure it is still there if you reload the page
      refresh_page
      wait_for_ajaximations

      comment = open_comment_dialog.find_element(:css, '.comment')
      expect(comment).to include_text(comment_text)
    end

    it "should let you post a group comment to a group assignment" do
      group_assignment = @course.assignments.create!({
                                                         :title => 'group assignment',
                                                         :due_at => (Time.now + 1.week),
                                                         :points_possible => @assignment_3_points,
                                                         :submission_types => 'online_text_entry',
                                                         :assignment_group => @group,
                                                         :group_category => GroupCategory.create!(:name => "groups", :context => @course),
                                                         :grade_group_students_individually => true
                                                     })
      project_group = group_assignment.group_category.groups.create!(:name => 'g1', :context => @course)
      project_group.users << @student_1
      project_group.users << @student_2

      comment_text = "This is a new group comment!"

      get "/courses/#{@course.id}/gradebook2"

      dialog = open_comment_dialog(3)
      set_value(dialog.find_element(:id, "add_a_comment"), comment_text)
      dialog.find_element(:id, "group_comment").click
      f("form.submission_details_add_comment_form.clearfix > button.btn").click
      wait_for_ajaximations

      #make sure it's on the other student's submission
      comment = keep_trying_until do
        open_comment_dialog(3, 1)
        fj(".submission_details_dialog:visible .comment")
      end
      expect(comment).to include_text(comment_text)
    end

    it "should validate assignment details" do
      submissions_count = @second_assignment.submissions.count.to_s + ' submissions'

      get "/courses/#{@course.id}/gradebook2"

      open_assignment_options(1)
      f('[data-action="showAssignmentDetails"]').click
      wait_for_ajaximations
      details_dialog = f('#assignment-details-dialog')
      expect(details_dialog).to be_displayed
      table_rows = ff('#assignment-details-dialog-stats-table tr')
      expect(table_rows[3].find_element(:css, 'td').text).to eq submissions_count
    end

    it "should not throw an error when setting the default grade when concluded enrollments exist" do
      skip("bug 7413 - Error assigning default grade for all students when one student's enrollment has been concluded.")
      conclude_and_unconclude_course
      3.times { student_in_course }

      get "/courses/#{@course.id}/gradebook2"


      #TODO - when show concluded enrollments fix goes in we probably have to add that code right here
      #for the test to work correctly

      set_default_grade(2, 5)
      grade_grid = f('#gradebook_grid')
      @course.student_enrollments.each_with_index do |e, n|
        next if e.completed?
        expect(find_slick_cells(n, grade_grid)[2].text).to eq 5
      end
    end

    describe "message students who" do
      it "should send messages" do
        message_text = "This is a message"

        get "/courses/#{@course.id}/gradebook2"

        open_assignment_options(2)
        f('[data-action="messageStudentsWho"]').click
        expect {
          message_form = f('#message_assignment_recipients')
          message_form.find_element(:css, '#body').send_keys(message_text)
          submit_form(message_form)
          wait_for_ajax_requests
        }.to change(ConversationMessage, :count).by_at_least(2)
      end

      it "should only send messages to students who have not submitted and have not been graded" do
        # student 1 submitted but not graded yet
        @third_submission = @third_assignment.submit_homework(@student_1, :body => ' student 1 submission assignment 4')
        @third_submission.save!

        # student 2 graded without submission (turned in paper by hand)
        @third_assignment.grade_student(@student_2, :grade => 42)

        # student 3 has neither submitted nor been graded

        message_text = "This is a message"
        get "/courses/#{@course.id}/gradebook2"
        open_assignment_options(2)
        f('[data-action="messageStudentsWho"]').click
        expect {
          message_form = f('#message_assignment_recipients')
          click_option('#message_assignment_recipients .message_types', "Haven't submitted yet")
          message_form.find_element(:css, '#body').send_keys(message_text)
          submit_form(message_form)
          wait_for_ajax_requests
        }.to change { ConversationMessage.count(:conversation_id) }.by(1)
      end

      it "should send messages when Scored more than X points" do
        message_text = "This is a message"
        get "/courses/#{@course.id}/gradebook2"

        open_assignment_options(1)
        f('[data-action="messageStudentsWho"]').click
        expect {
          message_form = f('#message_assignment_recipients')
          click_option('#message_assignment_recipients .message_types', 'Scored more than')
          message_form.find_element(:css, '.cutoff_score').send_keys('3') # both assignments have score of 5
          message_form.find_element(:css, '#body').send_keys(message_text)
          submit_form(message_form)
          wait_for_ajax_requests
        }.to change(ConversationMessage, :count).by_at_least(2)
      end

      it "should have a Have not been graded option" do
        # student 2 has submitted assignment 3, but it hasn't been graded
        submission = @third_assignment.submit_homework(@student_2, :body => 'student 2 submission assignment 3')
        submission.save!

        get "/courses/#{@course.id}/gradebook2"
        # set grade for first student, 3rd assignment
        # l4 because the the first two columns are part of the same grid
        edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .l4', 0)
        open_assignment_options(2)

        # expect dialog to show 1 more student with the "Haven't been graded" option
        f('[data-action="messageStudentsWho"]').click
        visible_students = ffj('.student_list li:visible')
        expect(visible_students.size).to eq 1
        expect(visible_students[0].text.strip).to eq @student_name_3
        click_option('#message_assignment_recipients .message_types', "Haven't been graded")
        visible_students = ffj('.student_list li:visible')
        expect(visible_students.size).to eq 2
        expect(visible_students[0].text.strip).to eq @student_name_2
        expect(visible_students[1].text.strip).to eq @student_name_3
      end

      it "should create separate conversations" do
        message_text = "This is a message"

        get "/courses/#{@course.id}/gradebook2"

        open_assignment_options(2)
        f('[data-action="messageStudentsWho"]').click
        expect {
          message_form = f('#message_assignment_recipients')
          message_form.find_element(:css, '#body').send_keys(message_text)
          submit_form(message_form)
          wait_for_ajax_requests
        }.to change(Conversation, :count).by_at_least(2)
      end
    end


    it "should handle multiple enrollments correctly" do
      @course.enroll_student(@student_1, :section => @other_section, :allow_multiple_enrollments => true)

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      meta_cells = find_slick_cells(0, f('.grid-canvas'))
      expect(meta_cells[0]).to include_text @course.default_section.display_name
      expect(meta_cells[0]).to include_text @other_section.display_name

      switch_to_section(@course.default_section)
      meta_cells = find_slick_cells(0, f('.grid-canvas'))
      expect(meta_cells[0]).to include_text @student_name_1

      switch_to_section(@other_section)
      meta_cells = find_slick_cells(0, f('.grid-canvas'))
      expect(meta_cells[0]).to include_text @student_name_1
    end

    it "should display for users with only :view_all_grades permissions" do
      user_logged_in

      role = custom_account_role('CustomAdmin', :account => Account.default)
      RoleOverride.create!(:role => role,
                           :permission => 'view_all_grades',
                           :context => Account.default,
                           :enabled => true)
      AccountUser.create!(:user => @user,
                          :account => Account.default,
                          :role => role)

      get "/courses/#{@course.id}/gradebook2"
      expect(flash_message_present?(:error)).to be_falsey
    end

    it "should display for users with only :manage_grades permissions" do
      user_logged_in
      role = custom_account_role('CustomAdmin', :account => Account.default)
      RoleOverride.create!(:role => role,
                           :permission => 'manage_grades',
                           :context => Account.default,
                           :enabled => true)
      AccountUser.create!(:user => @user,
                          :account => Account.default,
                          :role => role)

      get "/courses/#{@course.id}/gradebook2"
      expect(flash_message_present?(:error)).to be_falsey
    end

    it "should include student view student for grading" do
      @fake_student1 = @course.student_view_student
      @fake_student1.update_attribute :workflow_state, "deleted"
      @fake_student2 = @course.student_view_student
      @fake_student1.update_attribute :workflow_state, "registered"
      @fake_submission = @first_assignment.submit_homework(@fake_student1, :body => 'fake student submission')

      get "/courses/#{@course.id}/gradebook2"

      fakes = [@fake_student1.name, @fake_student2.name]
      expect(ff('.student-name').last(2).map(&:text)).to eq fakes

      # test students should always be last
      f('.slick-header-column').click
      expect(ff('.student-name').last(2).map(&:text)).to eq fakes
    end

    it "should not include non-graded group assignment in group total" do
      gc = group_category
      graded_assignment = @course.assignments.create!({
                                                          :title => 'group assignment 1',
                                                          :due_at => (Time.now + 1.week),
                                                          :points_possible => 10,
                                                          :submission_types => 'online_text_entry',
                                                          :assignment_group => @group,
                                                          :group_category => gc,
                                                          :grade_group_students_individually => true
                                                      })
      group_assignment = @course.assignments.create!({
                                                         :title => 'group assignment 2',
                                                         :due_at => (Time.now + 1.week),
                                                         :points_possible => 0,
                                                         :submission_types => 'not_graded',
                                                         :assignment_group => @group,
                                                         :group_category => gc,
                                                         :grade_group_students_individually => true
                                                     })
      project_group = group_assignment.group_category.groups.create!(:name => 'g1', :context => @course)
      project_group.users << @student_1
      #project_group.users << @student_2
      graded_assignment.submissions.create(:user => @student)
      graded_assignment.grade_student @student_1, :grade => 10 # 10 points possible
      group_assignment.submissions.create(:user => @student)
      group_assignment.grade_student @student_1, :grade => 2 # 0 points possible

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .assignment-group-cell .percentage')).to include_text('100%') # otherwise 108%
      expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .total-cell .percentage')).to include_text('100%') # otherwise 108%
    end

    it "should hide and show student names" do

      def toggle_hiding_students
        keep_trying_until do
          f('#gradebook_settings').click
          student_toggle = f('.student_names_toggle')
          expect(student_toggle).to be_displayed
          student_toggle.click
          true
        end
      end

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      toggle_hiding_students
      expect(fj('.student-name:visible')).to be_nil
      expect(ffj('.student-placeholder:visible').length).to be > 0

      toggle_hiding_students
      expect(ffj('.student-name:visible').length).to be > 0
      expect(fj('.student-placeholder:visible')).to be_nil
    end

    context "turnitin" do
      it "should show turnitin data" do
        s1 = @first_assignment.submit_homework(@student_1, :submission_type => 'online_text_entry', :body => 'asdf')
        s1.update_attribute :turnitin_data, {"submission_#{s1.id}" => {:similarity_score => 0.0, :web_overlap => 0.0, :publication_overlap => 0.0, :student_overlap => 0.0, :state => 'none'}}
        a = attachment_model(:context => @student_2, :content_type => 'text/plain')
        s2 = @first_assignment.submit_homework(@student_2, :submission_type => 'online_upload', :attachments => [a])
        s2.update_attribute :turnitin_data, {"attachment_#{a.id}" => {:similarity_score => 1.0, :web_overlap => 5.0, :publication_overlap => 0.0, :student_overlap => 0.0, :state => 'acceptable'}}

        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations
        icons = ffj('.gradebook-cell-turnitin')
        expect(icons.size).to eq 2

        # make sure it appears in each submission dialog
        icons.each do |icon|
          cell = icon.find_element(:xpath, '..')

          keep_trying_until do
            driver.action.move_to(f('#gradebook_settings')).move_to(cell).perform
            expect(cell.find_element(:css, "a")).to be_displayed
          end
          cell.find_element(:css, "a").click
          wait_for_ajaximations

          fj('.ui-icon-closethick:visible').click
        end
      end
    end

    context "downloading and uploading submissions" do
      it "updates the dropdown menu after downloading and processes submission uploads" do
        # Given I have a student with an uploaded submission
        a = attachment_model(:context => @student_2, :content_type => 'text/plain')
        s2 = @first_assignment.submit_homework(@student_2, :submission_type => 'online_upload', :attachments => [a])

        # When I go to the gradebook
        get "/courses/#{@course.id}/gradebook2"

        # And I click the dropdown menu on the assignment
        f('.gradebook-header-drop').click

        # And I click the download submissions button
        f('[data-action="downloadSubmissions"]').click

        # And I close the download submissions dialog
        fj("div:contains('Download Assignment Submissions'):first .ui-dialog-titlebar-close").click

        # And I click the dropdown menu on the assignment again
        f('.gradebook-header-drop').click

        # And I click the re-upload submissions link
        f('[data-action="reuploadSubmissions"]').click

        # When I attach a submissions zip file
        fixtureFile = Rails.root.join('spec/fixtures/files/submissions.zip')
        f('input[name=submissions_zip]').send_keys(fixtureFile)

        # And I upload it
        expect_new_page_load do
          fj('button:contains("Upload Files")').click
          # And I wait for the upload
          wait_for_ajax_requests
        end

        # Then I should see a message indicating the file was processed
        expect(f('#content h3')).to include_text 'Attached files to the following user submissions'
      end
    end

    it "should show late submissions" do
      get "/courses/#{@course.id}/gradebook2"
      expect(ff('.late').count).to eq 0

      @student_3_submission.write_attribute(:cached_due_date, 1.week.ago)
      @student_3_submission.save!
      get "/courses/#{@course.id}/gradebook2"

      keep_trying_until { expect(ffj('.late').count).to eq 1 }
    end

    it "should not display a speedgrader link for large courses" do
      Course.any_instance.stubs(:large_roster?).returns(true)

      get "/courses/#{@course.id}/gradebook2"

      f('.gradebook-header-drop').click
      expect(f('.gradebook-header-menu').text).not_to match(/SpeedGrader/)
    end

    context "multiple api-pages of students" do
      before do
        @page_size = 5
        Setting.set 'api_max_per_page', @page_size
      end

      def test_n_students(n)
        n.times { |i| student_in_course(:name => "student #{i+1}") }
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations
        filter_student(n)
        expect(ff('.student-name').size).to eq 1
        expect(f('.student-name').text).to eq "student #{n}"
      end

      it "should work for 2 pages" do
        test_n_students @page_size + 1
      end

      it "should work for >2 pages" do
        test_n_students @page_size * 2 + 1
      end
    end

    describe "Total points toggle" do
      def should_show_percentages
        ff(".total-column").each { |total| expect(total.text).to match /%/ }
      end

      def open_display_dialog
        f("#total_dropdown").click
        f(".toggle_percent").click
      end

      def close_display_dialog
        f(".ui-icon-closethick").click
      end

      def toggle_grade_display
        open_display_dialog
        dialog = fj('.ui-dialog:visible')
        submit_dialog(dialog, '.ui-button')
      end

      it "should warn the teacher that studens will see a change" do
        get "/courses/#{@course.id}/gradebook2"
        open_display_dialog
        dialog = fj('.ui-dialog:visible')
        expect(dialog.text).to match /Warning/
      end

      it 'should allow toggling display by points or percent' do
        should_show_percentages

        get "/courses/#{@course.id}/gradebook2"
        toggle_grade_display

        expected_points = 15, 10, 10
        ff(".total-column").each { |total|
          expect(total.text).to match /\A#{expected_points.shift}$/
        }

        toggle_grade_display
        should_show_percentages
      end

      it 'should not show the warning once dont show is checked' do
        get "/courses/#{@course.id}/gradebook2"
        open_display_dialog
        dialog = fj('.ui-dialog:visible')
        fj("#hide_warning").click
        submit_dialog(dialog, '.ui-button')

        open_display_dialog
        dialog = fj('.ui-dialog:visible')
        expect(dialog).to equal nil
      end
    end

    def header_text(n)
      f(".container_0 .slick-header-column:nth-child(#{n})").try(:text)
    end

    context "custom gradebook columns" do
      def custom_column(opts = {})
        opts.reverse_merge! title: "<b>SIS ID</b>"
        @course.custom_gradebook_columns.create! opts
      end

      it "shows custom columns" do
        hidden = custom_column title: "hidden", hidden: true
        col = custom_column
        col.update_order([col.id, hidden.id])

        col.custom_gradebook_column_data.new.tap { |d|
          d.user_id = @student_1.id
          d.content = "123456"
        }.save!

        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        expect(header_text(3)).to eq col.title
        expect(header_text(4)).not_to eq hidden.title
        expect(ff(".slick-cell.custom_column").select { |c|
          c.text == "123456"
        }.size).to eq 1
      end

      it "lets you show and hide the teacher notes column" do
        get "/courses/#{@course.id}/gradebook2"

        has_notes_column = lambda {
          ff(".container_0 .slick-header-column").any? { |h|
            h.text == "Notes"
          }
        }
        expect(has_notes_column.call).to be_falsey

        dropdown_link = f("#gradebook_settings")
        click_dropdown_option = lambda { |option|
          dropdown_link.click
          ff(".gradebook_drop_down a").find { |a|
            a.text == option
          }.click
          wait_for_ajaximations
        }
        show_notes = lambda { click_dropdown_option.("Show Notes Column") }
        hide_notes = lambda { click_dropdown_option.("Hide Notes Column") }

        # create the column
        show_notes.call
        expect(has_notes_column.call).to be_truthy

        # hide the column
        hide_notes.call
        expect(has_notes_column.call).to be_falsey

        # un-hide the column
        show_notes.call
        expect(has_notes_column.call).to be_truthy
      end
    end

    context "differentiated assignments" do
      before :each do
        @course.enable_feature!(:differentiated_assignments)
        @da_assignment = assignment_model({
          :course => @course,
          :name => 'DA assignment',
          :points_possible => @assignment_1_points,
          :submission_types => 'online_text_entry',
          :assignment_group => @group,
          :only_visible_to_overrides => true
        })
        @override = create_section_override_for_assignment(@da_assignment, course_section: @other_section)
      end

      it "should gray out cells" do
        get "/courses/#{@course.id}/gradebook"
        #student 3, assignment 4
        selector = '#gradebook_grid .container_1 .slick-row:nth-child(3) .l5'
        cell = f(selector)
        expect(cell.find_element(:css, '.gradebook-cell')).to have_class('grayed-out')
        cell.click
        expect(f(selector + ' .grade')).to be_nil
        #student 2, assignment 4 (not grayed out)
        cell = f('#gradebook_grid .container_1 .slick-row:nth-child(2) .l5')
        expect(cell.find_element(:css, '.gradebook-cell')).not_to have_class('grayed-out')
      end

      it "should gray out cells after removing a score which removes visibility" do
        selector = '#gradebook_grid .container_1 .slick-row:nth-child(1) .l5'
        @da_assignment.grade_student(@student_1, :grade => 42)
        @override.destroy
        get "/courses/#{@course.id}/gradebook"
        edit_grade(selector, '')
        wait_for_ajax_requests
        cell = f(selector)
        expect(cell.find_element(:css, '.gradebook-cell')).to have_class('grayed-out')
      end
    end
  end

  context "as an observer" do
    before (:each) do
      data_setup_as_observer
    end

    it "should allow observer to see grade totals" do
      get "/courses/#{@course.id}/grades/#{@student_2.id}"
      expect(f(".final_grade .grade")).to include_text("66.7")
      f("#only_consider_graded_assignments").click
      wait_for_ajax_requests
      expect(f(".final_grade .grade")).to include_text("12.5")
    end
  end

  describe "outcome gradebook" do
    before(:each) do
      gradebook_data_setup
    end

    it "should not be visible by default" do
      get "/courses/#{@course.id}/gradebook2"
      expect(ff('.gradebook-navigation').length).to eq 0
    end

    it "should be visible when enabled" do
      Account.default.set_feature_flag!('outcome_gradebook', 'on')
      get "/courses/#{@course.id}/gradebook2"
      expect(ff('.gradebook-navigation').length).to eq 1

      f('a[data-id=outcome]').click
      wait_for_ajaximations
      expect(f('.outcome-gradebook-container')).not_to be_nil
    end
  end

  describe "post_grades" do
    before(:each) do
      gradebook_data_setup
    end

    it "should not be visible by default" do
      get "/courses/#{@course.id}/gradebook2"
      expect(ff('.post-grades-placeholder').length).to eq 0
    end

    it "should be visible when enabled on course with sis_source_id" do
      Account.default.set_feature_flag!('post_grades', 'on')
      @course.sis_source_id = 'xyz'
      @course.save
      get "/courses/#{@course.id}/gradebook2"
      expect(ff('.post-grades-placeholder').length).to eq 1
    end

    it "should not be displayed if viewing outcome gradebook" do
      Account.default.set_feature_flag!('post_grades', 'on')
      Account.default.set_feature_flag!('outcome_gradebook', 'on')

      get "/courses/#{@course.id}/gradebook2"

      f('a[data-id=outcome]').click
      wait_for_ajaximations
      expect(f('.post-grades-placeholder')).not_to be_displayed

      f('a[data-id=assignment]').click
      wait_for_ajaximations

      expect(f('.post-grades-placeholder')).to be_displayed
    end
  end
end
