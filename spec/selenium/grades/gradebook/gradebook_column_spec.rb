require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/assignment_overrides'

describe "assignment column headers" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include Gradebook2Common

  before(:each) do
    gradebook_data_setup
    @assignment = @course.assignments.first
    @header_selector = %([id$="assignment_#{@assignment.id}"])
  end

  it "should validate row sorting works when first column is clicked", priority: "1", test_id: 220023  do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    first_column = ff('.slick-column-name')[0]
    first_column.click
    meta_cells = find_slick_cells(0, f('#gradebook_grid  .container_0'))
    grade_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    #filter validation
    expect(meta_cells[0].text).to eq @student_name_3 + "\n" + @course.name
    expect(grade_cells[0].text).to eq @assignment_2_points
    expect(grade_cells[4].find_element(:css, '.percentage').text).to eq @student_3_total_ignoring_ungraded
  end

  it "should have a tooltip with the assignment name", priority: "1", test_id: 220025 do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    expect(f(@header_selector)["title"]).to eq @assignment.title
  end

  it "should handle a ton of assignments without wrapping the slick-header", priority: "1", test_id: 220026 do
    100.times do
      @course.assignments.create! :title => 'a really long assignment name, o look how long I am this is so cool'
    end
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    # being 38px high means it did not wrap
    expect(f("#gradebook_grid .slick-header-columns").size.height).to eq 38
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
    expect(first_row_cells[0].text).to eq '-'
    expect(first_row_cells[1].text).to eq @assignment_2_points
    expect(first_row_cells[2].text).to eq @assignment_1_points

    # both predefined short orders should be displayed since neither one is selected.
    f('#gradebook_settings').click
    arrange_settings = ff('input[name="arrange-columns-by"]')
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
    @fourth_assignment.grade_student(@student_1, grade: 150, grader: @teacher)

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0].text).to eq '-'
    expect(first_row_cells[1].text).to eq @assignment_2_points
    expect(first_row_cells[2].text).to eq @assignment_1_points
    expect(first_row_cells[3].text).to eq '150'
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
    expect(first_row_cells[0].text).to eq '-'
    expect(first_row_cells[1].text).to eq @assignment_2_points
  end

  it "should validate show attendance columns option", priority: "1", test_id: 220034 do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    f('#gradebook_settings').click
    f('#show_attendance').find_element(:xpath, '..').click
    headers = ff('.slick-header')
    expect(headers[1]).to include_text(@attendance_assignment.title)
    f('#gradebook_settings').click
    f('#show_attendance').find_element(:xpath, '..').click
  end

  it "should show letter grade in total column", priority: "1", test_id: 220035 do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .total-cell .letter-grade-points')).to include_text("A")
    edit_grade('#gradebook_grid .slick-row:nth-child(2) .l2', '50')
    wait_for_ajax_requests
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(2) .total-cell .letter-grade-points')).to include_text("A")
  end
end
