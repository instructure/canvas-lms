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
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')

class TestUserApi
  include Api::V1::User
  attr_accessor :services_enabled, :context, :current_user
  def service_enabled?(service); @services_enabled.include? service; end
  def avatar_image_url(user_id); "avatar_image_url(#{user_id})"; end
  def initialize
    @domain_root_account = Account.default
  end
end

describe Api::V1::User do
  before do
    @test_api = TestUserApi.new
    @test_api.services_enabled = []
    @admin = account_admin_user
    course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'pvuser@example.com'))
    @student = @user
    @student.pseudonym.update_attribute(:sis_user_id, 'sis-user-id')
    @user = @admin
    Account.default.tap { |a| a.enable_service(:avatars) }.save
    user_with_pseudonym(:user => @user)
  end

  context 'user_json' do
    it 'should support optionally providing the avatar if avatars are enabled' do
      @test_api.user_json(@student, @admin, {}, ['avatar_url'], @course).has_key?("avatar_url").should be_false
      @test_api.services_enabled = [:avatars]
      @test_api.user_json(@student, @admin, {}, [], @course).has_key?("avatar_url").should be_false
      @test_api.user_json(@student, @admin, {}, ['avatar_url'], @course).should encompass({
        "avatar_url" => "avatar_image_url(#{User.avatar_key(@student.id)})"
      })
    end

    it 'should use the correct SIS pseudonym' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.create!(:unique_id => 'abc', :account => @account2) { |p| p.sis_user_id = 'abc' }
      @user.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default) { |p| p.sis_user_id = 'xyz' }
      @test_api.user_json(@user, @admin, {}, [], Account.default).should == {
          'name' => 'User',
          'sortable_name' => 'User',
          'sis_user_id' => 'xyz',
          'id' => @user.id,
          'short_name' => 'User',
          'login_id' => 'xyz',
          'sis_login_id' => 'xyz'
        }
    end

    it 'should use the SIS pseudonym instead of another pseudonym' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.create!(:unique_id => 'abc', :account => Account.default)
      @user.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default) { |p| p.sis_user_id = 'xyz' }
      @test_api.user_json(@user, @admin, {}, [], Account.default).should == {
          'name' => 'User',
          'sortable_name' => 'User',
          'sis_user_id' => 'xyz',
          'id' => @user.id,
          'short_name' => 'User',
          'login_id' => 'xyz',
          'sis_login_id' => 'xyz'
        }
    end

    it 'should use the correct pseudonym' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.create!(:unique_id => 'abc', :account => @account2)
      @pseudonym = @user.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default)
      @user.stubs(:find_pseudonym_for_account).with(Account.default).returns(@pseudonym)
      @test_api.user_json(@user, @admin, {}, [], Account.default).should == {
          'name' => 'User',
          'sortable_name' => 'User',
          'id' => @user.id,
          'short_name' => 'User',
          'login_id' => 'xyz',
        }
    end


    def test_context(mock_context, context_to_pass)
      mock_context.expects(:account).returns(mock_context)
      mock_context.expects(:id).returns(42)
      mock_context.expects(:grants_right?).with(@admin, :manage_students).returns(true)
      if context_to_pass
        @test_api.user_json(@student, @admin, {}, [], context_to_pass)
      else
        @test_api.user_json(@student, @admin, {}, [])
      end.should == { "name"=>"Student",
                      "sortable_name"=>"Student",
                      "sis_user_id"=>"sis-user-id",
                      "id"=>@student.id,
                      "short_name"=>"Student",
                      "login_id"=>"pvuser@example.com",
                      "sis_login_id"=>"pvuser@example.com"}
    end

    it 'should support manually passing the context' do
      mock_context = mock()
      test_context(mock_context, mock_context)
    end

    it 'should support loading the context as a member var' do
      @test_api.context = mock()
      test_context(@test_api.context, nil)
    end
  end

  context 'user_json_is_admin?' do

    it 'should support manually passing the current user' do
      @test_api.context = mock()
      @test_api.context.expects(:id).returns(42)
      @test_api.context.expects(:account).returns(@test_api.context)
      @test_api.context.expects(:grants_right?).with(@admin, :manage_students).returns(true)
      @test_api.current_user = @admin
      @test_api.user_json_is_admin?.should == true
    end

    it 'should support loading the current user as a member var' do
      mock_context = mock()
      mock_context.expects(:id).returns(42)
      mock_context.expects(:account).returns(mock_context)
      mock_context.expects(:grants_right?).with(@admin, :manage_students).returns(true)
      @test_api.current_user = @admin
      @test_api.user_json_is_admin?(mock_context, @admin).should == true
    end

    it 'should support loading multiple different things (via args)' do
      @test_api.user_json_is_admin?(@admin, @student).should be_false
      @test_api.user_json_is_admin?(@student, @admin).should be_true
      @test_api.user_json_is_admin?(@student, @admin).should be_true
      @test_api.user_json_is_admin?(@admin, @student).should be_false
      @test_api.user_json_is_admin?(@admin, @student).should be_false
    end

    it 'should support loading multiple different things (via member vars)' do
      @test_api.current_user = @student
      @test_api.context = @admin
      @test_api.user_json_is_admin?.should be_false
      @test_api.current_user = @admin
      @test_api.context = @student
      @test_api.user_json_is_admin?.should be_true
      @test_api.user_json_is_admin?.should be_true
      @test_api.current_user = @student
      @test_api.context = @admin
      @test_api.user_json_is_admin?.should be_false
      @test_api.user_json_is_admin?.should be_false
    end

  end

