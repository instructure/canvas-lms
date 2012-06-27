require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/shared_user_methods')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/users_specs')

describe "admin courses tab" do
  it_should_behave_like "in-process server selenium tests"

  context "add user basic" do
    describe "shared users specs" do
      let(:account) { Account.default }
      let(:url) { "/accounts/#{account.id}/users" }
      let(:opts) { {:name => 'student'} }
      it_should_behave_like "users basic tests"
    end
  end

  context "add users" do

    before (:each) do
      course_with_admin_logged_in
      get "/accounts/#{Account.default.id}/users"
    end

    it "should add an new user with a sortable name" do
      add_user({:sortable_name => "sortable name"})
    end

    it "should add an new user with a short name" do
      add_user({:short_name => "short name"})
    end

    it "should add a new user with confirmation disabled" do
      add_user({:confirmation => 0})
    end

    it "should search for a user and should go to it" do
      pending('disabled until we can fix performance')
      name = "user_1"
      add_user({:name => name})
      f("#right-side #user_name").send_keys(name)
      ff(".ui-menu-item .ui-corner-all").count > 0
      wait_for_ajax_requests
      fj(".ui-menu-item .ui-corner-all:visible").should include_text(name)
      fj(".ui-menu-item .ui-corner-all:visible").click
      wait_for_ajax_requests
      f("#content h2").should include_text name
    end

    it "should search for a bogus user" do
      name = "user_1"
      add_user({:name => name})
      bogus_name = "ser 1"
      f("#right-side #user_name").send_keys(bogus_name)
      ff(".ui-menu-item .ui-corner-all").count == 0
    end
  end
end