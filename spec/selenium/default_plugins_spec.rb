require File.expand_path(File.dirname(__FILE__) + '/common')

describe "default plugins" do
  it_should_behave_like "in-process server selenium tests"

  before(:each) do
    user_logged_in
    Account.site_admin.add_user(@user)
  end

  it "should allow configuring twitter plugin" do
    settings = Canvas::Plugin.find(:twitter).try(:settings)
    settings.should be_nil

    Twitter.stubs(:config_check).returns("Bad check")
    get "/plugins/twitter"

    driver.find_element(:css, "#plugin_setting_disabled").click

    driver.find_element(:css, "#settings_api_key").send_keys("asdf")
    driver.find_element(:css, "#settings_secret_key").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click

    assert_flash_error_message /There was an error/

    Twitter.stubs(:config_check).returns(nil)
    driver.find_element(:css, "button.save_button").click
    wait_for_ajax_requests

    assert_flash_notice_message /successfully updated/

    settings = Canvas::Plugin.find(:twitter).try(:settings)
    settings.should_not be_nil
    settings[:api_key].should == 'asdf'
    settings[:secret_key].should == 'asdf'
  end

  it "should allow configuring etherpad plugin" do
    settings = Canvas::Plugin.find(:etherpad).try(:settings)
    settings.should be_nil

    get "/plugins/etherpad"

    driver.find_element(:css, "#plugin_setting_disabled").click

    driver.find_element(:css, "#settings_domain").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click

    assert_flash_error_message /There was an error/

    driver.find_element(:css, "#settings_name").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click
    wait_for_ajax_requests

    assert_flash_notice_message /successfully updated/

    settings = Canvas::Plugin.find(:etherpad).try(:settings)
    settings.should_not be_nil
    settings[:domain].should == 'asdf'
    settings[:name].should == 'asdf'
  end

  it "should allow configuring google docs plugin" do
    settings = Canvas::Plugin.find(:google_docs).try(:settings)
    settings.should be_nil

    GoogleDocs.stubs(:config_check).returns("Bad check")
    get "/plugins/google_docs"

    driver.find_element(:css, "#plugin_setting_disabled").click

    driver.find_element(:css, "#settings_api_key").send_keys("asdf")
    driver.find_element(:css, "#settings_secret_key").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click

    assert_flash_error_message /There was an error/

    GoogleDocs.stubs(:config_check).returns(nil)
    driver.find_element(:css, "button.save_button").click
    wait_for_ajax_requests

    assert_flash_notice_message /successfully updated/

    settings = Canvas::Plugin.find(:google_docs).try(:settings)
    settings.should_not be_nil
    settings[:api_key].should == 'asdf'
    settings[:secret_key].should == 'asdf'
  end

  it "should allow configuring linked in plugin" do
    settings = Canvas::Plugin.find(:linked_in).try(:settings)
    settings.should be_nil

    LinkedIn.stubs(:config_check).returns("Bad check")
    get "/plugins/linked_in"

    driver.find_element(:css, "#plugin_setting_disabled").click

    driver.find_element(:css, "#settings_api_key").send_keys("asdf")
    driver.find_element(:css, "#settings_secret_key").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click

    assert_flash_error_message /There was an error/

    LinkedIn.stubs(:config_check).returns(nil)
    driver.find_element(:css, "button.save_button").click
    wait_for_ajax_requests

    assert_flash_notice_message /successfully updated/

    settings = Canvas::Plugin.find(:linked_in).try(:settings)
    settings.should_not be_nil
    settings[:api_key].should == 'asdf'
    settings[:secret_key].should == 'asdf'
  end

  it "should allow configuring scribd plugin" do
    settings = Canvas::Plugin.find(:scribd).try(:settings)
    settings.should be_nil

    ScribdAPI.stubs(:config_check).returns("Bad check")
    get "/plugins/scribd"

    driver.find_element(:css, "#plugin_setting_disabled").click

    driver.find_element(:css, "#settings_api_key").send_keys("asdf")
    driver.find_element(:css, "#settings_secret_key").send_keys("asdf")
    keep_trying_until {
      driver.find_element(:css, "button.save_button").click
      wait_for_ajaximations
      assert_flash_error_message /There was an error/
    }

    ScribdAPI.stubs(:config_check).returns(nil)
    driver.find_element(:css, "button.save_button").click
    wait_for_ajax_requests

    assert_flash_notice_message /successfully updated/

    settings = Canvas::Plugin.find(:scribd).try(:settings)
    settings.should_not be_nil
    settings[:api_key].should == 'asdf'
    settings[:secret_key].should == 'asdf'
  end

  it "should allow configuring tinychat plugin" do
    settings = Canvas::Plugin.find(:tinychat).try(:settings)
    settings.should be_nil

    Tinychat.stubs(:config_check).returns("Bad check")
    get "/plugins/tinychat"

    driver.find_element(:css, "#plugin_setting_disabled").click

    driver.find_element(:css, "#settings_api_key").send_keys("asdf")
    driver.find_element(:css, "#settings_secret_key").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click

    assert_flash_error_message /There was an error/

    Tinychat.stubs(:config_check).returns(nil)
    driver.find_element(:css, "button.save_button").click
    wait_for_ajax_requests

    assert_flash_notice_message /successfully updated/

    settings = Canvas::Plugin.find(:tinychat).try(:settings)
    settings.should_not be_nil
    settings[:api_key].should == 'asdf'
    settings[:secret_key].should == 'asdf'
  end
end

