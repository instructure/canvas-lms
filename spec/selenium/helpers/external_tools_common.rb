require File.expand_path(File.dirname(__FILE__) + '/../common')

shared_examples_for "external tools tests" do
  it_should_behave_like "in-process server selenium tests"

  def add_external_tool (*opts)
    name = "external tool"
    key = "1234567"
    secret = "secret"

    f("#tab-tools .add_tool_link").click
    f("#external_tools_dialog").should be_displayed

    f("#external_tool_name").send_keys(name)
    f("#external_tool_consumer_key").send_keys(key)
    f("#external_tool_shared_secret").send_keys(secret)
    if opts.include? :xml
      add_xml
    elsif opts.include? :url
      add_url
    else
      add_manual opts
    end
    f("#external_tools_dialog .save_button").click
    wait_for_ajax_requests
    ContextExternalTool.count > 0
    tool = ContextExternalTool.last
    tool.name.should eql name
    tool.consumer_key.should eql key
    tool.shared_secret.should eql secret
    tool_checker tool, opts
  end

  def tool_checker (tool, opts)

    if (opts.include? :xml)
      url = "http://example.com/other_url"
      tool.url.should eql url
      tool.workflow_state.should eql "public"
      tool.description.should eql "Description"
      tool.has_editor_button.should be_true
      tool.has_resource_selection.should be_true
      tool.has_course_navigation.should be_true
      tool.has_account_navigation.should be_true
      tool.has_user_navigation.should be_true
      f("#external_tool_#{tool.id} .url").text.should eql url
      f("#external_tool_#{tool.id} .editor_button").should be_displayed
      f("#external_tool_#{tool.id} .resource_selection").should be_displayed
      f("#external_tool_#{tool.id} .course_navigation").should be_displayed
      f("#external_tool_#{tool.id} .user_navigation").should be_displayed
      f("#external_tool_#{tool.id} .account_navigation").should be_displayed
      f("#external_tool_#{tool.id} .readable_state").text.should eql "Public"
      f("#external_tool_#{tool.id} .description").text.should eql "Description"
    elsif opts.include? :url
      url = "https://lti-examples.heroku.com/tool_redirect"
      kitten_text = "pictures of kittens to your site"
      tool.workflow_state.should eql "anonymous"
      tool.url.should eql url
      tool.description.should include_text kitten_text
      tool.has_editor_button.should be_true
      tool.settings.should be_present
      tool.settings[:editor_button].should be_present
      f("#external_tool_#{tool.id} .url").text.should eql url
      f("#external_tool_#{tool.id} .description").text.should include_text kitten_text
      f("#external_tool_#{tool.id} .editor_button").should be_displayed

    else
      tool.description.should eql @description
      tool.settings.count > 0
      tool.settings[:custom_fields].keys.count >0
      custom_hash = {@custom_key => @custom_value}
      tool.settings[:custom_fields].should eql custom_hash
      f("#external_tool_#{tool.id} .description").text.should eql @description

      if (opts.include? :manual_url)
        f("#external_tool_#{tool.id} .url").text.should eql @manual_url
        tool.url.should eql @manual_url
      else
        tool.domain.should eql @domain
      end

      if (opts.include? :name_only)
        tool.workflow_state.should eql "name_only"
        f("#external_tool_#{tool.id} .readable_state").text.should eql "Name Only"
      elsif (opts.include? :public)
        tool.workflow_state.should eql "public"
        f("#external_tool_#{tool.id} .readable_state").text.should eql "Public"
      else
        tool.workflow_state.should eql "anonymous"
        f("#external_tool_#{tool.id} .readable_state").text.should eql "Anonymous"
      end
    end

  end

  def add_manual (opts)
    f("#external_tool_config_type option[value='manual']").click
    f("#external_tool_form .config_type.manual").should be_displayed
    f("#external_tool_config_url").should_not be_displayed
    f("#external_tool_config_xml").should_not be_displayed
    @custom_key = "value"
    @custom_value = "custom tool"
    @description = "this is an external tool"
    @domain = "http://example.org"
    f("#external_tool_custom_fields_string").send_keys(@custom_key+"="+ @custom_value)
    f("#external_tool_description").send_keys(@description)
    if opts.include? :manual_url
      @manual_url = @domain+":80"
      f("#external_tool_match_by option[value='url']").click
      f("#external_tool_url").send_keys(@manual_url)
    else
      f("#external_tool_match_by option[value='domain']").click
      f("#external_tool_domain").send_keys(@domain)
    end

    if opts.include? :name_only
      f("#external_tool_privacy_level option[value='name_only']").click
    elsif opts.include? :public
      f("#external_tool_privacy_level option[value='public']").click
    else
      f("#external_tool_privacy_level option[value='anonymous']").click
    end
  end

  def add_url
    url = "https://lti-examples.heroku.com/config/editor_button2.xml"
    f("#external_tool_config_type option[value='by_url']").click
    f("#external_tool_form .config_type.manual").should_not be_displayed
    f("#external_tool_config_xml").should_not be_displayed
    f("#external_tool_config_url").should be_displayed
    f("#external_tool_config_url").send_keys(url)
  end


  def add_xml
    f("#external_tool_config_type option[value='by_xml']").click
    f("#external_tool_form .config_type.manual").should_not be_displayed
    f("#external_tool_config_url").should_not be_displayed
    f("#external_tool_config_xml").should be_displayed

#XML must be broken up to avoid intermittent selenium failures
    f("#external_tool_config_xml").send_keys <<-XML
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
    f("#external_tool_config_xml").send_keys <<-XML
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
    f("#external_tool_config_xml").send_keys <<-XML
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
    f("#external_tool_config_xml").send_keys <<-XML
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
  end
end