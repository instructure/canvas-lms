require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "managing developer keys" do
  it_should_behave_like "in-process server selenium tests"

  before :each do
    account_admin_user(:account => Account.site_admin)
    user_session(@admin)
  end

  it "should allow creating, editing and deleting a developer key" do
    get '/developer_keys'
    wait_for_ajaximations
    ff("#keys tbody tr").length.should == 0

    f(".add_key").click
    f("#edit_dialog").should be_displayed
    f("#key_name").send_keys("Cool Tool")
    f("#email").send_keys("admin@example.com")
    f("#tool_id").send_keys("cool_tool")
    f("#redirect_uri").send_keys("http://example.com")
    f("#icon_url").send_keys("/images/delete.png")
    submit_dialog("#edit_dialog", '.submit')
    wait_for_ajaximations

    f("#edit_dialog").should_not be_displayed
    DeveloperKey.count.should == 1
    key = DeveloperKey.last
    key.name.should == "Cool Tool"
    key.tool_id.should == "cool_tool"
    key.email.should == "admin@example.com"
    key.redirect_uri.should == "http://example.com"
    key.icon_url.should == "/images/delete.png"
    ff("#keys tbody tr").length.should == 1

    f("#keys tbody tr.key .edit_link").click
    f("#edit_dialog").should be_displayed
    replace_content(f("#key_name"),"Cooler Tool")
    replace_content(f("#email"), "admins@example.com")
    replace_content(f("#tool_id"), "cooler_tool")
    replace_content(f("#redirect_uri"), "https://example.com")
    replace_content(f("#icon_url") ,"/images/add.png")
    submit_dialog("#edit_dialog", '.submit')
    wait_for_ajaximations

    f("#edit_dialog").should_not be_displayed
    DeveloperKey.count.should == 1
    key = DeveloperKey.last
    key.name.should == "Cooler Tool"
    key.email.should == "admins@example.com"
    key.tool_id.should == "cooler_tool"
    key.redirect_uri.should == "https://example.com"
    key.icon_url.should == "/images/add.png"
    ff("#keys tbody tr").length.should == 1

    f("#keys tbody tr.key .edit_link").click
    f("#edit_dialog").should be_displayed
    f("#tool_id").send_keys([:backspace] * 20, [:delete] * 20)
    f("#icon_url").send_keys([:backspace] * 20, [:delete] * 20)
    submit_dialog("#edit_dialog", '.submit')
    wait_for_ajaximations

    f("#edit_dialog").should_not be_displayed
    DeveloperKey.count.should == 1
    key = DeveloperKey.last
    key.tool_id.should == nil
    key.icon_url.should == nil
    ff("#keys tbody tr").length.should == 1

    f("#keys tbody tr.key .delete_link").click
    driver.switch_to.alert.accept
    driver.switch_to.default_content
    keep_trying_until { ff("#keys tbody tr").length == 0 }
    DeveloperKey.count.should == 0
  end

  it "should show the first 10 by default, with pagination working" do
    25.times { |i| DeveloperKey.create!(:name => "tool #{i}") }
    get '/developer_keys'
    f("#loading").should_not have_class('loading')
    ff("#keys tbody tr").length.should == 10
    f('#loading').should have_class('show_more')
    f("#loading .show_all").click
    wait_for_ajaximations
    keep_trying_until do
      f("#loading").should_not have_class('loading')
      true
    end
    ff("#keys tbody tr").length.should == 25
  end
end
