require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/grading_schemes_specs')

describe "sub account grading schemes" do
  describe "shared grading scheme specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:url) { "/accounts/#{account.id}/grading_standards" }
    it_should_behave_like "grading scheme basic tests"
  end
end
