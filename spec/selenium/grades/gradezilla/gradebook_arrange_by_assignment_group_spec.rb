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

    arrange_settings = ff('input[name="arrange-columns-by"]')
    f('#gradebook_settings').click
    expect(arrange_settings.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).not_to be_displayed
  end

  it "should validate arrange columns by assignment group option", priority: "1", test_id: 220029 do
    # since assignment group is the default, sort by due date, then assignment group again
    arrange_settings = -> { ff('input[name="arrange-columns-by"]') }
    f('#gradebook_settings').click
    arrange_settings.call.first.find_element(:xpath, '..')
    arrange_settings.call.last.find_element(:xpath, '..')
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text @assignment_1_points
    expect(first_row_cells[1]).to include_text @assignment_2_points
    expect(first_row_cells[2]).to include_text "-"

    arrange_settings = -> { ff('input[name="arrange-columns-by"]') }
    f('#gradebook_settings')
    expect(arrange_settings.call.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.call.last.find_element(:xpath, '..')).not_to be_displayed

    # Setting should stick (not be messed up) after reload
    gradezilla_page.visit(@course)

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text @assignment_1_points
    expect(first_row_cells[1]).to include_text @assignment_2_points
    expect(first_row_cells[2]).to include_text "-"

    arrange_settings = ff('input[name="arrange-columns-by"]')
    f('#gradebook_settings').click
    expect(arrange_settings.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).not_to be_displayed
  end
end
