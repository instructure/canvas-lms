require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/settings_common')

describe "sub account settings" do
  it_should_behave_like "in-process server selenium tests"
  let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
  let(:account_settings_url) { "/accounts/#{account.id}/settings" }
  let(:admin_tab_url) { "/accounts/#{account.id}/settings#tab-users" }

  before (:each) do
    course_with_admin_logged_in
  end

  context "admins tab" do

    before (:each) do
      get "/accounts/#{account.id}/settings"
      f("#tab-users-link").click
    end

    it "should add an account admin" do
      should_add_an_account_admin
    end

    it "should delete an account admin" do
      should_delete_an_account_admin
    end
  end

  context "account settings" do

    before (:each) do
      get account_settings_url
    end

    it "should change the account name " do
      should_change_the_account_name
    end

    it "should change the default file quota" do
      should_change_the_default_file_quota
    end

    it "should change the default language to spanish" do
      should_change_the_default_language_to_spanish
    end
  end
end