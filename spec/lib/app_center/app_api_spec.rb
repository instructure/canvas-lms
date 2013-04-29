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

  before(:each) do
    default_settings = api.app_center.default_settings
    default_settings['base_url'] = 'www.example.com'
    PluginSetting.create(:name => api.app_center.id, :settings => default_settings)
  end

  it "finds the app_center plugin" do
    api.app_center.should_not be_nil
    api.app_center.should == Canvas::Plugin.find(:app_center)
    api.app_center.should be_enabled
    api.app_center.settings['base_url'].should_not be_empty
  end

  describe '#get_apps' do
    before(:each) { Canvas::HTTP.stubs(:get).returns(response)}

    it "gets a list of apps" do
      apps = api.get_apps
      apps.should be_a Array
      apps.size.should == 2
    end

    it "returns an empty array if the app center is disabled" do
      setting = PluginSetting.find_by_name(api.app_center.id)
      setting.destroy

      api.app_center.should_not be_enabled

      apps = api.get_apps
      apps.should be_a Array
      apps.size.should == 0
    end

    it "respects per_page" do
      apps = api.get_apps(0, 1)
      apps.size.should == 1
      apps.first['id'].should == 'first_tool'
    end

    it "respects offset" do
      apps = api.get_apps(1,1)
      apps.size.should == 1
      apps.first['id'].should == 'second_tool'
    end

    it "caches results" do
      enable_cache do
        Canvas::HTTP.unstub(:get)
        Canvas::HTTP.expects(:get).returns(response)
        api.get_apps()
        api.get_apps()
      end
    end

    it "caches multiple calls" do
      enable_cache do
        Canvas::HTTP.unstub(:get)
        Canvas::HTTP.expects(:get).returns(response).times(2)
        api.get_apps(0,1)
        api.get_apps(1,1)
        api.get_apps(0,1)
        api.get_apps(1,1)
      end
    end
  end
end
