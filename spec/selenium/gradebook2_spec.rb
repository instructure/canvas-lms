require File.expand_path(File.dirname(__FILE__) + "/common")

describe "gradebook2 selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  ASSIGNMENT_1_POINTS = "10"
  ASSIGNMENT_2_POINTS = "5"
  ASSIGNMENT_3_POINTS = "50"
  ATTENDANCE_POINTS = "15"

  EXPECTED_ASSIGN_1_TOTAL = "100%"
  EXPECTED_ASSIGN_2_TOTAL = "67%"

  STUDENT_NAME_1 = "nobody1@example.com"
  STUDENT_NAME_2 = "nobody2@example.com"
  DEFAULT_PASSWORD = "qwerty"

  def find_slick_cells(row_index, element)
    grid = element
    rows = grid.find_elements(:css, '.slick-row')
    row_cells = rows[row_index].find_elements(:css, '.slick-cell')
    row_cells
  end

  def edit_grade(cell, grade)
    cell.click
    grade_input = cell.find_element(:css, '.grade')
    grade_input.clear
    grade_input.send_keys(grade)
    grade_input.send_keys(:return)
    wait_for_ajax_requests
  end

  def validate_cell_text(cell, text)
    cell.text.should == text
    cell.text
  end

  def open_gradebook_settings(element_to_click)
    driver.find_element(:css, '#gradebook_settings').click
    driver.find_element(:css, '#ui-menu-0').should be_displayed
    element_to_click.click if element_to_click != nil
  end

  def open_comment_dialog(jquery_selector = "first")
    driver.execute_script("$('.gradebook-cell:"+jquery_selector+"').mouseenter()") #move_to occasionally breaks in the hudson build
    comment = keep_trying_until do
      comment = find_with_jquery('.gradebook-cell-comment:visible')
      comment.should be_displayed
      comment
    end
    comment.click
    details_dialog = find_with_jquery('.ui-dialog:visible')
    keep_trying_until { driver.find_element(:id, "add_a_comment").should be_displayed }
    wait_for_ajax_requests
    details_dialog
  end

  def open_assignment_options(cell_index)
    assignment_cell = driver.find_elements(:css, '.slick-column-name')[cell_index]
    driver.action.move_to(assignment_cell).perform
    assignment_cell.find_element(:css, '.gradebook-header-drop').click
    driver.find_element(:css, '#ui-menu-1').should be_displayed
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
    @student_2 = User.create!(:name => STUDENT_NAME_2)
    @student_2.register!
    @student_2.pseudonyms.create!(:unique_id => STUDENT_NAME_2, :password => DEFAULT_PASSWORD, :password_confirmation => DEFAULT_PASSWORD)

    e2 = @course.enroll_student(@student_2)
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

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
  end

  it "should validate correct number of students showing up in gradebook" do
    driver.find_elements(:css, '.student-name').count.should == @course.students.count
  end

  it "should validate initial grade totals are correct" do
    grade_grid = driver.find_element(:css, '#gradebook_grid')
    first_row_cells = find_slick_cells(0, grade_grid)
    second_row_cells = find_slick_cells(1, grade_grid)

    #validating first student initial total
    validate_cell_text(first_row_cells[4], EXPECTED_ASSIGN_1_TOTAL)

    #validating second student initial total
    validate_cell_text(second_row_cells[4], EXPECTED_ASSIGN_2_TOTAL)
  end

  it "should change grades and validate course total is correct" do
    pending("Bug in gradebook2 with grade rounding, gradebook1 shows 33.3% gradebook2 shows 33%")
    expected_edited_total = "33.3%"
    grade_grid = driver.find_element(:css, '#gradebook_grid')
    first_row_cells = find_slick_cells(0, grade_grid)
    second_row_cells = find_slick_cells(1, grade_grid)

    #editing grade for first row, first cell
    edit_grade(first_row_cells[0], 0)

    #editing grade for second row, first cell
    edit_grade(second_row_cells[0], 0)

    #page refresh
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    #total validation after page refresh
    grade_grid = driver.find_element(:css, '#gradebook_grid')
    first_row_cells = find_slick_cells(0, grade_grid)
    second_row_cells = find_slick_cells(1, grade_grid)
    first_row_total = validate_cell_text(first_row_cells[4], expected_edited_total)
    second_row_total = validate_cell_text(second_row_cells[4], expected_edited_total)

    #go back to grade book one get those total values and compare to make sure they match
    expect_new_page_load { driver.find_element(:css, '#change_gradebook_version_link_holder > a').click }
    wait_for_ajax_requests
    first_row_total.should == find_with_jquery(".assignment_final-grade > span:nth-child(1)").text
    second_row_total.should == find_with_jquery(".assignment_final-grade > span:nth-child(2)").text
  end

  it "should validate that gradebook settings is displayed when button is clicked" do
    open_gradebook_settings(nil)
  end

  it "should validate row sorting works when first column is clicked" do
    first_column = driver.find_elements(:css, '.slick-column-name')[0]
    2.times do
      first_column.click
    end
    meta_cells = find_slick_cells(0, driver.find_element(:css, '.grid-canvas'))
    grade_cells = find_slick_cells(0, driver.find_element(:css, '#gradebook_grid'))

    #filter validation
    validate_cell_text(meta_cells[0], STUDENT_NAME_2)
    validate_cell_text(grade_cells[0], ASSIGNMENT_2_POINTS)
    validate_cell_text(grade_cells[4], EXPECTED_ASSIGN_2_TOTAL)
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

  it "should validate include ungraded assignments option" do
    pending("new changes broke this link, clicking include ungraded assignments doesn't make grade totals change anymore'")
    expected_total_row_1 = "19%"
    expected_total_row_2 = "13%"
    open_gradebook_settings(driver.find_element(:css, '#ui-menu-0-7'))
    grade_grid = driver.find_element(:css, '#gradebook_grid')
    first_row_cells = find_slick_cells(0, grade_grid)
    second_row_cells = find_slick_cells(1, grade_grid)

    #validating first student total after ungraded option click
    validate_cell_text(first_row_cells[4], expected_total_row_1)

    #validating second student total after ungraded option click
    validate_cell_text(second_row_cells[4], expected_total_row_2)
  end

  it "should validate posting a comment to a graded assignment" do
    comment_text = "This is a new comment!"

    open_comment_dialog
    comment_box = find_with_jquery("#add_a_comment")
    comment_box.clear
    comment_box.send_keys(comment_text)
    driver.find_element(:css, "form.submission_details_add_comment_form.clearfix > button.button").click
    wait_for_ajaximations
    #have to refresh the page in order to get open_comment_dialog to work again
    refresh_page
    wait_for_ajaximations
    dialog = open_comment_dialog
    keep_trying_until { dialog.find_element(:css, '.comment').should include_text(comment_text) }
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
    curve_form.find_element(:css, '#middle_score').send_keys(curved_grade_text)
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