end

describe "Users API", :type => :integration do
  before do
    @admin = account_admin_user
    course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'pvuser@example.com'))
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
      'avatar_url' => "http://www.example.com/images/users/#{User.avatar_key(@student.id)}",
    }
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
             :controller => "profile", :action => "show", :user_id => new_user.to_param, :format => 'json')
    json.should == {
      'id' => new_user.id,
      'name' => 'new guy',
      'sortable_name' => 'guy, new',
      'short_name' => 'new guy',
      'login_id' => nil,
      'primary_email' => nil,
      'avatar_url' => "http://www.example.com/images/users/#{User.avatar_key(new_user.id)}",
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
      'login_id' => 'nobody@example.com',
      'avatar_url' => "http://www.example.com/images/users/#{User.avatar_key(@admin.id)}",
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
      'avatar_url' => "http://www.example.com/images/users/#{User.avatar_key(@student.id)}",
      'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
    }
  end

  it "should return this user's avatars, if allowed" do
    @user = @student
    json = api_call(:get, "/api/v1/users/#{@student.id}/avatars",
                    :controller => "profile", :action => "profile_pics", :user_id => @student.to_param, :format => 'json')
    json.map{ |j| j['type'] }.sort.should eql ['gravatar', 'no_pic']
  end

  it "shouldn't return disallowed profiles" do
    @user = @student
    raw_api_call(:get, "/api/v1/users/#{@admin.id}/profile",
             :controller => "profile", :action => "show", :user_id => @admin.to_param, :format => 'json')
    response.status.should == "401 Unauthorized"
    JSON.parse(response.body).should == {"status"=>"unauthorized", "message"=>"You are not authorized to perform that action."}
  end

  it "shouldn't return disallowed avatars" do
    @user = @student
    raw_api_call(:get, "/api/v1/users/#{@admin.id}/avatars",
                 :controller => "profile", :action => "profile_pics", :user_id => @admin.to_param, :format => 'json')
    response.status.should == "401 Unauthorized"
    JSON.parse(response.body).should == {"status"=>"unauthorized", "message"=>"You are not authorized to perform that action."}
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
    response.headers['Link'].should match /next/
    response.headers['Link'].should_not match /last/
    json = api_call(:get, "/api/v1/users/sis_user_id:sis-user-id/page_views?page=2",
                       { :controller => "page_views", :action => "index", :user_id => 'sis_user_id:sis-user-id', :format => 'json', :page => '2' })
    json.size.should == 1
    json.each { |j| j['url'].should == "http://www.example.com/courses/1" }
    response.headers['Link'].should_not match /next/
    response.headers['Link'].should_not match /last/
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
      @account = Account.default
      users = []
      [['Test User1', 'test@example.com'], ['Test User2', 'test2@example.com'], ['Test User3', 'test3@example.com']].each_with_index do |u, i|
        users << User.create!(:name => u[0])
        users[i].pseudonyms.create!(:unique_id => u[1], :account => @account) { |p| p.sis_user_id = u[1] }
      end
      @account.all_users.scoped(:order => :sortable_name).each_with_index do |user, i|
        next unless users.find { |u| u == user }
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
          'sis_login_id' => user.pseudonym.sis_user_id
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
            :time_zone     => "Mountain Time (United States & Canada)",
            :locale        => 'en'
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
      user.locale.should eql 'en'

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
        "sis_login_id"  => "test@example.com",
        "locale"        => "en"
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

  describe "user account updates" do
    before do
      @admin = account_admin_user
      course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'student@example.com'))
      @student = @user
      @student.pseudonym.update_attribute(:sis_user_id, 'sis-user-id')
      @user = @admin
      @path = "/api/v1/users/#{@student.id}"
      @path_options = { :controller => 'users', :action => 'update', :format => 'json', :id => @student.id.to_param }
      user_with_pseudonym(:user => @user, :username => 'admin@example.com')
    end
    context "an admin user" do
      it "should be able to update a user" do
        json = api_call(:put, @path, @path_options, {
          :user => {
            :name => 'Tobias Funke',
            :short_name => 'Tobias',
            :sortable_name => 'Funke, Tobias',
            :time_zone => 'Tijuana',
            :locale => 'en'
          }
        })
        user = User.find(json['id'])
        avatar_url = json.delete("avatar_url")
        json.should == {
          'name' => 'Tobias Funke',
          'sortable_name' => 'Funke, Tobias',
          'sis_user_id' => 'sis-user-id',
          'id' => user.id,
          'short_name' => 'Tobias',
          'login_id' => 'student@example.com',
          'sis_login_id' => 'student@example.com',
          'locale' => 'en'
        }
        user.time_zone.should eql 'Tijuana'
      end

      it "should update the user's avatar with a token" do
        json = api_call(:get, "/api/v1/users/#{@student.id}/avatars",
                        :controller => "profile", :action => "profile_pics", :user_id => @student.to_param, :format => 'json')
        to_set = json.first

        @student.avatar_image_source.should_not eql to_set['type']
        json = api_call(:put, @path, @path_options, {
          :user => {
            :avatar => {
              :token => to_set['token']
            }
          }
        })
        user = User.find(json['id'])
        user.avatar_image_source.should eql to_set['type']
        user.avatar_state.should eql :approved
      end

      it "should re-lock the avatar after being updated by an admin" do
        json = api_call(:get, "/api/v1/users/#{@student.id}/avatars",
                        :controller => "profile", :action => "profile_pics", :user_id => @student.to_param, :format => 'json')
        to_set = json.first

        old_source = to_set['type'] == 'gravatar' ? 'twitter' : 'gravatar'
        @student.avatar_image_source = old_source
        @student.avatar_state = 'locked'
        @student.save!

        @student.avatar_image_source.should_not eql to_set['type']
        json = api_call(:put, @path, @path_options, {
          :user => {
            :avatar => {
              :token => to_set['token']
            }
          }
        })
        user = User.find(json['id'])
        user.avatar_image_source.should eql to_set['type']
        user.avatar_state.should eql :locked
      end

      it "should allow the user's avatar to be set to an external url" do
        url_to_set = 'http://www.instructure.example.com/image.jpg'
        json = api_call(:put, @path, @path_options, {
          :user => {
            :avatar => {
              :url => url_to_set
            }
          }
        })
        user = User.find(json['id'])
        user.avatar_image_source.should eql 'external'
        user.avatar_image_url.should eql url_to_set
      end
    end

    context "an unauthorized user" do
      it "should receive a 401" do
        user
        raw_api_call(:put, @path, @path_options, {
          :user => { :name => 'Gob Bluth' }
        })
        response.code.should eql '401'
      end
    end
  end

  describe "user deletion" do
    before do
      @admin = account_admin_user
      course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'student@example.com'))
      @student = @user
      @user = @admin
      @path = "/api/v1/accounts/#{Account.default.id}/users/#{@student.id}"
      @path_options = { :controller => 'users', :action => 'destroy',
        :format => 'json', :id => @student.to_param,
        :account_id => Account.default.to_param }
    end

    context "a user with permissions" do
      it "should be able to delete a user" do
        json = api_call(:delete, @path, @path_options)
        @student.reload.should be_deleted
        json.should == {
          'id' => @student.id,
          'name' => 'Student',
          'short_name' => 'Student',
          'sortable_name' => 'Student'
        }
      end

      it "should be able to delete a user by SIS ID" do
        @student.pseudonym.update_attribute(:sis_user_id, '12345')
        id_param = "sis_user_id:#{@student.sis_user_id}"

        path = "/api/v1/accounts/#{Account.default.id}/users/#{id_param}"
        path_options = @path_options.merge(:id => id_param)

        json = api_call(:delete, path, path_options)
        response.code.should eql '200'
        @student.reload.should be_deleted
      end

      it 'should be able to delete itself' do
        path = "/api/v1/accounts/#{Account.default.to_param}/users/#{@user.id}"
        json = api_call(:delete, path, @path_options.merge(:id => @user.to_param))
        @user.reload.should be_deleted
        json.should == {
          'id' => @user.id,
          'name' => @user.name,
          'short_name' => @user.short_name,
          'sortable_name' => @user.sortable_name
        }
      end
    end

    context 'an unauthorized user' do
      it "should receive a 401" do
        user
        raw_api_call(:delete, @path, @path_options)
        response.code.should eql '401'
      end
    end
  end

  context "user files" do
    it_should_behave_like "file uploads api with folders"

    def preflight(preflight_params)
      api_call(:post, "/api/v1/users/self/files",
        { :controller => "users", :action => "create_file", :format => "json", :user_id => 'self', },
        preflight_params)
    end

    def context
      @user
    end

    it "should not allow uploading to other users" do
      user2 = User.create!
      api_call(:post, "/api/v1/users/#{user2.id}/files",
        { :controller => "users", :action => "create_file", :format => "json", :user_id => user2.to_param, },
        { :name => "my_essay.doc" }, {}, :expected_status => 401)
    end
  end

  describe "following" do
    before do
      @me = @user
      @u2 = user_model
      @user = @me
      @u2.update_attribute(:public, true)
    end

    it "should allow following a public user" do
      json = api_call(:put, "/api/v1/users/#{@u2.id}/followers/self", :controller => "users", :action => "follow", :user_id => @u2.to_param, :format => "json")
      @user.user_follows.map(&:followed_item).should == [@u2]
      uf = @user.user_follows.first
      json.should == { "following_user_id" => @user.id, "followed_user_id" => @u2.id, "created_at" => uf.created_at.as_json }
    end

    it "should do nothing if already following the user" do
      @user.user_follows.create!(:followed_item => @u2)
      uf = @user.user_follows.first
      @user.user_follows.map(&:followed_item).should == [@u2]

      json = api_call(:put, "/api/v1/users/#{@u2.id}/followers/self", :controller => "users", :action => "follow", :user_id => @u2.to_param, :format => "json")
      @user.user_follows.map(&:followed_item).should == [@u2]
      uf = @user.user_follows.first
      json.should == { "following_user_id" => @user.id, "followed_user_id" => @u2.id, "created_at" => uf.created_at.as_json }
    end

    it "should not allow following a private user" do
      @u2.update_attribute(:public, false)
      json = api_call(:put, "/api/v1/users/#{@u2.id}/followers/self", { :controller => "users", :action => "follow", :user_id => @u2.to_param, :format => "json" }, {}, {}, :expected_status => 401)
      @user.reload.user_follows.should == []
    end

    describe "unfollowing" do
      it "should allow unfollowing a collection" do
        @user.user_follows.create!(:followed_item => @u2)
        @user.reload.user_follows.map(&:followed_item).should == [@u2]

        json = api_call(:delete, "/api/v1/users/#{@u2.id}/followers/self", :controller => "users", :action => "unfollow", :user_id => @u2.to_param, :format => "json")
        @user.reload.user_follows.should == []
      end

      it "should do nothing if not following" do
        @user.reload.user_follows.should == []
        json = api_call(:delete, "/api/v1/users/#{@u2.id}/followers/self", :controller => "users", :action => "unfollow", :user_id => @u2.to_param, :format => "json")
        @user.reload.user_follows.should == []
      end
    end
  end
end
