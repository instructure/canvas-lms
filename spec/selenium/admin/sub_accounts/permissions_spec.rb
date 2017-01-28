require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/permissions_specs')

describe "sub account permissions" do
  describe "shared permission specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:url) { "/accounts/#{account.id}/permissions?account_roles=1" }
    include_examples "permission tests"
  end
end
