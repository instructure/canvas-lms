require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/outcome_specs')

describe "sub account outcomes" do
  describe "shared outcome specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:outcome_url) { "/accounts/#{account.id}/outcomes" }
    let(:who_to_login) { 'admin' }
    it_should_behave_like "outcome tests"
  end
end