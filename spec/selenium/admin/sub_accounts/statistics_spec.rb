require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/statistics_specs')

describe "sub account statistics" do
  describe "shared statistics specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:url) { "/accounts/#{account.id}/statistics" }
    let(:list_css) { {:started => '#recently_started_item_list', :ended => '#recently_ended_item_list', :logged_in => '#recently_logged_in_item_list'} }
    include_examples "statistics basic tests"
  end
end
