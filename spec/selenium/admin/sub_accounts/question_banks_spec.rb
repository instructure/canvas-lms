require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/question_banks_specs')

describe "sub account question banks" do
  describe "shared question bank specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:url) { "/accounts/#{account.id}/question_banks" }
    include_examples "question bank basic tests"
  end
end