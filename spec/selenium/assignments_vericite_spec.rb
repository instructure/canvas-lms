require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments turn it in" do
  include_context "in-process server selenium tests"

  def change_vericite_settings
    keep_trying_until {
      expect(f('#assignment_submission_type')).to be_displayed
    }
    click_option('#assignment_submission_type', 'Online')
    f('#assignment_text_entry').click
    expect(f('#advanced_vericite_settings_link')).not_to be_displayed
    f('#assignment_vericite_enabled').click
    expect(f('#advanced_vericite_settings_link')).to be_displayed
    f('#advanced_vericite_settings_link').click
    expect(f('#assignment_vericite_settings')).to be_displayed

    click_option('#settings_originality_report_visibility', 'After the Due Date')
    f('#exclude_quoted').click # 1 -> 0
    submit_form('#assignment_vericite_settings')
    wait_for_ajaximations

    # dialog is closed and removed from the page
    expect(f('#assignment_vericite_settings')).to be_nil
  end

  def expected_settings
    {
        'originality_report_visibility' => 'after_due_date',
        'exclude_quoted' => '0'
    }
  end

  it "should create vericite settings" do
    expect {
      get "/courses/#{@course.id}/assignments/new"
      f('#assignment_name').send_keys('test assignment')
      change_vericite_settings
    }.to_not change { Assignment.count } # although we "saved" the dialog, we haven't actually posted anything yet

    expect_new_page_load { submit_form('#edit_assignment_form') }
    expect(Assignment.last.vericite_settings).to eq expected_settings
  end

  it "should edit vericite settings" do
    assignment = @course.assignments.create!(
        :name => 'test assignment',
        :due_at => (Time.now.utc + 2.days),
        :assignment_group => @course.assignment_groups.create!(:name => "default")
    )

    get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"

    change_vericite_settings
    expect_new_page_load { submit_form('#edit_assignment_form') }

    assignment.reload
    expect(assignment.vericite_settings).to eq expected_settings
  end
end
