require_relative '../common'

describe "assignments turn it in" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    account = Account.default
    account.turnitin_account_id = 'asdf'
    account.turnitin_shared_secret = 'asdf'
    account.settings[:enable_turnitin] = true
    account.save!
  end

  def change_turnitin_settings
    expect(f('#assignment_submission_type')).to be_displayed
    click_option('#assignment_submission_type', 'Online')
    f('#assignment_text_entry').click
    expect(f('#advanced_turnitin_settings_link')).not_to be_displayed
    f('#assignment_turnitin_enabled').click
    expect(f('#advanced_turnitin_settings_link')).to be_displayed
    f('#advanced_turnitin_settings_link').click
    expect(f('#assignment_turnitin_settings')).to be_displayed

    click_option('#settings_originality_report_visibility', 'After the Due Date')
    f('#s_paper_check').click # 1 -> 0
    f('#internet_check').click # 1 -> 0
    f('#journal_check').click # 1 -> 0
    f('#exclude_biblio').click # 1 -> 0
    f('#exclude_quoted').click # 1 -> 0
    f('#exclude_small_matches').click # 0 -> 1
    f('#exclude_small_matches_type_r1').click
    f('#exclude_small_matches_words_value').click # 0 -> 1
    f('#submit_papers_to').click # 1 -> 0
    f('#exclude_small_matches_words_value').send_keys([:backspace, "5"]) # '0' -> 5
    submit_dialog_form('#assignment_turnitin_settings')
    wait_for_ajaximations

    # dialog is closed and removed from the page
    expect(f("#content")).not_to contain_css('#assignment_turnitin_settings')
  end

  def expected_settings
    {
        'originality_report_visibility' => 'after_due_date',
        's_paper_check' => '0',
        'internet_check' => '0',
        'journal_check' => '0',
        'exclude_biblio' => '0',
        'exclude_quoted' => '0',
        'exclude_type' => '1',
        'exclude_value' => '5',
        'submit_papers_to' => '0',
        's_view_report' => '1'
    }
  end

  it "should create turnitin settings" do
    skip_if_chrome('issue with change_turnitin_settings method')
    expect {
      get "/courses/#{@course.id}/assignments/new"
      f('#assignment_name').send_keys('test assignment')
      change_turnitin_settings
    }.to_not change { Assignment.count } # although we "saved" the dialog, we haven't actually posted anything yet

    expect_new_page_load { submit_form('#edit_assignment_form') }
    expect(Assignment.last.turnitin_settings).to eq expected_settings
  end

  it "should edit turnitin settings" do
    skip_if_chrome('issue with change_turnitin_settings method')
    assignment = @course.assignments.create!(
        :name => 'test assignment',
        :due_at => (Time.now.utc + 2.days),
        :assignment_group => @course.assignment_groups.create!(:name => "default")
    )

    get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"

    change_turnitin_settings
    expect_new_page_load { submit_form('#edit_assignment_form') }

    assignment.reload
    expect(assignment.turnitin_settings).to eq expected_settings
  end
end
