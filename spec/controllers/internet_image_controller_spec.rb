#
# Copyright (C) 2019 - present Instructure, Inc.
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

require 'spec_helper'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

describe InternetImageController do
  it 'should require a user be logged in' do
    get 'image_search', params: {query: 'cats'}
    assert_unauthorized
  end

  describe "GET 'image_search'" do
    before :once do
      # these specs need an enabled unsplash plugin
      @plugin = PluginSetting.create!(name: 'unsplash')
      @plugin.update_attribute(:settings, { access_key: 'key' }.with_indifferent_access)
    end

    before :each do
      user_model
      user_session(@user)
    end

    it 'should update link headers to point to Canvas' do
      stub_request(:get, "https://api.unsplash.com/search/photos?page=1&per_page=10&query=cats").to_return(
        status: 200,
        body: '',
        headers: {
          'Link' => '<https://api.unsplash.com/search/photos?page=1&query=cats>; rel="first", <https://api.unsplash.com/search/photos?page=1&query=cats>; rel="prev", <https://api.unsplash.com/search/photos?page=3&query=cats>; rel="last", <https://api.unsplash.com/search/photos?page=3&query=cats>; rel="next"'
        }
      )
      get 'image_search', params: {query: 'cats'}
      local_url = request.protocol + request.host_with_port
      expect(response.headers['Link']).to eq "<#{local_url}/api/v1/image_search?page=1&query=cats>; rel=\"first\", <#{local_url}/api/v1/image_search?page=1&query=cats>; rel=\"prev\", <#{local_url}/api/v1/image_search?page=3&query=cats>; rel=\"last\", <#{local_url}/api/v1/image_search?page=3&query=cats>; rel=\"next\""
    end

    it 'should return only the data we specify' do
      stub_request(:get, "https://api.unsplash.com/search/photos?page=1&per_page=10&query=cats").
        to_return(status: 200, body: file_fixture("unsplash.json").read)
      get 'image_search', params: {query: 'cats'}
      expect(JSON.parse(response.body.sub("while(1)\;", ''))).to eq([{
        "id" => "eOLpJytrbsQ",
        "description" => "A man drinking a coffee.",
        "user" => "Jeff Sheldon",
        "user_url" => "http://unsplash.com/@ugmonk",
        "large_url" => "https://images.unsplash.com/photo-1416339306562-f3d12fefd36f?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max&s=92f3e02f63678acc8416d044e189f515",
        "regular_url" => "https://images.unsplash.com/photo-1416339306562-f3d12fefd36f?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=400&fit=max&s=263af33585f9d32af39d165b000845eb",
        "small_url" => "https://images.unsplash.com/photo-1416339306562-f3d12fefd36f?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=200&fit=max&s=8aae34cf35df31a592f0bef16e6342ef"
      }])
    end

    it 'should send the app key as a client id header' do
      stub_request(:get, "https://api.unsplash.com/search/photos?page=1&per_page=10&query=cats").with(headers: {'Authorization': 'Client-ID key'})
      get 'image_search', params: {query: 'cats'}
      expect(WebMock).to have_requested(:get, "https://api.unsplash.com/search/photos?page=1&per_page=10&query=cats").
        with(headers: {'Authorization': 'Client-ID key'}).once
    end
  end
end
