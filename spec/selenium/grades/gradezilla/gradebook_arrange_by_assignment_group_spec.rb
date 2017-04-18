require_relative '../../helpers/gradezilla_common'
require_relative '../../helpers/assignment_overrides'
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla - arrange by assignment group" do
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

  it "should default to arrange columns by assignment group", priority: "1", test_id: 220028 do
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text @assignment_1_points
    expect(first_row_cells[1]).to include_text @assignment_2_points
    expect(first_row_cells[2]).to include_text "-"

    view_menu = gradezilla_page.open_gradebook_menu('View')
    arrange_by_group = gradezilla_page.gradebook_menu_group('Arrange By', container: view_menu)
    arrangement_menu_options = gradezilla_page.gradebook_menu_options(arrange_by_group)
    selected_menu_options = arrangement_menu_options.select do |menu_item|
      menu_item.attribute('aria-checked') == 'true'
    end

    expect(selected_menu_options.size).to eq(1)
    expect(selected_menu_options[0].text.strip).to eq('Default Order')
  end

  it "should validate arrange columns by assignment group option", priority: "1", test_id: 220029 do
    # since assignment group is the default, sort by due date, then assignment group again
    view_menu = gradezilla_page.open_gradebook_menu('View')
    gradezilla_page.select_gradebook_menu_option('Default Order', container: view_menu)

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text @assignment_1_points
    expect(first_row_cells[1]).to include_text @assignment_2_points
    expect(first_row_cells[2]).to include_text "-"

    view_menu = gradezilla_page.open_gradebook_menu('View')
    arrange_by_group = gradezilla_page.gradebook_menu_group('Arrange By', container: view_menu)
    arrangement_menu_options = gradezilla_page.gradebook_menu_options(arrange_by_group)
    selected_menu_options = arrangement_menu_options.select do |menu_item|
      menu_item.attribute('aria-checked') == 'true'
    end

    expect(selected_menu_options.size).to eq(1)
    expect(selected_menu_options[0].text.strip).to eq('Default Order')

    # Setting should stick (not be messed up) after reload
    gradezilla_page.visit(@course)

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text @assignment_1_points
    expect(first_row_cells[1]).to include_text @assignment_2_points
    expect(first_row_cells[2]).to include_text "-"

    view_menu = gradezilla_page.open_gradebook_menu('View')
    arrange_by_group = gradezilla_page.gradebook_menu_group('Arrange By', container: view_menu)
    arrangement_menu_options = gradezilla_page.gradebook_menu_options(arrange_by_group)
    selected_menu_options = arrangement_menu_options.select do |menu_item|
      menu_item.attribute('aria-checked') == 'true'
    end

    expect(selected_menu_options.size).to eq(1)
    expect(selected_menu_options[0].text.strip).to eq('Default Order')
  end
end
