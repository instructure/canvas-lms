require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/outcome_specs')

describe "account admin outcomes" do
  it_should_behave_like "outcome tests"

  describe "shared outcome specs" do
    let(:outcome_url) { "/accounts/#{Account.default.id}/outcomes" }
    let(:who_to_login) { 'admin' }
    it_should_behave_like "outcome specs"
  end
end