require File.expand_path(File.dirname(__FILE__) + '/common')

describe "managing developer keys" do
  it_should_behave_like "in-process server selenium tests"

  before :each do
    account_admin_user(:account => Account.site_admin)
    user_session(@admin)
  end
  
  it "should allow creating, editing and deleting a developer key" do
    get '/developer_keys'
    keep_trying_until { f("#loading").attribute('class') != 'loading' }
    driver.find_elements(:css, "#keys tbody tr").length.should == 0
    
    f(".add_key").click
    f("#edit_dialog").should be_displayed
    f("#key_name").send_keys "Cool Tool"
    f("#email").send_keys "admin@example.com"
    f("#tool_id").send_keys "cool_tool"
    f("#redirect_uri").send_keys "http://example.com"
    f("#icon_url").send_keys "/images/delete.png"
    f("#edit_dialog .submit").click
    
    keep_trying_until { !f("#edit_dialog").displayed? }
    DeveloperKey.count.should == 1
    key = DeveloperKey.last
    key.name.should == "Cool Tool"
    key.tool_id.should == "cool_tool"
    key.email.should == "admin@example.com"
    key.redirect_uri.should == "http://example.com"
    key.icon_url.should == "/images/delete.png"
    driver.find_elements(:css, "#keys tbody tr").length.should == 1
    
    f("#keys tbody tr.key .edit_link").click
    f("#edit_dialog").should be_displayed
    f("#key_name").send_keys [:backspace] * 20, [:delete] * 20, "Cooler Tool"
    f("#email").send_keys [:backspace] * 20, [:delete] * 20, "admins@example.com"
    f("#tool_id").send_keys [:backspace] * 20, [:delete] * 20, "cooler_tool"
    f("#redirect_uri").send_keys [:backspace] * 20, [:delete] * 20, "https://example.com"
    f("#icon_url").send_keys [:backspace] * 20, [:delete] * 20, "/images/add.png"
    f("#edit_dialog .submit").click
    
    keep_trying_until { !f("#edit_dialog").displayed? }
    DeveloperKey.count.should == 1
    key = DeveloperKey.last
    key.name.should == "Cooler Tool"
    key.email.should == "admins@example.com"
    key.tool_id.should == "cooler_tool"
    key.redirect_uri.should == "https://example.com"
    key.icon_url.should == "/images/add.png"
    driver.find_elements(:css, "#keys tbody tr").length.should == 1
    
    f("#keys tbody tr.key .edit_link").click
    f("#edit_dialog").should be_displayed
    f("#tool_id").send_keys [:backspace] * 20, [:delete] * 20
    f("#icon_url").send_keys [:backspace] * 20, [:delete] * 20
    f("#edit_dialog .submit").click
    
    keep_trying_until { !f("#edit_dialog").displayed? }
    DeveloperKey.count.should == 1
    key = DeveloperKey.last
    key.tool_id.should == nil
    key.icon_url.should == nil
    driver.find_elements(:css, "#keys tbody tr").length.should == 1
    
    f("#keys tbody tr.key .delete_link").click
    driver.switch_to.alert.accept
    driver.switch_to.default_content
    keep_trying_until { driver.find_elements(:css, "#keys tbody tr").length == 0 }
    DeveloperKey.count.should == 0
  end
  
  it "should show the first 10 by default, with pagination working" do
    25.times do |i|
      DeveloperKey.create!(:name => "tool #{i}")
    end
    get '/developer_keys'
    keep_trying_until { f("#loading").attribute('class') != 'loading' }
    driver.find_elements(:css, "#keys tbody tr").length.should == 10
    f("#loading").attribute('class').should == 'show_more'
    f("#loading .show_all").click
    keep_trying_until { f("#loading").attribute('class') != 'loading' }
    driver.find_elements(:css, "#keys tbody tr").length.should == 25
  end
  
end
