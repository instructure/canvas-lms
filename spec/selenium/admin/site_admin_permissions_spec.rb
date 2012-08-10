require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/permissions_specs')

describe "account permissions" do

  describe "shared permission specs" do
    let(:url) { "/accounts/#{Account.default.id}/permissions?account_roles=1" }
    let(:account) { Account.default }
    it_should_behave_like "permission tests"
  end
end