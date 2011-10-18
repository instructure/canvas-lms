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
    driver.execute_script("return $('#add_sis_stickiness').is(':visible')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').is(':visible')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#add_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#add_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_false
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.execute_script("return $('#add_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#clear_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#override_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#add_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#add_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_true
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.execute_script("return $('#add_sis_stickiness').is(':visible')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').is(':visible')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#add_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#add_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_false
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.find_element(:css, "#add_sis_stickiness").click
    driver.execute_script("return $('#add_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#clear_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#override_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#add_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').is(':disabled')").should be_true
    driver.execute_script("return $('#override_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#add_sis_stickiness').attr('checked')").should be_true
    driver.execute_script("return $('#clear_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_true
    driver.find_element(:css, "#add_sis_stickiness").click
    driver.execute_script("return $('#add_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#clear_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#override_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#add_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#add_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_true
    driver.find_element(:css, "#clear_sis_stickiness").click
    driver.execute_script("return $('#add_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#clear_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#override_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#add_sis_stickiness').is(':disabled')").should be_true
    driver.execute_script("return $('#clear_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#add_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').attr('checked')").should be_true
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_true
    driver.find_element(:css, "#clear_sis_stickiness").click
    driver.execute_script("return $('#add_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#clear_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#override_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#add_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').is(':disabled')").should be_false
    driver.execute_script("return $('#add_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').attr('checked')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_true
    driver.find_element(:css, "#clear_sis_stickiness").click
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.execute_script("return $('#add_sis_stickiness').is(':visible')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').is(':visible')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_false
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.find_element(:css, "#clear_sis_stickiness").click
    driver.find_element(:css, "#add_sis_stickiness").click
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.execute_script("return $('#add_sis_stickiness').is(':visible')").should be_false
    driver.execute_script("return $('#clear_sis_stickiness').is(':visible')").should be_false
    driver.execute_script("return $('#override_sis_stickiness').is(':visible')").should be_true
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_false
  end

  it 'should pass options along to the batch' do
    account_with_admin_logged_in
    @account.update_attribute(:allow_sis_import, true)
    get "/accounts/#{@account.id}/sis_import"
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.find_element(:css, "#add_sis_stickiness").click
    driver.find_element(:css, "#batch_mode").click
    driver.find_element(:css, "button.submit_button").click
    keep_trying_until { driver.execute_script("return $('div.progress_bar_holder div.progress_message').is(':visible')") }
    SisBatch.last.process_without_send_later
    keep_trying_until { driver.find_element(:css, "div.sis_messages div.error_message").text =~ /There was an error importing your SIS data\./ }
    SisBatch.last.batch_mode.should == true
    SisBatch.last.options.should == { :override_sis_stickiness => true,
                                      :add_sis_stickiness => true }

    expect_new_page_load { get "/accounts/#{@account.id}/sis_import" }
    driver.find_element(:css, "#override_sis_stickiness").click
    driver.find_element(:css, "button.submit_button").click
    keep_trying_until { driver.execute_script("return $('div.progress_bar_holder div.progress_message').is(':visible')") }
    SisBatch.last.process_without_send_later
    keep_trying_until { driver.find_element(:css, "div.sis_messages div.error_message").text =~ /There was an error importing your SIS data\./ }
    (!!SisBatch.last.batch_mode).should be_false
    SisBatch.last.options.should == { :override_sis_stickiness => true }
  end
end
