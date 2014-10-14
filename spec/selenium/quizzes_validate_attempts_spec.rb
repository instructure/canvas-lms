require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes question creation with attempts" do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  include_examples "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @last_quiz = start_quiz_question
  end

  def fill_out_attempts_and_validate(attempts, alert_text, expected_attempt_text)
    wait_for_ajaximations
    click_settings_tab
    sleep 2 # wait for page to load
    quiz_attempt_field = lambda {
      set_value(f('#multiple_attempts_option'), false)
      set_value(f('#multiple_attempts_option'), true)
      set_value(f('#limit_attempts_option'), false)
      set_value(f('#limit_attempts_option'), true)
      replace_content(f('#quiz_allowed_attempts'), attempts)
      driver.execute_script(%{$('#quiz_allowed_attempts').blur();}) unless alert_present?
    }
    keep_trying_until do
      quiz_attempt_field.call
      alert_present?
    end
    alert = driver.switch_to.alert
    expect(alert.text).to eq alert_text
    alert.dismiss
    expect(fj('#quiz_allowed_attempts')).to have_attribute('value', expected_attempt_text) # fj to avoid selenium caching
  end

  it "should not allow quiz attempts that are entered with letters" do
    fill_out_attempts_and_validate('abc', 'Quiz attempts can only be specified in numbers', '')
  end

  it "should not allow quiz attempts that are more than 3 digits long" do
    fill_out_attempts_and_validate('12345', 'Quiz attempts are limited to 3 digits, if you would like to give your students unlimited attempts, do not check Allow Multiple Attempts box to the left', '')
  end

  it "should not allow quiz attempts that are letters and numbers mixed" do
    fill_out_attempts_and_validate('31das', 'Quiz attempts can only be specified in numbers', '')
  end

  it "should allow a 3 digit number for a quiz attempt" do
    attempts = "123"
    click_settings_tab
    f('#multiple_attempts_option').click
    f('#limit_attempts_option').click
    replace_content(f('#quiz_allowed_attempts'), attempts)
    f('#quiz_time_limit').click
    expect(alert_present?).to be_falsey
    expect(fj('#quiz_allowed_attempts')).to have_attribute('value', attempts) # fj to avoid selenium caching

    expect_new_page_load {
      f('.save_quiz_button').click
      wait_for_ajaximations
      keep_trying_until { expect(f('.header-bar-right')).to be_displayed }
    }

    expect(Quizzes::Quiz.last.allowed_attempts).to eq attempts.to_i
  end

end
