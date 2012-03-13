require File.expand_path(File.dirname(__FILE__) + "/common")

describe "gradebook2" do
  it_should_behave_like "in-process server selenium tests"

  def set_default_grade(cell_index, points = "5")
    open_assignment_options(cell_index)
    driver.find_element(:css, '#ui-menu-1-3').click
    dialog = find_with_jquery('.ui-dialog:visible')
    dialog_form = dialog.find_element(:css, '.ui-dialog-content')
    driver.find_element(:css, '.grading_value').send_keys(points)
    dialog_form.submit
    keep_trying_until do
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.dismiss
      true
    end
    driver.switch_to.default_content
  end

  def open_assignment_options(cell_index)
    assignment_cell = driver.find_elements(:css, '#gradebook_grid .slick-header-column')[cell_index]
    driver.action.move_to(assignment_cell).perform
    assignment_cell.find_element(:css, '.gradebook-header-drop').click
    driver.find_element(:css, '#ui-menu-1').should be_displayed
  end

  def find_slick_cells(row_index, element)
    grid = element
    rows = grid.find_elements(:css, '.slick-row')
    row_cells = rows[row_index].find_elements(:css, '.slick-cell')
    row_cells
  end

  context "gradebook2" do

    ASSIGNMENT_1_POINTS = "10"
    ASSIGNMENT_2_POINTS = "5"
    ASSIGNMENT_3_POINTS = "50"
    ATTENDANCE_POINTS = "15"

    STUDENT_NAME_1 = "Zoey Anteater"
    STUDENT_NAME_2 = "Arnold Zebra"
    STUDENT_SORTABLE_NAME_1 = "Anteater, Zoey"
    STUDENT_SORTABLE_NAME_2 = "Zebra, Arnold"
    STUDENT_1_TOTAL_IGNORING_UNGRADED = "100%"
    STUDENT_2_TOTAL_IGNORING_UNGRADED = "66.7%"
    STUDENT_1_TOTAL_TREATING_UNGRADED_AS_ZEROS = "18.8%"
    STUDENT_2_TOTAL_TREATING_UNGRADED_AS_ZEROS = "12.5%"
    DEFAULT_PASSWORD = "qwerty"

    def edit_grade(cell, grade)
      grade_input = keep_trying_until do
        cell.click
        cell.find_element(:css, '.grade')
      end
      set_value(grade_input, grade)
      grade_input.send_keys(:return)
      wait_for_ajax_requests
    end

    def validate_cell_text(cell, text)
      cell.text.should == text
      cell.text
    end

    def open_gradebook_settings(element_to_click = nil)
      driver.find_element(:css, '#gradebook_settings').click
      driver.find_element(:css, '#ui-menu-0').should be_displayed
      element_to_click.click if element_to_click != nil
    end

    def open_comment_dialog(x=0, y=0)
      #move_to occasionally breaks in the hudson build
      cell = driver.execute_script "return $('#gradebook_grid .slick-row:nth-child(#{y+1}) .slick-cell:nth-child(#{x+1})').addClass('hover')[0]"
      cell.find_element(:css, '.gradebook-cell-comment').click
      # the dialog fetches the comments async after it displays and then innerHTMLs the whole
      # thing again once it has fetched them from the server, completely replacing it
      wait_for_ajax_requests
      find_with_jquery '.submission_details_dialog:visible'
    end

    def final_score_for_row(row)
      grade_grid = driver.find_element(:css, '#gradebook_grid')
      cells = find_slick_cells(row, grade_grid)
      cells[4].find_element(:css, '.percentage').text
    end

    def switch_to_section(section=nil)
      section = section.id if section.is_a?(CourseSection)
      section ||= ""
      button = driver.find_element(:id, 'section_to_show')
      button.click
      sleep 1 #TODO find a better way to wait for css3 anmation to end
      driver.find_element(:id, 'section-to-show-menu').should be_displayed
      driver.find_element(:css, "label[for='section_option_#{section}']").click
    end

    # `students` should be a hash of student_id, expected total pairs, like:
    # {
    #   1 => '12%',
    #   3 => '86.7%',
    # }
    def check_gradebook_1_totals(students)
      get "/courses/#{@course.id}/gradebook"
      # this keep_trying_untill is there because gradebook1 loads it's cells in a bunch of setTimeouts
      keep_trying_until {
        students.each do |student_id, expected_score|
          row_total = driver.find_element(:css, ".final_grade .student_#{student_id} .grade").text + '%'
          row_total.should eql expected_score
        end
      }
    end

    def conclude_and_unconclude_course
      #conclude course
      @course.complete!
      @user.reload
      @user.cached_current_enrollments(:reload)
      @enrollment.reload

      #un-conclude course
      @enrollment.workflow_state = 'active'
      @enrollment.save!
      @course.reload
    end

    before (:each) do
      course_with_teacher_logged_in
      @course.grading_standard_enabled = true
      @course.save!
      @course.reload

      #add first student
      @student_1 = User.create!(:name => STUDENT_NAME_1)

      @student_1.register!
      @student_1.pseudonyms.create!(:unique_id => "nobody1@example.com", :password => DEFAULT_PASSWORD, :password_confirmation => DEFAULT_PASSWORD)

      e1 = @course.enroll_student(@student_1)
      e1.workflow_state = 'active'
      e1.save!
      @course.reload
      #add second student
      @other_section = @course.course_sections.create(:name => "the other section")
      @student_2 = User.create!(:name => STUDENT_NAME_2)
      @student_2.register!
      @student_2.pseudonyms.create!(:unique_id => "nobody2@example.com", :password => DEFAULT_PASSWORD, :password_confirmation => DEFAULT_PASSWORD)
      e2 = @course.enroll_student(@student_2, :section => @other_section)

      e2.workflow_state = 'active'
      e2.save!
      @course.reload

      #first assignment data
      @group = @course.assignment_groups.create!(:name => 'first assignment group', :group_weight => 100)
      @first_assignment = assignment_model({
        :course => @course,
        :name => 'A name that would not reasonably fit in the header cell which should have some limit set',
        :due_at => nil,
        :points_possible => ASSIGNMENT_1_POINTS,
        :submission_types => 'online_text_entry',
        :assignment_group => @group
      })
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      @submission = @assignment.submit_homework(@student_1, :body => 'student 1 submission assignment 1')
      @assignment.grade_student(@student_1, :grade => 10)
      @submission.score = 10
      @submission.save!

      #second student submission for assignment 1
      @student_2_submission = @assignment.submit_homework(@student_2, :body => 'student 2 submission assignment 1')
      @assignment.grade_student(@student_2, :grade => 5)
      @student_2_submission.score = 5
      @submission.save!

      #second assignment data
      @second_assignment = assignment_model({
        :course => @course,
        :name => 'second assignment',
        :due_at => nil,
        :points_possible => ASSIGNMENT_2_POINTS,
        :submission_types => 'online_text_entry',
        :assignment_group => @group
      })
      @second_association = @rubric.associate_with(@second_assignment, @course, :purpose => 'grading')

      #student 1 submission for assignment 2
      @second_submission = @second_assignment.submit_homework(@student_1, :body => 'student 1 submission assignment 2')
      @second_assignment.grade_student(@student_1, :grade => 5)
      @second_submission.save!

      #student 2 submission for assignment 2
      @second_submission = @second_assignment.submit_homework(@student_2, :body => 'student 2 submission assignment 2')
      @second_assignment.grade_student(@student_2, :grade => 5)
      @second_submission.save!

      #third assignment data
      due_date = Time.now + 1.days
      @third_assignment = assignment_model({
        :course => @course,
        :name => 'assignment three',
        :due_at => due_date,
        :points_possible => ASSIGNMENT_3_POINTS,
        :submission_types => 'online_text_entry',
        :assignment_group => @group
      })
      @third_association = @rubric.associate_with(@third_assignment, @course, :purpose => 'grading')

      #attendance assignment
      @attendance_assignment = assignment_model({
        :course => @course,
        :name => 'attendance assignment',
        :title => 'attendance assignment',
        :due_at => nil,
        :points_possible => ATTENDANCE_POINTS,
        :submission_types => 'attendance',
        :assignment_group => @group,
      })

      @ungraded_assignment = @course.assignments.create!(
        :title => 'not-graded assignment',
        :submission_types => 'not_graded',
        :assignment_group => @group)
    end

    describe "assignment column headers" do
      before do
        @assignment = @course.assignments.first
        @header_selector = %([id$="assignment_#{@assignment.id}"])
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations
      end

      it "should minimize a column and remember it" do
        pending("dragging and dropping these dont actually work in selenium")
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations
        first_dragger, second_dragger = driver.find_elements(:css, '#gradebook_grid .slick-resizable-handle')
        driver.action.drag_and_drop(second_dragger, first_dragger).perform
      end

      it "should have a tooltip with the assignment name" do
        f(@header_selector)["title"].should eql @assignment.title
      end

      it "should handle a ton of assignments without wrapping the slick-header" do
        100.times do
          @course.assignments.create! :title => 'a really long assignment name, o look how long I am this is so cool'
        end
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations
        # being 38px high means it did not wrap
        driver.execute_script('return $("#gradebook_grid .slick-header-columns").height()').should eql 38
      end

      it "should validate row sorting works when first column is clicked" do
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        first_column = driver.find_elements(:css, '.slick-column-name')[0]
        2.times do
          first_column.click
        end
        meta_cells = find_slick_cells(0, driver.find_element(:css, '.grid-canvas'))
        grade_cells = find_slick_cells(0, driver.find_element(:css, '#gradebook_grid'))

        #filter validation
        validate_cell_text(meta_cells[0], STUDENT_NAME_2 + "\n" + @other_section.name)
        validate_cell_text(grade_cells[0], ASSIGNMENT_2_POINTS)
        validate_cell_text(grade_cells[4].find_element(:css, '.percentage'), STUDENT_2_TOTAL_IGNORING_UNGRADED)
      end

      it "should validate arrange columns by due date option" do
        expected_text = "-"

        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-4'))
        first_row_cells = find_slick_cells(0, driver.find_element(:css, '#gradebook_grid'))
        validate_cell_text(first_row_cells[0], expected_text)
      end

      it "should validate arrange columns by assignment group option" do
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-4'))
        open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-5'))
        first_row_cells = find_slick_cells(0, driver.find_element(:css, '#gradebook_grid'))
        validate_cell_text(first_row_cells[0], ASSIGNMENT_1_POINTS)
      end

      it "should validate show attendance columns option" do
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-6'))
        headers = driver.find_elements(:css, '.slick-header')
        headers[1].should include_text(@attendance_assignment.title)
        open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-6'))
      end

      it "show letter grade in total column" do
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations
        driver.find_element(:css, '#gradebook_grid [row="0"] .total-cell .letter-grade-points').should include_text("A")
        edit_grade(driver.find_element(:css, '#gradebook_grid [row="1"] .l2'), '50')
        wait_for_ajax_requests
        driver.find_element(:css, '#gradebook_grid [row="1"] .total-cell .letter-grade-points').should include_text("A")
      end
    end

    it "should not show 'not-graded' assignments" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      driver.find_element(:css, '.slick-header-columns').should_not include_text(@ungraded_assignment.title)
    end

    it "should not show 'not-graded' assignments" do
      driver.find_element(:css, '#gradebook_grid .slick-header').should_not include_text(@ungraded_assignment.title)
    end

    it "should notify user that no updates are made if default grade assignment doesn't change anything" do
      get "/courses/#{@course.id}/gradebook2"

      ##
      # borrowed this code from set_default_grade method. not calling it directly because
      # we need to assert the content of the alert box.
      open_assignment_options(0)
      driver.find_element(:css, '#ui-menu-1-3').click
      dialog = find_with_jquery('.ui-dialog:visible')
      dialog_form = dialog.find_element(:css, '.ui-dialog-content')
      driver.find_element(:css, '.grading_value').send_keys(5)
      dialog_form.submit
      keep_trying_until do
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.text.should eql 'None to Update'
        driver.switch_to.alert.dismiss
        true
      end
      driver.switch_to.default_content
    end

    it "should not update default grades for users not in this section" do
      # create new user and section

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      driver.execute_script "$('#section_option_#{@other_section.id}').click()"

      set_default_grade(2, 13)
      @other_section.users.each { |u| u.submissions.map(&:grade).should include '13' }
      @course.default_section.users.each { |u| u.submissions.map(&:grade).should_not include '13' }
    end

    it "should validate correct number of students showing up in gradebook" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      driver.find_elements(:css, '.student-name').count.should == @course.students.count
    end

    it "should not show concluded enrollments" do
      conclude_and_unconclude_course
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      driver.find_elements(:css, '.student-name').count.should == @course.students.count
    end

    it "should show students sorted by their sortable_name" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      dom_names = driver.find_elements(:css, '.student-name').map(&:text)
      dom_names.should == [STUDENT_NAME_1, STUDENT_NAME_2]
    end

    it "should not show student avatars until they are enabled" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      driver.find_elements(:css, '.student-name').length.should == 2
      driver.find_elements(:css, '.avatar img').length.should == 0

      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      @account.service_enabled?(:avatars).should be_true
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      driver.find_elements(:css, '.student-name').length.should == 2
      driver.find_elements(:css, '.avatar img').length.should == 2
    end

    it "should link to a student's grades page" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      els = driver.find_elements(:css, '.student-name')
      els.map { |e| URI.parse(e.find_element(:css, 'a').attribute('href')).path }.should == [
          "/courses/#{@course.id}/grades/#{@student_1.id}",
          "/courses/#{@course.id}/grades/#{@student_2.id}",
      ]
    end

    it "should allow showing only a certain section" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      button = driver.find_element(:id, 'section_to_show')
      button.should include_text "All Sections"
      switch_to_section(@other_section)
      button.should include_text @other_section.name

      # verify that it remembers the section to show across page loads
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      button = driver.find_element(:id, 'section_to_show')
      button.should include_text @other_section.name

      # now verify that you can set it back
      switch_to_section()
      button.should include_text "All Sections"
    end

    it "should validate initial grade totals are correct" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      final_score_for_row(0).should eql STUDENT_1_TOTAL_IGNORING_UNGRADED
      final_score_for_row(1).should eql STUDENT_2_TOTAL_IGNORING_UNGRADED
    end

    it "should not factor non graded assignments into group total" do
      pending("bug 7558 - Non-Graded Assignments are being factored in the Assignment Group's total") do
        expected_totals = [STUDENT_1_TOTAL_IGNORING_UNGRADED, STUDENT_2_TOTAL_IGNORING_UNGRADED]
        ungraded_submission = @ungraded_assignment.submit_homework(@student_1, :body => 'student 1 submission ungraded assignment')
        @ungraded_assignment.grade_student(@student_1, :grade => 20)
        ungraded_submission.save!
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        assignment_group_cells = driver.find_elements(:css, '.assignment-group-cell')
        assignment_group_cells.each_with_index do |agc, i|
          validate_cell_text(agc, expected_totals[i])
        end
      end
    end

    def toggle_muting(assignment)
      find_with_jquery(".gradebook-header-drop[data-assignment-id='#{assignment.id}']").click
      find_with_jquery('[data-action="toggleMuting"]').click
      find_with_jquery('.ui-dialog-buttonpane .ui-button:visible').click
      wait_for_ajaximations
    end

    it "should handle muting/unmuting correctly" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      toggle_muting(@second_assignment)
      find_with_jquery(".slick-header-column[id*='assignment_#{@second_assignment.id}'] .muted").should be_displayed
      @second_assignment.reload.should be_muted

      # reload the page and make sure it remembered the setting
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      find_with_jquery(".slick-header-column[id*='assignment_#{@second_assignment.id}'] .muted").should be_displayed

      # make sure you can un-mute
      toggle_muting(@second_assignment)
      find_with_jquery(".slick-header-column[id*='assignment_#{@second_assignment.id}'] .muted").should be_nil
      @second_assignment.reload.should_not be_muted
    end

    it "should treat ungraded as 0's when asked, and ignore when not" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      # make sure it shows like it is not treating ungraded as 0's by default
      is_checked('#include_ungraded_assignments').should be_false
      final_score_for_row(0).should eql STUDENT_1_TOTAL_IGNORING_UNGRADED
      final_score_for_row(1).should eql STUDENT_2_TOTAL_IGNORING_UNGRADED

      # set the "treat ungraded as 0's" option in the header
      open_gradebook_settings(driver.find_element(:css, 'label[for="include_ungraded_assignments"]'))

      # now make sure that the grades show as if those ungraded assignments had a '0'
      is_checked('#include_ungraded_assignments').should be_true
      final_score_for_row(0).should eql STUDENT_1_TOTAL_TREATING_UNGRADED_AS_ZEROS
      final_score_for_row(1).should eql STUDENT_2_TOTAL_TREATING_UNGRADED_AS_ZEROS

      # reload the page and make sure it remembered the setting
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      is_checked('#include_ungraded_assignments').should be_true
      final_score_for_row(0).should eql STUDENT_1_TOTAL_TREATING_UNGRADED_AS_ZEROS
      final_score_for_row(1).should eql STUDENT_2_TOTAL_TREATING_UNGRADED_AS_ZEROS

      # NOTE: gradebook1 does not handle 'remembering' the `include_ungraded_assignments` setting

      # clear our saved settings
      driver.execute_script '$.store.clear();'
    end

    it "should allow setting a letter grade on a no-points assignment" do
      assignment_model(:course => @course, :grading_type => 'letter_grade', :points_possible => nil, :title => 'no-points')
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      edit_grade(driver.find_element(:css, '#gradebook_grid [row="0"] .l3'), 'A-')
      wait_for_ajax_requests
      driver.find_element(:css, '#gradebook_grid [row="0"] .l3').text.should == 'A-'
      @assignment.submissions.size.should == 1
      sub = @assignment.submissions.first
      sub.grade.should == 'A-'
      sub.score.should == 0.0
    end

    it "should change grades and validate course total is correct" do
      expected_edited_total = "33.3%"

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      #editing grade for first row, first cell
      edit_grade(driver.find_element(:css, '#gradebook_grid [row="0"] .l0'), 0)

      #editing grade for second row, first cell
      edit_grade(driver.find_element(:css, '#gradebook_grid [row="1"] .l0'), 0)

      #refresh page and make sure the grade sticks
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      final_score_for_row(0).should eql expected_edited_total
      final_score_for_row(1).should eql expected_edited_total

      #go back to gradebook1 and compare to make sure they match
      check_gradebook_1_totals({
                                   @student_1.id => expected_edited_total,
                                   @student_2.id => expected_edited_total
                               })
    end

    it "should edit a grade, move to the next cell and validate focus is not lost" do
      pending('bug 7375 - server response causes active cell in same row to loose focus') do
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        first_cell = driver.find_element(:css, '#gradebook_grid [row="0"] .l0')
        grade_input = keep_trying_until do
          first_cell.click
          first_cell.find_element(:css, '.grade')
        end
        set_value(grade_input, 3)
        first_cell.send_keys(:tab)
        wait_for_ajax_requests
        driver.find_element(:css, '#gradebook_grid [row="0"] .l1').should have_class('editable')
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
      wait_for_ajaximations

      dialog = open_comment_dialog
      set_value(dialog.find_element(:id, "add_a_comment"), comment_text)
      driver.find_element(:css, "form.submission_details_add_comment_form.clearfix > button.button").click
      wait_for_ajaximations

      #make sure it is still there if you reload the page
      refresh_page
      wait_for_ajaximations

      comment = open_comment_dialog.find_element(:css, '.comment')
      comment.should include_text(comment_text)
    end

    it "should let you post a group comment to a group assignment" do
      group_assignment = assignment_model({
                                              :course => @course,
                                              :name => 'group assignment',
                                              :due_at => (Time.now + 1.week),
                                              :points_possible => ASSIGNMENT_3_POINTS,
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
      wait_for_ajaximations

      dialog = open_comment_dialog(3)
      set_value(dialog.find_element(:id, "add_a_comment"), comment_text)
      dialog.find_element(:id, "group_comment").click
      driver.find_element(:css, "form.submission_details_add_comment_form.clearfix > button.button").click
      wait_for_ajaximations

      #make sure it's on the other student's submission
      comment = open_comment_dialog(3, 1).find_element(:css, '.comment')
      comment.should include_text(comment_text)
    end

    it "should validate assignment details" do
      submissions_count = @second_assignment.submissions.count.to_s + ' submissions'

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      open_assignment_options(1)
      driver.find_element(:css, '#ui-menu-1-0').click
      wait_for_ajaximations
      details_dialog = driver.find_element(:css, '#assignment-details-dialog')
      details_dialog.should be_displayed
      table_rows = driver.find_elements(:css, '#assignment-details-dialog-stats-table tr')
      table_rows[3].find_element(:css, 'td').text.should == submissions_count
    end

    it "should not throw an error when setting the default grade when concluded enrollments exist" do
      pending("bug 7413 - Error assigning default grade for all students when one student's enrollment has been concluded.") do
        conclude_and_unconclude_course
        3.times { student_in_course }

        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        #TODO - when show concluded enrollments fix goes in we probably have to add that code right here
        #for the test to work correctly

        set_default_grade(2, 5)
        grade_grid = driver.find_element(:css, '#gradebook_grid')
        @course.student_enrollments.each_with_index do |e, n|
          next if e.completed?
          find_slick_cells(n, grade_grid)[2].text.should == 5
        end
      end
    end

    describe "message students who" do
      it "should send messages" do
        message_text = "This is a message"

        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        open_assignment_options(2)
        driver.find_element(:css, '#ui-menu-1-2').click
        expect {
          message_form = driver.find_element(:css, '#message_assignment_recipients')
          message_form.find_element(:css, '#body').send_keys(message_text)
          message_form.submit
          wait_for_ajax_requests
        }.to change(ConversationMessage, :count).by(2)
      end

      it "should have a 'Haven't been graded' option" do
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations
        # set grade for first student, 3rd assignment
        edit_grade(driver.find_element(:css, '#gradebook_grid [row="0"] .l2'), 0)
        open_assignment_options(2)

        # expect dialog to show 1 fewer student with the "Haven't been graded" option
        driver.find_element(:css, '#ui-menu-1-2').click
        find_all_with_jquery('.student_list li:visible').size.should eql 2
        # select option
        select = driver.find_element(:css, '#message_assignment_recipients select.message_types')
        select.click
        select.all(:tag_name => 'option').find { |o| o.text == "Haven't been graded" }.click
        find_all_with_jquery('.student_list li:visible').size.should eql 1
      end
    end

    it "should validate curving grades option" do
      curved_grade_text = "8"

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      open_assignment_options(0)
      driver.find_element(:css, '#ui-menu-1-4').click
      curve_form = driver.find_element(:css, '#curve_grade_dialog')
      set_value(curve_form.find_element(:css, '#middle_score'), curved_grade_text)
      find_with_jquery('.ui-dialog-buttonset .ui-button:contains("Curve Grades")').click
      keep_trying_until do
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.dismiss
        true
      end
      driver.switch_to.default_content
      find_slick_cells(1, driver.find_element(:css, '#gradebook_grid'))[0].text.should == curved_grade_text
    end

    it "should handle multiple enrollments correctly" do
      @course.enroll_student(@student_1, :section => @other_section, :allow_multiple_enrollments => true)

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      meta_cells = find_slick_cells(0, driver.find_element(:css, '.grid-canvas'))
      meta_cells[0].should include_text @course.default_section.display_name
      meta_cells[0].should include_text @other_section.display_name

      switch_to_section(@course.default_section)
      meta_cells = find_slick_cells(0, driver.find_element(:css, '.grid-canvas'))
      meta_cells[0].should include_text STUDENT_NAME_1

      switch_to_section(@other_section)
      meta_cells = find_slick_cells(0, driver.find_element(:css, '.grid-canvas'))
      meta_cells[0].should include_text STUDENT_NAME_1
    end

    it "should update a graded quiz and have the points carry over to the quiz attempts page" do
      points = 50
      q = factory_with_protected_attributes(@course.quizzes, :title => "new quiz", :points_possible => points, :quiz_type => 'assignment', :workflow_state => 'available')
      q.save!
      qs = q.generate_submission(@student_1)
      qs.grade_submission
      q.reload

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      edit_grade(driver.find_element(:css, '#gradebook_grid [row="0"] .l3'), points.to_s)

      get "/courses/#{@course.id}/quizzes/#{q.id}/history?quiz_submission_id=#{qs.id}"
      driver.find_element(:css, '.score_value').text.should == points.to_s
      driver.find_element(:id, 'after_fudge_points_total').text.should == points.to_s
    end

    it "should validate setting default grade for an assignment" do
      expected_grade = "45"

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      set_default_grade(2, expected_grade)
      grade_grid = driver.find_element(:css, '#gradebook_grid')
      StudentEnrollment.count.times do |n|
        find_slick_cells(n, grade_grid)[2].text.should == expected_grade
      end
    end

    it "should correctly set default grades for a specific section" do
      pending('bug 7540 - Setting default grade for one section changes it for all ') do
        def open_section_menu_and_click(menu_item_css)
          driver.find_element(:id, 'section_to_show').click
          section_menu = driver.find_element(:id, 'section-to-show-menu')
          section_menu.should be_displayed
          section_menu.find_element(:css, menu_item_css).click
        end

        expected_grade = "45"
        gradebook_row_1 = '#gradebook_grid [row="1"]'
        get "/courses/#{@course.id}/gradebook2"
        wait_for_ajaximations

        open_section_menu_and_click('#section-to-show-menu-1')
        set_default_grade(2, expected_grade)
        open_section_menu_and_click('#section-to-show-menu-0')
        driver.find_element(:css, gradebook_row_1).should be_displayed
        validate_cell_text(driver.find_element(:css, "#{gradebook_row_1} .r2"), '-')
      end
    end

    it "should include student view student for grading" do
      @fake_student = @course.student_view_student
      @fake_submission = @first_assignment.submit_homework(@fake_student, :body => 'fake student submission')

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      ff('.student-name').map(&:text).join(" ").should match @fake_student.name
    end
  end

  context "group weights" do

    def get_group_points
      group_points_holder = keep_trying_until do
        group_points_holder = driver.find_elements(:css, 'div.assignment-points-possible')
        group_points_holder
      end
      group_points_holder
    end

    def check_group_points(expected_weight_text)
      for i in 2..3 do
        get_group_points[i].text.should == expected_weight_text + ' of grade'
      end
    end

    def set_group_weight(assignment_group, weight_number)
      driver.find_element(:id, 'gradebook_settings').click
      wait_for_animations
      driver.find_element(:css, '[aria-controls="assignment_group_weights_dialog"]').click

      dialog = driver.find_element(:id, 'assignment_group_weights_dialog')
      dialog.should be_displayed

      group_check = dialog.find_element(:id, 'group_weighting_scheme')
      keep_trying_until do
        group_check.click
        is_checked('#group_weighting_scheme').should be_true
      end
      group_weight_input = driver.find_element(:id, "assignment_group_#{assignment_group.id}_weight")
      set_value(group_weight_input, weight_number)
      save_button = find_with_jquery('.ui-dialog-buttonset .ui-button:contains("Save")')
      save_button.click
      wait_for_ajaximations
      @course.reload.group_weighting_scheme.should == 'percent'
    end

    def validate_group_weight_text(assignment_groups, weight_numbers)
      assignment_groups.each_with_index do |ag, i|
        heading = find_with_jquery(".slick-column-name:contains('#{ag.name}') .assignment-points-possible")
        heading.should include_text("#{weight_numbers[i]}% of grade")
      end
    end

    def validate_group_weight(assignment_group, weight_number)
      assignment_group.reload.group_weight.should == weight_number
    end

    before (:each) do
      course_with_teacher_logged_in
      student_in_course
      @course.update_attributes(:group_weighting_scheme => 'percent')
      @group1 = @course.assignment_groups.create!(:name => 'first assignment group', :group_weight => 50)
      @group2 = @course.assignment_groups.create!(:name => 'second assignment group', :group_weight => 50)
      @assignment1 = assignment_model({
                                          :course => @course,
                                          :name => 'first assignment',
                                          :due_at => Date.today,
                                          :points_possible => 50,
                                          :submission_types => 'online_text_entry',
                                          :assignment_group => @group1
                                      })
      @assignment2 = assignment_model({
                                          :course => @course,
                                          :name => 'second assignment',
                                          :due_at => Date.today,
                                          :points_possible => 10,
                                          :submission_types => 'online_text_entry',
                                          :assignment_group => @group2
                                      })
      @course.reload
    end

    it "should validate setting group weights" do
      weight_numbers = [26.0, 73.5]

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      group_1 = AssignmentGroup.find_by_name(@group1.name)
      group_2 = AssignmentGroup.find_by_name(@group2.name)

      #set and check the group weight of the first assignment group
      set_group_weight(group_1, weight_numbers[0])
      validate_group_weight(group_1, weight_numbers[0])

      #set and check the group weight of the first assignment group
      set_group_weight(group_2, weight_numbers[1])
      validate_group_weight(group_2, weight_numbers[1])

      # TODO: make the header cell in the UI update to reflect new value
      # validate_group_weight_text(AssignmentGroup.all, weight_numbers)
    end

    it "should display group weights correctly when set on assignment groups" do
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      check_group_points('50%')
    end

    it "should display group weights correctly when unsetting group weights through assignments page" do
      pending("bug 7435 - Gradebook2 keeps weighted assignment groups, even when turned off") do
        get "/courses/#{@course.id}/assignments"

        driver.find_element(:id, 'class_weighting_policy').click
        wait_for_ajaximations
        check_group_points('0%')
      end
    end
  end
end
