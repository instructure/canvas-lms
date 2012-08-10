require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/rubrics_specs')

describe "sub account rubrics" do
  describe "shared rubric specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:rubric_url) { "/accounts/#{account.id}/rubrics" }
    let(:who_to_login) { 'admin' }
    it_should_behave_like "rubric tests"
  end
end