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
  let(:api){ AppCenter::AppApi.new }

  before(:each) do
    default_settings = api.app_center.default_settings
    default_settings['base_url'] = 'www.example.com'
    default_settings['apps_index_endpoint'] = '/apps'
    default_settings['app_reviews_endpoint'] = '/apps/:id'
    PluginSetting.create(:name => api.app_center.id, :settings => default_settings)
  end

  it "finds the app_center plugin" do
    api.app_center.should_not be_nil
    api.app_center.should == Canvas::Plugin.find(:app_center)
    api.app_center.should be_enabled
    api.app_center.settings['base_url'].should_not be_empty
  end

  describe '#fetch_app_center_response' do
    let(:response) do
      response = mock
      response.stubs(:body).returns(
          {
              'meta' => { "next" => "https://www.example.com/api/v1/apps?offset=60"},
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
      Canvas::HTTP.expects(:get).with("#{api.app_center.settings['base_url']}#{endpoint}&offset=#{page * per_page - per_page}").returns(response)
      api.fetch_app_center_response(endpoint, 11.minutes, page, per_page)
    end

    it "can handle an invalid response" do
      response.stubs(:body).returns('')
      Canvas::HTTP.expects(:get).returns(response)
      api.fetch_app_center_response('', 12.minutes, 8, 3).should == {}
    end

    it "resets the cache when getting an invalid response" do
      enable_cache do
        response.stubs(:body).returns('')
        Canvas::HTTP.expects(:get).returns(response).twice()
        api.fetch_app_center_response('', 13.minutes, 7,4).should == {}
        api.fetch_app_center_response('', 13.minutes, 7,4).should == {}
      end
    end

    it "can handle an error response" do
      message = {"message" => "Tool not found","type" =>"error"}
      response.stubs(:body).returns(message.to_json)
      Canvas::HTTP.expects(:get).returns(response)
      api.fetch_app_center_response('', 13.minutes, 6,9).should == message
    end

    it "respects per_page param" do
      endpoint = '/?myparam=value'
      per_page = 1
      page = 1
      offset = page * per_page - per_page
      Canvas::HTTP.expects(:get).with("#{api.app_center.settings['base_url']}#{endpoint}&offset=#{offset}").returns(response)
      response = api.fetch_app_center_response(endpoint, 11.minutes, page, per_page)
      results = response['objects']
      results.size.should == 1
      results.first.should == 'object1'
      response['meta']['next_page'].should == 2
    end

    it "can omit next page" do
      message = {"objects" => %w(object1 object2 object3 object4), "meta" => {}}
      response.stubs(:body).returns(message.to_json)
      endpoint = '/?myparam=value'
      per_page = 5
      page = 1
      offset = page * per_page - per_page
      Canvas::HTTP.expects(:get).with("#{api.app_center.settings['base_url']}#{endpoint}&offset=#{offset}").returns(response)
      response = api.fetch_app_center_response(endpoint, 11.minutes, page, per_page)
      results = response['objects']
      results.size.should == 4
      response['meta']['next_page'].should be_nil
    end
  end

  describe '#get_apps' do
    let(:response) do
      response = mock
      response.stubs(:body).returns(
          {
              'meta' => { "next" => "https://www.example.com/api/v1/apps?offset=72"},
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
      Canvas::HTTP.stubs(:get).returns(response)
      apps = api.get_apps()['objects']
      apps.should be_a Array
      apps.size.should == 2
    end

    it "returns an empty hash if the app center is disabled" do
      Canvas::HTTP.stubs(:get).returns(response)
      setting = PluginSetting.find_by_name(api.app_center.id)
      setting.destroy

      api.app_center.should_not be_enabled

      response = api.get_apps()
      response.should be_a Hash
      response.size.should == 0
    end

    it "gets the next page" do
      enable_cache do
        Canvas::HTTP.stubs(:get).returns(response)
        response = api.get_apps
        response['meta']['next_page'].should == 2
      end
    end

    it "caches apps results" do
      enable_cache do
        Canvas::HTTP.expects(:get).returns(response)
        api.get_apps()
        api.get_apps()
      end
    end

    it "caches multiple calls" do
      enable_cache do
        Canvas::HTTP.expects(:get).returns(response).times(2)
        api.get_apps(0)
        api.get_apps(1)
        api.get_apps(0)
        api.get_apps(1)
      end
    end
  end

  describe '#get_app_reviews' do
    let(:response) do
      response = mock
      response.stubs(:body).returns(
          {
              'meta' => { "next" => "https://www.example.com/api/v1/apps/first_tool/reviews?offset=15"},
              'current_offset' => 0,
              'limit' => 15,
              'objects' => [
                  {
                      'user_name' => 'Iron Man',
                      'user_avatar_url' => 'http://www.example.com/rich.ico',
                      'comments' => 'This tool is so great',
                  },
                  {
                      'user_name' => 'The Hulk',
                      'user_avatar_url' => 'http://www.example.com/beefy.ico',
                      'comments' => 'SMASH!',
                  }
              ]
          }.to_json
      )
      response
    end

    it "gets an apps reviews" do
      Canvas::HTTP.stubs(:get).returns(response)
      reviews = api.get_app_reviews('first_tool')['objects']
      reviews.should be_a Array
      reviews.size.should == 2
    end

    it "returns an empty hash if the app center is disabled" do
      Canvas::HTTP.stubs(:get).returns(response)
      setting = PluginSetting.find_by_name(api.app_center.id)
      setting.destroy

      api.app_center.should_not be_enabled

      response = api.get_app_reviews('first_tool')
      response.should be_a Hash
      response.size.should == 0
    end

    it "gets the next page" do
      Canvas::HTTP.stubs(:get).returns(response)
      response = api.get_app_reviews('first_tool')
      response['meta']['next_page'].should == 2
    end

    it "caches apps results" do
      enable_cache do
        Canvas::HTTP.expects(:get).returns(response)
        api.get_app_reviews('first_tool')
        api.get_app_reviews('first_tool')
      end
    end

    it "caches multiple calls" do
      enable_cache do
        Canvas::HTTP.expects(:get).returns(response).times(2)
        api.get_app_reviews('first_tool',0)
        api.get_app_reviews('first_tool',1)
        api.get_app_reviews('first_tool',0)
        api.get_app_reviews('first_tool',1)
      end
    end
  end
end
