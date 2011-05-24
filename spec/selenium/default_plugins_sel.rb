require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "plugins selenium tests" do
  it_should_behave_like "in-process server selenium tests"
  
  before(:each) do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    Account.site_admin.add_user(u)
    login_as(username, password)
  end
  
  it "should allow configuring twitter plugin" do
    settings = Canvas::Plugin.find(:twitter).try(:settings)
    settings.should be_nil
    
    Twitter.stub(:config_check).and_return("Bad check")
    get "/plugins/twitter"
    
    driver.find_element(:css, "#settings_api_key").send_keys("asdf")
    driver.find_element(:css, "#settings_secret_key").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click
    
    keep_trying{ driver.find_element(:css, "#flash_error_message").displayed? }
    driver.find_element(:css, "#flash_error_message").text.should match(/There was an error/)
    
    Twitter.stub(:config_check).and_return(nil)
    driver.find_element(:css, "button.save_button").click
    
    keep_trying{ driver.find_element(:css, "#flash_notice_message").displayed? }
    driver.find_element(:css, "#flash_notice_message").text.should match(/successfully updated/)
    
    settings = Canvas::Plugin.find(:twitter).try(:settings)
    settings.should_not be_nil
    settings[:api_key].should == 'asdf'
    settings[:secret_key].should == 'asdf'
  end
  
  it "should allow configuring etherpad plugin" do
    settings = Canvas::Plugin.find(:etherpad).try(:settings)
    settings.should be_nil
    
    get "/plugins/etherpad"
    
    driver.find_element(:css, "#settings_domain").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click
    
    keep_trying{ driver.find_element(:css, "#flash_error_message").displayed? }
    driver.find_element(:css, "#flash_error_message").text.should match(/There was an error/)
    
    driver.find_element(:css, "#settings_name").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click
    
    keep_trying{ driver.find_element(:css, "#flash_notice_message").displayed? }
    driver.find_element(:css, "#flash_notice_message").text.should match(/successfully updated/)
    
    settings = Canvas::Plugin.find(:etherpad).try(:settings)
    settings.should_not be_nil
    settings[:domain].should == 'asdf'
    settings[:name].should == 'asdf'
  end
  
  it "should allow configuring google docs plugin" do
    settings = Canvas::Plugin.find(:google_docs).try(:settings)
    settings.should be_nil
    
    GoogleDocs.stub(:config_check).and_return("Bad check")
    get "/plugins/google_docs"
    
    driver.find_element(:css, "#settings_api_key").send_keys("asdf")
    driver.find_element(:css, "#settings_secret_key").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click
    
    keep_trying{ driver.find_element(:css, "#flash_error_message").displayed? }
    driver.find_element(:css, "#flash_error_message").text.should match(/There was an error/)
    
    GoogleDocs.stub(:config_check).and_return(nil)
    driver.find_element(:css, "button.save_button").click
    
    keep_trying{ driver.find_element(:css, "#flash_notice_message").displayed? }
    driver.find_element(:css, "#flash_notice_message").text.should match(/successfully updated/)
    
    settings = Canvas::Plugin.find(:google_docs).try(:settings)
    settings.should_not be_nil
    settings[:api_key].should == 'asdf'
    settings[:secret_key].should == 'asdf'
  end
  
  it "should allow configuring linked in plugin" do
    settings = Canvas::Plugin.find(:linked_in).try(:settings)
    settings.should be_nil
    
    LinkedIn.stub(:config_check).and_return("Bad check")
    get "/plugins/linked_in"
    
    driver.find_element(:css, "#settings_api_key").send_keys("asdf")
    driver.find_element(:css, "#settings_secret_key").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click
    
    keep_trying{ driver.find_element(:css, "#flash_error_message").displayed? }
    driver.find_element(:css, "#flash_error_message").text.should match(/There was an error/)
    
    LinkedIn.stub(:config_check).and_return(nil)
    driver.find_element(:css, "button.save_button").click
    
    keep_trying{ driver.find_element(:css, "#flash_notice_message").displayed? }
    driver.find_element(:css, "#flash_notice_message").text.should match(/successfully updated/)
    
    settings = Canvas::Plugin.find(:linked_in).try(:settings)
    settings.should_not be_nil
    settings[:api_key].should == 'asdf'
    settings[:secret_key].should == 'asdf'
  end
  
  it "should allow configuring scribd plugin" do
    settings = Canvas::Plugin.find(:scribd).try(:settings)
    settings.should be_nil
    
    ScribdAPI.stub(:config_check).and_return("Bad check")
    get "/plugins/scribd"
    
    driver.find_element(:css, "#settings_api_key").send_keys("asdf")
    driver.find_element(:css, "#settings_secret_key").send_keys("asdf")
    driver.find_element(:css, "button.save_button").click
    
    keep_trying{ driver.find_element(:css, "#flash_error_message").displayed? }
    driver.find_element(:css, "#flash_error_message").text.should match(/There was an error/)
    
    ScribdAPI.stub(:config_check).and_return(nil)
    driver.find_element(:css, "button.save_button").click
    
    keep_trying{ driver.find_element(:css, "#flash_notice_message").displayed? }
    driver.find_element(:css, "#flash_notice_message").text.should match(/successfully updated/)
    
    settings = Canvas::Plugin.find(:scribd).try(:settings)
    settings.should_not be_nil
    settings[:api_key].should == 'asdf'
    settings[:secret_key].should == 'asdf'
  end
end

describe "plugins Windows-Firefox-Tests" do
  it_should_behave_like "plugins selenium tests"
end

