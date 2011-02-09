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

describe "security" do

  describe "session fixation" do
    it "should change the cookie session id after logging in" do
    
      u = user_with_pseudonym :active_user => true,
                              :username => "nobody@example.com",
                              :password => "asdfasdf"
      u.save!
    
      https!
      
      get_via_redirect "/login"
      assert_response :success
      cookie = cookies['_normandy_session']
      
      post_via_redirect "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
                                  "pseudonym_session[password]" => "asdfasdf",
                                  "pseudonym_session[remember_me]" => "1",
                                  "redirect_to_ssl" => "1"
      assert_response :success
      path.should eql("/dashboard")
      new_cookie = cookies['_normandy_session']
      new_cookie.should be_present
      cookie.should_not eql(new_cookie)
    end
  end

  describe "permissions" do
    it "should flush the role_override caches on permission changes" do
      course_with_teacher_logged_in

      get "/courses/#{@course.to_param}/users"
      assert_response :success

      RoleOverride.create!(:context => @course,
                           :permission => 'read_roster',
                           :enrollment_type => 'TeacherEnrollment',
                           :enabled => false)

      # if this second get doesn't fail with a permission denied error, we've
      # still got the permissions cached and haven't seen the change
      get "/courses/#{@course.to_param}/users"
      assert_response 401
    end

    # if we end up moving the permissions cache to memcache, this test won't be
    # valid anymore and we need some more extensive tests for actual cache
    # invalidation. right now, though, this is the only really valid way to
    # test that we're actually flushing on every request.
    it "should flush the role_override caches on every request" do
      course_with_teacher_logged_in

      get "/courses/#{@course.to_param}/users"
      assert_response :success

      RoleOverride.send(:instance_variable_get, '@cached_permissions').should_not be_empty
      RoleOverride.send(:class_variable_get, '@@role_override_chain').should_not be_empty

      get "/"
      assert_response 302

      # verify the cache is emptied on every request
      RoleOverride.send(:instance_variable_get, '@cached_permissions').should be_empty
      RoleOverride.send(:class_variable_get, '@@role_override_chain').should be_empty
    end
  end

  it "should make both session-related cookies httponly" do
    u = user_with_pseudonym :active_user => true,
                            :username => "nobody@example.com",
                            :password => "asdfasdf"
    u.save!

    https!

    post "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
      "pseudonym_session[password]" => "asdfasdf",
      "pseudonym_session[remember_me]" => "1",
      "redirect_to_ssl" => "1"
    assert_response 302
    response['Set-Cookie'].each do |cookie|
      if cookie =~ /\Apseudonym_credentials=/ || cookie =~ /\A_normandy_session=/
        cookie.should match(/; *HttpOnly/)
      end
    end
  end
end
