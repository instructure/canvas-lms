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
      'sortable_name' => 'Student',
      'short_name' => 'Student',
      'primary_email' => 'pvuser@example.com',
      'sis_user_id' => 'sis-user-id',
      'sis_login_id' => 'pvuser@example.com',
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
      'sortable_name' => 'User',
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
      'sortable_name' => 'Student',
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
    page_view_model(:user => @student, :created_at => 1.day.ago)
    page_view_model(:user => @student)
    page_view_model(:user => @student, :created_at => 1.day.from_now)
    Setting.set('api_max_per_page', '2')
    json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?per_page=1000",
                       { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :per_page => '1000' })
    json.size.should == 2
    json.each { |j| j['url'].should == "http://www.example.com/courses/1" }
    json[0]['created_at'].should be > json[1]['created_at']
    json = api_call(:get, "/api/v1/users/sis_user_id:sis-user-id/page_views?page=2",
                       { :controller => "page_views", :action => "index", :user_id => 'sis_user_id:sis-user-id', :format => 'json', :page => '2' })
    json.size.should == 1
    json.each { |j| j['url'].should == "http://www.example.com/courses/1" }
  end

  it "shouldn't find users in other root accounts by sis id" do
    acct = account_model(:name => 'other root')
    acct.add_user(@user)
    @me = @user
    course_with_student(:account => acct, :active_all => true, :user => user_with_pseudonym(:name => 's2', :username => 'other@example.com'))
    @other_user = @user
    @other_user.pseudonym.update_attribute('sis_user_id', 'other-sis')
    @other_user.pseudonym.update_attribute('account_id', acct.id)
    @user = @me
    raw_api_call(:get, "/api/v1/users/sis_user_id:other-sis/page_views",
                       { :controller => "page_views", :action => "index", :user_id => 'sis_user_id:other-sis', :format => 'json' })
    response.status.should == "404 Not Found"
  end

  it "should allow id of 'self'" do
    page_view_model(:user => @admin)
    json = api_call(:get, "/api/v1/users/self/page_views?per_page=1000",
                       { :controller => "page_views", :action => "index", :user_id => 'self', :format => 'json', :per_page => '1000' })
    json.size.should == 1
  end

  describe "user account listing" do
    it "should return users for an account" do
      @account = @user.account
      users = []
      [['Test User1', 'test@example.com'], ['Test User2', 'test2@example.com'], ['Test User3', 'test3@example.com']].each_with_index do |u, i|
        users << User.create(:name => u[0])
        users[i].pseudonyms.create(:unique_id => u[1], :password => '123456', :password_confirmation => '123456')
        users[i].pseudonym.update_attribute(:sis_user_id, (i + 1) * 100)
        users[i].pseudonym.update_attribute(:account_id, @account.id)
      end
      @account.all_users.scoped(:order => :sortable_name).each_with_index do |user, i|
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/users",
               { :controller => 'users', :action => 'index', :account_id => @account.id.to_param, :format => 'json' },
               { :per_page => 1, :page => i + 1 })
        json.should == [{
          'name' => user.name,
          'sortable_name' => user.sortable_name,
          'sis_user_id' => user.sis_user_id,
          'id' => user.id,
          'short_name' => user.short_name,
          'login_id' => user.pseudonym.unique_id,
          'sis_login_id' => user.pseudonym.sis_user_id ? user.pseudonym.unique_id : nil
        }]
      end
    end

    it "should limit the maximum number of users returned" do
      @account = @user.account
      15.times do |n|
        user = User.create(:name => "u#{n}")
        user.pseudonyms.create!(:unique_id => "u#{n}@example.com", :account => @account)
      end
      api_call(:get, "/api/v1/accounts/#{@account.id}/users?per_page=12", :controller => "users", :action => "index", :account_id => @account.id.to_param, :format => 'json', :per_page => '12').size.should == 12
      Setting.set('api_max_per_page', '5')
      api_call(:get, "/api/v1/accounts/#{@account.id}/users?per_page=12", :controller => "users", :action => "index", :account_id => @account.id.to_param, :format => 'json', :per_page => '12').size.should == 5
    end

    it "should return unauthorized for users without permissions" do
      @account = @student.account
      @user    = @student
      raw_api_call(:get, "/api/v1/accounts/#{@account.id}/users", :controller => "users", :action => "index", :account_id => @account.id.to_param, :format => "json")
      response.code.should eql "401"
    end
  end

  describe "user account creation" do
    it "should allow site admins to create users" do
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        {
          :user => {
            :name          => "Test User",
            :short_name    => "Test",
            :sortable_name => "User, T.",
            :time_zone     => "Mountain Time (United States & Canada)"
          },
          :pseudonym => {
            :unique_id         => "test@example.com",
            :password          => "password123",
            :sis_user_id       => "12345",
            :send_confirmation => 0
          }
        }
      )
      users = User.find_all_by_name "Test User"
      users.length.should eql 1
      user = users.first
      user.name.should eql "Test User"
      user.short_name.should eql "Test"
      user.sortable_name.should eql "User, T."
      user.time_zone.should eql "Mountain Time (United States & Canada)"

      user.pseudonyms.count.should eql 1
      pseudonym = user.pseudonyms.first
      pseudonym.unique_id.should eql "test@example.com"
      pseudonym.sis_user_id.should eql "12345"

      JSON.parse(response.body).should == {
        "name"          => "Test User",
        "short_name"    => "Test",
        "sortable_name" => "User, T.",
        "id"            => user.id,
        "sis_user_id"   => "12345",
        "login_id"      => "test@example.com",
        "sis_login_id"  => "test@example.com"
      }
    end

    it "should not allow non-admins to create users" do
      @user = @student
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        {
          :user      => { :name => "Test User" },
          :pseudonym => { :unique_id => "test@example.com", :password => "password123" }
        }
      )
      response.status.should eql "403 Forbidden"
    end

    it "should send a confirmation if send_confirmation is set to 1" do
      Pseudonym.any_instance.expects(:send_registration_notification!)
      api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        {
          :user => {
            :name => "Test User"
          },
          :pseudonym => {
            :unique_id         => "test@example.com",
            :password          => "password123",
            :send_confirmation => 1
          }
        }
      )
    end

    it "should return a 400 error if the request doesn't include a unique id" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        {
          :user      => { :name => "Test User" },
          :pseudonym => { :password => "password123" }
        }
      )
      response.status.should eql "400 Bad Request"
      errors = JSON.parse(response.body)['errors']
      errors.length.should eql 1
      errors['unique_id'].length.should be > 0
    end
  end
end

