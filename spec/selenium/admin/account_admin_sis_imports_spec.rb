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
    expect(f('#add_sis_stickiness')).not_to be_displayed
    expect(f('#clear_sis_stickiness')).not_to be_displayed
    expect(f('#override_sis_stickiness')).to be_displayed
    expect(f('#add_sis_stickiness')).to be_enabled
    expect(f('#clear_sis_stickiness')).to be_enabled
    expect(f('#override_sis_stickiness')).to be_enabled
    expect(is_checked('#add_sis_stickiness')).to be_falsey
    expect(is_checked('#clear_sis_stickiness')).to be_falsey
    expect(driver.execute_script("return $('#override_sis_stickiness').attr('checked')")).to be_falsey
    expect(is_checked('#override_sis_stickiness')).to be_falsey
    f("#override_sis_stickiness").click
    expect(f('#add_sis_stickiness')).to be_displayed
    expect(f('#clear_sis_stickiness')).to be_displayed
    expect(f('#override_sis_stickiness')).to be_displayed
    expect(f('#add_sis_stickiness')).to be_enabled
    expect(f('#clear_sis_stickiness')).to be_enabled
    expect(f('#override_sis_stickiness')).to be_enabled
    expect(is_checked('#add_sis_stickiness')).to be_falsey
    expect(is_checked('#clear_sis_stickiness')).to be_falsey
    expect(is_checked('#override_sis_stickiness')).to be_truthy
    f("#override_sis_stickiness").click

    expect(f('#add_sis_stickiness')).not_to be_displayed
    expect(f('#clear_sis_stickiness')).not_to be_displayed
    expect(f('#override_sis_stickiness')).to be_displayed
    expect(f('#add_sis_stickiness')).to be_enabled
    expect(f('#clear_sis_stickiness')).to be_enabled
    expect(f('#override_sis_stickiness')).to be_enabled
    expect(is_checked('#add_sis_stickiness')).to be_falsey
    expect(is_checked('#clear_sis_stickiness')).to be_falsey
    expect(is_checked('#override_sis_stickiness')).to be_falsey
    f("#override_sis_stickiness").click
    f("#add_sis_stickiness").click

    expect(f('#add_sis_stickiness')).to be_displayed
    expect(f('#clear_sis_stickiness')).to be_displayed
    expect(f('#override_sis_stickiness')).to be_displayed
    expect(f('#add_sis_stickiness')).to be_enabled
    expect(f('#clear_sis_stickiness')).not_to be_enabled
    expect(f('#override_sis_stickiness')).to be_enabled
    expect(is_checked('#add_sis_stickiness')).to be_truthy
    expect(is_checked('#clear_sis_stickiness')).to be_falsey
    expect(is_checked('#override_sis_stickiness')).to be_truthy
    f("#add_sis_stickiness").click

    expect(f('#add_sis_stickiness')).to be_displayed
    expect(f('#clear_sis_stickiness')).to be_displayed
    expect(f('#override_sis_stickiness')).to be_displayed
    expect(f('#add_sis_stickiness')).to be_enabled
    expect(f('#clear_sis_stickiness')).to be_enabled
    expect(f('#override_sis_stickiness')).to be_enabled
    expect(is_checked('#add_sis_stickiness')).to be_falsey
    expect(is_checked('#clear_sis_stickiness')).to be_falsey
    expect(is_checked('#override_sis_stickiness')).to be_truthy
    f("#clear_sis_stickiness").click

    expect(f('#add_sis_stickiness')).to be_displayed
    expect(f('#clear_sis_stickiness')).to be_displayed
    expect(f('#override_sis_stickiness')).to be_displayed
    expect(f('#add_sis_stickiness')).not_to be_enabled
    expect(f('#clear_sis_stickiness')).to be_enabled
    expect(f('#override_sis_stickiness')).to be_enabled

    expect(is_checked('#add_sis_stickiness')).to be_falsey
    expect(is_checked('#clear_sis_stickiness')).to be_truthy
    expect(is_checked('#override_sis_stickiness')).to be_truthy
    f("#clear_sis_stickiness").click

    expect(f('#add_sis_stickiness')).to be_displayed
    expect(f('#clear_sis_stickiness')).to be_displayed
    expect(f('#override_sis_stickiness')).to be_displayed
    expect(f('#add_sis_stickiness')).to be_enabled
    expect(f('#clear_sis_stickiness')).to be_enabled
    expect(f('#override_sis_stickiness')).to be_enabled

    expect(is_checked('#add_sis_stickiness')).to be_falsey
    expect(is_checked('#clear_sis_stickiness')).to be_falsey
    expect(is_checked('#override_sis_stickiness')).to be_truthy
    f("#clear_sis_stickiness").click
    f("#override_sis_stickiness").click

    expect(f('#add_sis_stickiness')).not_to be_displayed
    expect(f('#clear_sis_stickiness')).not_to be_displayed
    expect(f('#override_sis_stickiness')).to be_displayed
    expect(is_checked('#override_sis_stickiness')).to be_falsey
    f("#override_sis_stickiness").click
    f("#clear_sis_stickiness").click
    f("#add_sis_stickiness").click
    f("#override_sis_stickiness").click

    expect(f('#add_sis_stickiness')).not_to be_displayed
    expect(f('#clear_sis_stickiness')).not_to be_displayed
    expect(f('#override_sis_stickiness')).to be_displayed
    expect(is_checked('#override_sis_stickiness')).to be_falsey
  end

  it 'should pass options along to the batch' do
    account_with_admin_logged_in
    @account.update_attribute(:allow_sis_import, true)
    get "/accounts/#{@account.id}/sis_import"
    f("#override_sis_stickiness").click
    f("#add_sis_stickiness").click
    f("#batch_mode").click
    submit_form('#sis_importer')
    keep_trying_until { expect(f('.progress_bar_holder .progress_message')).to be_displayed }
    SisBatch.last.process_without_send_later
    keep_trying_until { f(".sis_messages .sis_error_message").text =~ /No SIS records were imported. The import failed with these messages:/ }
    expect(SisBatch.last.batch_mode).to eq true
    expect(SisBatch.last.options).to eq({:override_sis_stickiness => true,
                                     :add_sis_stickiness => true})

    expect_new_page_load { get "/accounts/#{@account.id}/sis_import" }
    f("#override_sis_stickiness").click
    submit_form('#sis_importer')
    keep_trying_until { expect(f('.progress_bar_holder .progress_message')).to be_displayed }
    SisBatch.last.process_without_send_later
    keep_trying_until { f(".sis_messages .sis_error_message").text =~ /No SIS records were imported. The import failed with these messages:/ }
    expect(!!SisBatch.last.batch_mode).to be_falsey
    expect(SisBatch.last.options).to eq({:override_sis_stickiness => true})
  end
end
