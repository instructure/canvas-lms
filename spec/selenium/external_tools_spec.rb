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
  
  it "should allow adding an external tool to a course module" do
    course_with_teacher_logged_in
    @module = @course.context_modules.create!(:name => "module")
    get "/courses/#{@course.id}/modules"
    
    keep_trying_until{ driver.execute_script("return window.modules.refreshed == true") }

    driver.find_element(:css, "#context_module_#{@module.id} .add_module_item_link").click
    driver.find_element(:css, "#add_module_item_select option[value='context_external_tool']").click
    driver.find_element(:css, "#external_tool_create_url").send_keys("http://www.example.com")
    driver.find_element(:css, "#external_tool_create_title").send_keys("Example")
    driver.find_element(:css, "#external_tool_create_new_tab").click
    driver.find_element(:css, "#select_context_content_dialog .add_item_button").click
    
    keep_trying_until{ !driver.find_element(:css, "#select_context_content_dialog").displayed? }
    keep_trying_until{ driver.find_elements(:css, "#context_module_item_new").length == 0 }
    
    @tag = ContentTag.last
    @tag.should_not be_nil
    @tag.title.should == "Example"
    @tag.new_tab.should == true
    @tag.url.should == "http://www.example.com"
  end
  
  it "should allow editing the settings for a tool in a module" do
    course_with_teacher_logged_in
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
      :type => 'context_external_tool',
      :title => 'Example',
      :url => 'http://www.example.com',
      :new_tab => '1'
    })
    get "/courses/#{@course.id}/modules"
    keep_trying_until{ driver.execute_script("return window.modules.refreshed == true") }
    
    driver.find_element(:css, "#context_module_item_#{@tag.id}").click
    driver.find_element(:css, "#context_module_item_#{@tag.id} .edit_item_link").click
    
    driver.find_element(:css, "#edit_item_form").should be_displayed
    driver.find_element(:css, "#edit_item_form #content_tag_title").clear
    driver.find_element(:css, "#edit_item_form #content_tag_title").send_keys "Example 2"
    driver.find_element(:css, "#edit_item_form #content_tag_new_tab").click
    driver.find_element(:css, "#edit_item_form button[type='submit']").click

    wait_for_ajax_requests
    
    @tag.reload
    @tag.should_not be_nil
    @tag.title.should == "Example 2"
    @tag.new_tab.should == false
    @tag.url.should == "http://www.example.com"
  end
  
  it "should automatically load tools with defaul configuration" do
    course_with_teacher_logged_in
    @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
      :type => 'context_external_tool',
      :title => 'Example',
      :url => 'http://www.example.com',
      :new_tab => '0'
    })
    get "/courses/#{@course.id}/modules/items/#{@tag.id}"
    
    driver.find_elements(:css, "#tool_content").length.should == 1
    keep_trying_until { driver.find_element(:css, "#tool_content").displayed? }
  end
  
  it "should not automatically load tools configured to load in a new tab" do
    course_with_teacher_logged_in
    @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
      :type => 'context_external_tool',
      :title => 'Example',
      :url => 'http://www.example.com',
      :new_tab => '1'
    })
    get "/courses/#{@course.id}/modules/items/#{@tag.id}"
    
    driver.find_elements(:css, "#tool_content").length.should == 0
    driver.find_element(:css, "#tool_form").should be_displayed
    driver.find_elements(:css, "#tool_form .load_tab").length.should == 1
  end
end
