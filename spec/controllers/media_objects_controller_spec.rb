#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MediaObjectsController do

  describe "GET 'show'" do
    before do
      # We don't actually want to ping kaltura during these tests
      allow(MediaObject).to receive(:media_id_exists?).and_return(true)
      allow_any_instance_of(MediaObject).to receive(:media_sources).and_return([{:url => "whatever man", :bitrate => 12345}])
    end

    it "should create a MediaObject if necessary on request" do
      # this test is purposely run with no user logged in to make sure it works in public courses

      missing_media_id = "0_12345678"
      expect(MediaObject.by_media_id(missing_media_id)).to be_empty

      get 'show', params: {:media_object_id => missing_media_id}
      expect(json_parse(response.body)).to eq({
              'can_add_captions' => false,
              'media_id' => missing_media_id,
              'user_entered_title' => nil,
              'title' => nil,
              'media_tracks' => [],
              'media_sources' => [{"bitrate"=>12345, "label"=>"12 kbps", "src"=>"whatever man", "url"=>"whatever man"}]
      })
      expect(MediaObject.by_media_id(missing_media_id).first.media_id).to eq missing_media_id
    end

    it "should retrieve info about a 'deleted' MediaObject" do
      deleted_media_id = '0_deadbeef'
      course_factory
      media_object = course_factory.media_objects.build :media_id => deleted_media_id
      media_object.workflow_state = 'deleted'
      media_object.save!

      get 'show', params: {:media_object_id => deleted_media_id}
      expect(json_parse(response.body)).to eq({
          'can_add_captions' => false,
          'media_id' => deleted_media_id,
          'title' => nil,
          'user_entered_title' => nil,
          'media_tracks' => [],
          'media_sources' => [{"bitrate"=>12345, "label"=>"12 kbps", "src"=>"whatever man", "url"=>"whatever man"}]
      })
    end

  end

  describe "GET 'index'" do
    before do
      # We don't actually want to ping kaltura during these tests
      allow(MediaObject).to receive(:media_id_exists?).and_return(true)
      allow_any_instance_of(MediaObject).to receive(:media_sources).and_return([{:url => "whatever man", :bitrate => 12345}])
    end

    it "should retrieve all MediaObjects user has created" do
      user_factory
      user_session(@user)
      MediaObject.create!(:user_id => @user, :media_id => "test")
      MediaObject.create!(:user_id => @user, :media_id => "test2")
      MediaObject.create!(:user_id => @user, :media_id => "test3")

      get 'index'
      expect(json_parse(response.body)).to eq([
        {
          "can_add_captions"=>true,
         "media_id"=>"test3",
         "media_sources"=>
          [{"bitrate"=>12345,
            "label"=>"12 kbps",
            "src"=>"whatever man",
            "url"=>"whatever man"}],
         "media_tracks"=>[],
         "title"=>nil,
         "user_entered_title"=>nil
        },
        {"can_add_captions"=>true,
         "media_id"=>"test2",
         "media_sources"=>
          [{"bitrate"=>12345,
            "label"=>"12 kbps",
            "src"=>"whatever man",
            "url"=>"whatever man"}],
         "media_tracks"=>[],
         "title"=>nil,
         "user_entered_title"=>nil},
        {"can_add_captions"=>true,
         "media_id"=>"test",
         "media_sources"=>
          [{"bitrate"=>12345,
            "label"=>"12 kbps",
            "src"=>"whatever man",
            "url"=>"whatever man"}],
         "media_tracks"=>[],
         "title"=>nil,
         "user_entered_title"=>nil}
      ])
    end

    it "will not retrive items you did not create" do
      user1 = user_factory
      user2 = user_factory
      user_session(user1)
      MediaObject.create!(:user_id => user2, :media_id => "test")
      MediaObject.create!(:user_id => user2, :media_id => "test2")
      MediaObject.create!(:user_id => user2, :media_id => "test3")

      get 'index'
      expect(json_parse(response.body)).to eq([])
    end
  end
end
