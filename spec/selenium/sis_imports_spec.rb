require File.expand_path(File.dirname(__FILE__) + '/common')

describe "sis imports ui" do
  it_should_behave_like "in-process server selenium tests"

  def account_with_admin_logged_in(opts = {})
    @account = Account.default
    account_admin_user
    user_session(@admin)
  end

  it 'should properly show sis stickiness options' do
    account_with_admin_logged_in
    @account.update_attribute(:allow_sis_import, true)
    get "/accounts/#{@account.id}/sis_import"
    driver.find_element(:id, 'add_sis_stickiness').should_not be_displayed
    driver.find_element(:id, 'clear_sis_stickiness').should_not be_displayed
    driver.find_element(:id, 'override_sis_stickiness').should be_displayed
    driver.find_element(:id, 'add_sis_stickiness').should be_enabled
    driver.find_element(:id, 'clear_sis_stickiness').should be_enabled
    driver.find_element(:id, 'override_sis_stickiness').should be_enabled
    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_false
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_false
    is_checked('#override_sis_stickiness').should be_false
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.find_element(:id, 'add_sis_stickiness').should be_displayed
    driver.find_element(:id, 'clear_sis_stickiness').should be_displayed
    driver.find_element(:id, 'override_sis_stickiness').should be_displayed
    driver.find_element(:id, 'add_sis_stickiness').should be_enabled
    driver.find_element(:id, 'clear_sis_stickiness').should be_enabled
    driver.find_element(:id, 'override_sis_stickiness').should be_enabled
    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_false
    is_checked('#override_sis_stickiness').should be_true
    driver.find_element(:css, "#override_sis_stickiness").click

    driver.find_element(:id, 'add_sis_stickiness').should_not be_displayed
    driver.find_element(:id, 'clear_sis_stickiness').should_not be_displayed
    driver.find_element(:id, 'override_sis_stickiness').should be_displayed
    driver.find_element(:id, 'add_sis_stickiness').should be_enabled
    driver.find_element(:id, 'clear_sis_stickiness').should be_enabled
    driver.find_element(:id, 'override_sis_stickiness').should be_enabled
    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_false
    is_checked('#override_sis_stickiness').should be_false
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.find_element(:css, "#add_sis_stickiness").click

    driver.find_element(:id, 'add_sis_stickiness').should be_displayed
    driver.find_element(:id, 'clear_sis_stickiness').should be_displayed
    driver.find_element(:id, 'override_sis_stickiness').should be_displayed
    driver.find_element(:id, 'add_sis_stickiness').should be_enabled
    driver.find_element(:id, 'clear_sis_stickiness').should_not be_enabled
    driver.find_element(:id, 'override_sis_stickiness').should be_enabled
    is_checked('#add_sis_stickiness').should be_true
    is_checked('#clear_sis_stickiness').should be_false
    is_checked('#override_sis_stickiness').should be_true
    driver.find_element(:css, "#add_sis_stickiness").click

    driver.find_element(:id, 'add_sis_stickiness').should be_displayed
    driver.find_element(:id, 'clear_sis_stickiness').should be_displayed
    driver.find_element(:id, 'override_sis_stickiness').should be_displayed
    driver.find_element(:id, 'add_sis_stickiness').should be_enabled
    driver.find_element(:id, 'clear_sis_stickiness').should be_enabled
    driver.find_element(:id, 'override_sis_stickiness').should be_enabled
    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_false
    is_checked('#override_sis_stickiness').should be_true
    driver.find_element(:css, "#clear_sis_stickiness").click

    driver.find_element(:id, 'add_sis_stickiness').should be_displayed
    driver.find_element(:id, 'clear_sis_stickiness').should be_displayed
    driver.find_element(:id, 'override_sis_stickiness').should be_displayed
    driver.find_element(:id, 'add_sis_stickiness').should_not be_enabled
    driver.find_element(:id, 'clear_sis_stickiness').should be_enabled
    driver.find_element(:id, 'override_sis_stickiness').should be_enabled

    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_true
    is_checked('#override_sis_stickiness').should be_true
    driver.find_element(:css, "#clear_sis_stickiness").click

    driver.find_element(:id, 'add_sis_stickiness').should be_displayed
    driver.find_element(:id, 'clear_sis_stickiness').should be_displayed
    driver.find_element(:id, 'override_sis_stickiness').should be_displayed
    driver.find_element(:id, 'add_sis_stickiness').should be_enabled
    driver.find_element(:id, 'clear_sis_stickiness').should be_enabled
    driver.find_element(:id, 'override_sis_stickiness').should be_enabled

    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_false
    is_checked('#override_sis_stickiness').should be_true
    driver.find_element(:css, "#clear_sis_stickiness").click
    driver.find_element(:css, "#override_sis_stickiness").click

    driver.find_element(:id, 'add_sis_stickiness').should_not be_displayed
    driver.find_element(:id, 'clear_sis_stickiness').should_not be_displayed
    driver.find_element(:id, 'override_sis_stickiness').should be_displayed
    is_checked('#override_sis_stickiness').should be_false
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.find_element(:css, "#clear_sis_stickiness").click
    driver.find_element(:css, "#add_sis_stickiness").click
    driver.find_element(:css, "#override_sis_stickiness").click

    driver.find_element(:id, 'add_sis_stickiness').should_not be_displayed
    driver.find_element(:id, 'clear_sis_stickiness').should_not be_displayed
    driver.find_element(:id, 'override_sis_stickiness').should be_displayed
    is_checked('#override_sis_stickiness').should be_false
  end

  it 'should pass options along to the batch' do
    skip_if_ie("Java crashes")
    account_with_admin_logged_in
    @account.update_attribute(:allow_sis_import, true)
    get "/accounts/#{@account.id}/sis_import"
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.find_element(:css, "#add_sis_stickiness").click
    driver.find_element(:css, "#batch_mode").click
    submit_form('#sis_importer')
    keep_trying_until { driver.find_element(:css, 'div.progress_bar_holder div.progress_message').should be_displayed }
    SisBatch.last.process_without_send_later
    keep_trying_until { driver.find_element(:css, "div.sis_messages div.sis_error_message").text =~ /No SIS records were imported. The import failed with these messages:/ }
    SisBatch.last.batch_mode.should == true
    SisBatch.last.options.should == {:override_sis_stickiness => true,
                                     :add_sis_stickiness => true}

    expect_new_page_load { get "/accounts/#{@account.id}/sis_import" }
    driver.find_element(:css, "#override_sis_stickiness").click
    submit_form('#sis_importer')
    keep_trying_until { driver.find_element(:css, 'div.progress_bar_holder div.progress_message').should be_displayed }
    SisBatch.last.process_without_send_later
    keep_trying_until { driver.find_element(:css, "div.sis_messages div.sis_error_message").text =~ /No SIS records were imported. The import failed with these messages:/ }
    (!!SisBatch.last.batch_mode).should be_false
    SisBatch.last.options.should == {:override_sis_stickiness => true}
  end
end
