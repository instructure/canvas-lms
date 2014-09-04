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
  before :once do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)

  end

  describe "GET 'show'" do
    context 'ContentItemSelectionResponse' do
      before :once do
        @tool = new_valid_tool(@course)
        @tool.course_navigation = { message_type: 'ContentItemSelectionResponse' }
        @tool.save!

        @course.name = 'a course'
        @course.save!
      end

      it "generates launch params for a ContentItemSelectionResponse message" do
        user_session(@teacher)
        Lti::Asset.stubs(:opaque_identifier_for).returns('ABC123')

        @course.root_account.lti_guid = 'root-account-guid'
        @course.root_account.name = 'root account'
        @course.root_account.save!

        get :show, :course_id => @course.id, id: @tool.id

        response.should be_success
        lti_launch = assigns[:lti_launch]
        lti_launch.link_text.should == 'bob'
        lti_launch.resource_url.should == 'http://www.example.com/basic_lti'
        lti_launch.launch_type.should be_nil
        lti_launch.params['lti_message_type'].should == 'ContentItemSelectionResponse'
        lti_launch.params['lti_version'].should == 'LTI-1p0'
        lti_launch.params['context_id'].should == 'ABC123'
        lti_launch.params['resource_link_id'].should == 'ABC123'
        lti_launch.params['tool_consumer_instance_guid'].should == 'root-account-guid'
        lti_launch.params['tool_consumer_instance_name'].should == 'root account'
        lti_launch.params['context_title'].should == 'a course'
        lti_launch.params['launch_presentation_return_url'].should start_with 'http'
      end

      it "sends content item json for a course" do
        user_session(@teacher)
        get :show, :course_id => @course.id, id: @tool.id
        content_item = JSON.parse(assigns[:lti_launch].params['content_items'])
        placement = content_item['@graph'].first

        content_item['@context'].should == 'http://purl.imsglobal.org/ctx/lti/v1/ContentItemPlacement'
        content_item['@graph'].size.should == 1
        placement['@type'].should == 'ContentItemPlacement'
        placement['placementOf']['@type'].should == 'FileItem'
        placement['placementOf']['@id'].should == "#{api_v1_course_content_exports_url(@course)}?export_type=common_cartridge"
        placement['placementOf']['mediaType'].should == 'application/vnd.instructure.api.content-exports.course'
        placement['placementOf']['title'].should == 'a course'
      end

      it "sends content item json for an assignment" do
        user_session(@teacher)
        assignment = @course.assignments.create!(name: 'an assignment')
        get :show, :course_id => @course.id, id: @tool.id, :assignments => [assignment.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        migration_url.should start_with api_v1_course_content_exports_url(@course)
        params.should include "select%5Bassignments%5D%5B%5D=#{assignment.id}"
        placement['placementOf']['mediaType'].should == 'application/vnd.instructure.api.content-exports.assignment'
        placement['placementOf']['title'].should == 'an assignment'
      end

      it "sends content item json for a discussion topic" do
        user_session(@teacher)
        topic = @course.discussion_topics.create!(:title => "blah")
        get :show, :course_id => @course.id, id: @tool.id, :discussion_topics => [topic.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        migration_url.should start_with api_v1_course_content_exports_url(@course)
        params.should include "select%5Bdiscussion_topics%5D%5B%5D=#{topic.id}"
        placement['placementOf']['mediaType'].should == 'application/vnd.instructure.api.content-exports.discussion_topic'
        placement['placementOf']['title'].should == 'blah'
      end

      it "sends content item json for a quiz" do
        user_session(@teacher)
        quiz = @course.quizzes.create!(title: 'a quiz')
        get :show, :course_id => @course.id, id: @tool.id, :quizzes => [quiz.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        migration_url.should start_with api_v1_course_content_exports_url(@course)
        params.should include "select%5Bquizzes%5D%5B%5D=#{quiz.id}"
        placement['placementOf']['mediaType'].should == 'application/vnd.instructure.api.content-exports.quiz'
        placement['placementOf']['title'].should == 'a quiz'
      end

      it "sends content item json for a module" do
        user_session(@teacher)
        context_module = @course.context_modules.create!(name: 'a module')
        get :show, :course_id => @course.id, id: @tool.id, :modules => [context_module.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        migration_url.should start_with api_v1_course_content_exports_url(@course)
        params.should include "select%5Bmodules%5D%5B%5D=#{context_module.id}"
        placement['placementOf']['mediaType'].should == 'application/vnd.instructure.api.content-exports.module'
        placement['placementOf']['title'].should == 'a module'
      end

      it "sends content item json for a module item" do
        user_session(@teacher)
        context_module = @course.context_modules.create!(name: 'a module')
        quiz = @course.quizzes.create!(title: 'a quiz')
        tag = context_module.add_item(:id => quiz.id, :type => 'quiz')

        get :show, :course_id => @course.id, id: @tool.id, :module_items => [tag.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        migration_url.should start_with api_v1_course_content_exports_url(@course)
        params.should include "select%5Bmodule_items%5D%5B%5D=#{tag.id}"
        placement['placementOf']['mediaType'].should == 'application/vnd.instructure.api.content-exports.quiz'
        placement['placementOf']['title'].should == 'a quiz'
      end

      it "sends content item json for a page" do
        user_session(@teacher)
        page = @course.wiki.wiki_pages.create!(title: 'a page')
        get :show, :course_id => @course.id, id: @tool.id, :pages => [page.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        migration_url.should start_with api_v1_course_content_exports_url(@course)
        params.should include "select%5Bpages%5D%5B%5D=#{page.id}"
        placement['placementOf']['mediaType'].should == 'application/vnd.instructure.api.content-exports.page'
        placement['placementOf']['title'].should == 'a page'
      end

      it "sends content item json for selected content" do
        user_session(@teacher)
        get :show, :course_id => @course.id, id: @tool.id, :pages => [1,6], :assignments => [6]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        migration_url.should start_with api_v1_course_content_exports_url(@course)
        params.should include 'export_type=common_cartridge'
        params.should include "select%5Bpages%5D%5B%5D=1"
        params.should include "select%5Bpages%5D%5B%5D=6"
        params.should include "select%5Bassignments%5D%5B%5D=6"
        placement['placementOf']['mediaType'].should == 'application/vnd.instructure.api.content-exports.course'
        placement['placementOf']['title'].should == 'a course'
      end
    end
  end

  describe "GET 'retrieve'" do
    it "should require authentication" do
      user_model
      user_session(@user)
      get 'retrieve', :course_id => @course.id
      assert_unauthorized
    end

    it "should find tools matching by exact url" do
      user_session(@teacher)
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.url = "http://www.example.com/basic_lti"
      tool.save!
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com/basic_lti"
      response.should be_success
      assigns[:tool].should == tool
      assigns[:lti_launch].params.should_not be_nil
    end

    it "should find tools matching by domain" do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com/basic_lti"
      response.should be_success
      assigns[:tool].should == tool
      assigns[:lti_launch].params.should_not be_nil
    end

    it "should redirect if no matching tools are found" do
      user_session(@teacher)
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com"
      response.should be_redirect
      flash[:error].should == "Couldn't find valid settings for this link"
    end
  end

  describe "GET 'resource_selection'" do
    it "should require authentication" do
      user_model
      user_session(@user)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => 0
      assert_unauthorized
    end

    it "should be accessible by students" do
      user_session(@student)
      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
    end

    it "should redirect if no matching tools are found" do
      user_session(@teacher)
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.url = "http://www.example.com/basic_lti"
      # this tool exists, but isn't properly configured
      tool.save!
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_redirect
      flash[:error].should == "Couldn't find valid settings for this tool"
    end

    it "should find a valid tool if one exists" do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
      assigns[:tool].should == tool
      assigns[:lti_launch].params['custom_canvas_enrollment_state'].should == 'active'
    end

    it "should set html selection if specified" do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      html = "<img src='/blank.png'/>"
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id, :editor_button => '1', :selection => html
      response.should be_success
      assigns[:tool].should == tool
      assigns[:lti_launch].params['text'].should == CGI::escape(html)
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
      user_session(@student)
      @course.conclude_at = 1.day.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
      assigns[:tool].should == tool
      assigns[:lti_launch].params['custom_canvas_enrollment_state'].should == 'inactive'
    end

    it "should be accessible even after course is hard-concluded" do
      user_session(@student)
      @course.complete

      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
      assigns[:tool].should == tool
      assigns[:lti_launch].params['custom_canvas_enrollment_state'].should == 'inactive'
    end

    it "should be accessible even after enrollment is concluded and include a parameter indicating inactive state" do
      user_session(@student)
      e = @student.enrollments.first
      e.conclude
      e.reload
      e.workflow_state.should == 'completed'

      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
      assigns[:tool].should == tool
      assigns[:lti_launch].params['custom_canvas_enrollment_state'].should == 'inactive'
    end
  end

  describe "POST 'create'" do
    it "should require authentication" do
      post 'create', :course_id => @course.id, :format => "json"
      assert_status(401)
    end

    it "should accept basic configurations" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret"}, :format => "json"
      response.should be_success
      assigns[:tool].should_not be_nil
      assigns[:tool].name.should == "tool name"
      assigns[:tool].url.should == "http://example.com"
      assigns[:tool].consumer_key.should == "key"
      assigns[:tool].shared_secret.should == "secret"
    end

    it "should fail on basic xml with no url or domain set" do
      user_session(@teacher)
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
      user_session(@teacher)
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
      assigns[:tool].has_placement?(:editor_button).should be_true
    end

    it "should handle advanced xml configurations with no url or domain set" do
      user_session(@teacher)
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
      assigns[:tool].has_placement?(:editor_button).should be_true
    end

    it "should handle advanced xml configurations by URL retrieval" do
      user_session(@teacher)
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
      assigns[:tool].has_placement?(:editor_button).should be_true
    end

    it "should fail gracefully on invalid URL retrieval or timeouts" do
      Net::HTTP.any_instance.stubs(:request).raises(Timeout::Error)
      user_session(@teacher)
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
          user_session(@teacher)
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
          user_session(@teacher)
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
          user_session(@teacher)
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
          user_session(@teacher)
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
