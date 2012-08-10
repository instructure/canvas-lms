require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "assignment column headers" do
  it_should_behave_like "gradebook2 selenium tests"

  before (:each) do
    data_setup
    @assignment = @course.assignments.first
    @header_selector = %([id$="assignment_#{@assignment.id}"])
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
  end

  it "should minimize a column and remember it" do
    pending("dragging and dropping these dont actually work in selenium")
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    first_dragger, second_dragger = ff('#gradebook_grid .slick-resizable-handle')
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
    first_column = ff('.slick-column-name')[0]
    2.times do
      first_column.click
    end
    meta_cells = find_slick_cells(0, f('.grid-canvas'))
    grade_cells = find_slick_cells(0, f('#gradebook_grid'))
    #filter validation
    validate_cell_text(meta_cells[0], STUDENT_NAME_2 + "\n" + @other_section.name)
    validate_cell_text(grade_cells[0], ASSIGNMENT_2_POINTS)
    validate_cell_text(grade_cells[4].find_element(:css, '.percentage'), STUDENT_2_TOTAL_IGNORING_UNGRADED)
  end

  it "should validate arrange columns by due date option" do
    expected_text = "-"
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    open_gradebook_settings(f('#ui-menu-0-4'))
    first_row_cells = find_slick_cells(0, f('#gradebook_grid'))
    validate_cell_text(first_row_cells[0], expected_text)
  end

  it "should validate arrange columns by assignment group option" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    open_gradebook_settings(f('#ui-menu-0-4'))
    open_gradebook_settings(f('#ui-menu-0-5'))
    first_row_cells = find_slick_cells(0, f('#gradebook_grid'))
    validate_cell_text(first_row_cells[0], ASSIGNMENT_1_POINTS)
  end

  it "should validate show attendance columns option" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    open_gradebook_settings(f('#ui-menu-0-6'))
    headers = ff('.slick-header')
    headers[1].should include_text(@attendance_assignment.title)
    open_gradebook_settings(f('#ui-menu-0-6'))
  end

  it "show letter grade in total column" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    f('#gradebook_grid [row="0"] .total-cell .letter-grade-points').should include_text("A")
    edit_grade(f('#gradebook_grid [row="1"] .l2'), '50')
    wait_for_ajax_requests
    f('#gradebook_grid [row="1"] .total-cell .letter-grade-points').should include_text("A")
  end
end