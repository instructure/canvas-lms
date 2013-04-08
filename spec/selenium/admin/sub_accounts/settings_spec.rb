require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/settings_specs')

describe "sub account settings" do
  describe "shared settings specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:account_settings_url) { "/accounts/#{account.id}/settings" }
    let(:admin_tab_url) { "/accounts/#{account.id}/settings#tab-users" }
    it_should_behave_like "settings basic tests"
  end
end