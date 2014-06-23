require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "assignment column headers" do
  include_examples "in-process server selenium tests"

  ASSIGNMENT_1_POINTS = "10"
  ASSIGNMENT_2_POINTS = "5"
  ASSIGNMENT_3_POINTS = "50"
  ATTENDANCE_POINTS = "15"

  STUDENT_NAME_1 = "student 1"
  STUDENT_NAME_2 = "student 2"
  STUDENT_NAME_3 = "student 3"
  STUDENT_SORTABLE_NAME_1 = "1, student"
  STUDENT_SORTABLE_NAME_2 = "2, student"
  STUDENT_SORTABLE_NAME_3 = "3, student"
  STUDENT_1_TOTAL_IGNORING_UNGRADED = "100%"
  STUDENT_2_TOTAL_IGNORING_UNGRADED = "66.7%"
  STUDENT_3_TOTAL_IGNORING_UNGRADED = "66.7%"
  STUDENT_1_TOTAL_TREATING_UNGRADED_AS_ZEROS = "18.8%"
  STUDENT_2_TOTAL_TREATING_UNGRADED_AS_ZEROS = "12.5%"
  STUDENT_3_TOTAL_TREATING_UNGRADED_AS_ZEROS = "12.5%"
  DEFAULT_PASSWORD = "qwerty"

  before (:each) do
    data_setup
    @assignment = @course.assignments.first
    @header_selector = %([id$="assignment_#{@assignment.id}"])
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
  end

  it "should validate row sorting works when first column is clicked" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    first_column = ff('.slick-column-name')[0]
    first_column.click
    meta_cells = find_slick_cells(0, f('#gradebook_grid  .container_0'))
    grade_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    #filter validation
    validate_cell_text(meta_cells[0], STUDENT_NAME_3 + "\n" + @course.name)
    validate_cell_text(grade_cells[0], ASSIGNMENT_2_POINTS)
    validate_cell_text(grade_cells[4].find_element(:css, '.percentage'), STUDENT_3_TOTAL_IGNORING_UNGRADED)
  end

  it "should minimize a column and remember it" do
    pending("dragging and dropping these does not work well in selenium")
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    first_dragger, second_dragger = ff('#gradebook_grid .slick-resizable-handle')
    driver.action.drag_and_drop(second_dragger, first_dragger).perform
  end

  it "should have a tooltip with the assignment name" do
    f(@header_selector)["title"].should == @assignment.title
  end

  it "should handle a ton of assignments without wrapping the slick-header" do
    100.times do
      @course.assignments.create! :title => 'a really long assignment name, o look how long I am this is so cool'
    end
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    # being 38px high means it did not wrap
    driver.execute_script('return $("#gradebook_grid .slick-header-columns").height()').should == 38
  end

  it "should validate arrange columns by due date option" do
    expected_text = "-"
    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings(arrange_settings.first.find_element(:xpath, '..'))
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], expected_text)
    open_gradebook_settings()
    arrange_settings.first.find_element(:xpath, '..').should_not be_displayed
    arrange_settings.last.find_element(:xpath, '..').should be_displayed

    # Setting should stick after reload
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], expected_text)

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], expected_text)
    validate_cell_text(first_row_cells[1], ASSIGNMENT_1_POINTS)
    validate_cell_text(first_row_cells[2], ASSIGNMENT_2_POINTS)

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    arrange_settings.first.find_element(:xpath, '..').should_not be_displayed
    arrange_settings.last.find_element(:xpath, '..').should be_displayed
  end

  it "should default to arrange columns by assignment group" do
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], ASSIGNMENT_1_POINTS)
    validate_cell_text(first_row_cells[1], ASSIGNMENT_2_POINTS)
    validate_cell_text(first_row_cells[2], "-")

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    arrange_settings.first.find_element(:xpath, '..').should be_displayed
    arrange_settings.last.find_element(:xpath, '..').should_not be_displayed
  end

  it "should validate arrange columns by assignment group option" do
    # since assignment group is the default, sort by due date, then assignment group again
    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings(arrange_settings.first.find_element(:xpath, '..'))
    open_gradebook_settings(arrange_settings.last.find_element(:xpath, '..'))
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], ASSIGNMENT_1_POINTS)
    validate_cell_text(first_row_cells[1], ASSIGNMENT_2_POINTS)
    validate_cell_text(first_row_cells[2], "-")

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    arrange_settings.first.find_element(:xpath, '..').should be_displayed
    arrange_settings.last.find_element(:xpath, '..').should_not be_displayed

    # Setting should stick (not be messed up) after reload
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], ASSIGNMENT_1_POINTS)
    validate_cell_text(first_row_cells[1], ASSIGNMENT_2_POINTS)
    validate_cell_text(first_row_cells[2], "-")

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    arrange_settings.first.find_element(:xpath, '..').should be_displayed
    arrange_settings.last.find_element(:xpath, '..').should_not be_displayed
  end

  it "should allow custom column ordering" do
    pending("drag and drop doesn't seem to work")
    columns = ff('.assignment-points-possible')
    columns.should_not be_empty
    driver.action.drag_and_drop_by(columns[1], -300, 0).perform

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], ASSIGNMENT_2_POINTS)
    validate_cell_text(first_row_cells[1], ASSIGNMENT_1_POINTS)
    validate_cell_text(first_row_cells[2], "-")

    # with a custom order, both sort options should be displayed
    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    arrange_settings.first.find_element(:xpath, '..').should be_displayed
    arrange_settings.last.find_element(:xpath, '..').should be_displayed
  end

  it "should load custom column ordering" do
    # since drag and drop doesn't work, we'll just have to store a fake configuration and make sure it gets loaded.

    script = <<-JS
      sortOrder = {
        sortType: 'custom',
        customOrder: [#{@third_assignment.id}, #{@second_assignment.id}, #{@first_assignment.id}] };
      localStorage.setItem('_#{@user.id}_course_#{@course.id}_sort_grade_columns_by', JSON.stringify(sortOrder));
    JS
    driver.execute_script(script)
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], '-')
    validate_cell_text(first_row_cells[1], ASSIGNMENT_2_POINTS)
    validate_cell_text(first_row_cells[2], ASSIGNMENT_1_POINTS)

    # both predefined short orders should be displayed since neither one is selected.
    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    arrange_settings.first.find_element(:xpath, '..').should be_displayed
    arrange_settings.last.find_element(:xpath, '..').should be_displayed
  end

  it "should put new assignments at the end when columns have custom order" do
    script = <<-JS
      sortOrder = {
        sortType: 'custom',
        customOrder: [#{@third_assignment.id}, #{@second_assignment.id}, #{@first_assignment.id}] };
      localStorage.setItem('_#{@user.id}_course_#{@course.id}_sort_grade_columns_by', JSON.stringify(sortOrder));
    JS
    driver.execute_script(script)

    @fourth_assignment = assignment_model({
      :course => @course,
      :name => "new assignment",
      :due_at => nil,
      :points_possible => 150,
      :assignment_group => nil,
      })
    @fourth_assignment.grade_student(@student_1, :grade => 150)

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], '-')
    validate_cell_text(first_row_cells[1], ASSIGNMENT_2_POINTS)
    validate_cell_text(first_row_cells[2], ASSIGNMENT_1_POINTS)
    validate_cell_text(first_row_cells[3], '150')
  end

  it "should maintain order of remaining assignments if an assignment is destroyed" do
    script = <<-JS
      sortOrder = {
        sortType: 'custom',
        customOrder: [#{@third_assignment.id}, #{@second_assignment.id}, #{@first_assignment.id}] };
      localStorage.setItem('_#{@user.id}_course_#{@course.id}_sort_grade_columns_by', JSON.stringify(sortOrder));
    JS
    driver.execute_script(script)
    @first_assignment.destroy

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], '-')
    validate_cell_text(first_row_cells[1], ASSIGNMENT_2_POINTS)
  end

  it "should validate show attendance columns option" do
    attendance_setting = f('#show_attendance').find_element(:xpath, '..')
    open_gradebook_settings(attendance_setting)
    headers = ff('.slick-header')
    headers[1].should include_text(@attendance_assignment.title)
    open_gradebook_settings(attendance_setting)
  end

  it "show letter grade in total column" do
    f('#gradebook_grid .container_1 .slick-row:nth-child(1) .total-cell .letter-grade-points').should include_text("A")
    edit_grade('#gradebook_grid .slick-row:nth-child(2) .l2', '50')
    wait_for_ajax_requests
    f('#gradebook_grid .container_1 .slick-row:nth-child(2) .total-cell .letter-grade-points').should include_text("A")
  end
end
