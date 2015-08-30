require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "assignment column headers" do
  include_context "in-process server selenium tests"

  before (:each) do
    gradebook_data_setup
    @assignment = @course.assignments.first
    @header_selector = %([id$="assignment_#{@assignment.id}"])
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
  end

  it "should validate row sorting works when first column is clicked", priority: "1", test_id: 220023  do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    first_column = ff('.slick-column-name')[0]
    first_column.click
    meta_cells = find_slick_cells(0, f('#gradebook_grid  .container_0'))
    grade_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    #filter validation
    validate_cell_text(meta_cells[0], @student_name_3 + "\n" + @course.name)
    validate_cell_text(grade_cells[0], @assignment_2_points)
    validate_cell_text(grade_cells[4].find_element(:css, '.percentage'), @student_3_total_ignoring_ungraded)
  end

  it "should minimize a column and remember it" do
    skip("dragging and dropping these does not work well in selenium")
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    first_dragger, second_dragger = ff('#gradebook_grid .slick-resizable-handle')
    driver.action.drag_and_drop(second_dragger, first_dragger).perform
  end

  it "should have a tooltip with the assignment name", priority: "1", test_id: 220025 do
    expect(f(@header_selector)["title"]).to eq @assignment.title
  end

  it "should handle a ton of assignments without wrapping the slick-header", priority: "1", test_id: 220026 do
    100.times do
      @course.assignments.create! :title => 'a really long assignment name, o look how long I am this is so cool'
    end
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    # being 38px high means it did not wrap
    expect(driver.execute_script('return $("#gradebook_grid .slick-header-columns").height()')).to eq 38
  end

  it "should validate arrange columns by due date option", priority: "1", test_id: 220027 do
    expected_text = "-"
    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings(arrange_settings.first.find_element(:xpath, '..'))
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], expected_text)
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).not_to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).to be_displayed

    # Setting should stick after reload
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], expected_text)

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], expected_text)
    validate_cell_text(first_row_cells[1], @assignment_1_points)
    validate_cell_text(first_row_cells[2], @assignment_2_points)

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).not_to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).to be_displayed
  end

  it "should default to arrange columns by assignment group", priority: "1", test_id: 220028 do
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], @assignment_1_points)
    validate_cell_text(first_row_cells[1], @assignment_2_points)
    validate_cell_text(first_row_cells[2], "-")

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).not_to be_displayed
  end

  it "should validate arrange columns by assignment group option", priority: "1", test_id: 220029 do
    # since assignment group is the default, sort by due date, then assignment group again
    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings(arrange_settings.first.find_element(:xpath, '..'))
    open_gradebook_settings(arrange_settings.last.find_element(:xpath, '..'))
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], @assignment_1_points)
    validate_cell_text(first_row_cells[1], @assignment_2_points)
    validate_cell_text(first_row_cells[2], "-")

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).not_to be_displayed

    # Setting should stick (not be messed up) after reload
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], @assignment_1_points)
    validate_cell_text(first_row_cells[1], @assignment_2_points)
    validate_cell_text(first_row_cells[2], "-")

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).not_to be_displayed
  end

  it "should allow custom column ordering" do
    skip("drag and drop doesn't seem to work")
    columns = ff('.assignment-points-possible')
    expect(columns).not_to be_empty
    driver.action.drag_and_drop_by(columns[1], -300, 0).perform

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], @assignment_2_points)
    validate_cell_text(first_row_cells[1], @assignment_1_points)
    validate_cell_text(first_row_cells[2], "-")

    # with a custom order, both sort options should be displayed
    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).to be_displayed
  end

  it "should load custom column ordering", priority: "1", test_id: 220031 do
    @user.preferences[:gradebook_column_order] = {}
    @user.preferences[:gradebook_column_order][@course.id] = {
      sortType: 'custom',
      customOrder: ["#{@third_assignment.id}", "#{@second_assignment.id}", "#{@first_assignment.id}"]
    }
    @user.save!
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], '-')
    validate_cell_text(first_row_cells[1], @assignment_2_points)
    validate_cell_text(first_row_cells[2], @assignment_1_points)

    # both predefined short orders should be displayed since neither one is selected.
    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).to be_displayed
  end

  it "should put new assignments at the end when columns have custom order", priority: "1", test_id: 220032 do
    @user.preferences[:gradebook_column_order] = {}
    @user.preferences[:gradebook_column_order][@course.id] = {
      sortType: 'custom',
      customOrder: ["#{@third_assignment.id}", "#{@second_assignment.id}", "#{@first_assignment.id}"]
    }
    @user.save!
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
    validate_cell_text(first_row_cells[1], @assignment_2_points)
    validate_cell_text(first_row_cells[2], @assignment_1_points)
    validate_cell_text(first_row_cells[3], '150')
  end

  it "should maintain order of remaining assignments if an assignment is destroyed", priority: "1", test_id: 220033 do
    @user.preferences[:gradebook_column_order] = {}
    @user.preferences[:gradebook_column_order][@course.id] = {
      sortType: 'custom',
      customOrder: ["#{@third_assignment.id}", "#{@second_assignment.id}", "#{@first_assignment.id}"]
    }
    @user.save!

    @first_assignment.destroy

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], '-')
    validate_cell_text(first_row_cells[1], @assignment_2_points)
  end

  it "should validate show attendance columns option", priority: "1", test_id: 220034 do
    attendance_setting = f('#show_attendance').find_element(:xpath, '..')
    open_gradebook_settings(attendance_setting)
    headers = ff('.slick-header')
    expect(headers[1]).to include_text(@attendance_assignment.title)
    open_gradebook_settings(attendance_setting)
  end

  it "should show letter grade in total column", priority: "1", test_id: 220035 do
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .total-cell .letter-grade-points')).to include_text("A")
    edit_grade('#gradebook_grid .slick-row:nth-child(2) .l2', '50')
    wait_for_ajax_requests
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(2) .total-cell .letter-grade-points')).to include_text("A")
  end
end
