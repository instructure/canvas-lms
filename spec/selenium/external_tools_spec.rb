require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/external_tools_common')

describe "editing external tools" do
  it_should_behave_like "external tools tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should allow creating a new course external tool with custom fields" do
    get "/courses/#{@course.id}/settings"
    f("#tab-tools-link").click
    add_external_tool
    f("#external_tools_dialog").should_not be_displayed
    tool = ContextExternalTool.last
    tool_elem = f("#external_tool_#{tool.id}")
    tool_elem.should be_displayed
  end

  it "should allow creating a new course external tool with extensions" do
    get "/courses/#{@course.id}/settings"
    f("#tab-tools-link").click
    add_external_tool :xml
  end

  it "should allow editing an existing external tool with custom fields" do
    tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
    get "/courses/#{@course.id}/settings"
    keep_trying_until { f("#tab-tools-link").should be_displayed }
    f("#tab-tools-link").click
    tool_elem = f("#external_tool_#{tool.id}")
    tool_elem.find_element(:css, ".edit_tool_link").click
    f("#external_tools_dialog").should be_displayed
    replace_content(f("#external_tool_name"),"new tool (updated)")
    replace_content(f("#external_tool_consumer_key"),"key (updated)")
    replace_content(f("#external_tool_shared_secret"),"secret (updated)")
    replace_content(f("#external_tool_domain"), "example2.com")
    replace_content(f("#external_tool_custom_fields_string"),"a=9\nb=8")
    f("#external_tools_dialog .save_button").click
    wait_for_ajax_requests
    f("#external_tools_dialog").should_not be_displayed
    tool_elem = fj("#external_tools .external_tool:visible").should be_displayed
    tool_elem.should_not be_nil
    tool.reload
    tool.name.should eql "new tool (updated)"
    tool.consumer_key.should eql "key (updated)"
    tool.shared_secret.should eql "secret (updated)"
    tool.domain.should eql "example2.com"
    tool.settings[:custom_fields].should == {'a' => '9', 'b' => '8'}
  end

  it "should allow adding an external tool to a course module" do
    @module = @course.context_modules.create!(:name => "module")
    get "/courses/#{@course.id}/modules"

    keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

    f("#context_module_#{@module.id} .add_module_item_link").click
    f("#add_module_item_select option[value='context_external_tool']").click
    f("#external_tool_create_url").send_keys("http://www.example.com")
    f("#external_tool_create_title").send_keys("Example")
    f("#external_tool_create_new_tab").click
    f("#select_context_content_dialog .add_item_button").click
    wait_for_ajax_requests
    f("#select_context_content_dialog").should_not be_displayed
    ff("#context_module_item_new").length.should eql 0

    @tag = ContentTag.last
    @tag.should_not be_nil
    @tag.title.should == "Example"
    @tag.new_tab.should == true
    @tag.url.should == "http://www.example.com"
  end

  it "should not list external tools that don't have a url, domain, or resource_selection configured" do
    @module = @course.context_modules.create!(:name => "module")
    
    @tool1 = @course.context_external_tools.create!(:name => "First Tool", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
    @tool2 = @course.context_external_tools.new(:name => "Another Tool", :consumer_key => "key", :shared_secret => "secret")
    @tool2.settings[:editor_button] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
    @tool2.save!
    @tool3 = @course.context_external_tools.new(:name => "Third Tool", :consumer_key => "key", :shared_secret => "secret")
    @tool3.settings[:resource_selection] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
    @tool3.save!

    get "/courses/#{@course.id}/modules"

    keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

    driver.find_element(:css, "#context_module_#{@module.id} .add_module_item_link").click
    driver.find_element(:css, "#add_module_item_select option[value='context_external_tool']").click
    
    keep_trying_until { driver.find_elements(:css, "#context_external_tools_select .tool .name").length > 0 }
    names = driver.find_elements(:css, "#context_external_tools_select .tool .name").map(&:text)
    names.should be_include(@tool1.name)
    names.should_not be_include(@tool2.name)
    names.should be_include(@tool3.name)
  end

  it "should allow adding an existing external tool to a course module, and should pick the correct tool" do
    @module = @course.context_modules.create!(:name => "module")
    @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
    @tool2 = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

    get "/courses/#{@course.id}/modules"

    keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

    f("#context_module_#{@module.id} .add_module_item_link").click
    f("#add_module_item_select option[value='context_external_tool']").click
    keep_trying_until { ff("#context_external_tools_select .tools .tool").length > 0 }
    ff("#context_external_tools_select .tools .tool")[1].click
    f("#external_tool_create_url").should have_value @tool2.url
    f("#external_tool_create_title").should have_value @tool2.name
    ff("#context_external_tools_select .tools .tool")[0].click
    f("#external_tool_create_url").should have_value @tool1.url
    f("#external_tool_create_title").should have_value @tool1.name
    f("#select_context_content_dialog .add_item_button").click
    wait_for_ajax_requests
    f("#select_context_content_dialog").should_not be_displayed
    keep_trying_until { ff("#context_module_item_new").length.should eql 0 }

    @tag = ContentTag.last
    @tag.should_not be_nil
    @tag.title.should == @tool1.name
    @tag.url.should == @tool1.url
    @tag.content.should == @tool1

    f("#context_module_#{@module.id} .add_module_item_link").click
    f("#add_module_item_select option[value='context_external_tool']").click
    ff("#context_external_tools_select .tools .tool")[1].click
    f("#external_tool_create_url").should have_value @tool2.url
    f("#external_tool_create_title").should have_value @tool2.name
    f("#select_context_content_dialog .add_item_button").click
    wait_for_ajax_requests
    f("#select_context_content_dialog").should_not be_displayed
    ff("#context_module_item_new").length.should eql 0

    @tag = ContentTag.last
    @tag.should_not be_nil
    @tag.title.should == @tool2.name
    @tag.url.should == @tool2.url
  end

  it "should allow adding an external tool with resource selection enabled to a course module" do
    @module = @course.context_modules.create!(:name => "module")
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
    tool.settings[:resource_selection] = {
        :url => "http://#{HostUrl.default_host}/selection_test",
        :selection_width => 400,
        :selection_height => 400
    }
    tool.save!
    tool2 = @course.context_external_tools.new(:name => "not bob", :consumer_key => "not bob", :shared_secret => "not bob", :url => "https://www.example.com")
    tool2.save!
    get "/courses/#{@course.id}/modules"

    keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

    f("#context_module_#{@module.id} .add_module_item_link").click
    f("#add_module_item_select option[value='context_external_tool']").click
    wait_for_ajax_requests
    ff("#context_external_tools_select .tools .tool").length > 0

    tools = ff("#context_external_tools_select .tools .tool")
    tools[0].find_element(:css, ".name").text.should_not match(/not/)
    tools[1].find_element(:css, ".name").text.should match(/not bob/)
    tools[1].click
    f("#external_tool_create_url").should have_value "https://www.example.com"
    f("#external_tool_create_title").should have_value"not bob"

    tools[0].click
    keep_trying_until { f("#resource_selection_dialog").should be_displayed }

    in_frame('resource_selection_iframe') do
      keep_trying_until { ff("#basic_lti_link").length > 0 }
      ff(".link").length.should eql 4
      f("#basic_lti_link").click
      wait_for_ajax_requests
    end
    f("#resource_selection_dialog").should_not be_displayed
    f("#external_tool_create_url").should have_value "http://www.example.com"
    f("#external_tool_create_title").should have_value "lti embedded link"
  end

  it "should alert when invalid url data is returned by a resource selection dialog" do
    skip_if_ie("Out of memory / Stack overflow")
    @module = @course.context_modules.create!(:name => "module")
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
    tool.settings[:resource_selection] = {
        :url => "http://#{HostUrl.default_host}/selection_test",
        :selection_width => 400,
        :selection_height => 400
    }
    tool.save!
    tool2 = @course.context_external_tools.new(:name => "not bob", :consumer_key => "not bob", :shared_secret => "not bob", :url => "https://www.example.com")
    tool2.save!
    get "/courses/#{@course.id}/modules"

    keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

    f("#context_module_#{@module.id} .add_module_item_link").click
    f("#add_module_item_select option[value='context_external_tool']").click
    wait_for_ajax_requests
    ff("#context_external_tools_select .tools .tool").length > 0

    tools = ff("#context_external_tools_select .tools .tool")
    tools[0].find_element(:css, ".name").text.should_not match(/not/)
    tools[1].find_element(:css, ".name").text.should match(/not bob/)
    tools[1].click
    f("#external_tool_create_url").should have_value "https://www.example.com"
    f("#external_tool_create_title").should have_value "not bob"

    tools[0].click

    keep_trying_until {f("#resource_selection_dialog").should be_displayed }

    expect_fired_alert do
      in_frame('resource_selection_iframe') do
        keep_trying_until { ff("#basic_lti_link").length > 0 }
        ff(".link").length.should eql 4
        f("#bad_url_basic_lti_link").click
      end
    end
    wait_for_ajax_requests
    f("#resource_selection_dialog").should_not be_displayed

    f("#external_tool_create_url").should have_value ""
    f("#external_tool_create_title").should have_value ""

    tools[0].click
    keep_trying_until {f("#resource_selection_dialog").should be_displayed }

    expect_fired_alert do
      in_frame('resource_selection_iframe') do
        keep_trying_until { ff("#basic_lti_link").length > 0 }
        ff(".link").length.should eql 4
        f("#no_url_basic_lti_link").click
      end
    end
    wait_for_ajax_requests
    f("#resource_selection_dialog").should_not be_displayed
    f("#external_tool_create_url").should have_value ""
    f("#external_tool_create_title").should have_value ""
  end

  it "should use the tool name if no link text is returned" do
    @module = @course.context_modules.create!(:name => "module")
    tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
    tool.settings[:resource_selection] = {
        :url => "http://#{HostUrl.default_host}/selection_test",
        :selection_width => 400,
        :selection_height => 400
    }
    tool.save!
    tool2 = @course.context_external_tools.new(:name => "not bob", :consumer_key => "not bob", :shared_secret => "not bob", :url => "https://www.example.com")
    tool2.save!
    get "/courses/#{@course.id}/modules"

    keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

    f("#context_module_#{@module.id} .add_module_item_link").click
    f("#add_module_item_select option[value='context_external_tool']").click

    keep_trying_until { ff("#context_external_tools_select .tools .tool").length > 0 }

    tools = ff("#context_external_tools_select .tools .tool")
    tools[0].find_element(:css, ".name").text.should_not match(/not/)
    tools[1].find_element(:css, ".name").text.should match(/not bob/)
    tools[1].click
    f("#external_tool_create_url").should have_value "https://www.example.com"
    f("#external_tool_create_title").should have_value "not bob"

    tools[0].click
    keep_trying_until {f("#resource_selection_dialog").should be_displayed }
    in_frame('resource_selection_iframe') do
      keep_trying_until { ff("#basic_lti_link").length > 0 }
      ff(".link").length.should eql 4
      f("#no_text_basic_lti_link").click
      wait_for_ajax_requests
    end
    f("#resource_selection_dialog").should_not be_displayed
    f("#external_tool_create_url").should have_value "http://www.example.com"
    f("#external_tool_create_title").should have_value "bob"
  end

  it "should allow editing the settings for a tool in a module" do
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
                                :type => 'context_external_tool',
                                :title => 'Example',
                                :url => 'http://www.example.com',
                                :new_tab => '1'
                            })
    get "/courses/#{@course.id}/modules"
    keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

    f("#context_module_item_#{@tag.id}").click
    f("#context_module_item_#{@tag.id} .edit_item_link").click

    f("#edit_item_form").should be_displayed
    replace_content(f("#edit_item_form #content_tag_title"), "Example 2")
    f("#edit_item_form #content_tag_new_tab").click
    submit_form("#edit_item_form")

    wait_for_ajax_requests

    @tag.reload
    @tag.should_not be_nil
    @tag.title.should == "Example 2"
    @tag.new_tab.should == false
    @tag.url.should == "http://www.example.com"
  end

  it "should launch assignment external tools when viewing assignment" do
    @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
    assignment_model(:course => @course, :points_possible => 40, :submission_types => 'external_tool', :grading_type => 'points')
    tag = @assignment.build_external_tool_tag(:url => "http://example.com/one")
    tag.content_type = 'ContextExternalTool'
    tag.save!
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"

    ff("#tool_content").length.should == 1
    keep_trying_until { f("#tool_content").should be_displayed }
  end

  it "should automatically load tools with default configuration" do
    @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
                                :type => 'context_external_tool',
                                :title => 'Example',
                                :url => 'http://www.example.com',
                                :new_tab => '0'
                            })
    get "/courses/#{@course.id}/modules/items/#{@tag.id}"

    ff("#tool_content").length.should eql 1
    keep_trying_until { f("#tool_content").should be_displayed }
  end

  it "should not automatically load tools configured to load in a new tab" do
    @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({
                                :type => 'context_external_tool',
                                :title => 'Example',
                                :url => 'http://www.example.com',
                                :new_tab => '1'
                            })
    get "/courses/#{@course.id}/modules/items/#{@tag.id}"

    ff("#tool_content").length.should eql 0
    f("#tool_form").should be_displayed
    ff("#tool_form .load_tab").length.should eql 1
  end
end
