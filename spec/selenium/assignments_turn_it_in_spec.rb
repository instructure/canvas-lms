require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments turn it in" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    account = Account.default
    account.turnitin_account_id = 'asdf'
    account.turnitin_shared_secret = 'asdf'
    account.save
    @course.account = account
    @course.save
  end

  def change_turnitin_settings
    keep_trying_until { driver.find_element(:css, '.submission_type_option').should be_displayed }
    driver.find_element(:css, '.submission_type_option > option[value="online"]').click
    driver.find_element(:id, 'assignment_online_text_entry').click
    driver.find_element(:id, 'assignment_turnitin_settings').should_not be_displayed
    driver.find_element(:id, 'assignment_turnitin_enabled').click
    driver.find_element(:id, 'assignment_turnitin_settings').should be_displayed
    driver.find_element(:css, '.show_turnitin_settings').click
    wait_for_animations
    driver.find_element(:id, 'turnitin_settings_form').should be_displayed

    driver.find_element(:css, '#settings_originality_report_visibility > option[value="after_due_date"]').click # immediate -> after_due_date
    driver.find_element(:id, 'settings_student_paper_check').click # 1 -> 0
    driver.find_element(:id, 'settings_internet_check').click # 1 -> 0
    driver.find_element(:id, 'settings_journal_check').click # 1 -> 0
    driver.find_element(:id, 'settings_exclude_biblio').click # 1 -> 0
    driver.find_element(:id, 'settings_exclude_quoted').click # 1 -> 0
    driver.find_element(:id, 'settings_exclude_small_matches').click # 0 -> 1
    driver.find_element(:id, 'settings_exclude_fewer_than_count').click # 0 -> 1
    driver.find_element(:id, 'settings_exclude_value_count').send_keys("5") # '' -> 5
    submit_form('#turnitin_settings_form')
    wait_for_ajaximations
    driver.find_element(:id, 'turnitin_settings_form').should_not be_displayed
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
        'exclude_value' => '5'
    }
  end

  it "should create turnitin settings" do
    skip_if_ie('Out of memory')
    expect {
      get "/courses/#{@course.id}/assignments/new"

      driver.find_element(:id, 'assignment_title').send_keys('test assignment')
      change_turnitin_settings
    }.to_not change { Assignment.count } # although we "saved" the dialog, we haven't actually posted anything yet

    submit_form('#edit_assignment_form')
    wait_for_ajaximations
    keep_trying_until do
      assignment = Assignment.last
      assignment.turnitin_settings.should eql(expected_settings)
    end
  end

  it "should edit turnitin settings" do
    skip_if_ie('Out of memory')
    assignment = @course.assignments.create!(
        :name => 'test assignment',
        :due_at => (Time.now.utc + 2.days),
        :assignment_group => @course.assignment_groups.create!(:name => "default")
    )

    get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"

    change_turnitin_settings

    assignment.reload
    assignment.turnitin_settings.should eql(expected_settings)
  end
end