#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# Public: Create a new valid LTI tool for the given course.
#
# course - The course to create the tool for.
#
# Returns a valid ExternalTool.
def new_valid_tool(course)
  tool = course.context_external_tools.new(:name => "bob",
                                           :consumer_key => "bob",
                                           :shared_secret => "bob")
  tool.url = "http://www.example.com/basic_lti"
  tool.resource_selection = {
    :url => "http://#{HostUrl.default_host}/selection_test",
    :selection_width => 400,
    :selection_height => 400}
  tool.save!
  tool
end

describe ExternalToolsController do
  describe "GET 'retrieve'" do
    it "should require authentication" do
      course_with_teacher(:active_all => true)
      user_model
      user_session(@user)
      get 'retrieve', :course_id => @course.id
      assert_unauthorized
    end

    it "should find tools matching by exact url" do
      course_with_teacher_logged_in(:active_all => true)
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.url = "http://www.example.com/basic_lti"
      tool.save!
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com/basic_lti"
      response.should be_success
      assigns[:tool].should == tool
      assigns[:tool_settings].should_not be_nil
    end

    it "should find tools matching by domain" do
      course_with_teacher_logged_in(:active_all => true)
      tool = new_valid_tool(@course)
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com/basic_lti"
      response.should be_success
      assigns[:tool].should == tool
      assigns[:tool_settings].should_not be_nil
    end

    it "should redirect if no matching tools are found" do
      course_with_teacher_logged_in(:active_all => true)
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com"
      response.should be_redirect
      flash[:error].should == "Couldn't find valid settings for this link"
    end
  end

  describe "GET 'resource_selection'" do
    it "should require authentication" do
      course_with_teacher(:active_all => true)
      user_model
      user_session(@user)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => 0
      assert_unauthorized
    end

    it "should be accessible by students" do
      course_with_student_logged_in(:active_all => true)
      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
    end

    it "should redirect if no matching tools are found" do
      course_with_teacher_logged_in(:active_all => true)
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.url = "http://www.example.com/basic_lti"
      # this tool exists, but isn't properly configured
      tool.save!
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_redirect
      flash[:error].should == "Couldn't find valid settings for this tool"
    end

    it "should find a valid tool if one exists" do
      course_with_teacher_logged_in(:active_all => true)
      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
      assigns[:tool].should == tool
      assigns[:tool_settings]['custom_canvas_enrollment_state'].should == 'active'
    end

    it "should set html selection if specified" do
      course_with_teacher_logged_in(:active_all => true)
      tool = new_valid_tool(@course)
      html = "<img src='/blank.png'/>"
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id, :editor_button => '1', :selection => html
      response.should be_success
      assigns[:tool].should == tool
      assigns[:tool_settings]['text'].should == CGI::escape(html)
    end

    it "should find account-level tools" do
      @user = account_admin_user
      user_session(@user)

      tool = new_valid_tool(Account.default)
      get 'resource_selection', :account_id => Account.default.id, :external_tool_id => tool.id
      response.should be_success
      assigns[:tool].should == tool
    end

    it "should be accessible even after course is soft-concluded" do
      course_with_student_logged_in(:active_all => true)
      @course.conclude_at = 1.day.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
      assigns[:tool].should == tool
      assigns[:tool_settings]['custom_canvas_enrollment_state'].should == 'inactive'
    end

    it "should be accessible even after course is hard-concluded" do
      course_with_student_logged_in(:active_all => true)
      @course.complete

      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
      assigns[:tool].should == tool
      assigns[:tool_settings]['custom_canvas_enrollment_state'].should == 'inactive'
    end

    it "should be accessible even after enrollment is concluded and include a parameter indicating inactive state" do
      course_with_student_logged_in(:active_all => true)
      e = @student.enrollments.first
      e.conclude
      e.reload
      e.workflow_state.should == 'completed'

      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
      assigns[:tool].should == tool
      assigns[:tool_settings]['custom_canvas_enrollment_state'].should == 'inactive'
    end
  end

  describe "POST 'create'" do
    it "should require authentication" do
      course_with_teacher(:active_all => true)
      post 'create', :course_id => @course.id, :format => "json"
      assert_status(401)
    end

    it "should accept basic configurations" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret"}, :format => "json"
      response.should be_success
      assigns[:tool].should_not be_nil
      assigns[:tool].name.should == "tool name"
      assigns[:tool].url.should == "http://example.com"
      assigns[:tool].consumer_key.should == "key"
      assigns[:tool].shared_secret.should == "secret"
    end

    it "should fail on basic xml with no url or domain set" do
      rescue_action_in_public! if CANVAS_RAILS2
      course_with_teacher_logged_in(:active_all => true)
      xml = <<-XML
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
    <blti:title>Other Name</blti:title>
    <blti:description>Description</blti:description>
    <blti:extensions platform="canvas.instructure.com">
      <lticm:property name="privacy_level">public</lticm:property>
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>  
      XML
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
      response.should_not be_success
    end

    it "should handle advanced xml configurations" do
      course_with_teacher_logged_in(:active_all => true)
      xml = <<-XML
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
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>  
      XML
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
      response.should be_success
      assigns[:tool].should_not be_nil
      # User-entered name overrides name provided in xml
      assigns[:tool].name.should == "tool name"
      assigns[:tool].description.should == "Description"
      assigns[:tool].url.should == "http://example.com/other_url"
      assigns[:tool].consumer_key.should == "key"
      assigns[:tool].shared_secret.should == "secret"
      assigns[:tool].has_editor_button.should be_true
    end

    it "should handle advanced xml configurations with no url or domain set" do
      course_with_teacher_logged_in(:active_all => true)
      xml = <<-XML
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
    <blti:title>Other Name</blti:title>
    <blti:description>Description</blti:description>
    <blti:extensions platform="canvas.instructure.com">
      <lticm:property name="privacy_level">public</lticm:property>
      <lticm:options name="editor_button">
        <lticm:property name="url">http://example.com/editor</lticm:property>
        <lticm:property name="icon_url">http://example.com/icon.png</lticm:property>
        <lticm:property name="text">Editor Button</lticm:property>
        <lticm:property name="selection_width">500</lticm:property>
        <lticm:property name="selection_height">300</lticm:property>
      </lticm:options>
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>  
      XML
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
      response.should be_success
      assigns[:tool].should_not be_nil
      # User-entered name overrides name provided in xml
      assigns[:tool].name.should == "tool name"
      assigns[:tool].description.should == "Description"
      assigns[:tool].url.should be_nil
      assigns[:tool].domain.should be_nil
      assigns[:tool].consumer_key.should == "key"
      assigns[:tool].shared_secret.should == "secret"
      assigns[:tool].has_editor_button.should be_true
    end

    it "should fail gracefully on invalid xml configurations" do
      course_with_teacher_logged_in(:active_all => true)
      xml = "bob"
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
      response.should_not be_success
      assigns[:tool].should be_new_record
      json = json_parse(response.body)
      json['errors']['config_xml'][0]['message'].should == I18n.t(:invalid_xml_syntax, 'Invalid xml syntax')

      course_with_teacher_logged_in(:active_all => true)
      xml = "<a><b>c</b></a>"
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
      response.should_not be_success
      assigns[:tool].should be_new_record
      json = json_parse(response.body)
      json['errors']['config_xml'][0]['message'].should == I18n.t(:invalid_xml_syntax, 'Invalid xml syntax')
    end

    it "should handle advanced xml configurations by URL retrieval" do
      course_with_teacher_logged_in(:active_all => true)
      xml = <<-XML
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
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>  
      XML
      obj = OpenStruct.new({:body => xml})
      Net::HTTP.any_instance.stubs(:request).returns(obj)
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_url", :config_url => "http://config.example.com"}, :format => "json"
      response.should be_success
      assigns[:tool].should_not be_nil
      # User-entered name overrides name provided in xml
      assigns[:tool].name.should == "tool name"
      assigns[:tool].description.should == "Description"
      assigns[:tool].url.should == "http://example.com/other_url"
      assigns[:tool].consumer_key.should == "key"
      assigns[:tool].shared_secret.should == "secret"
      assigns[:tool].has_editor_button.should be_true
    end

    it "should fail gracefully on invalid URL retrieval or timeouts" do
      Net::HTTP.any_instance.stubs(:request).raises(Timeout::Error)
      course_with_teacher_logged_in(:active_all => true)
      xml = "bob"
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_url", :config_url => "http://config.example.com"}, :format => "json"
      response.should_not be_success
      assigns[:tool].should be_new_record
      json = json_parse(response.body)
      json['errors']['config_url'][0]['message'].should == I18n.t(:retrieve_timeout, 'could not retrieve configuration, the server response timed out')
    end

    context "navigation tabs caching" do
      it "shouldn't clear the navigation tabs cache for non navigtaion tools" do
        enable_cache do
          course_with_teacher_logged_in(:active_all => true)
          nav_cache = Lti::NavigationCache.new(@course.root_account)
          cache_key = nav_cache.cache_key
          xml = <<-XML
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
  <blti:title>Redirect Tool</blti:title>
  <blti:description>
    Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
  </blti:description>
  <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
  <blti:custom>
    <lticm:property name="url">https://</lticm:property>
  </blti:custom>
  <blti:extensions platform="canvas.instructure.com">
    <lticm:property name="icon_url">
      https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
    </lticm:property>
    <lticm:property name="link_text"/>
    <lticm:property name="privacy_level">anonymous</lticm:property>
    <lticm:property name="tool_id">redirect</lticm:property>
  </blti:extensions>
