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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Users API", :type => :integration do
  before do
    @admin = account_admin_user
    course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'pvuser@example.com'))
    @student = @user
    @student.pseudonym.update_attribute(:sis_user_id, 'sis-user-id')
    @user = @admin
    Account.default.tap { |a| a.enable_service(:avatars) }.save
    user_with_pseudonym(:user => @user)
  end

  it "should return another user's profile, if allowed" do
    json = api_call(:get, "/api/v1/users/#{@student.id}/profile",
             :controller => "profile", :action => "show", :user_id => @student.to_param, :format => 'json')
    json.should == {
      'id' => @student.id,
      'name' => 'Student',
      'sortable_name' => 'student',
      'short_name' => 'Student',
      'primary_email' => 'pvuser@example.com',
      'sis_user_id' => 'sis-user-id',
      'sis_login_id' => nil,
      'login_id' => 'pvuser@example.com',
      'avatar_url' => "http://www.example.com/images/users/#{@student.id}",
    }
  end

  it "should return user info for users with no pseudonym" do
    @me = @user
    new_user = user(:name => 'new guy')
    @user = @me
    @course.enroll_user(new_user, 'ObserverEnrollment')
    Account.site_admin.add_user(@user)
    json = api_call(:get, "/api/v1/users/#{new_user.id}/profile",
             :controller => "profile", :action => "show", :user_id => new_user.to_param, :format => 'json')
    json.should == {
      'id' => new_user.id,
      'name' => 'new guy',
      'sortable_name' => 'guy, new',
      'short_name' => 'new guy',
      'login_id' => nil,
      'primary_email' => nil,
      'avatar_url' => "http://www.example.com/images/users/#{new_user.id}",
    }

    get("/courses/#{@course.id}/students")
  end

  it "should return this user's profile" do
    json = api_call(:get, "/api/v1/users/self/profile",
             :controller => "profile", :action => "show", :user_id => 'self', :format => 'json')
    json.should == {
      'id' => @admin.id,
      'name' => 'User',
      'sortable_name' => 'user',
      'short_name' => 'User',
      'primary_email' => 'nobody@example.com',
      'sis_user_id' => nil,
      'sis_login_id' => nil,
      'login_id' => 'nobody@example.com',
      'avatar_url' => "http://www.example.com/images/users/#{@admin.id}",
      'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@admin.uuid}.ics" },
    }
  end

  it "should return this user's profile (non-admin)" do
    @user = @student
    json = api_call(:get, "/api/v1/users/#{@student.id}/profile",
             :controller => "profile", :action => "show", :user_id => @student.to_param, :format => 'json')
    json.should == {
      'id' => @student.id,
      'name' => 'Student',
      'sortable_name' => 'student',
      'short_name' => 'Student',
      'primary_email' => 'pvuser@example.com',
      'login_id' => 'pvuser@example.com',
      'avatar_url' => "http://www.example.com/images/users/#{@student.id}",
      'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
    }
  end

  it "shouldn't return disallowed profiles" do
    @user = @student
    raw_api_call(:get, "/api/v1/users/#{@admin.id}/profile",
             :controller => "profile", :action => "show", :user_id => @admin.to_param, :format => 'json')
    response.status.should == "401 Unauthorized"
    JSON.parse(response.body).should == { 'status' => 'unauthorized' }
  end

  it "should return page view history" do
    page_view_model(:user => @student)
    page_view_model(:user => @student)
    page_view_model(:user => @student)
    Setting.set('api_max_per_page', '2')
    json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?per_page=1000",
                       { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :per_page => '1000' })
    json.size.should == 2
    json.each { |j| j['url'].should == "http://www.example.com/courses/1" }
    json = api_call(:get, "/api/v1/users/sis_user_id:sis-user-id/page_views?page=2",
                       { :controller => "page_views", :action => "index", :user_id => 'sis_user_id:sis-user-id', :format => 'json', :page => '2' })
    json.size.should == 1
    json.each { |j| j['url'].should == "http://www.example.com/courses/1" }
  end

  it "should allow id of 'self'" do
    page_view_model(:user => @admin)
    json = api_call(:get, "/api/v1/users/self/page_views?per_page=1000",
                       { :controller => "page_views", :action => "index", :user_id => 'self', :format => 'json', :per_page => '1000' })
    json.size.should == 1
  end
end

