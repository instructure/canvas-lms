require File.expand_path(File.dirname(__FILE__) + '/common')

describe "editing external tools" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should allow creating a new course external tool with custom fields" do
    get "/courses/#{@course.id}/settings"

    keep_trying_until do
      driver.find_element(:css, "#tab-tools-link").should be_displayed
      driver.find_element(:css, "#tab-tools-link").click
      tool_link = driver.find_element(:css, ".add_tool_link")
      tool_link.should be_displayed
      tool_link.click
      true
    end
    driver.find_element(:css, "#external_tools_dialog").should be_displayed
    driver.find_element(:css, "#external_tool_name").send_keys "Tool"
    driver.find_element(:css, "#external_tool_consumer_key").send_keys "Key"
    driver.find_element(:css, "#external_tool_shared_secret").send_keys "Secret"

    driver.find_element(:css, "#external_tool_match_by option[value='url']").click
    driver.find_element(:css, "#external_tool_domain").should_not be_displayed
    driver.find_element(:css, "#external_tool_url").should be_displayed
    driver.find_element(:css, "#external_tool_match_by option[value='domain']").click
    driver.find_element(:css, "#external_tool_domain").should be_displayed
    driver.find_element(:css, "#external_tool_url").should_not be_displayed

    driver.find_element(:css, "#external_tool_domain").send_keys "example.com"
    driver.find_element(:css, "#external_tool_custom_fields_string").send_keys "a=1\nb=123"
    driver.find_element(:css, "#external_tools_dialog .save_button").click

    keep_trying_until { !driver.find_element(:css, "#external_tools_dialog").displayed? }

    tool = ContextExternalTool.last
    tool_elem = driver.find_element(:css, "#external_tool_#{tool.id}")
    tool_elem.should be_displayed
    tool.should_not be_nil
    tool.name.should == "Tool"
    tool.consumer_key.should == "Key"
    tool.shared_secret.should == "Secret"
    tool.domain.should == "example.com"
    tool_elem.attribute('class').should_not match(/has_editor_button|has_resource_selection|has_course_navigation|has_account_navigation|has_user_navigation/)
    tool.settings[:custom_fields].should == {'a' => '1', 'b' => '123'}
  end

  it "should allow creating a new course external tool with extensions" do
    get "/courses/#{@course.id}/settings"

    keep_trying_until { driver.find_element(:css, "#tab-tools-link").displayed? }
    driver.find_element(:css, "#tab-tools-link").click
    driver.find_element(:css, ".add_tool_link").click
    driver.find_element(:css, "#external_tools_dialog").should be_displayed
    driver.find_element(:css, "#external_tool_name").send_keys "Tool"
    driver.find_element(:css, "#external_tool_consumer_key").send_keys "Key"
    driver.find_element(:css, "#external_tool_shared_secret").send_keys "Secret"

    driver.find_element(:css, "#external_tool_config_type option[value='by_url']").click
    driver.find_element(:css, "#external_tool_form .config_type.manual").should_not be_displayed
    driver.find_element(:css, "#external_tool_config_url").should be_displayed
    driver.find_element(:css, "#external_tool_config_xml").should_not be_displayed

    driver.find_element(:css, "#external_tool_config_type option[value='by_xml']").click
    driver.find_element(:css, "#external_tool_form .config_type.manual").should_not be_displayed
    driver.find_element(:css, "#external_tool_config_url").should_not be_displayed
    driver.find_element(:css, "#external_tool_config_xml").should be_displayed

    #XML must be broken up to avoid intermittent selenium failures
    driver.find_element(:css, "#external_tool_config_xml").send_keys <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
    xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
    xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
    xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
    xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
    http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
    XML
    driver.find_element(:css, "#external_tool_config_xml").send_keys <<-XML
    <blti:title>Other Name</blti:title>
    <blti:description>Description</blti:description>
    <blti:launch_url>http://example.com/other_url</blti:launch_url>
    <blti:extensions platform="canvas.instructure.com">
      <lticm:property name="privacy_level">public</lticm:property>
      <lticm:options name="editor_button">
        <lticm:property name="url">http://example.com/editor</lticm:property>
        <lticm:property name="icon_url">http://example.com/icon.png</lticm:property>
        <lticm:property name="text">Editor Button</lticm:property>
        <lticm:property name="selection_width">500</lticm:property>
        <lticm:property name="selection_height">300</lticm:property>
      </lticm:options>
    XML
    driver.find_element(:css, "#external_tool_config_xml").send_keys <<-XML
      <lticm:options name="resource_selection">
        <lticm:property name="url">https://example.com/wiki</lticm:property>
        <lticm:property name="text">Build/Link to Wiki Page</lticm:property>
        <lticm:property name="selection_width">500</lticm:property>
        <lticm:property name="selection_height">300</lticm:property>
      </lticm:options>
      <lticm:options name="course_navigation">
        <lticm:property name="url">https://example.com/attendance</lticm:property>
        <lticm:property name="text">Attendance</lticm:property>
      </lticm:options>
    XML
    driver.find_element(:css, "#external_tool_config_xml").send_keys <<-XML
      <lticm:options name="user_navigation">
        <lticm:property name="url">https://example.com/attendance</lticm:property>
        <lticm:property name="text">Attendance</lticm:property>
      </lticm:options>
      <lticm:options name="account_navigation">
        <lticm:property name="url">https://example.com/attendance</lticm:property>
        <lticm:property name="text">Attendance</lticm:property>
      </lticm:options>
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>  
    XML

    driver.find_element(:css, "#external_tools_dialog .save_button").click

    keep_trying_until { !driver.find_element(:css, "#external_tools_dialog").displayed? }

    tool = ContextExternalTool.last
    tool_elem = driver.find_element(:css, "#external_tool_#{tool.id}")
    tool_elem.should be_displayed
    tool.has_editor_button.should be_true
    tool.has_resource_selection.should be_true
    tool.has_course_navigation.should be_true
    tool.has_account_navigation.should be_true
    tool.has_user_navigation.should be_true
    tool_elem.attribute('class').should match(/has_editor_button/)
    tool_elem.attribute('class').should match(/has_resource_selection/)
    tool_elem.attribute('class').should match(/has_course_navigation/)
    tool_elem.attribute('class').should match(/has_account_navigation/)
    tool_elem.attribute('class').should match(/has_user_navigation/)
    tool.name.should == "Tool"
    tool.consumer_key.should == "Key"
    tool.shared_secret.should == "Secret"
    tool.url.should == "http://example.com/other_url"
  end

  it "should allow editing an existing external tool with custom fields" do
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
    @module = @course.context_modules.create!(:name => "module")
    get "/courses/#{@course.id}/modules"

    keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

    driver.find_element(:css, "#context_module_#{@module.id} .add_module_item_link").click
    driver.find_element(:css, "#add_module_item_select option[value='context_external_tool']").click
    driver.find_element(:css, "#external_tool_create_url").send_keys("http://www.example.com")
    driver.find_element(:css, "#external_tool_create_title").send_keys("Example")
    driver.find_element(:css, "#external_tool_create_new_tab").click
    driver.find_element(:css, "#select_context_content_dialog .add_item_button").click

    keep_trying_until { !driver.find_element(:css, "#select_context_content_dialog").displayed? }
    keep_trying_until { driver.find_elements(:css, "#context_module_item_new").length == 0 }

    @tag = ContentTag.last
    @tag.should_not be_nil
    @tag.title.should == "Example"
    @tag.new_tab.should == true
    @tag.url.should == "http://www.example.com"
  end

  it "should allow adding an existing external tool to a course module, and should pick the correct tool" do
    @module = @course.context_modules.create!(:name => "module")
    @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
    @tool2 = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
    
    get "/courses/#{@course.id}/modules"

    keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

    driver.find_element(:css, "#context_module_#{@module.id} .add_module_item_link").click
    driver.find_element(:css, "#add_module_item_select option[value='context_external_tool']").click
    keep_trying_until { driver.find_elements(:css, "#context_external_tools_select .tools .tool").length > 0 }
    driver.find_elements(:css, "#context_external_tools_select .tools .tool")[1].click
    driver.find_element(:css, "#external_tool_create_url").attribute('value').should == @tool2.url
    driver.find_element(:css, "#external_tool_create_title").attribute('value').should == @tool2.name
    driver.find_elements(:css, "#context_external_tools_select .tools .tool")[0].click
    driver.find_element(:css, "#external_tool_create_url").attribute('value').should == @tool1.url
    driver.find_element(:css, "#external_tool_create_title").attribute('value').should == @tool1.name
    driver.find_element(:css, "#select_context_content_dialog .add_item_button").click

    keep_trying_until { !driver.find_element(:css, "#select_context_content_dialog").displayed? }
    keep_trying_until { driver.find_elements(:css, "#context_module_item_new").length == 0 }

    @tag = ContentTag.last
    @tag.should_not be_nil
    @tag.title.should == @tool1.name
    @tag.url.should == @tool1.url
    @tag.content.should == @tool1

    driver.find_element(:css, "#context_module_#{@module.id} .add_module_item_link").click
    driver.find_element(:css, "#add_module_item_select option[value='context_external_tool']").click
    driver.find_elements(:css, "#context_external_tools_select .tools .tool")[1].click
    driver.find_element(:css, "#external_tool_create_url").attribute('value').should == @tool2.url
    driver.find_element(:css, "#external_tool_create_title").attribute('value').should == @tool2.name
    driver.find_element(:css, "#select_context_content_dialog .add_item_button").click

    keep_trying_until { !driver.find_element(:css, "#select_context_content_dialog").displayed? }
    keep_trying_until { driver.find_elements(:css, "#context_module_item_new").length == 0 }

    @tag = ContentTag.last
    @tag.should_not be_nil
    @tag.title.should == @tool2.name
    @tag.url.should == @tool2.url
    @tag.content.should == @tool2
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

    driver.find_element(:css, "#context_module_#{@module.id} .add_module_item_link").click
    driver.find_element(:css, "#add_module_item_select option[value='context_external_tool']").click

    keep_trying_until { driver.find_elements(:css, "#context_external_tools_select .tools .tool").length > 0 }

    tools = driver.find_elements(:css, "#context_external_tools_select .tools .tool")
    tools[0].find_element(:css, ".name").text.should_not match(/not/)
    tools[1].find_element(:css, ".name").text.should match(/not bob/)
    tools[1].click
    driver.find_element(:css, "#external_tool_create_url").attribute('value').should == "https://www.example.com"
    driver.find_element(:css, "#external_tool_create_title").attribute('value').should == "not bob"

    tools[0].click
    keep_trying_until { driver.find_elements(:css, "#resource_selection_dialog")[0].try(:displayed?) }

    in_frame('resource_selection_iframe') do
      keep_trying_until { driver.find_elements(:css, "#basic_lti_link").length > 0 }
      driver.find_elements(:css, ".link").length.should == 4
      driver.find_element(:css, "#basic_lti_link").click
    end

    keep_trying_until { !driver.find_element(:css, "#resource_selection_dialog").displayed? }

    driver.find_element(:css, "#external_tool_create_url").attribute('value').should == "http://www.example.com"
    driver.find_element(:css, "#external_tool_create_title").attribute('value').should == "lti embedded link"
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

    driver.find_element(:css, "#context_module_#{@module.id} .add_module_item_link").click
    driver.find_element(:css, "#add_module_item_select option[value='context_external_tool']").click

    keep_trying_until { driver.find_elements(:css, "#context_external_tools_select .tools .tool").length > 0 }

    tools = driver.find_elements(:css, "#context_external_tools_select .tools .tool")
    tools[0].find_element(:css, ".name").text.should_not match(/not/)
    tools[1].find_element(:css, ".name").text.should match(/not bob/)
    tools[1].click
    driver.find_element(:css, "#external_tool_create_url").attribute('value').should == "https://www.example.com"
    driver.find_element(:css, "#external_tool_create_title").attribute('value').should == "not bob"

    tools[0].click

    keep_trying_until { driver.find_elements(:css, "#resource_selection_dialog")[0].try(:displayed?) }

    expect_fired_alert do
      in_frame('resource_selection_iframe') do
        keep_trying_until { driver.find_elements(:css, "#basic_lti_link").length > 0 }
        driver.find_elements(:css, ".link").length.should == 4
        driver.find_element(:css, "#bad_url_basic_lti_link").click
      end
    end

    driver.find_element(:css, "#resource_selection_dialog").should_not be_displayed

    driver.find_element(:css, "#external_tool_create_url").attribute('value').should == ""
    driver.find_element(:css, "#external_tool_create_title").attribute('value').should == ""

    tools[0].click

    keep_trying_until { driver.find_elements(:css, "#resource_selection_dialog")[0].try(:displayed?) }

    expect_fired_alert do
      in_frame('resource_selection_iframe') do
        keep_trying_until { driver.find_elements(:css, "#basic_lti_link").length > 0 }
        driver.find_elements(:css, ".link").length.should == 4
        driver.find_element(:css, "#no_url_basic_lti_link").click
      end
    end

    driver.find_element(:css, "#resource_selection_dialog").should_not be_displayed

    driver.find_element(:css, "#external_tool_create_url").attribute('value').should == ""
    driver.find_element(:css, "#external_tool_create_title").attribute('value').should == ""
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

    driver.find_element(:css, "#context_module_#{@module.id} .add_module_item_link").click
    driver.find_element(:css, "#add_module_item_select option[value='context_external_tool']").click

    keep_trying_until { driver.find_elements(:css, "#context_external_tools_select .tools .tool").length > 0 }

    tools = driver.find_elements(:css, "#context_external_tools_select .tools .tool")
    tools[0].find_element(:css, ".name").text.should_not match(/not/)
    tools[1].find_element(:css, ".name").text.should match(/not bob/)
    tools[1].click
    driver.find_element(:css, "#external_tool_create_url").attribute('value').should == "https://www.example.com"
    driver.find_element(:css, "#external_tool_create_title").attribute('value').should == "not bob"

    tools[0].click

    keep_trying_until { driver.find_elements(:css, "#resource_selection_dialog")[0].try(:displayed?) }

    in_frame('resource_selection_iframe') do
      keep_trying_until { driver.find_elements(:css, "#basic_lti_link").length > 0 }
      driver.find_elements(:css, ".link").length.should == 4
      driver.find_element(:css, "#no_text_basic_lti_link").click
    end

    keep_trying_until { !driver.find_element(:css, "#resource_selection_dialog").displayed? }

    driver.find_element(:css, "#external_tool_create_url").attribute('value').should == "http://www.example.com"
    driver.find_element(:css, "#external_tool_create_title").attribute('value').should == "bob"
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

  it "should launch assignment external tools when viewing assignment" do
    @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
    assignment_model(:course => @course, :points_possible => 40, :submission_types => 'external_tool', :grading_type => 'points')
    tag = @assignment.build_external_tool_tag(:url => "http://example.com/one")
    tag.content_type = 'ContextExternalTool'
    tag.save!
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"

    driver.find_elements(:css, "#tool_content").length.should == 1
    keep_trying_until { driver.find_element(:css, "#tool_content").displayed? }
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

    driver.find_elements(:css, "#tool_content").length.should == 1
    keep_trying_until { driver.find_element(:css, "#tool_content").displayed? }
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

    driver.find_elements(:css, "#tool_content").length.should == 0
    driver.find_element(:css, "#tool_form").should be_displayed
    driver.find_elements(:css, "#tool_form .load_tab").length.should == 1
  end
end
