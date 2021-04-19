# frozen_string_literal: true

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

describe InternetImageController do
  around(:example) do |example|
    WebMock.disable_net_connect!(allow_localhost: true)
    example.run
    WebMock.enable_net_connect!
  end

  it 'should require a user be logged in' do
    get 'image_search', params: {query: 'cats'}
    assert_unauthorized
  end

  it 'should require the plugin be configured' do
    user_model
    user_session(@user)
    get 'image_search', params: {query: 'cats'}
    assert_status(404)
  end

  describe "GET 'image_search'" do
    before :once do
      # these specs need an enabled unsplash plugin
      @plugin = PluginSetting.create!(name: 'unsplash')
      @plugin.update_attribute(:settings, { access_key: 'key', application_name: 'canvas' }.with_indifferent_access)
    end

    before :each do
      user_model
      user_session(@user)
    end

    it 'should update link headers to point to Canvas' do
      stub_request(:get, "https://api.unsplash.com/search/photos?content_filter=high&page=1&per_page=10&query=cats").to_return(
        status: 200,
        body: '',
        headers: {
          'Link' => '<https://api.unsplash.com/search/photos?content_filter=high&page=1&query=cats>; rel="first", <https://api.unsplash.com/search/photos?content_filter=high&page=1&query=cats>; rel="prev", <https://api.unsplash.com/search/photos?content_filter=high&page=3&query=cats>; rel="last", <https://api.unsplash.com/search/photos?content_filter=high&page=3&query=cats>; rel="next"'
        }
      )
      get 'image_search', params: {query: 'cats'}
      local_url = request.protocol + request.host_with_port
      expect(response.headers['Link']).to eq "<#{local_url}/api/v1/image_search?content_filter=high&page=1&query=cats>; rel=\"first\", <#{local_url}/api/v1/image_search?content_filter=high&page=1&query=cats>; rel=\"prev\", <#{local_url}/api/v1/image_search?content_filter=high&page=3&query=cats>; rel=\"last\", <#{local_url}/api/v1/image_search?content_filter=high&page=3&query=cats>; rel=\"next\""
    end

    it 'should return only the data we specify' do
      stub_request(:get, "https://api.unsplash.com/search/photos?content_filter=high&page=1&per_page=10&query=cats").
        to_return(status: 200, body: file_fixture("unsplash.json").read, headers: {'Content-Type' => 'application/json'})
      get 'image_search', params: {query: 'cats'}
      json = JSON.parse(response.body).first
      expect(json['description']).to eq nil
      expect(json['alt']).to eq 'selective focus photo of gray tabby cat'
      expect(json['user']).to eq "Erika Jan"
      expect(json['user_url']).to eq "https://unsplash.com/@ejan?utm_medium=referral&utm_source=canvas"
      expect(json['large_url']).to eq "https://images.unsplash.com/photo-1841217-8f162f1e1131?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max&ixid=eyJhcHBfaWQiOjQxMzYwfQ&utm_medium=referral&utm_source=canvas"
      expect(json['regular_url']).to eq "https://images.unsplash.com/photo-1841217-8f162f1e1131?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=400&fit=max&ixid=eyJhcHBfaWQiOjQxMzYwfQ&utm_medium=referral&utm_source=canvas"
      expect(json['small_url']).to eq "https://images.unsplash.com/photo-1841217-8f162f1e1131?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=200&fit=max&ixid=eyJhcHBfaWQiOjQxMzYwfQ&utm_medium=referral&utm_source=canvas"
      expect(json['raw_url']).to eq "https://images.unsplash.com/photo-1841217-8f162f1e1131?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjQxMzYwfQ&utm_medium=referral&utm_source=canvas"
      download_url = Canvas::Security.url_key_decrypt_data(json['id'])
      expect(download_url).to eq "https://api.unsplash.com/photos/bPxGLgJiMI/download"
    end

    it 'should send the app key as a client id header' do
      stub_request(:get, "https://api.unsplash.com/search/photos?page=1&per_page=10&query=cats").with(headers: {'Authorization': 'Client-ID key'})
      get 'image_search', params: {query: 'cats'}
      expect(WebMock).to have_requested(:get, "https://api.unsplash.com/search/photos?content_filter=high&page=1&per_page=10&query=cats").
        with(headers: {'Authorization': 'Client-ID key'}).once
    end

    it 'should read params back correctly' do
      begin
        WebMock::Config.instance.query_values_notation = :flat_array
        stub_request(:get, "https://api.unsplash.com/search/photos?page=2&per_page=18&query=cats").with(headers: {'Authorization': 'Client-ID key'})
        get 'image_search', params: {"query" => 'cats', "per_page" => 18, "page" => 2, "orientation" => 'landscape'}
        expect(WebMock).to have_requested(:get, "https://api.unsplash.com/search/photos?content_filter=high&page=2&per_page=18&query=cats&orientation=landscape").
          with(headers: {'Authorization': 'Client-ID key'}).once
      ensure
        WebMock::Config.instance.query_values_notation = :subscript
      end
    end
  end

  describe "GET 'image_selection'" do
    before :once do
      # these specs need an enabled unsplash plugin
      @plugin = PluginSetting.create!(name: 'unsplash')
      @plugin.update_attribute(:settings, { access_key: 'key' }.with_indifferent_access)
    end

    before :each do
      user_model
      user_session(@user)
    end

    it 'should show success message if successful' do
      stub_request(:head, "https://api.unsplash.com/photos/bPxGLgJiMI/download").with(headers: {'Authorization': 'Client-ID key'}).
        to_return(status: 200, headers: {'Content-Type' => 'application/json'})
      post 'image_selection', params: {id: "MNXkDmA1CTOTRxPFXAtX59DunVompzL9sdrM_Qa18WkF96Kd9ZlGD6xWDJlNgU4S3RQMdMPX4lrZ~dWUR5iRwMEGydMoD~fCYd8vLgJASKwTKsesSgTQ"}
      expect(WebMock).to have_requested(:head, "https://api.unsplash.com/photos/bPxGLgJiMI/download").
        with(headers: {'Authorization': 'Client-ID key'}).once
      expect(JSON.parse(response.body)).to eq({"message" => 'Confirmation success. Thank you.'})
    end

    it 'should show Unsplash message if Unsplash gives a 404' do
      stub_request(:head, "https://api.unsplash.com/photos/bPxGLgJiMI/download").with(headers: {'Authorization': 'Client-ID key'}).
        to_return(status: 404, body: "{\"errors\": [\"Couldn't find Photo\"]}", headers: {'Content-Type' => 'application/json'})
      post 'image_selection', params: {id: "MNXkDmA1CTOTRxPFXAtX59DunVompzL9sdrM_Qa18WkF96Kd9ZlGD6xWDJlNgU4S3RQMdMPX4lrZ~dWUR5iRwMEGydMoD~fCYd8vLgJASKwTKsesSgTQ"}
      expect(WebMock).to have_requested(:head, "https://api.unsplash.com/photos/bPxGLgJiMI/download").
        with(headers: {'Authorization': 'Client-ID key'}).once
      expect(JSON.parse(response.body)).to eq({"message" => "Couldn't find Photo"})
    end

    it 'should show an id error if it fails to parse the id' do
      post 'image_selection', params: {id: "MNXkDmA1CTOTRxPFXAtX59DunVompzL9sdrM_Qa18WkF96Kd9ZlGD6xWDJlNgU4S3RQMdMPX4lr~dWUR5iRwMEGydMoD~fCYd8vLgJASKwTKsesSgTQ"}
      expect(JSON.parse(response.body)).to eq({"message" => 'Could not find image.  Please check the id and try again'})
    end

    it 'should show 500 error if another error happens' do
      stub_request(:head, "https://api.unsplash.com/photos/bPxGLgJiMI").with(headers: {'Authorization': 'Client-ID key'}).
        to_return(status: 400)
      post 'image_selection', params: {id: "MNXkDmA1CTOTRxPFXAtX59DunVompzL9sdrM_Qa18WkF96Kd9ZlGD6xWDJlNgU4S3RQMdMPX4lrZ~dWUR5iRwMEGydMoD~fCYd8vLgJASKwTKsesSgTQ"}
      expect(WebMock).to have_requested(:head, "https://api.unsplash.com/photos/bPxGLgJiMI/download").
        with(headers: {'Authorization': 'Client-ID key'}).once
      assert_status(500)
    end
  end
end
