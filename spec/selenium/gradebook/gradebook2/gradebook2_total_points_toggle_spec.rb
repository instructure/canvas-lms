require_relative '../../helpers/gradebook2_common'

describe "gradebook2 - total points toggle" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let!(:setup) { gradebook_data_setup }

  def should_show_percentages
    ff(".total-column").each { |total| expect(total.text).to match(/%/) }
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

  it "should warn the teacher that studens will see a change" do
    get "/courses/#{@course.id}/gradebook2"
    open_display_dialog
    dialog = fj('.ui-dialog:visible')
    expect(dialog.text).to match(/Warning/)
  end

  it 'should allow toggling display by points or percent', priority: "1", test_id: 164012 do
    should_show_percentages

    get "/courses/#{@course.id}/gradebook2"
    toggle_grade_display

    expected_points = 15, 10, 10
    ff(".total-column").each do |total|
      expect(total.text).to match(/\A#{expected_points.shift}$/)
    end

    toggle_grade_display
    should_show_percentages
  end

  it 'should not show the warning once dont show is checked' do
    get "/courses/#{@course.id}/gradebook2"
    open_display_dialog
    dialog = fj('.ui-dialog:visible')
    fj("#hide_warning").click
    submit_dialog(dialog, '.ui-button')

    open_display_dialog
    dialog = fj('.ui-dialog:visible')
    expect(dialog).to equal nil
  end
end