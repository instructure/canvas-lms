require_relative '../../helpers/gradezilla_common'
require_relative '../../helpers/assignment_overrides'
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla - arrange by due date" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include GradezillaCommon

  let(:gradezilla_page) { Gradezilla::MultipleGradingPeriods.new }

  before(:once) do
    gradebook_data_setup
    @assignment = @course.assignments.first
  end

  before(:each) do
    user_session(@teacher)
    gradezilla_page.visit(@course)
  end

  it "should validate arrange columns by due date option", priority: "1", test_id: 220027 do
    expected_text = "-"

    view_menu = gradezilla_page.open_gradebook_menu('View')
    gradezilla_page.select_gradebook_menu_option('Arrange By > Due Date - Oldest to Newest', container: view_menu)

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text expected_text

    view_menu = gradezilla_page.open_gradebook_menu('View')
    arrange_by_group = gradezilla_page.gradebook_menu_group('Arrange By', container: view_menu)
    arrangement_menu_options = gradezilla_page.gradebook_menu_options(arrange_by_group)
    selected_menu_options = arrangement_menu_options.select do |menu_item|
      menu_item.attribute('aria-checked') == 'true'
    end

    expect(selected_menu_options.size).to eq(1)
    expect(selected_menu_options[0].text.strip).to eq('Due Date - Oldest to Newest')

    # Setting should stick after reload
    gradezilla_page.visit(@course)
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text expected_text

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text expected_text
    expect(first_row_cells[1]).to include_text @assignment_1_points
    expect(first_row_cells[2]).to include_text @assignment_2_points

    view_menu = gradezilla_page.open_gradebook_menu('View')
    arrange_by_group = gradezilla_page.gradebook_menu_group('Arrange By', container: view_menu)
    arrangement_menu_options = gradezilla_page.gradebook_menu_options(arrange_by_group)
    selected_menu_options = arrangement_menu_options.select do |menu_item|
      menu_item.attribute('aria-checked') == 'true'
    end

    expect(selected_menu_options.size).to eq(1)
    expect(selected_menu_options[0].text.strip).to eq('Due Date - Oldest to Newest')
  end

  it "should put assignments with no due date last when sorting by due date and VDD", priority: "2", test_id: 251038 do
    assignment2 = @course.assignments.where(title: 'second assignment').first
    assignment3 = @course.assignments.where(title: 'assignment three').first
    # create 1 section
    @section_a = @course.course_sections.create!(name: 'Section A')
    # give second assignment a default due date and an override
    assignment2.update_attribute(:due_at, 3.days.from_now)
    create_assignment_override(assignment2, @section_a, 2)

    view_menu = gradezilla_page.open_gradebook_menu('View')
    gradezilla_page.select_gradebook_menu_option('Arrange By > Due Date - Oldest to Newest', container: view_menu)
    # since due date changes in assignments don't reflect in column sorting without a refresh
    gradezilla_page.visit(@course)
    expect(f('#gradebook_grid .container_1 .slick-header-column:nth-child(1)')).to include_text(assignment3.title)
    expect(f('#gradebook_grid .container_1 .slick-header-column:nth-child(2)')).to include_text(assignment2.title)
    expect(f('#gradebook_grid .container_1 .slick-header-column:nth-child(3)')).to include_text(@assignment.title)
  end

  it "should arrange columns by due date when multiple due dates are present", priority: "2", test_id: 378823 do
    assignment3 = @course.assignments.where(title: 'assignment three').first
    # create 2 sections
    @section_a = @course.course_sections.create!(name: 'Section A')
    @section_b = @course.course_sections.create!(name: 'Section B')
    # give each assignment a default due date
    @assignment.update_attribute(:due_at, 3.days.from_now)
    assignment3.update_attribute(:due_at, 2.days.from_now)
    # creating overrides in each section
    create_assignment_override(@assignment, @section_a, 5)
    create_assignment_override(assignment3, @section_b, 4)

    view_menu = gradezilla_page.open_gradebook_menu('View')
    gradezilla_page.select_gradebook_menu_option('Arrange By > Due Date - Oldest to Newest', container: view_menu)

    expect(f('#gradebook_grid .container_1 .slick-header-column:nth-child(1)')).to include_text(assignment3.title)
    expect(f('#gradebook_grid .container_1 .slick-header-column:nth-child(2)')).to include_text(@assignment.title)
  end
end
