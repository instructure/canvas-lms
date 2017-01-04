require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/statistics_specs')

describe "account admin statistics" do
  describe "shared statistics specs" do
    let(:url) { "/accounts/#{Account.default.id}/statistics" }
    let(:account) { Account.default }
    let(:list_css) { {:created => '#recently_created_item_list', :started => '#recently_started_item_list', :ended => '#recently_ended_item_list', :logged_in => '#recently_logged_in_item_list'} }
    include_examples "statistics basic tests"
  end
end
