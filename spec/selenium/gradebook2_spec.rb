require File.expand_path(File.dirname(__FILE__) + "/common")

describe "gradebook2 selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  ASSIGNMENT_1_POINTS = "10"
  ASSIGNMENT_2_POINTS = "5"
  ASSIGNMENT_3_POINTS = "50"
  ATTENDANCE_POINTS = "15"


  STUDENT_NAME_1 = "nobody1@example.com"
  STUDENT_NAME_2 = "nobody2@example.com"
  STUDENT_1_TOTAL_IGNORING_UNGRADED = "100%"
  STUDENT_2_TOTAL_IGNORING_UNGRADED = "66.7%"
  STUDENT_1_TOTAL_TREATING_UNGRADED_AS_ZEROS = "18.8%"
  STUDENT_2_TOTAL_TREATING_UNGRADED_AS_ZEROS = "12.5%"
  DEFAULT_PASSWORD = "qwerty"

  def find_slick_cells(row_index, element)
    grid = element
    rows = grid.find_elements(:css, '.slick-row')
    row_cells = rows[row_index].find_elements(:css, '.slick-cell')
    row_cells
  end

  def edit_grade(cell, grade)
    grade_input = keep_trying_until do
      cell.click
      cell.find_element(:css, '.grade')
    end
    grade_input.clear
    grade_input.send_keys(grade)
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

  def open_comment_dialog
    #move_to occasionally breaks in the hudson build
    cell = driver.execute_script "return $('#gradebook_grid .slick-row:first .slick-cell:first').addClass('hover')[0]"
    cell.find_element(:css, '.gradebook-cell-comment').click
    # the dialog fetches the comments async after it displays and then innerHTMLs the whole
    # thing again once it has fetched them from the server, completely replacing it
    wait_for_ajax_requests
    find_with_jquery '.submission_details_dialog:visible'
  end

  def open_assignment_options(cell_index)
    assignment_cell = driver.find_elements(:css, '.slick-column-name')[cell_index]
    driver.action.move_to(assignment_cell).perform
    assignment_cell.find_element(:css, '.gradebook-header-drop').click
    driver.find_element(:css, '#ui-menu-1').should be_displayed
  end

  def final_score_for_row(row)
    grade_grid = driver.find_element(:css, '#gradebook_grid')
    cells = find_slick_cells(row, grade_grid)
    cells[4].text
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
        row_total = driver.find_element(:css, ".final_grade .student_#{student_id}").text
        # gradebook1 has a space between number and % like: "33.3 %"
        row_total = row_total.sub ' ', ''
        row_total.should eql expected_score
      end
    }
  end

  before(:each) do
    course_with_teacher_logged_in

    #add first student
    @student_1 = User.create!(:name => STUDENT_NAME_1)
    @student_1.register!
    @student_1.pseudonyms.create!(:unique_id => STUDENT_NAME_1, :password => DEFAULT_PASSWORD, :password_confirmation => DEFAULT_PASSWORD)

    e1 = @course.enroll_student(@student_1)
    e1.workflow_state = 'active'
    e1.save!
    @course.reload
    #add second student
    @other_section = @course.course_sections.create(:name => "the other section")
    @student_2 = User.create!(:name => STUDENT_NAME_2)
    @student_2.register!
    @student_2.pseudonyms.create!(:unique_id => STUDENT_NAME_2, :password => DEFAULT_PASSWORD, :password_confirmation => DEFAULT_PASSWORD)
    e2 = @course.enroll_student(@student_2, :section => @other_section)

    e2.workflow_state = 'active'
    e2.save!
    @course.reload

    #first assignment data
    @group = @course.assignment_groups.create!(:name => 'first assignment group')
    @assignment = assignment_model({
                                       :course => @course,
                                       :name => 'first assignment',
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

    @ungraded_assignment = @course.assignments.create! :title => 'not-graded assignment',
                                                       :submission_types => 'not_graded'

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
  end

  it "should not show 'not-graded' assignments" do
    driver.find_element(:css, '#gradebook_grid .slick-header').should_not include_text(@ungraded_assignment.title)
  end

  it "should validate correct number of students showing up in gradebook" do
    driver.find_elements(:css, '.student-name').count.should == @course.students.count
  end

  it "should allow showing only a certain section" do
    button = driver.find_element(:id, 'section_to_show')
    button.should include_text "All Sections"
    button.click
    sleep 1 #TODO find a better way to wait for css3 anmation to end
    driver.find_element(:id, 'section-to-show-menu').should be_displayed
    driver.find_element(:css, "label[for='section_option_#{@other_section.id}']").click
    button.should include_text @other_section.name

    # verify that it remembers the section to show across page loads
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    button = driver.find_element(:id, 'section_to_show')
    button.should include_text @other_section.name

    # now verify that you can set it back
    button.click
    sleep 1 #TODO find a better way to wait for css3 anmation to end
    driver.find_element(:id, 'section-to-show-menu').should be_displayed
    driver.find_element(:css, "label[for='section_option_']").click
    button.should include_text "All Sections"
  end

  it "should validate initial grade totals are correct" do
    final_score_for_row(0).should eql STUDENT_1_TOTAL_IGNORING_UNGRADED
    final_score_for_row(1).should eql STUDENT_2_TOTAL_IGNORING_UNGRADED
  end

  def toggle_muting(assignment)
    find_with_jquery(".gradebook-header-drop[data-assignment-id='#{assignment.id}']").click
    find_with_jquery('[data-action="toggleMuting"]').click
    find_with_jquery('.ui-dialog-buttonpane .ui-button:visible').click
    wait_for_ajaximations
  end

  it "should handle muting/unmuting correctly" do
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

  it "should change grades and validate course total is correct" do
    expected_edited_total = "33.3%"

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

  it "should validate that gradebook settings is displayed when button is clicked" do
    open_gradebook_settings
  end

  it "should validate row sorting works when first column is clicked" do
    first_column = driver.find_elements(:css, '.slick-column-name')[0]
    2.times do
      first_column.click
    end
    meta_cells = find_slick_cells(0, driver.find_element(:css, '.grid-canvas'))
    grade_cells = find_slick_cells(0, driver.find_element(:css, '#gradebook_grid'))

    #filter validation
    validate_cell_text(meta_cells[0], STUDENT_NAME_2 + "\n" + @other_section.name)
    validate_cell_text(grade_cells[0], ASSIGNMENT_2_POINTS)
    validate_cell_text(grade_cells[4], STUDENT_2_TOTAL_IGNORING_UNGRADED)
  end

  it "should validate setting group weights" do
    weight_num = 50.0

    driver.find_element(:id, 'gradebook_settings').click
    wait_for_animations
    driver.find_element(:css, '[aria-controls="assignment_group_weights_dialog"]').click

    dialog = driver.find_element(:id, 'assignment_group_weights_dialog')
    dialog.should be_displayed

    dialog.find_element(:css, '#group_weighting_scheme').click
    set_value(dialog.find_element(:css, '.group_weight'), weight_num)

    save_button = find_with_jquery('.ui-dialog-buttonset .ui-button:contains("Save")')
    save_button.click
    wait_for_ajax_requests
    @course.reload.group_weighting_scheme.should == 'percent'
    @group.reload.group_weight.should eql(weight_num)

    # TODO: make the header cell in the UI update to reflect new value
    # heading = find_with_jquery(".slick-column-name:contains('#{@group.name}') .assignment-points-possible")
    # heading.should include_text("#{weight_num}% of grade")
  end

  it "should validate arrange columns by due date option" do
    expected_text = "-"

    open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-4'))
    first_row_cells = find_slick_cells(0, driver.find_element(:css, '#gradebook_grid'))
    validate_cell_text(first_row_cells[0], expected_text)
  end

  it "should validate arrange columns by assignment group option" do
    open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-4'))
    open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-5'))
    first_row_cells = find_slick_cells(0, driver.find_element(:css, '#gradebook_grid'))
    validate_cell_text(first_row_cells[0], ASSIGNMENT_1_POINTS)
  end

  it "should validate show attendance columns option" do
    open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-6'))
    headers = driver.find_elements(:css, '.slick-header')
    headers[1].should include_text(@attendance_assignment.title)
    open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-6'))
  end

  it "should validate posting a comment to a graded assignment" do
    pending("opening the comment dialog frequently fails")
    comment_text = "This is a new comment!"

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

  it "should validate assignment details" do
    submissions_count = @second_assignment.submissions.count.to_s + ' submissions'

    open_assignment_options(2)
    driver.find_element(:css, '#ui-menu-1-0').click
    details_dialog = driver.find_element(:css, '#assignment-details-dialog')
    details_dialog.should be_displayed
    table_rows = driver.find_elements(:css, '#assignment-details-dialog-stats-table tr')
    table_rows[3].find_element(:css, 'td').text.should == submissions_count
  end

  it "should validate setting default grade for an assignment" do
    expected_grade = "45"

    open_assignment_options(4)
    driver.find_element(:css, '#ui-menu-1-3').click
    dialog = find_with_jquery('.ui-dialog:visible')
    dialog_form = dialog.find_element(:css, '.ui-dialog-content')
    driver.find_element(:css, '.grading_value').send_keys("45")
    dialog_form.submit
    keep_trying_until do
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.dismiss
      true
    end
    driver.switch_to.default_content
    grade_grid = driver.find_element(:css, '#gradebook_grid')
    2.times do |n|
      find_slick_cells(n, grade_grid)[2].text.should == expected_grade
    end
  end

  it "should validate send a message to students who option" do
    message_text = "This is a message"

    open_assignment_options(4)
    driver.find_element(:css, '#ui-menu-1-2').click
    expect {
      message_form = driver.find_element(:css, '#message_assignment_recipients')
      message_form.find_element(:css, '#body').send_keys(message_text)
      message_form.submit
      wait_for_ajax_requests
    }.to change(ConversationMessage, :count).by(2)
  end

  it "should validate curving grades option" do
    curved_grade_text = "8"

    open_assignment_options(2)
    driver.find_element(:css, '#ui-menu-1-4').click
    curve_form = driver.find_element(:css, '#curve_grade_dialog')
    set_value(curve_form.find_element(:css, '#middle_score'), curved_grade_text)
    curve_form.submit
    keep_trying_until do
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.dismiss
      true
    end
    driver.switch_to.default_content
    find_slick_cells(1, driver.find_element(:css, '#gradebook_grid'))[0].text.should == curved_grade_text
  end
end
