require_relative '../../helpers/gradebook2_common'

describe "gradebook2 - total points toggle" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let!(:setup) { gradebook_data_setup }

  def should_show_percentages
    wait_for_ajaximations
    ff(".slick-row .slick-cell:nth-child(5)").each { |total| expect(total.text).to match(/%/) }
  end

  def should_show_points
    expected_points = 15, 10, 10
    ff(".slick-row .slick-cell:nth-child(5)").each do |total|
      expect(total.text).to match(/\A#{expected_points.shift}$/)
    end
  end
  
  def open_display_dialog
    f("#total_dropdown").click
    f(".toggle_percent").click
  end

  def close_display_dialog
    f(".ui-icon-closethick").click
  end

  def toggle_grade_display
    open_display_dialog
    dialog = fj('.ui-dialog:visible')
    submit_dialog(dialog, '.ui-button')
  end

  def close_dialog_and_dont_show_again
    dialog = fj('.ui-dialog:visible')
    fj("#hide_warning").click
    submit_dialog(dialog, '.ui-button')
  end

  it "setting group weights should switch to percentage", test_id: 164231, priority: "2" do
    get "/courses/#{@course.id}/gradebook2"

    toggle_grade_display
    should_show_points

    group = AssignmentGroup.where(name: @group.name).first
    set_group_weight(group, 50, enable_scheme: true)

    disable_group_weight
    should_show_percentages
  end

  it "should warn the teacher that studens will see a change" do
    get "/courses/#{@course.id}/gradebook2"
    open_display_dialog
    dialog = fj('.ui-dialog:visible')
    expect(dialog.text).to match(/Warning/)
  end

  it 'should allow toggling display by points or percent', priority: "1", test_id: 164012 do
    get "/courses/#{@course.id}/gradebook2"
    should_show_percentages
    toggle_grade_display

    should_show_points

    toggle_grade_display
    should_show_percentages
  end

  it 'should change the text on the toggle option when toggling' do
    get "/courses/#{@course.id}/gradebook"
    dropdown_text = []
    f("#total_dropdown").click
    dropdown_text << f(".toggle_percent").text
    f(".toggle_percent").click
    close_dialog_and_dont_show_again
    f("#total_dropdown").click
    dropdown_text << f(".toggle_percent").text
    f(".toggle_percent").click
    f("#total_dropdown").click
    dropdown_text << f(".toggle_percent").text
    expect(dropdown_text).to eq ["Switch to points", "Switch to percent", "Switch to points"]
  end

  it 'should not show the warning once dont show is checked' do
    get "/courses/#{@course.id}/gradebook2"
    open_display_dialog
    close_dialog_and_dont_show_again

    open_display_dialog
    expect(f("body")).not_to contain_jqcss('.ui-dialog:visible')
  end
end
