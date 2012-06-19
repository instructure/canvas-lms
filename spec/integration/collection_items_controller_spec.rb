#
# Copyright (C) 2012 Instructure, Inc.
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

describe CollectionItemsController do
  before(:all) { Bundler.require :embedly }

  context "#link_data" do
    it "should error if the user isn't logged in" do
      PluginSetting.expects(:settings_for_plugin).never
      post "/collection_items/link_data", :url => "http://www.example.com/"
      response.status.to_i.should == 401
    end

    it "should return null data if embedly isn't configured" do
      PluginSetting.expects(:settings_for_plugin).with(:embedly).returns(nil)
      user_session(user)
      post "/collection_items/link_data", :url => "http://www.example.com/"
      response.should be_success
      json_parse.should == {
        'title' => nil,
        'description' => nil,
        'images' => [],
        'object_html' => nil,
        'data_type' => nil,
      }
    end

    it "should return basic data for free embedly accounts" do
      user_session(user)
      data = OpenObject.new(:title => "t1", :description => "d1", :thumbnail_url => "/1.jpg")
      PluginSetting.expects(:settings_for_plugin).with(:embedly).returns({ :api_key => 'test', :plan_type => 'free'})
      Embedly::API.any_instance.expects(:oembed).with(
        :url => "http://www.example.com/",
        :autoplay => true,
        :maxwidth => Canvas::Embedly::MAXWIDTH
      ).returns([data])
      post "/collection_items/link_data", :url => "http://www.example.com/"
      response.should be_success
      json_parse.should == {
        'title' => data.title,
        'description' => data.description,
        'images' => [{ 'url' => data.thumbnail_url }],
        'object_html' => nil,
        'data_type' => nil,
      }
    end

    it "should return extended data for paid embedly accounts" do
      user_session(user)
      data = OpenObject.new(:title => "t1", :description => "d1", :images => [{'url' => 'u1'},{'url' => 'u2'}], :object => OpenObject.new(:html => "<iframe src='test'></iframe>"))
      PluginSetting.expects(:settings_for_plugin).with(:embedly).returns({ :api_key => 'test', :plan_type => 'paid'})
      Embedly::API.any_instance.expects(:preview).with(
        :url => "http://www.example.com/",
        :autoplay => true,
        :maxwidth => Canvas::Embedly::MAXWIDTH
      ).returns([data])
      post "/collection_items/link_data", :url => "http://www.example.com/"
      response.should be_success
      json_parse.should == {
        'title' => data.title,
        'description' => data.description,
        'images' => [{ 'url' => 'u1' }, { 'url' => 'u2' }],
        'object_html' => "<iframe src='test'></iframe>",
        'data_type' => nil,
      }
    end
  end
end
