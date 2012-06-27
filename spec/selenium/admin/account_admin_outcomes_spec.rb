require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/outcome_specs')

describe "account admin outcomes" do
  describe "shared outcome specs" do
    let(:outcome_url) { "/accounts/#{Account.default.id}/outcomes" }
    let(:who_to_login) { 'admin' }
    let(:account) { Account.default }
    it_should_behave_like "outcome tests"
  end
end