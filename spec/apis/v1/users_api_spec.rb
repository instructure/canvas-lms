#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

class TestUserApi
  include Api::V1::User
  attr_accessor :services_enabled, :context, :current_user, :params, :request
  def service_enabled?(service); @services_enabled.include? service; end
  def avatar_image_url(*args); "avatar_image_url(#{args.first})"; end
  def course_student_grades_url(course_id, user_id); ""; end
  def course_user_url(course_id, user_id); ""; end
  def initialize
    @domain_root_account = Account.default
    @params = {}
    @request = OpenStruct.new
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
      @test_api.user_json(@student, @admin, {}, ['avatar_url'], @course)["avatar_url"].should match(
        %r{^https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(@student.email)}.*#{CGI.escape("/images/messages/avatar-50.png")}}
      )
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
          'sis_import_id' => nil,
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
      p = @user.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default) { |p| p.sis_user_id = 'xyz' }
      sis_batch = p.account.sis_batches.create
      SisBatch.where(id: sis_batch).update_all(workflow_state: 'imported')
      Pseudonym.where(id: p.id).update_all(sis_batch_id: sis_batch.id)
      @test_api.user_json(@user, @admin, {}, [], Account.default).should == {
          'name' => 'User',
          'sortable_name' => 'User',
          'sis_user_id' => 'xyz',
          'sis_import_id' => sis_batch.id,
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

    context "computed scores" do
      before do
        @enrollment.computed_current_score = 95.0;
        @enrollment.computed_final_score = 85.0;
        def @course.grading_standard_enabled?; true; end
        @student1_enrollment = @enrollment
        @student2 = course_with_student(:course => @course).user
      end

      it "should return scores as admin" do
        json = @test_api.user_json(@student, @admin, {}, [], @course, [@student1_enrollment])
        json['enrollments'].first['grades'].should == {
          "html_url" => "",
          "current_score" => 95.0,
          "final_score" => 85.0,
          "current_grade" => "A",
          "final_grade" => "B",
        }
      end

      it "should not return scores as another student" do
        json = @test_api.user_json(@student, @student2, {}, [], @course, [@student1_enrollment])
        json['enrollments'].first['grades'].keys.should == ["html_url"]
      end
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
                      "sis_import_id"=>@student.pseudonym.sis_batch_id,
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

describe "Users API", type: :request do
  def avatar_url(id)
    "http://www.example.com/images/users/#{User.avatar_key(id)}?fallback=http%3A%2F%2Fwww.example.com%2Fimages%2Fmessages%2Favatar-50.png"
  end

  before do
    @admin = account_admin_user
    course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'pvuser@example.com', :active_user => true))
    @student.pseudonym.update_attribute(:sis_user_id, 'sis-user-id')
    @user = @admin
    Account.default.tap { |a| a.enable_service(:avatars) }.save
    user_with_pseudonym(:user => @user)
  end

  it "shouldn't return disallowed avatars" do
    @user = @student
    raw_api_call(:get, "/api/v1/users/#{@admin.id}/avatars",
                 :controller => "profile", :action => "profile_pics", :user_id => @admin.to_param, :format => 'json')
    assert_status(401)
  end

  shared_examples_for "page view api" do
    describe "page view api" do
      before do
        @timestamp = Time.zone.at(1.day.ago.to_i)
        page_view_model(:user => @student, :created_at => @timestamp - 1.day)
        page_view_model(:user => @student, :created_at => @timestamp + 1.day)
        page_view_model(:user => @student, :created_at => @timestamp)
      end

      it "should return page view history" do
        Setting.set('api_max_per_page', '2')
        json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?per_page=1000",
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :per_page => '1000' })
        json.size.should == 2
        json.each { |j| j['url'].should == "http://www.example.com/courses/1" }
        json[0]['created_at'].should be > json[1]['created_at']
        response.headers['Link'].should match /next/
        response.headers['Link'].should_not match /last/
        response.headers['Link'].split(',').find { |l| l =~ /<([^>]+)>.+next/ }
        url = $1
        page = Rack::Utils.parse_nested_query(url)['page']
        json = api_call(:get, url,
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :page => page, :per_page => Setting.get('api_max_per_page', '2') })
        json.size.should == 1
        json.each { |j| j['url'].should == "http://www.example.com/courses/1" }
        response.headers['Link'].should_not match /next/
        response.headers['Link'].should match /last/
      end

      it "should recognize start_time parameter" do
        Setting.set('api_max_per_page', '3')
        start_time = @timestamp.iso8601
        json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?start_time=#{start_time}",
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :start_time => start_time })
        json.size.should == 2
        json.each { |j| TimeHelper.try_parse(j['created_at']).to_i.should be >= @timestamp.to_i }
      end

      it "should recognize end_time parameter" do
        Setting.set('api_max_per_page', '3')
        end_time = @timestamp.iso8601
        json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?end_time=#{end_time}",
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :end_time => end_time })
        json.size.should == 2
        json.each { |j| TimeHelper.try_parse(j['created_at']).to_i.should be <= @timestamp.to_i }
      end
    end
  end

  include_examples "page view api"

  describe "cassandra page views" do
    include_examples "cassandra page views"
    include_examples "page view api"
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
    assert_status(404)
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
      @account.all_users.order(:sortable_name).each_with_index do |user, i|
        next unless users.find { |u| u == user }
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/users",
               { :controller => 'users', :action => 'index', :account_id => @account.id.to_param, :format => 'json' },
               { :per_page => 1, :page => i + 1 })
        json.should == [{
          'name' => user.name,
          'sortable_name' => user.sortable_name,
          'sis_user_id' => user.pseudonym.sis_user_id,
          'sis_import_id' => nil,
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

    it "returns an error when search_term is fewer than 3 characters" do
      @account = Account.default
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { :controller => 'users', :action => "index", :format => 'json', :account_id => @account.id.to_param }, {:search_term => 'ab'}, {}, :expected_status => 400)
      error = json["errors"].first
      verify_json_error(error, "search_term", "invalid", "3 or more characters is required")
    end

    it "returns a list of users filtered by search_term" do
      @account = Account.default
      expected_keys = %w{id name sortable_name short_name}

      users = []
      [['Test User1', 'test@example.com'], ['Test User2', 'test2@example.com'], ['Test User3', 'test3@example.com']].each_with_index do |u, i|
        users << User.create!(:name => u[0])
        users[i].pseudonyms.create!(:unique_id => u[1], :account => @account) { |p| p.sis_user_id = u[1] }
      end

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { :controller => 'users', :action => "index", :format => 'json', :account_id => @account.id.to_param }, {:search_term => 'test3@example.com'})

      json.count.should == 1
      json.each do |user|
        (user.keys & expected_keys).sort.should == expected_keys.sort
        users.map(&:id).should include(user['id'])
      end
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
            :time_zone     => "Mountain Time (US & Canada)",
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
      user.time_zone.name.should eql "Mountain Time (US & Canada)"
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
        "sis_import_id" => user.pseudonym.sis_batch_id,
        "login_id"      => "test@example.com",
        "sis_login_id"  => "test@example.com",
        "locale"        => "en"
      }
    end

    context "as a non-administrator" do
      before do
        user(active_all: true)
      end

      it "should not let you create a user if self_registration is off" do
        raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
          { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
          {
            :user      => { :name => "Test User" },
            :pseudonym => { :unique_id => "test@example.com" }
          }
        )
        assert_status(403)
      end

      it "should require an email pseudonym" do
        @admin.account.settings[:self_registration] = true
        @admin.account.save!
        raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
          { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
          {
            :user      => { :name => "Test User", :terms_of_use => "1" },
            :pseudonym => { :unique_id => "invalid" }
          }
        )
        assert_status(400)
      end

      it "should require acceptance of the terms" do
        @admin.account.settings[:self_registration] = true
        @admin.account.save!
        raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
          { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
          {
            :user      => { :name => "Test User" },
            :pseudonym => { :unique_id => "test@example.com" }
          }
        )
        assert_status(400)
      end

      it "should let you create a user if you pass all the validations" do
        @admin.account.settings[:self_registration] = true
        @admin.account.save!
        json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
          { :controller => 'users', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
          {
            :user      => { :name => "Test User", :terms_of_use => "1" },
            :pseudonym => { :unique_id => "test@example.com" }
          }
        )
        json['name'].should == 'Test User'
      end
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
      assert_status(400)
      errors = JSON.parse(response.body)['errors']
      errors['pseudonym'].should be_present
      errors['pseudonym']['unique_id'].should be_present
    end

    it "should set user's email address via communication_channel[address]" do
      api_call(:post, "/api/v1/accounts/#{@admin.account.id}/users",
        { :controller => 'users',
          :action => 'create',
          :format => 'json',
          :account_id => @admin.account.id.to_s
        },
        {
          :user => {
            :name => "Test User"
          },
          :pseudonym => {
            :unique_id         => "test",
            :password          => "password123"
          },
          :communication_channel => {
            :address           => "test@example.com"
          }
        }
      )
      response.should be_success
      users = User.find_all_by_name "Test User"
      users.size.should == 1
      users.first.pseudonyms.first.unique_id.should == "test"
      email = users.first.communication_channels.email.first
      email.path.should == "test@example.com"
      email.path_type.should == 'email'
    end
  end

  describe "user account updates" do
    before do
      # an outer before sets this
      @student.pseudonym.update_attribute(:sis_user_id, nil)

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
          'sis_import_id' => nil,
          'id' => user.id,
          'short_name' => 'Tobias',
          'login_id' => 'student@example.com',
          'sis_login_id' => 'student@example.com',
          'locale' => 'en'
        }
        user.time_zone.name.should eql 'Tijuana'
      end

      it "should allow updating without any params" do
        json = api_call(:put, @path, @path_options, {})
        json.should_not be_nil
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

  describe "user settings" do
    before do
      course_with_student(active_all: true)
      account_admin_user
    end

    let(:path) { "/api/v1/users/#{@student.to_param}/settings" }
    let(:path_options) {
      { controller: 'users', action: 'settings', format: 'json',
        id: @student.to_param }
    }

    context "an admin user" do
      it "should be able to view other users' settings" do
        json = api_call(:get, path, path_options)
        json['manual_mark_as_read'].should be_false
      end

      it "should be able to update other users' settings" do
        json = api_call(:put, path, path_options, manual_mark_as_read: true)
        json['manual_mark_as_read'].should be_true

        json = api_call(:put, path, path_options, manual_mark_as_read: false)
        json['manual_mark_as_read'].should be_false
      end
    end

    context "a student" do
      before do
        @user = @student
      end

      it "should be able to view its own settings" do
        json = api_call(:get, path, path_options)
        json['manual_mark_as_read'].should be_false
      end

      it "should be able to update its own settings" do
        json = api_call(:put, path, path_options, manual_mark_as_read: true)
        json['manual_mark_as_read'].should be_true

        json = api_call(:put, path, path_options, manual_mark_as_read: false)
        json['manual_mark_as_read'].should be_false
      end

      it "should receive 401 if updating another user's settings" do
        @course.enroll_student(user).accept!
        raw_api_call(:put, path, path_options, manual_mark_as_read: true)
        response.code.should == '401'
      end
    end
  end

  describe "user custom_data" do
    let(:namespace_a) { 'com.awesome-developer.mobile' }
    let(:namespace_b) { 'org.charitable-developer.generosity' }
    let(:scope) { 'nice/scope' }
    let(:scope2) { 'something-different' }
    let(:path) { "/api/v1/users/#{@student.to_param}/custom_data/#{scope}" }
    let(:path2) { "/api/v1/users/#{@student.to_param}/custom_data/#{scope2}" }
    let(:path_opts_put) { {controller: 'custom_data',
                              action: 'set_data',
                              format: 'json',
                              user_id: @student.to_param,
                              scope: scope} }
    let(:path_opts_get) { path_opts_put.merge({action: 'get_data'}) }
    let(:path_opts_del) { path_opts_put.merge({action: 'delete_data'}) }
    let(:path_opts_put2) { path_opts_put.merge({scope: scope2}) }
    let(:path_opts_get2) { path_opts_put2.merge({action: 'get_data'}) }

    it "scopes storage by namespace and a *scope glob" do
      data = 'boom shaka-laka'
      other_data = 'whoop there it is'
      data2 = 'whatevs'
      other_data2 = 'totes'
      api_call(:put, path,  path_opts_put,  {ns: namespace_a, data: data})
      api_call(:put, path2, path_opts_put2, {ns: namespace_a, data: data2})
      api_call(:put, path,  path_opts_put,  {ns: namespace_b, data: other_data})
      api_call(:put, path2, path_opts_put2, {ns: namespace_b, data: other_data2})

      body = api_call(:get, path, path_opts_get, {ns: namespace_a})
      body.should == {'data'=>data}

      body = api_call(:get, path, path_opts_get, {ns: namespace_b})
      body.should == {'data'=>other_data}

      body = api_call(:get, path2, path_opts_get2, {ns: namespace_a})
      body.should == {'data'=>data2}

      body = api_call(:get, path2, path_opts_get2, {ns: namespace_b})
      body.should == {'data'=>other_data2}
    end

    it "turns JSON hashes into scopes" do
      data = JSON.parse '{"a":"nice JSON","b":"dont you think?"}'
      get_path = path + '/b'
      get_scope = scope + '/b'
      api_call(:put, path, path_opts_put, {ns: namespace_a, data: data})
      body = api_call(:get, get_path, path_opts_get.merge({scope: get_scope}), {ns: namespace_a})
      body.should == {'data'=>'dont you think?'}
    end

    it "is deleteable" do
      data = JSON.parse '{"a":"nice JSON","b":"dont you think?"}'
      del_path = path + '/b'
      del_scope = scope + '/b'
      api_call(:put, path, path_opts_put, {ns: namespace_a, data: data})
      body = api_call(:delete, del_path, path_opts_del.merge({scope: del_scope}), {ns: namespace_a})
      body.should == {'data'=>'dont you think?'}

      body = api_call(:get, path, path_opts_get, {ns: namespace_a})
      body.should == {'data'=>{'a'=>'nice JSON'}}
    end

    context "without a namespace" do
      it "responds 400 to GET" do
        api_call(:get, path, path_opts_get, {}, {}, {expected_status: 400})
      end

      it "responds 400 to PUT" do
        api_call(:put, path, path_opts_put, {data: 'whatevs'}, {}, {expected_status: 400})
      end

      it "responds 400 to DELETE" do
        api_call(:delete, path, path_opts_del, {}, {}, {expected_status: 400})
      end
    end

    context "PUT" do
      it "responds 409 when the requested scope is invalid" do
        deeper_path = path + '/whoa'
        deeper_scope = scope + '/whoa'
        api_call(:put, path, path_opts_put, {ns: namespace_a, data: 'ohai!'})
        raw_api_call(:put, deeper_path, path_opts_put.merge({scope: deeper_scope}), {ns: namespace_a, data: 'dood'})
        response.code.should eql '409'
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
        id_param = "sis_user_id:#{@student.pseudonyms.first.sis_user_id}"

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
    before :each do
      @context = @user
    end
    
    include_examples "file uploads api with folders"
    include_examples "file uploads api with quotas"

    def preflight(preflight_params)
      api_call(:post, "/api/v1/users/self/files",
        { :controller => "users", :action => "create_file", :format => "json", :user_id => 'self', },
        preflight_params)
    end

    def has_query_exemption?
      false
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

    describe "user merge" do
    before do
      @account = Account.default
      @user1 = user_with_managed_pseudonym(
        active_all: true, account: @account, name: 'Jony Ive',
        username: 'jony@apple.com', sis_user_id: 'user_sis_id_01'
      )
      @user2 = user_with_managed_pseudonym(
        active_all: true, name: 'Steve Jobs', account: @account,
        username: 'steve@apple.com', sis_user_id: 'user_sis_id_02'
      )
      @user = account_admin_user(account: @account)
    end

    it "should merge users" do
      json = api_call(
        :put, "/api/v1/users/#{@user2.id}/merge_into/#{@user1.id}",
        { controller: 'users', action: 'merge_into', format: 'json',
          id: @user2.to_param, destination_user_id: @user1.to_param }
      )
      Pseudonym.find_by_sis_user_id('user_sis_id_02').user_id.should == @user1.id
      @user2.pseudonyms.should be_empty
    end

    it "should merge users cross accounts" do
      account = Account.create(name: 'new account')
      @user1.pseudonym.account_id = account.id
      @user1.pseudonym.save!
      @user = account_admin_user(account: account, user: @user)

      api_call(
        :put,
        "/api/v1/users/sis_user_id:user_sis_id_02/merge_into/accounts/#{account.id}/users/sis_user_id:user_sis_id_01",
        { controller: 'users', action: 'merge_into', format: 'json',
          id: 'sis_user_id:user_sis_id_02',
          destination_user_id: 'sis_user_id:user_sis_id_01',
          destination_account_id: account.to_param
        }
      )
      Pseudonym.find_by_sis_user_id('user_sis_id_02').user_id.should == @user1.id
      @user2.pseudonyms.should be_empty
    end

    it "should fail to merge users cross accounts without permissions" do
      account = Account.create(name: 'new account')
      @user1.pseudonym.account_id = account.id
      @user1.pseudonym.save!

      raw_api_call(
        :put,
        "/api/v1/users/#{@user2.id}/merge_into/#{@user1.id}",
        { controller: 'users', action: 'merge_into', format: 'json',
          id: @user2.to_param, destination_user_id: @user1.to_param}
      )
      assert_status(401)
    end
  end
end
