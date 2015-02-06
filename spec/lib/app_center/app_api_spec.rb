#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

# Manually stubbing the actual API request
describe AppCenter::AppApi do
  let(:api) { AppCenter::AppApi.new }

  before(:each) do
    default_settings = api.app_center.default_settings
    default_settings['base_url'] = 'http://www.example.com'
    default_settings['apps_index_endpoint'] = '/apps'
    default_settings['token'] = 'ABCDEFG1234567'
    PluginSetting.create!(:name => api.app_center.id, :settings => default_settings)
  end

  it "finds the app_center plugin" do
    expect(api.app_center).not_to be_nil
    expect(api.app_center).to eq Canvas::Plugin.find(:app_center)
    expect(api.app_center).to be_enabled
    expect(api.app_center.settings['base_url']).not_to be_empty
  end

  describe '#fetch_app_center_response' do
    let(:response) do
      response = mock
      response.stubs(:body).returns(
          {
              'meta' => {"next" => "https://www.example.com/api/v1/apps?offset=60"},
              'current_offset' => 0,
              'limit' => 50,
              'objects' => %w(object1 object2 object3 object4)
          }.to_json
      )
      response
    end

    it "can handle query params in the endpoint" do
      endpoint = '/?myparam=value'
      per_page = 11
      page = 3
      CanvasHttp.expects(:get).with("#{api.app_center.settings['base_url']}#{endpoint}&offset=#{page * per_page - per_page}").returns(response)
      api.fetch_app_center_response(endpoint, 11.minutes, page, per_page)
    end

    it "can handle an invalid response" do
      response.stubs(:body).returns('')
      CanvasHttp.expects(:get).returns(response)
      expect(api.fetch_app_center_response('', 12.minutes, 8, 3)).to eq({})
    end

    it "can handle an error response" do
      message = {"message" => "Tool not found", "type" => "error"}
      response.stubs(:body).returns(message.to_json)
      CanvasHttp.expects(:get).returns(response)
      expect(api.fetch_app_center_response('', 13.minutes, 6, 9)).to eq message
    end

    it "respects per_page param" do
      endpoint = '/?myparam=value'
      per_page = 1
      page = 1
      offset = page * per_page - per_page
      CanvasHttp.expects(:get).with("#{api.app_center.settings['base_url']}#{endpoint}&offset=#{offset}").returns(response)
      response = api.fetch_app_center_response(endpoint, 11.minutes, page, per_page)
      results = response['objects']
      expect(results.size).to eq 1
      expect(results.first).to eq 'object1'
      expect(response['meta']['next_page']).to eq 2
    end

    it "can omit next page" do
      message = {"objects" => %w(object1 object2 object3 object4), "meta" => {}}
      response.stubs(:body).returns(message.to_json)
      endpoint = '/?myparam=value'
      per_page = 5
      page = 1
      offset = page * per_page - per_page
      CanvasHttp.expects(:get).with("#{api.app_center.settings['base_url']}#{endpoint}&offset=#{offset}").returns(response)
      response = api.fetch_app_center_response(endpoint, 11.minutes, page, per_page)
      results = response['objects']
      expect(results.size).to eq 4
      expect(response['meta']['next_page']).to be_nil
    end

    describe "caching" do
      it "resets the cache when getting an invalid response" do
        enable_cache do
          response.stubs(:body).returns('')
          CanvasHttp.expects(:get).returns(response).twice()
          expect(api.fetch_app_center_response('', 13.minutes, 7, 4)).to eq({})
          expect(api.fetch_app_center_response('', 13.minutes, 7, 4)).to eq({})
        end
      end

      it "uses the configured token as part of the cache key" do
        enable_cache do
          CanvasHttp.expects(:get).returns(response).twice()

          api.fetch_app_center_response('/endpoint/url', 13.minutes, 7, 4)

          plugin_setting = PluginSetting.where(name: api.app_center.id).first
          plugin_setting.settings['token'] = 'new_token'
          plugin_setting.save!

          api2 = AppCenter::AppApi.new

          api2.fetch_app_center_response('/endpoint/url', 13.minutes, 7, 4)
        end
      end
    end
  end

  describe '#get_apps' do
    let(:response) do
      response = mock
      response.stubs(:body).returns(
          {
              'meta' => {"next" => "https://www.example.com/api/v1/apps?offset=72"},
              'current_offset' => 0,
              'limit' => 72,
              'objects' => [
                  {
                      'name' => 'First Tool',
                      'id' => 'first_tool',
                  },
                  {
                      'name' => 'Second Tool',
                      'id' => 'second_tool',
                  }
              ]
          }.to_json
      )
      response
    end

    it "gets a list of apps" do
      CanvasHttp.stubs(:get).returns(response)
      apps = api.get_apps()['lti_apps']
      expect(apps).to be_a Array
      expect(apps.size).to eq 2
    end

    it "returns an empty hash if the app center is disabled" do
      CanvasHttp.stubs(:get).returns(response)
      setting = PluginSetting.find_by_name(api.app_center.id)
      setting.destroy

      expect(api.app_center).not_to be_enabled

      response = api.get_apps()
      expect(response).to be_a Hash
      expect(response.size).to eq 0
    end

    it "gets the next page" do
      enable_cache do
        CanvasHttp.stubs(:get).returns(response)
        response = api.get_apps
        expect(response['meta']['next_page']).to eq 2
      end
    end

    it "caches apps results" do
      enable_cache do
        CanvasHttp.expects(:get).returns(response).once
        api.get_apps()
        api.get_apps()
      end
    end

    it "caches multiple calls" do
      enable_cache do
        CanvasHttp.expects(:get).returns(response).times(2)
        api.get_apps(0)
        api.get_apps(1)
        api.get_apps(0)
        api.get_apps(1)
      end
    end

    it "can handle an edu-apps api v1 response" do
      app = {
          "name" => "Wikipedia",
          "id" => "wikipedia",
          "categories" => [
              "Completely Free",
              "Open Content",
              "Web 2.0"
          ],
          "levels" => [
              "K-6th Grade",
              "7th-12th Grade",
              "Postsecondary"
          ],
          "description" => "Search through English Wikipedia articles and link to or embed these articles into course material.",
          "app_type" => "open_launch",
          "short_description" => "Articles from The Free Encyclopedia",
          "extensions" => [
              "editor_button",
              "resource_selection"
          ],
          "beta" => false,
          "test_instructions" => "",
          "support_link" => "https://twitter.com/whitmer",
          "ims_link" => "",
          "author_name" => "Brian Whitmer",
          "privacy_level" => "anonymous",
          "width" => 590,
          "height" => 450,
          "added" => "2012-03-22T00:00:00Z",
          "uses" => 30,
          "submitter_name" => nil,
          "submitter_url" => nil,
          "ratings_count" => 1,
          "comments_count" => 1,
          "avg_rating" => 5,
          "banner_url" => "http://mosdef.instructure.com/tools/wikipedia/banner.png",
          "logo_url" => "http://mosdef.instructure.com/tools/wikipedia/logo.png",
          "icon_url" => "http://mosdef.instructure.com/tools/wikipedia/icon.png",
          "new" => false,
          "config_url" => "http://mosdef.instructure.com/tools/wikipedia/config.xml",
          "any_key" => true,
          "preview" => {
              "url" => "/tools/wikipedia/index.html",
              "height" => 450
          },
          "short_name" => "wikipedia",
          "banner_image_url" => "http://mosdef.instructure.com/tools/wikipedia/banner.png",
          "logo_image_url" => "http://mosdef.instructure.com/tools/wikipedia/logo.png",
          "icon_image_url" => "http://mosdef.instructure.com/tools/wikipedia/icon.png",
          "config_xml_url" => "http://mosdef.instructure.com/tools/wikipedia/config.xml",
          "average_rating" => 5,
          "total_ratings" => 1,
          "config_options" => [
              {
                  "name" => "launch_url",
                  "description" => "Launch URL",
                  "type" => "text",
                  "value" => "example.com",
                  "required" => true
              }
          ]
      }

      response.stubs(:body).returns({"objects" => [app]}.to_json)
      CanvasHttp.expects(:get).returns(response)
      json = api.get_apps(0)
      tool = json['lti_apps'].first
      expect(tool['short_name']).to eq app['id']
      expect(tool['banner_image_url']).to eq app['banner_url']
      expect(tool['logo_image_url']).to eq app['logo_url']
      expect(tool['icon_image_url']).to eq app['icon_url']
      expect(tool['config_xml_url']).to eq app['config_url']
      expect(tool['average_rating']).to eq app['avg_rating']
      expect(tool['total_ratings']).to eq app['ratings_count']
      expect(tool['requires_secret']).to eq !app['any_key']
      opt = tool['config_options'].first
      expect(opt['name']).to eq app['config_options'].first['name']
      expect(opt['description']).to eq app['config_options'].first['description']
      expect(opt['param_type']).to eq app['config_options'].first['type']
      expect(opt['value']).to eq app['config_options'].first['value']
      expect(opt['is_required']).to eq app['config_options'].first['required']
    end

    it "can handle an edu-apps api v2 response" do
      app = {
          'id' => 2,
          'short_name' => "public_collections",
          'name' => "Public Collections",
          'short_description' => "",
          'status' => "active",
          'is_public' => true,
          'app_type' => "open_launch",
          'preview_url' => "http://www.edu-apps.org/tools/public_collections/index.html",
          'banner_image_url' => "http://www.edu-apps.org/tools/public_collections/banner.png",
          'logo_image_url' => "http://www.edu-apps.org/tools/public_collections/logo.png",
          'icon_image_url' => nil,
          'average_rating' => 0,
          'total_ratings' => 0,
          'is_certified' => false,
          'config_xml_url' => "http://localhost:3001/configurations/b1us84b2fewp5gqr.xml",
          'requires_secret' => true,
          'tags' => [
              {
                  'id' => 11,
                  'short_name' => "media",
                  'name' => "Media",
                  'context' => "category"
              },
              {
                  'id' => 12,
                  'short_name' => "open_content",
                  'name' => "Open Content",
                  'context' => "category"
              },
              {
                  'id' => 16,
                  'short_name' => "web_20",
                  'name' => "Web 2.0",
                  'context' => "category"
              },
              {
                  'id' => 17,
                  'short_name' => "free",
                  'name' => "Completely Free",
                  'context' => "category"
              },
              {
                  'id' => 19,
                  'short_name' => "K-6",
                  'name' => "K-6th Grade",
                  'context' => "education_level"
              },
              {
                  'id' => 20,
                  'short_name' => "7-12",
                  'name' => "7th-12th Grade",
                  'context' => "education_level"
              },
              {
                  'id' => 21,
                  'short_name' => "postsecondary",
                  'name' => "Postsecondary",
                  'context' => "education_level"
              }
          ]
      }
      response.stubs(:body).returns({"lti_apps" => [app]}.to_json)
      CanvasHttp.expects(:get).returns(response)
      json = api.get_apps(0)
      tool = json['lti_apps'].first

      expect(tool['categories'].length).to eq 4
      expect(tool['extensions']).to be_nil
      expect(tool['levels'].length).to eq 3
    end
  end
end
