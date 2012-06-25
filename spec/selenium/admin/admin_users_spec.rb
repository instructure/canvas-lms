require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "admin courses tab" do
  it_should_behave_like "in-process server selenium tests"
  
  before (:each) do
    course_with_admin_logged_in
    get "/accounts/#{Account.default.id}/users"
  end
  
  def add_user (opts={})
   f(".add_user_link").click
   name = opts[:name] ? opts[:name] : "user1"
   email = opts[:email] ? opts[:email] : "user1@test.com"
   sortable_name = opts[:sortable_name] ? opts[:sortable_name] : name
   confirmation = opts[:confirmation] ? opts[:confirmation] : 1
   short_name = opts[:short_name] ? opts[:short_name] : name
   if (!short_name.eql? name)
       replace_content f("#user_short_name"), short_name
   end
   
   if(!sortable_name.eql? name)
      replace_content f("#user_sortable_name"), sortable_name
   end
   is_checked("#pseudonym_send_confirmation").should be_true
   if (confirmation == 0)
      f("#pseudonym_send_confirmation").click
      is_checked("#pseudonym_send_confirmation").should be_false
   end
   f("#add_user_form #user_name").send_keys name
   f("#pseudonym_unique_id").send_keys email
   submit_form("#add_user_form")
   wait_for_ajax_requests
   user = User.first(:conditions =>{:name => name})
   user.should be_present
   user.sortable_name.should eql sortable_name
   user.short_name.should eql short_name
   user.email.should eql email
   user
  end
  
  it "should add an new user" do
    opts = {:name => "user_name"}
    user = add_user opts
    #we need to refresh the page to see the user
    refresh_page
    f("#user_#{user.id}").should be_displayed
    f("#user_#{user.id}").should include_text "user_name"
  end
  
  it "should add an new user with a sortable name" do
    opts = {:sortable_name => "sortable name"}
    add_user(opts)
  end
   
  it "should add an new user with a short name" do
    opts = {:short_name => "short name"}
    add_user(opts)
  end
  
  it "should add a new user with confirmation disabled" do
    opts = {:confirmation => 0}
    add_user(opts) 
  end
  
  it "should search for a user and should go to it" do
    pending do # disabled until we can fix performance
      name = "user_1"
      opts = {:name => name}
      add_user(opts)
      f("#right-side #user_name").send_keys(name)
      ff(".ui-menu-item .ui-corner-all").count > 0
      wait_for_ajax_requests
      fj(".ui-menu-item .ui-corner-all:visible").should include_text(name)
      fj(".ui-menu-item .ui-corner-all:visible").click
      wait_for_ajax_requests
      f("#content h2").should include_text name
    end
  end
  
  it "should search for a bogus user" do
    name = "user_1"
    opts = {:name => name}
    add_user(opts)
    bogus_name = "ser 1"
    f("#right-side #user_name").send_keys(bogus_name)
    ff(".ui-menu-item .ui-corner-all").count == 0
  end
end 