require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "sis imports ui" do
  include_examples "in-process server selenium tests"

  def account_with_admin_logged_in(opts = {})
    @account = Account.default
    account_admin_user
    user_session(@admin)
  end

  it 'should properly show sis stickiness options' do
    account_with_admin_logged_in
    @account.update_attribute(:allow_sis_import, true)
    get "/accounts/#{@account.id}/sis_import"
    f('#add_sis_stickiness').should_not be_displayed
    f('#clear_sis_stickiness').should_not be_displayed
    f('#override_sis_stickiness').should be_displayed
    f('#add_sis_stickiness').should be_enabled
    f('#clear_sis_stickiness').should be_enabled
    f('#override_sis_stickiness').should be_enabled
    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_false
    driver.execute_script("return $('#override_sis_stickiness').attr('checked')").should be_false
    is_checked('#override_sis_stickiness').should be_false
    f("#override_sis_stickiness").click
    f('#add_sis_stickiness').should be_displayed
    f('#clear_sis_stickiness').should be_displayed
    f('#override_sis_stickiness').should be_displayed
    f('#add_sis_stickiness').should be_enabled
    f('#clear_sis_stickiness').should be_enabled
    f('#override_sis_stickiness').should be_enabled
    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_false
    is_checked('#override_sis_stickiness').should be_true
    f("#override_sis_stickiness").click

    f('#add_sis_stickiness').should_not be_displayed
    f('#clear_sis_stickiness').should_not be_displayed
    f('#override_sis_stickiness').should be_displayed
    f('#add_sis_stickiness').should be_enabled
    f('#clear_sis_stickiness').should be_enabled
    f('#override_sis_stickiness').should be_enabled
    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_false
    is_checked('#override_sis_stickiness').should be_false
    f("#override_sis_stickiness").click
    f("#add_sis_stickiness").click

    f('#add_sis_stickiness').should be_displayed
    f('#clear_sis_stickiness').should be_displayed
    f('#override_sis_stickiness').should be_displayed
    f('#add_sis_stickiness').should be_enabled
    f('#clear_sis_stickiness').should_not be_enabled
    f('#override_sis_stickiness').should be_enabled
    is_checked('#add_sis_stickiness').should be_true
    is_checked('#clear_sis_stickiness').should be_false
    is_checked('#override_sis_stickiness').should be_true
    f("#add_sis_stickiness").click

    f('#add_sis_stickiness').should be_displayed
    f('#clear_sis_stickiness').should be_displayed
    f('#override_sis_stickiness').should be_displayed
    f('#add_sis_stickiness').should be_enabled
    f('#clear_sis_stickiness').should be_enabled
    f('#override_sis_stickiness').should be_enabled
    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_false
    is_checked('#override_sis_stickiness').should be_true
    f("#clear_sis_stickiness").click

    f('#add_sis_stickiness').should be_displayed
    f('#clear_sis_stickiness').should be_displayed
    f('#override_sis_stickiness').should be_displayed
    f('#add_sis_stickiness').should_not be_enabled
    f('#clear_sis_stickiness').should be_enabled
    f('#override_sis_stickiness').should be_enabled

    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_true
    is_checked('#override_sis_stickiness').should be_true
    f("#clear_sis_stickiness").click

    f('#add_sis_stickiness').should be_displayed
    f('#clear_sis_stickiness').should be_displayed
    f('#override_sis_stickiness').should be_displayed
    f('#add_sis_stickiness').should be_enabled
    f('#clear_sis_stickiness').should be_enabled
    f('#override_sis_stickiness').should be_enabled

    is_checked('#add_sis_stickiness').should be_false
    is_checked('#clear_sis_stickiness').should be_false
    is_checked('#override_sis_stickiness').should be_true
    f("#clear_sis_stickiness").click
    f("#override_sis_stickiness").click

    f('#add_sis_stickiness').should_not be_displayed
    f('#clear_sis_stickiness').should_not be_displayed
    f('#override_sis_stickiness').should be_displayed
    is_checked('#override_sis_stickiness').should be_false
    f("#override_sis_stickiness").click
    f("#clear_sis_stickiness").click
    f("#add_sis_stickiness").click
    f("#override_sis_stickiness").click

    f('#add_sis_stickiness').should_not be_displayed
    f('#clear_sis_stickiness').should_not be_displayed
    f('#override_sis_stickiness').should be_displayed
    is_checked('#override_sis_stickiness').should be_false
  end

  it 'should pass options along to the batch' do
    account_with_admin_logged_in
    @account.update_attribute(:allow_sis_import, true)
    get "/accounts/#{@account.id}/sis_import"
    f("#override_sis_stickiness").click
    f("#add_sis_stickiness").click
    f("#batch_mode").click
    submit_form('#sis_importer')
    keep_trying_until { f('.progress_bar_holder .progress_message').should be_displayed }
    SisBatch.last.process_without_send_later
    keep_trying_until { f(".sis_messages .sis_error_message").text =~ /No SIS records were imported. The import failed with these messages:/ }
    SisBatch.last.batch_mode.should == true
    SisBatch.last.options.should == {:override_sis_stickiness => true,
                                     :add_sis_stickiness => true}

    expect_new_page_load { get "/accounts/#{@account.id}/sis_import" }
    f("#override_sis_stickiness").click
    submit_form('#sis_importer')
    keep_trying_until { f('.progress_bar_holder .progress_message').should be_displayed }
    SisBatch.last.process_without_send_later
    keep_trying_until { f(".sis_messages .sis_error_message").text =~ /No SIS records were imported. The import failed with these messages:/ }
    (!!SisBatch.last.batch_mode).should be_false
    SisBatch.last.options.should == {:override_sis_stickiness => true}
  end
end
