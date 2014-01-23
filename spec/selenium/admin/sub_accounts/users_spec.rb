require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/users_specs')

describe "sub account users" do
  describe "shared users specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:url) { "/accounts/#{account.id}/users" }
    let(:opts) { {:name => 'student'} }
    include_examples "users basic tests"
  end
end