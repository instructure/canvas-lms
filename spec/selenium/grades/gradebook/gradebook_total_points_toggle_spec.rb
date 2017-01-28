require_relative '../../helpers/gradebook_common'

describe "gradebook - total points toggle" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }
  after(:each) { clear_local_storage }

  def should_show_percentages
    ff(".slick-row .slick-cell:nth-child(5)").each { |total| expect(total.text).to match(/%/) }
  end

  def should_show_points(*expected_points)
    ff(".slick-row .slick-cell:nth-child(5)").each do |total|
      raise Error "Total text is missing." unless total.text
      total.text.strip!
      expect(total.text).to match(/\A#{expected_points.shift}$/) unless total.text.length < 1
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

  it "shows points when group weights are not set" do
    @course.show_total_grade_as_points = true
    @course.save!
    @course.reload
    get "/courses/#{@course.id}/gradebook"

    should_show_points(15, 10, 10)
  end

  it "shows percentages when group weights are set", test_id: 164231, priority: "2" do
    @course.show_total_grade_as_points = false
    @course.save!
    @course.reload
    group = AssignmentGroup.where(name: @group.name).first
    group.group_weight = 50
    group.save!

    get "/courses/#{@course.id}/gradebook"
    should_show_percentages
  end

  it "should warn the teacher that studens will see a change" do
    get "/courses/#{@course.id}/gradebook"
    open_display_dialog
    dialog = fj('.ui-dialog:visible')
    expect(dialog).to include_text("Warning")
  end

  it 'should allow toggling display by points or percent', priority: "1", test_id: 164012 do
    get "/courses/#{@course.id}/gradebook"
    should_show_percentages
    toggle_grade_display

    wait_for_ajax_requests
    should_show_points(15, 10, 10)

    toggle_grade_display
    wait_for_ajax_requests
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
    get "/courses/#{@course.id}/gradebook"
    open_display_dialog
    close_dialog_and_dont_show_again

    open_display_dialog
    expect(f("body")).not_to contain_jqcss('.ui-dialog:visible')
  end
end
