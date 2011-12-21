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

describe CoursesController, :type => :integration do
  before do
    course_with_teacher(:active_all => true)
    @course1 = @course
    course_with_student(:user => @user, :active_all => true)
    @course2 = @course
  end
  
  it "should accept access_token" do
    @user.pseudonyms.create!(:unique_id => 'test@example.com')
    @token = @user.access_tokens.create!(:purpose => "test")

    @token.last_used_at.should be_nil
    
    raw_api_call(:get, "/api/v1/courses/#{@course2.id}/students.json?access_token=#{@token.token}",
            { :access_token => @token.token, :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    response.status.to_i.should == 200
    json = JSON.parse(response.body)
    json.should_not be_is_a(Hash)
    json.length.should == 1
    json[0]['id'].should == @user.id
    @token.reload.last_used_at.should_not be_nil
  end
  
  it "should not accept an invalid access_token" do
    @user.pseudonyms.create!(:unique_id => 'test@example.com')
    @token = @user.access_tokens.create!(:purpose => "test")

    raw_api_call(:get, "/api/v1/courses/#{@course2.id}/students.json?access_token=1234",
            { :access_token => "1234", :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    response.status.to_i.should == 400
    json = JSON.parse(response.body)
    json['errors'].should == "Invalid access token"
  end
  
  it "should not accept an expired access_token" do
    @user.pseudonyms.create!(:unique_id => 'test@example.com')
    @token = @user.access_tokens.create!(:purpose => "test", :expires_at => 2.weeks.ago)

    raw_api_call(:get, "/api/v1/courses/#{@course2.id}/students.json?access_token=#{@token.token}",
            { :access_token => @token.token, :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    response.status.to_i.should == 400
    json = JSON.parse(response.body)
    json['errors'].should == "Invalid access token"
  end

  it "should require an active pseudonym" do
    @token = @user.access_tokens.create!(:purpose => "test")

    @token.last_used_at.should be_nil

    raw_api_call(:get, "/api/v1/courses/#{@course2.id}/students.json?access_token=#{@token.token}",
            { :access_token => @token.token, :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    response.status.to_i.should == 400
    json = JSON.parse(response.body)
    json['errors'].should == "Invalid access token"
  end

  it "should allow as_user_id" do
    account_admin_user(:account => Account.site_admin)
    user_with_pseudonym(:user => @user)

    json = api_call(:get, "/api/v1/users/self/profile?as_user_id=#{@student.id}",
             :controller => "profile", :action => "show", :user_id => 'self', :format => 'json', :as_user_id => @student.id.to_param)
    assigns['current_user'].should == @student
    assigns['real_current_user'].should == @user
    json.should == {
      'id' => @student.id,
      'name' => 'User',
      'sortable_name' => 'User',
      'short_name' => 'User',
      'primary_email' => nil,
      'login_id' => nil,
      'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
    }

    # as_user_id is ignored if it's not allowed
    @user = @student
    user_with_pseudonym(:user => @user, :username => "nobody2@example.com")
    raw_api_call(:get, "/api/v1/users/self/profile?as_user_id=#{@admin.id}",
             :controller => "profile", :action => "show", :user_id => 'self', :format => 'json', :as_user_id => @admin.id.to_param)
    assigns['current_user'].should == @student
    assigns['real_current_user'].should be_nil
    json.should == {
      'id' => @student.id,
      'name' => 'User',
      'sortable_name' => 'User',
      'short_name' => 'User',
      'primary_email' => nil,
      'login_id' => nil,
      'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
    }
  end

  it "should allow sis_user_id as an as_user_id" do
    account_admin_user(:account => Account.site_admin)
    user_with_pseudonym(:user => @user)
    @student.pseudonyms.create!(:account => Account.default, :unique_id => "nobody_sis@example.com", :password => "secret", :password_confirmation => "secret")
    @student.pseudonym.update_attribute(:sis_user_id, "1234")

    json = api_call(:get, "/api/v1/users/self/profile?as_user_id=sis_user_id:#{@student.pseudonym.sis_user_id}",
             :controller => "profile", :action => "show", :user_id => 'self', :format => 'json', :as_user_id => "sis_user_id:#{@student.pseudonym.sis_user_id.to_param}")
    assigns['current_user'].should == @student
    assigns['real_current_user'].should == @user
    json.should == {
      'id' => @student.id,
      'name' => 'User',
      'sortable_name' => 'User',
      'short_name' => 'User',
      'primary_email' => nil,
      'login_id' => 'nobody_sis@example.com',
      'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
    }
  end

  it "should not prepend the CSRF protection to API requests" do
    user_with_pseudonym(:user => @user)
    raw_api_call(:get, "/api/v1/users/self/profile",
                    :controller => "profile", :action => "show", :user_id => "self", :format => "json")
    response.should be_success
    raw_json = response.body
    raw_json.should_not match(%r{^while\(1\);})
    json = JSON.parse(raw_json)
    json['id'].should == @user.id
  end

  it "should not prepend the CSRF protection to HTTP Basic API requests" do
    user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
    get "/api/v1/users/self/profile", {}, { :authorization => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'test123') }
    response.should be_success
    raw_json = response.body
    raw_json.should_not match(%r{^while\(1\);})
    json = JSON.parse(raw_json)
    json['id'].should == @user.id
  end

  it "should prepend the CSRF protection for API endpoints, when session auth is used" do
    user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
    post "/login", "pseudonym_session[unique_id]" => "test1@example.com",
      "pseudonym_session[password]" => "test123"
    assert_response 302
    get "/api/v1/users/self/profile"
    response.should be_success
    raw_json = response.body
    raw_json.should match(%r{^while\(1\);})
    expect { JSON.parse(raw_json) }.to raise_error
    json = JSON.parse(raw_json.sub(%r{^while\(1\);}, ''))
    json['id'].should == @user.id
  end
end
