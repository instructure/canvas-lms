require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/settings_specs')

describe "sub account basic settings" do
  let(:account) { Account.create(name: 'sub account from default account', parent_account: Account.default) }
  let(:account_settings_url) { "/accounts/#{account.id}/settings" }
  let(:admin_tab_url) { "/accounts/#{account.id}/settings#tab-users" }
  include_examples "settings basic tests", true

  it "should disable inherited settings if locked by a parent account", priority: "1", test_id: 250007 do
    parent = Account.default
    parent.settings[:restrict_student_future_view] = {locked: true, value: true}
    parent.save!

    get account_settings_url

    expect(f('#account_settings_restrict_student_past_view_value').attribute('disabled')).to be_nil
    expect(f('#account_settings_restrict_student_past_view_locked')).to_not be_nil

    expect(f('#account_settings_restrict_student_future_view_value').attribute('disabled')).to_not be_nil
    expect(f('#account_settings_restrict_student_future_view_locked')).to be_nil # don't even show the locked checkbox

    expect(is_checked('#account_settings_restrict_student_future_view_value')).to be_truthy
  end
end