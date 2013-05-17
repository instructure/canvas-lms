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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

# FIXME: don't copy paste
class TestUserApi
  include Api::V1::UserProfile
  attr_accessor :services_enabled, :context, :current_user
  def service_enabled?(service); @services_enabled.include? service; end
  def avatar_image_url(user_id); "avatar_image_url(#{user_id})"; end
  def initialize
    @domain_root_account = Account.default
  end
end

describe "User Profile API", :type => :integration do
  before do
    @admin = account_admin_user
    course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'pvuser@example.com'))
    @student.pseudonym.update_attribute(:sis_user_id, 'sis-user-id')
    @user = @admin
    Account.default.tap { |a| a.enable_service(:avatars) }.save
    user_with_pseudonym(:user => @user)
  end

  it "should return another user's avatars, if allowed" do
    json = api_call(:get, "/api/v1/users/#{@student.id}/avatars",
                    :controller => "profile", :action => "profile_pics", :user_id => @student.to_param, :format => 'json')
    json.map{ |j| j['type'] }.sort.should eql ['gravatar', 'no_pic']
  end

  it "should return user info for users with no pseudonym" do
    @me = @user
    new_user = user(:name => 'new guy')
    @user = @me
    @course.enroll_user(new_user, 'ObserverEnrollment')
    Account.site_admin.add_user(@user)
    json = api_call(:get, "/api/v1/users/#{new_user.id}/profile",
             :controller => "profile", :action => "settings", :user_id => new_user.to_param, :format => 'json')
    json.should == {
      'id' => new_user.id,
      'name' => 'new guy',
      'sortable_name' => 'guy, new',
      'short_name' => 'new guy',
      'login_id' => nil,
      'primary_email' => nil,
      'title' => nil,
      'bio' => nil,
      'avatar_url' => "https://secure.gravatar.com/avatar/000?s=50&d=http%3A%2F%2Fwww.example.com%2Fimages%2Fmessages%2Favatar-50.png",
    }

    get("/courses/#{@course.id}/students")
  end

  it "should return this user's profile" do
    json = api_call(:get, "/api/v1/users/self/profile",
             :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json')
    json.should == {
      'id' => @admin.id,
      'name' => 'User',
      'sortable_name' => 'User',
      'short_name' => 'User',
      'primary_email' => 'nobody@example.com',
      'login_id' => 'nobody@example.com',
      'avatar_url' => "https://secure.gravatar.com/avatar/8c5548eb0b2b80924f237953392df5e7?s=50&d=http%3A%2F%2Fwww.example.com%2Fimages%2Fmessages%2Favatar-50.png",
      'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@admin.uuid}.ics" },
      'title' => nil,
      'bio' => nil,
    }
  end

  it "should return this user's profile (non-admin)" do
    @user = @student
    json = api_call(:get, "/api/v1/users/#{@student.id}/profile",
             :controller => "profile", :action => "settings", :user_id => @student.to_param, :format => 'json')
    json.should == {
      'id' => @student.id,
      'name' => 'Student',
      'sortable_name' => 'Student',
      'short_name' => 'Student',
      'primary_email' => 'pvuser@example.com',
      'login_id' => 'pvuser@example.com',
      'avatar_url' => "https://secure.gravatar.com/avatar/7f2ba69d483b221f7bea6145425a19c1?s=50&d=http%3A%2F%2Fwww.example.com%2Fimages%2Fmessages%2Favatar-50.png",
      'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
      'title' => nil,
      'bio' => nil,
    }
  end

  it "should return this user's avatars, if allowed" do
    @user = @student
    @student.register
    json = api_call(:get, "/api/v1/users/#{@student.id}/avatars",
                    :controller => "profile", :action => "profile_pics", :user_id => @student.to_param, :format => 'json')
    json.map{ |j| j['type'] }.sort.should eql ['gravatar', 'no_pic']
  end

  it "shouldn't return disallowed profiles" do
    @user = @student
    raw_api_call(:get, "/api/v1/users/#{@admin.id}/profile",
             :controller => "profile", :action => "settings", :user_id => @admin.to_param, :format => 'json')
    response.status.should == "401 Unauthorized"
  end

  context "user_services" do
    before do
      @student.user_services.create! :service => 'skype', :service_user_name => 'user', :visible => false
      @student.user_services.create! :service => 'twitter', :service_user_name => 'user', :visible => true
    end

    it "should return user_services, if requested" do
      @user = @student
      json = api_call(:get, "/api/v1/users/#{@student.id}/profile?include[]=user_services",
                      :controller => "profile", :action => "settings",
                      :user_id => @student.to_param, :format => "json",
                      :include => ["user_services"])
      json["user_services"].should == [
        {"service" => "skype", "visible" => false, "service_user_link" => "skype:user?add"},
        {"service" => "twitter", "visible" => true, "service_user_link" => "http://www.twitter.com/user"},
      ]
    end

    it "should only return visible services for other users" do
      @user = @admin
      json = api_call(:get, "/api/v1/users/#{@student.id}/profile?include[]=user_services",
                      :controller => "profile", :action => "settings",
                      :user_id => @student.to_param, :format => "json",
                      :include => %w(user_services))
      json["user_services"].should == [
        {"service" => "twitter", "visible" => true, "service_user_link" => "http://www.twitter.com/user"},
      ]
    end

    it "should return profile links, if requested" do
      @student.profile.save
      @student.profile.links.create! :url => "http://instructure.com",
                                     :title => "Instructure"

      json = api_call(:get, "/api/v1/users/#{@student.id}/profile?include[]=links",
                      :controller => "profile", :action => "settings",
                      :user_id => @student.to_param, :format => "json",
                      :include => %w(links))
      json["links"].should == [
        {"url" => "http://instructure.com", "title" => "Instructure"}
      ]
    end
  end
end
