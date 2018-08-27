#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe ExternalToolsController do
  include ExternalToolsSpecHelper

  before :once do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
  end

  describe "POST 'create'" do
    let(:post_body) {
      'external_tool%5Bname%5D=IMS+Cert+Tool&external_tool%5Bprivacy_level%5D=name_only'\
          '&external_tool%5Bconsumer_key%5D=29f0c0ad-0cff-433f-8e35-797bd34710ea&external_tool'\
          '%5Bcustom_fields%5Bsimple_key%5D%5D=custom_simple_value&external_tool%5Bcustom_fields'\
          '%5Bcert_userid%5D%5D=%24User.id&external_tool%5Bcustom_fields%5BComplex!%40%23%24%5E*()'\
          '%7B%7D%5B%5DKEY%5D%5D=Complex!%40%23%24%5E*%3B()%7B%7D%5B%5D%C2%BDValue&external_tool'\
          '%5Bcustom_fields%5Bcert_username%5D%5D=%24User.username&external_tool%5Bcustom_fields'\
          '%5Btc_profile_url%5D%5D=%24ToolConsumerProfile.url&external_tool%5Bdomain%5D=null&'\
          'external_tool%5Burl%5D=https%3A%2F%2Fwww.imsglobal.org%2Flti%2Fcert%2Ftc_tool.php%3F'\
          'x%3DWith%2520Space%26y%3Dyes&external_tool%5Bdescription%5D=null&external_tool%5Bshared_secret%5D=secret'
    }

    it 'accepts form data' do
      user_session(@teacher)
      post(
        "/api/v1/courses/#{@course.id}/external_tools",
        params: post_body,
        headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded '}
      )
      expect(response).to be_successful
      expect(assigns[:tool]).not_to be_nil
    end

    it 'uses custom parsing for form data' do
      user_session(@teacher)
      post(
        "/api/v1/courses/#{@course.id}/external_tools",
        params: post_body,
        headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded '}
      )
      tool = assigns[:tool]
      expect(tool.settings[:custom_fields]["Complex!@#$^*(){}[]KEY"]).to eq 'Complex!@#$^*;(){}[]½Value'
    end

  end

  describe "PUT 'update'" do
    let(:post_body) {
      'external_tool%5Bname%5D=IMS+Cert+Tool&external_tool%5Bprivacy_level%5D=name_only'\
      '&external_tool%5Bconsumer_key%5D=29f0c0ad-0cff-433f-8e35-797bd34710ea&external_tool'\
      '%5Bcustom_fields%5Bsimple_key%5D%5D=custom_simple_value&external_tool%5Bcustom_fields'\
      '%5Bcert_userid%5D%5D=%24User.id&external_tool%5Bcustom_fields%5BComplex!%40%23%24%5E*()'\
      '%7B%7D%5B%5DKEY%5D%5D=Complex!%40%23%24%5E*%3B()%7B%7D%5B%5D%C2%BDValue&external_tool'\
      '%5Bcustom_fields%5Bcert_username%5D%5D=%24User.username&external_tool%5Bcustom_fields'\
      '%5Btc_profile_url%5D%5D=%24ToolConsumerProfile.url&external_tool%5Bdomain%5D=null&'\
      'external_tool%5Burl%5D=https%3A%2F%2Fwww.imsglobal.org%2Flti%2Fcert%2Ftc_tool.php%3F'\
      'x%3DWith%2520Space%26y%3Dyes&external_tool%5Bdescription%5D=null&external_tool%5Bshared_secret%5D=secret'
    }

    it "should not update tool if user lacks update_manually" do
      user_session(@student)
      tool = new_valid_tool(@course)
      put(
        "/api/v1/courses/#{@course.id}/external_tools/#{tool.id}",
        params: post_body,
        headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded '}
      )
      assert_status(401)
    end

    it "should update tool if user is granted update_manually" do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      put(
        "/api/v1/courses/#{@course.id}/external_tools/#{tool.id}",
        params: post_body,
        headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded '}
      )
      assert_status(200)
    end

    it 'accepts form data' do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      put(
        "/api/v1/courses/#{@course.id}/external_tools/#{tool.id}",
        params: post_body,
        headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded '}
      )
      expect(response).to be_successful
      expect(assigns[:tool]).not_to be_nil
    end

    it 'uses custom parsing for form data' do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      put(
        "/api/v1/courses/#{@course.id}/external_tools/#{tool.id}",
        params: post_body,
        headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded '}
      )

      expect(assigns[:tool].settings[:custom_fields]["Complex!@#$^*(){}[]KEY"]).to eq 'Complex!@#$^*;(){}[]½Value'
    end
  end

  describe "POST 'create_tool_with_verification'" do
    context "form post", type: :request do
      include WebMock::API

      let(:post_body) do
        {
          custom_fields_string: '',
          consumer_key: 'N/A',
          shared_secret: 'N/A',
          config_url: 'https://www.edu-apps.org/lti_public_resources/config.xml?id=youtube&name=YouTube&channel_name=jangbricks',
          config_type: 'by_url',
          name: 'YouTube',
          app_center_id: 'pr_youtube',
          config_settings: { name: 'YouTube', channel_name: 'foo-bar' },
          course_navigation: { enabled: true }
        }
      end

      let(:app_center_response) do
        {
          "id"   =>163,
          "short_name" => "pr_youtube",
          "name" => "YouTube",
          "description" => "\n<p>Search publicly available YouTube videos.</p>\n",
          "short_description" => "Search publicly available YouTube videos.",
          "status" => "active",
          "app_type" => nil,
          "preview_url" => "https://www.edu-apps.org/lti_public_resources/?tool_id=youtube",
          "banner_image_url" => "https://edu-app-center.s3.amazonaws.com/uploads/pr_youtube.png",
          "logo_image_url" => nil,
          "icon_image_url" => nil,
          "average_rating" => 4.0,
          "total_ratings" => 5.0,
          "is_certified" => false,
          "config_xml_url" => "https://www.edu-apps.org/lti_public_resources/config.xml?id=youtube",
          "requires_secret" => false,
          "config_options" => [
            {
              "name" => "channel_name",
              "param_type" => "text",
              "default_value" => "",
              "description" => "Channel Name (Optional)",
              "is_required" => false
            }
          ]
        }
      end

      before(:each) do
        allow_any_instance_of(AppCenter::AppApi).to receive(:fetch_app_center_response).and_return(app_center_response)

        configxml = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'config.youtube.xml'))
        stub_request(:get, app_center_response['config_xml_url']).to_return(body: configxml)
        stub_request(:get, "https://www.edu-apps.org/tool_i_should_not_have_access_to.xml").to_return(status: 404)
      end

      it 'creates tool when provided all required params' do
        user_session(@teacher)
        post(
          "/api/v1/courses/#{@course.id}/create_tool_with_verification",
          params: post_body.to_json,
          headers: {'CONTENT_TYPE' => 'application/json'}
        )

        expect(response).to be_successful
        expect(assigns[:tool].name).to eq app_center_response['name']
      end

      it 'gives error if app_center_id is not provided' do
        allow_any_instance_of(AppCenter::AppApi).to receive(:get_app_config_url).and_return('')
        user_session(@teacher)

        post(
          "/api/v1/courses/#{@course.id}/create_tool_with_verification",
          params: post_body.to_json,
          headers: {'CONTENT_TYPE' => 'application/json'}
        )

        expect(response).not_to be_success
      end

      it 'ignores non-required params' do
        user_session(@teacher)

        post(
          "/api/v1/courses/#{@course.id}/create_tool_with_verification",
          params: post_body.to_json,
          headers: {'CONTENT_TYPE' => 'application/json'}
        )

        expect(response).to be_successful
        expect(assigns[:tool].settings[:course_navigation]).not_to be_truthy
      end

      it 'uses the config xml provided by the app center' do
        user_session(@teacher)
        post_body['config_url'] = 'https://www.edu-apps.org/tool_i_should_not_have_access_to.xml'

        post(
          "/api/v1/courses/#{@course.id}/create_tool_with_verification",
          params: post_body.to_json,
          headers: {'CONTENT_TYPE' => 'application/json'}
        )

        expect(response).to be_successful
        expect(assigns[:tool].name).to eq app_center_response['name']
      end
    end
  end
end
