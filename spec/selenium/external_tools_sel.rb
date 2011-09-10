require File.expand_path(File.dirname(__FILE__) + '/common')

describe "editing external tools" do
  it_should_behave_like "in-process server selenium tests"
  
  it "should allow creating a new course external tool with custom fields" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/settings"
    
    keep_trying_until { driver.find_element(:css, "#tab-tools-link").displayed? }
    driver.find_element(:css, "#tab-tools-link").click
    driver.find_element(:css, ".add_tool_link").click
    driver.find_element(:css, "#external_tools_dialog").should be_displayed
    driver.find_element(:css, "#external_tool_name").send_keys "Tool"
    driver.find_element(:css, "#external_tool_consumer_key").send_keys "Key"
    driver.find_element(:css, "#external_tool_shared_secret").send_keys "Secret"
    driver.find_element(:css, "#external_tool_domain").send_keys "example.com"
    driver.find_element(:css, "#external_tool_custom_fields_string").send_keys "a=1\nb=123"
    driver.find_element(:css, "#external_tools_dialog .save_button").click
    
    keep_trying_until { !driver.find_element(:css, "#external_tools_dialog").displayed? }
    
    tool = ContextExternalTool.last
    driver.find_element(:css, "#external_tool_#{tool.id}").should be_displayed
    tool.should_not be_nil
    tool.name.should == "Tool"
    tool.consumer_key.should == "Key"
    tool.shared_secret.should == "Secret"
    tool.domain.should == "example.com"
    tool.settings[:custom_fields].should == {'a' => '1', 'b' => '123'}
  end
  
  it "should allow editing an existing external tool with custom fields" do
    course_with_teacher_logged_in
    tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
    get "/courses/#{@course.id}/settings"
    
    keep_trying_until { driver.find_element(:css, "#tab-tools-link").displayed? }
    driver.find_element(:css, "#tab-tools-link").click
    tool_elem = driver.find_element(:css, "#external_tool_#{tool.id}")
    tool_elem.find_element(:css, ".edit_tool_link").click

    driver.find_element(:css, "#external_tools_dialog").should be_displayed

    driver.find_element(:css, "#external_tool_name").clear
    driver.find_element(:css, "#external_tool_consumer_key").clear
    driver.find_element(:css, "#external_tool_shared_secret").clear
    driver.find_element(:css, "#external_tool_domain").clear
    driver.find_element(:css, "#external_tool_custom_fields_string").clear

    driver.find_element(:css, "#external_tool_name").send_keys "new tool (updated)"
    driver.find_element(:css, "#external_tool_consumer_key").send_keys "key (updated)"
    driver.find_element(:css, "#external_tool_shared_secret").send_keys "secret (updated)"
    driver.find_element(:css, "#external_tool_domain").send_keys "example2.com"
    driver.find_element(:css, "#external_tool_custom_fields_string").send_keys "a=9\nb=8"
    driver.find_element(:css, "#external_tools_dialog .save_button").click
    
    keep_trying_until { !driver.find_element(:css, "#external_tools_dialog").displayed? }
    
    tool_elem = driver.find_elements(:css, "#external_tools .external_tool").detect(&:displayed?)
    tool_elem.should_not be_nil
    tool.reload
    tool.name.should == "new tool (updated)"
    tool.consumer_key.should == "key (updated)"
    tool.shared_secret.should == "secret (updated)"
    tool.domain.should == "example2.com"
    tool.settings[:custom_fields].should == {'a' => '9', 'b' => '8'}
  end
end
