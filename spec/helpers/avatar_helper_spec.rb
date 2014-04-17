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

describe AvatarHelper do
  include AvatarHelper

  context "avatars" do
    let(:user) {user_model(short_name: "test user")}
    let(:services) {{avatars: true}}
    let(:avatar_size) {50}
    unless CANVAS_RAILS2
      let(:request) { Rack::Request.new(Rack::MockRequest.env_for("http://test.host/")) }
    end

    def service_enabled?(type)
      services[type]
    end

    describe ".avatar_image_attrs" do
      it "accepts a user id" do
        self.expects(:avatar_url_for_user).with(user).returns("test_url")
        avatar_image_attrs(user.id).should == ["test_url", user.short_name]
      end

      it "accepts a user" do
        self.expects(:avatar_url_for_user).with(user).returns("test_url")
        avatar_image_attrs(user).should == ["test_url", user.short_name]
      end

      it "falls back to blank avatar when given a user id of 0" do
        avatar_image_attrs(0).should == ["/images/messages/avatar-50.png", '']
      end

      it "falls back to blank avatar when user's avatar has been reported during this session" do
        self.expects(:session).returns({"reported_#{user.id}" => true})
        avatar_image_attrs(user).should == ["/images/messages/avatar-50.png", '']
      end

      it "falls back to a blank avatar when the user is nil" do
        avatar_image_attrs(nil).should == ["/images/messages/avatar-50.png", '']
      end
    end

    describe ".avatar" do
      let(:user) {user_model}

      it "leaves off the href if url is nil" do
        avatar(user, url: nil).should_not match(/href/)
      end

      it "sets the href to the given url" do
        avatar(user, url: "/test_url").should match(/href="\/test_url"/)
      end

      it "links to the context user's page when given a context_code" do
        self.expects(:context_prefix).with('course_1').returns('/courses/1')
        avatar(user, context_code: "course_1").should match("href=\"/courses/1/users/#{user.id}\"")
      end

      it "links to the user's page" do
        avatar(user).should match("/users/#{user.id}")
      end

      it "falls back to a blank avatar when the user is nil" do
        avatar(nil).should match("/images/messages/avatar-50.png")
      end
    end

    context "with avatar service off" do
      let(:services) {{avatars: false}}

      it "should return full URIs for users" do
        avatar_url_for_user(user).should match(%r{\Ahttps?://})
        avatar_url_for_user(user, true).should match(%r{\Ahttps?://})
      end
    end

    it "should return full URIs for users" do
      user
      avatar_url_for_user(@user).should match(%r{\Ahttps?://})
      avatar_url_for_user(@user, true).should match(%r{\Ahttps?://})

      @user.avatar_image_source = 'no_pic'
      @user.save!
      # reload to clear instance vars
      @user = User.find(@user.id)
      avatar_url_for_user(@user).should match(%r{\Ahttps?://})
      avatar_url_for_user(@user, true).should match(%r{\Ahttps?://})

      @user.avatar_state = 'approved'

      @user.avatar_image_source = 'attachment'
      @user.avatar_image_url = "/relative/canvas/path"
      @user.save!
      @user = User.find(@user.id)
      avatar_url_for_user(@user).should == "http://test.host/relative/canvas/path"

      @user.avatar_image_source = 'external'
      @user.avatar_image_url = "http://www.example.com/path"
      @user.save!
      @user = User.find(@user.id)
      avatar_url_for_user(@user).should == "http://www.example.com/path"
    end

    it "should return full URIs for groups" do
      avatar_url_for_group.should match(%r{\Ahttps?://})
      avatar_url_for_group(true).should match(%r{\Ahttps?://})
    end
  end
end
