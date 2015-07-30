require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/settings_specs')

describe "root account basic settings" do
  let(:account) { Account.default }
  let(:account_settings_url) { "/accounts/#{account.id}/settings" }
  let(:admin_tab_url) { "/accounts/#{account.id}/settings#tab-users" }
  include_examples "settings basic tests", false

  it "should change the default user quota", priority: "1", test_id: 250002 do
    course_with_admin_logged_in
    group_model(context: @course)
    get account_settings_url

    f('#tab-quotas-link').click

    # update the quotas
    user_quota = account.default_user_storage_quota_mb
    user_quota_input = f('[name="default_user_storage_quota_mb"]')
    expect(user_quota_input).to have_value(user_quota.to_s)

    user_quota += 15
    replace_content(user_quota_input, user_quota.to_s)

    submit_form('#default-quotas')
    wait_for_ajax_requests

    # ensure the account was updated properly
    account.reload
    expect(account.default_user_storage_quota).to eq user_quota * 1048576

    # ensure the new value is reflected after a refresh
    get account_settings_url
    expect(fj('[name="default_user_storage_quota_mb"]')).to have_value(user_quota.to_s) # fj to avoid selenium caching
  end
end