</cartridge_basiclti_link>
          XML
          post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
          response.should be_success
          nav_cache.cache_key.should == cache_key
        end
      end

      it 'should clear the navigation tabs cache for course nav' do
        enable_cache do
          course_with_teacher_logged_in(:active_all => true)
          cache_key = Lti::NavigationCache.new(@course.root_account).cache_key
          xml = <<-XML
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
  <blti:title>Redirect Tool</blti:title>
  <blti:description>
    Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
  </blti:description>
  <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
  <blti:custom>
    <lticm:property name="url">https://</lticm:property>
  </blti:custom>
  <blti:extensions platform="canvas.instructure.com">
    <lticm:options name="course_navigation">
      <lticm:property name="enabled">true</lticm:property>
      <lticm:property name="visibility">public</lticm:property>
    </lticm:options>
    <lticm:property name="icon_url">
      https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
    </lticm:property>
    <lticm:property name="link_text"/>
    <lticm:property name="privacy_level">anonymous</lticm:property>
    <lticm:property name="tool_id">redirect</lticm:property>
  </blti:extensions>
</cartridge_basiclti_link>
          XML
          post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
          response.should be_success
          Lti::NavigationCache.new(@course.root_account).cache_key.should_not == cache_key
        end
      end

      it 'should clear the navigation tabs cache for account nav' do
        enable_cache do
          course_with_teacher_logged_in(:active_all => true)
          cache_key = Lti::NavigationCache.new(@course.root_account).cache_key
          xml = <<-XML
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
  <blti:title>Redirect Tool</blti:title>
  <blti:description>
    Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
  </blti:description>
  <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
  <blti:custom>
    <lticm:property name="url">https://</lticm:property>
  </blti:custom>
  <blti:extensions platform="canvas.instructure.com">
    <lticm:options name="account_navigation">
      <lticm:property name="enabled">true</lticm:property>
      <lticm:property name="visibility">public</lticm:property>
    </lticm:options>
    <lticm:property name="icon_url">
      https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
    </lticm:property>
    <lticm:property name="link_text"/>
    <lticm:property name="privacy_level">anonymous</lticm:property>
    <lticm:property name="tool_id">redirect</lticm:property>
  </blti:extensions>
