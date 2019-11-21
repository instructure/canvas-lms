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
      expect(json_parse(response.body)).to include({
              'can_add_captions' => false,
              'media_id' => missing_media_id,
              'title' => "Untitled",
              'media_type' => nil,
              'media_tracks' => [],
              'media_sources' => [{"bitrate"=>12345, "label"=>"12 kbps", "src"=>"whatever man", "url"=>"whatever man"}]
      })
      expect(MediaObject.by_media_id(missing_media_id).first.media_id).to eq missing_media_id
    end

    it "should retrieve info about a 'deleted' MediaObject" do
      deleted_media_id = '0_deadbeef'
      course_factory
      mo = media_object = course_factory.media_objects.build :media_id => deleted_media_id
      media_object.workflow_state = 'deleted'
      media_object.save!

      get 'show', params: {:media_object_id => deleted_media_id}
      expect(json_parse(response.body)).to eq({
          'can_add_captions' => false,
          'created_at' => mo.created_at.as_json,
          'media_id' => deleted_media_id,
          'title' => "Untitled",
          'media_type' => nil,
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
      mo1 = MediaObject.create!(:user_id => @user, :media_id => "test", :media_type => "video")
      mo2 = MediaObject.create!(:user_id => @user, :media_id => "test2", :media_type => "audio", :title => "The Title")
      mo3 = MediaObject.create!(:user_id => @user, :media_id => "test3", :user_entered_title => "User Title")

      get 'index'
      expect(json_parse(response.body)).to eq([
        {
          "can_add_captions"=>true,
          "created_at"=>mo2.created_at.as_json,
          "media_id"=>"test2",
          "media_sources"=>
          [{"bitrate"=>12345,
            "label"=>"12 kbps",
            "src"=>"whatever man",
            "url"=>"whatever man"}],
          "media_tracks"=>[],
          "title"=>"The Title",
          "media_type"=>"audio"
        },
        {
          "can_add_captions"=>true,
          "created_at"=>mo3.created_at.as_json,
          "media_id"=>"test3",
          "media_sources"=>
          [{"bitrate"=>12345,
            "label"=>"12 kbps",
            "src"=>"whatever man",
            "url"=>"whatever man"}],
          "media_tracks"=>[],
          "title"=>"User Title",
          "media_type"=>nil
        },

        {
          "can_add_captions"=>true,
          "created_at"=>mo1.created_at.as_json,
          "media_id"=>"test",
          "media_sources"=>
          [{"bitrate"=>12345,
            "label"=>"12 kbps",
            "src"=>"whatever man",
            "url"=>"whatever man"}],
          "media_tracks"=>[],
          "title"=>"Untitled",
          "media_type"=>"video"
        }
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

    it "will exclude media_sources if asked to" do
      user_factory
      user_session(@user)
      mo = MediaObject.create!(:user_id => @user, :media_id => "test", :media_type => "video")

      get 'index', params: {:exclude => ["sources"]}
      expect(json_parse(response.body)).to eq([
        {
          "can_add_captions"=>true,
          "created_at"=>mo.created_at.as_json,
          "media_id"=>"test",
          "media_tracks"=>[],
          "title"=>"Untitled",
          "media_type"=>"video"
        }
      ])
    end

    it "will exclude media_tracks if asked to" do
      user_factory
      user_session(@user)
      mo = MediaObject.create!(:user_id => @user, :media_id => "test", :media_type => "video")

      get 'index', params: {:exclude => ["tracks"]}
      expect(json_parse(response.body)).to eq([
        {
          "can_add_captions"=>true,
          "created_at"=>mo.created_at.as_json,
          "media_id"=>"test",
          "media_sources"=>
          [{"bitrate"=>12345,
            "label"=>"12 kbps",
            "src"=>"whatever man",
            "url"=>"whatever man"}],
          "title"=>"Untitled",
          "media_type"=>"video"
        }
      ])
    end

    it "will limit return to course media" do
      course_with_teacher_logged_in
      mo1 = MediaObject.create!(:user_id => @user, :context => @course, :media_id => "in_course")
      MediaObject.create!(:user_id => @user, :media_id => "not_in_course")

      get 'index', params: {:course_id => @course.id, :exclude => ["sources", "tracks"]}

      expect(json_parse(response.body)).to eq([
        {
          "can_add_captions"=>true,
          "created_at"=>mo1.created_at.as_json,
          "media_id"=>"in_course",
          "title"=>"Untitled",
          "media_type"=>nil
        }
      ])
    end

    it "will return a 404 if the given course_id doesn't exist" do
      course_with_teacher_logged_in
      mo1 = MediaObject.create!(:user_id => @user, :context => @course, :media_id => "in_course")
      MediaObject.create!(:user_id => @user, :media_id => "not_in_course")

      get 'index', params: {:course_id => 171717, :exclude => ["sources", "tracks"]}

      expect(response.status.to_s).to eq("404")
    end

    it "will reutrn user's media of context_type isn't 'course'" do
      course_with_teacher_logged_in
      mo1 = MediaObject.create!(:user_id => @user, :context => @course, :media_id => "in_course", :user_entered_title => "AAA")
      mo2 = MediaObject.create!(:user_id => @user, :media_id => "not_in_course", :user_entered_title => "BBB")

      get 'index', params: {:exclude => ["sources", "tracks"]}

      expect(json_parse(response.body)).to eq([
        {
          "can_add_captions"=>true,
          "created_at"=>mo1.created_at.as_json,
          "media_id"=>"in_course",
          "title"=>"AAA",
          "media_type"=>nil
        },
        {
          "can_add_captions"=>true,
          "created_at"=>mo2.created_at.as_json,
          "media_id"=>"not_in_course",
          "title"=>"BBB",
          "media_type"=>nil
        }
      ])
    end

    it "will sort by title" do
      course_with_teacher_logged_in
      MediaObject.create!(:user_id => @user, :media_id => "test",  :title => "ZZZ")
      MediaObject.create!(:user_id => @user, :media_id => "test2", :title => "YYY")
      MediaObject.create!(:user_id => @user, :media_id => "test3", :title => "XXX")

      get 'index', params: {
        :exclude => ["sources", "tracks"],
        :sort => "title",
        :order => "asc"
      }

      result = json_parse(response.body)
      expect(result[0]["title"]).to eq("XXX")
      expect(result[1]["title"]).to eq("YYY")
      expect(result[2]["title"]).to eq("ZZZ")
    end

    it "will sort by title or user_entered_title" do
      course_with_teacher_logged_in
      MediaObject.create!(:user_id => @user, :media_id => "test",  :title => "AAA", :user_entered_title => "ZZZ")
      MediaObject.create!(:user_id => @user, :media_id => "test2", :title => "YYY", :user_entered_title => nil)
      MediaObject.create!(:user_id => @user, :media_id => "test3", :title => "CCC", :user_entered_title => "XXX")

      get 'index', params: {
        :exclude => ["sources", "tracks"],
        :sort => "title",
        :order => "asc"
      }

      result = json_parse(response.body)
      expect(result[0]["title"]).to eq("XXX")
      expect(result[1]["title"]).to eq("YYY")
      expect(result[2]["title"]).to eq("ZZZ")
    end

    it "will sort by created_at" do
      course_with_teacher_logged_in
      Timecop.freeze(2.seconds.ago) { MediaObject.create!(:user_id => @user, :media_id => "test",  :title => "AAA") }
      Timecop.freeze(1.seconds.ago) { MediaObject.create!(:user_id => @user, :media_id => "test2", :title => "BBB") }
      MediaObject.create!(:user_id => @user, :media_id => "test3", :title => "CCC")

      get 'index', params: {
        :exclude => ["sources", "tracks"],
        :sort => "created_at",
        :order => "desc"
      }

      result = json_parse(response.body)
      expect(result[0]["title"]).to eq("CCC")
      expect(result[1]["title"]).to eq("BBB")
      expect(result[2]["title"]).to eq("AAA")
    end
  end

  describe "PUT update_media_object" do
    it "returns a 401 if the MediaObject doesn't exist" do
      course_with_teacher_logged_in
      put 'update_media_object', params: {:media_object_id => "anything", :user_entered_title => "new title"}
      assert_status(401)
    end

    it "returns a 401 if the MediaObject doesn't belong to the current user" do
      course_with_teacher_logged_in
      another_user = user_factory
      MediaObject.create!(:user_id => another_user, :media_id => "another-video")
      put 'update_media_object', params: {:media_object_id => "another-video", :user_entered_title => "new title"}
      assert_status(401)
    end

    it "requires a logged in user" do
      another_user = user_factory
      MediaObject.create!(:user_id => another_user, :media_id => "another-video")
      put 'update_media_object', params: {:media_object_id => "another-video", :user_entered_title => "new title"}
      assert_status(302) # redirect to login
    end

    it "returns the updated MediaObject" do
      course_with_teacher_logged_in
      MediaObject.create!(:user_id => @user, :media_id => "the-video", :title => "filename.mov")
      put 'update_media_object', params: {:media_object_id => "the-video", :user_entered_title => "new title"}

      assert_status(200)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("new title")
    end
  end
end