</cartridge_basiclti_link>
          XML
          post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
          response.should be_success
          Lti::NavigationCache.new(@course.root_account).cache_key.should_not == cache_key
        end
      end

      it 'should clear the navigation tabs cache for user nav' do
        enable_cache do
          course_with_teacher_logged_in(:active_all => true)
          cache_key = Lti::NavigationCache.new(@course.root_account).cache_key
          xml = <<-XML
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
  <blti:title>Redirect Tool</blti:title>
  <blti:description>
    Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
  </blti:description>
  <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
  <blti:custom>
    <lticm:property name="url">https://</lticm:property>
  </blti:custom>
  <blti:extensions platform="canvas.instructure.com">
    <lticm:options name="user_navigation">
      <lticm:property name="enabled">true</lticm:property>
      <lticm:property name="visibility">public</lticm:property>
    </lticm:options>
    <lticm:property name="icon_url">
      https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
    </lticm:property>
    <lticm:property name="link_text"/>
    <lticm:property name="privacy_level">anonymous</lticm:property>
    <lticm:property name="tool_id">redirect</lticm:property>
  </blti:extensions>
</cartridge_basiclti_link>
          XML
          post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
          response.should be_success
          Lti::NavigationCache.new(@course.root_account).cache_key.should_not == cache_key
        end
      end
    end

  end
end
