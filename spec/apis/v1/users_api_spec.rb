#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
  before :once do
    @admin = account_admin_user
    course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'pvuser@example.com'))
    @student = @user
    @student.pseudonym.update_attribute(:sis_user_id, 'sis-user-id')
    @user = @admin
    Account.default.tap { |a| a.enable_service(:avatars) }.save
    user_with_pseudonym(:user => @user)
  end

  before :each do
    @test_api = TestUserApi.new
    @test_api.services_enabled = []
  end

  context 'user_json' do
    it 'should support optionally providing the avatar if avatars are enabled' do
      expect(@test_api.user_json(@student, @admin, {}, ['avatar_url'], @course).has_key?("avatar_url")).to be_falsey
      @test_api.services_enabled = [:avatars]
      expect(@test_api.user_json(@student, @admin, {}, [], @course).has_key?("avatar_url")).to be_falsey
      expect(@test_api.user_json(@student, @admin, {}, ['avatar_url'], @course)["avatar_url"]).to match(
        %r{^https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(@student.email)}.*#{CGI.escape("/images/messages/avatar-50.png")}}
      )
    end

    it 'should use the correct SIS pseudonym' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.create!(:unique_id => 'abc', :account => @account2) { |p| p.sis_user_id = 'abc' }
      @user.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default) { |p| p.sis_user_id = 'xyz' }
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
          'name' => 'User',
          'sortable_name' => 'User',
          'sis_user_id' => 'xyz',
          'sis_import_id' => nil,
          'id' => @user.id,
          'short_name' => 'User',
          'sis_user_id' => 'xyz',
          'integration_id' => nil,
          'login_id' => 'xyz',
          'sis_login_id' => 'xyz'
        })
    end

    it 'should use the SIS pseudonym instead of another pseudonym' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.create!(:unique_id => 'abc', :account => Account.default)
      p = @user.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default) { |p| p.sis_user_id = 'xyz' }
      sis_batch = p.account.sis_batches.create
      SisBatch.where(id: sis_batch).update_all(workflow_state: 'imported')
      Pseudonym.where(id: p.id).update_all(sis_batch_id: sis_batch.id)
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
          'name' => 'User',
          'sortable_name' => 'User',
          'sis_user_id' => 'xyz',
          'sis_import_id' => sis_batch.id,
          'id' => @user.id,
          'short_name' => 'User',
          'sis_user_id' => 'xyz',
          'integration_id' => nil,
          'login_id' => 'xyz',
          'sis_login_id' => 'xyz'
        })
    end

    it 'should use an sis pseudonym from another account if necessary' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.create!(:unique_id => 'abc', :account => @account2) { |p| p.sis_user_id = 'a'}
      Account.default.any_instantiation.stubs(:trust_exists?).returns(true)
      Account.default.any_instantiation.stubs(:trusted_account_ids).returns([@account2.id])
      HostUrl.expects(:context_host).with(@account2).returns('school1')
      @user.stubs(:find_pseudonym_for_account).with(Account.default).returns(@pseudonym)
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
          'name' => 'User',
          'sortable_name' => 'User',
          'id' => @user.id,
          'short_name' => 'User',
          'login_id' => 'abc',
          'sis_login_id' => 'abc',
          'sis_user_id' => 'a',
          'integration_id' => nil,
          'root_account' => 'school1',
          'sis_import_id' => nil,
      })
    end

    it 'should use the correct pseudonym' do
      @user = User.create!(:name => 'User')
      @account2 = Account.create!
      @user.pseudonyms.create!(:unique_id => 'abc', :account => @account2)
      @pseudonym = @user.pseudonyms.create!(:unique_id => 'xyz', :account => Account.default)
      @user.stubs(:find_pseudonym_for_account).with(Account.default).returns(@pseudonym)
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
          'name' => 'User',
          'sortable_name' => 'User',
          'id' => @user.id,
          'short_name' => 'User',
          'login_id' => 'xyz',
        })
    end

    context "computed scores" do
      before :once do
        @enrollment.computed_current_score = 95.0;
        @enrollment.computed_final_score = 85.0;
        @student1_enrollment = @enrollment
        @student2 = course_with_student(:course => @course).user
      end

      before :each do
        def @course.grading_standard_enabled?; true; end
      end

      it "should return scores as admin" do
        json = @test_api.user_json(@student, @admin, {}, [], @course, [@student1_enrollment])
        expect(json['enrollments'].first['grades']).to eq({
          "html_url" => "",
          "current_score" => 95.0,
          "final_score" => 85.0,
          "current_grade" => "A",
          "final_grade" => "B",
        })
      end

      it "should not return scores as another student" do
        json = @test_api.user_json(@student, @student2, {}, [], @course, [@student1_enrollment])
        expect(json['enrollments'].first['grades'].keys).to eq ["html_url"]
      end
    end

    def test_context(mock_context, context_to_pass)
      mock_context.expects(:account).returns(mock_context)
      mock_context.expects(:global_id).returns(42)
      mock_context.expects(:grants_right?).with(@admin, :manage_students).returns(true)
      expect(if context_to_pass
        @test_api.user_json(@student, @admin, {}, [], context_to_pass)
      else
        @test_api.user_json(@student, @admin, {}, [])
      end).to eq({ "name"=>"Student",
                      "sortable_name"=>"Student",
                      "sis_user_id"=>"sis-user-id",
                      "id"=>@student.id,
                      "short_name"=>"Student",
                      "sis_user_id"=>"sis-user-id",
                      "integration_id" => nil,
                      "sis_import_id"=>@student.pseudonym.sis_batch_id,
                      "sis_login_id"=>"pvuser@example.com",
                      "login_id" => "pvuser@example.com"
      })
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
      @test_api.context.expects(:global_id).returns(42)
      @test_api.context.expects(:account).returns(@test_api.context)
      @test_api.context.expects(:grants_right?).with(@admin, :manage_students).returns(true)
      @test_api.current_user = @admin
      expect(@test_api.user_json_is_admin?).to eq true
    end

    it 'should support loading the current user as a member var' do
      mock_context = mock()
      mock_context.expects(:global_id).returns(42)
      mock_context.expects(:account).returns(mock_context)
      mock_context.expects(:grants_right?).with(@admin, :manage_students).returns(true)
      @test_api.current_user = @admin
      expect(@test_api.user_json_is_admin?(mock_context, @admin)).to eq true
    end

    it 'should support loading multiple different things (via args)' do
      expect(@test_api.user_json_is_admin?(@admin, @student)).to be_falsey
      expect(@test_api.user_json_is_admin?(@student, @admin)).to be_truthy
      expect(@test_api.user_json_is_admin?(@student, @admin)).to be_truthy
      expect(@test_api.user_json_is_admin?(@admin, @student)).to be_falsey
      expect(@test_api.user_json_is_admin?(@admin, @student)).to be_falsey
    end

    it 'should support loading multiple different things (via member vars)' do
      @test_api.current_user = @student
      @test_api.context = @admin
      expect(@test_api.user_json_is_admin?).to be_falsey
      @test_api.current_user = @admin
      @test_api.context = @student
      expect(@test_api.user_json_is_admin?).to be_truthy
      expect(@test_api.user_json_is_admin?).to be_truthy
      @test_api.current_user = @student
      @test_api.context = @admin
      expect(@test_api.user_json_is_admin?).to be_falsey
      expect(@test_api.user_json_is_admin?).to be_falsey
    end

  end

end

describe "Users API", type: :request do
  def avatar_url(id)
    "http://www.example.com/images/users/#{User.avatar_key(id)}?fallback=http%3A%2F%2Fwww.example.com%2Fimages%2Fmessages%2Favatar-50.png"
  end

  before :once do
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
        expect(json.size).to eq 2
        json.each { |j| expect(j['url']).to eq "http://www.example.com/courses/1" }
        expect(json[0]['created_at']).to be > json[1]['created_at']
        expect(response.headers['Link']).to match /next/
        expect(response.headers['Link']).not_to match /last/
        response.headers['Link'].split(',').find { |l| l =~ /<([^>]+)>.+next/ }
        url = $1
        page = Rack::Utils.parse_nested_query(url)['page']
        json = api_call(:get, url,
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :page => page, :per_page => Setting.get('api_max_per_page', '2') })
        expect(json.size).to eq 1
        json.each { |j| expect(j['url']).to eq "http://www.example.com/courses/1" }
        expect(response.headers['Link']).not_to match /next/
        expect(response.headers['Link']).to match /last/
      end

      it "should recognize start_time parameter" do
        Setting.set('api_max_per_page', '3')
        start_time = @timestamp.iso8601
        json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?start_time=#{start_time}",
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :start_time => start_time })
        expect(json.size).to eq 2
        json.each { |j| expect(CanvasTime.try_parse(j['created_at']).to_i).to be >= @timestamp.to_i }
      end

      it "should recognize end_time parameter" do
        Setting.set('api_max_per_page', '3')
        end_time = @timestamp.iso8601
        json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?end_time=#{end_time}",
                           { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :end_time => end_time })
        expect(json.size).to eq 2
        json.each { |j| expect(CanvasTime.try_parse(j['created_at']).to_i).to be <= @timestamp.to_i }
      end
    end
  end

  include_examples "page view api"

  describe "cassandra page views" do
    before do
      # can't use :once'd @student, since cassandra doesn't reset
      student_in_course(:course => @course, :user => user_with_pseudonym(:name => 'Student', :username => 'pvuser2@example.com', :active_user => true))
      @user = @admin
    end
    include_examples "cassandra page views"
    include_examples "page view api"
  end

  it "shouldn't find users in other root accounts by sis id" do
    acct = account_model(:name => 'other root')
    acct.account_users.create!(user: @user)
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
    expect(json.size).to eq 1
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
        expect(json).to eq [{
          'name' => user.name,
          'sortable_name' => user.sortable_name,
          'sis_user_id' => user.pseudonym.sis_user_id,
          'sis_import_id' => nil,
          'id' => user.id,
          'short_name' => user.short_name,
          'sis_user_id' => user.pseudonym.sis_user_id,
          'integration_id' => nil,
          'sis_login_id' => user.pseudonym.sis_user_id,
          'login_id' => user.pseudonym.unique_id
        }]
      end
    end

    it "should limit the maximum number of users returned" do
      @account = @user.account
      3.times do |n|
        user = User.create(:name => "u#{n}")
        user.pseudonyms.create!(:unique_id => "u#{n}@example.com", :account => @account)
      end
      expect(api_call(:get, "/api/v1/accounts/#{@account.id}/users?per_page=2", :controller => "users", :action => "index", :account_id => @account.id.to_param, :format => 'json', :per_page => '2').size).to eq 2
      Setting.set('api_max_per_page', '1')
      expect(api_call(:get, "/api/v1/accounts/#{@account.id}/users?per_page=2", :controller => "users", :action => "index", :account_id => @account.id.to_param, :format => 'json', :per_page => '2').size).to eq 1
    end

    it "should return unauthorized for users without permissions" do
      @account = @student.account
      @user    = @student
      raw_api_call(:get, "/api/v1/accounts/#{@account.id}/users", :controller => "users", :action => "index", :account_id => @account.id.to_param, :format => "json")
      expect(response.code).to eql "401"
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

      expect(json.count).to eq 1
      json.each do |user|
        expect((user.keys & expected_keys).sort).to eq expected_keys.sort
        expect(users.map(&:id)).to include(user['id'])
      end
    end
  end

  describe "user account creation" do
    def create_user_skip_cc_confirm(admin_user)
      json = api_call(:post, "/api/v1/accounts/#{admin_user.account.id}/users",
                      { :controller => 'users', :action => 'create', :format => 'json', :account_id => admin_user.account.id.to_s },
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
                          },
                          :communication_channel => {
                              :type => "sms",
                              :address => '8018888888',
                              :skip_confirmation => 1
                          }
                      }
      )
      users = User.where(name: "Test User").to_a
      expect(users.length).to eql 1
      user = users.first
      expect(user.sms_channel.workflow_state).to eq 'active'
    end

    context 'as a site admin' do
      before :once do
        @site_admin = user_with_pseudonym
        Account.site_admin.account_users.create!(user: @site_admin)
      end

      it "should allow site admins to create users" do
        json = api_call(:post, "/api/v1/accounts/#{@site_admin.account.id}/users",
          { :controller => 'users', :action => 'create', :format => 'json', :account_id => @site_admin.account.id.to_s },
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
            },
            :communication_channel => {
              :confirmation_url => true
            }
          }
        )
        users = User.where(name: "Test User").to_a
        expect(users.length).to eql 1
        user = users.first
        expect(user.name).to eql "Test User"
        expect(user.short_name).to eql "Test"
        expect(user.sortable_name).to eql "User, T."
        expect(user.time_zone.name).to eql "Mountain Time (US & Canada)"
        expect(user.locale).to eql 'en'

        expect(user.pseudonyms.count).to eql 1
        pseudonym = user.pseudonyms.first
        expect(pseudonym.unique_id).to eql "test@example.com"
        expect(pseudonym.sis_user_id).to eql "12345"

        expect(JSON.parse(response.body)).to eq({
          "name"             => "Test User",
          "short_name"       => "Test",
          "sortable_name"    => "User, T.",
          "id"               => user.id,
          "sis_user_id"      => "12345",
          "sis_import_id"    => user.pseudonym.sis_batch_id,
          "login_id"         => "test@example.com",
          "sis_login_id"     => "test@example.com",
          "integration_id"   => nil,
          "locale"           => "en",
          "confirmation_url" => user.communication_channels.email.first.confirmation_url
        })
      end

      it "should catch invalid dates before passing to the database" do
        json = api_call(:post, "/api/v1/accounts/#{@site_admin.account.id}/users",
                        { :controller => 'users', :action => 'create', :format => 'json', :account_id => @site_admin.account.id.to_s },
                        { :pseudonym => { :unique_id => "test@example.com"},
                          :user => { :name => "Test User", :birthdate => "-3587-11-20" } }, {}, {:expected_status => 400} )
      end

      it "should allow site admins to create users and auto-validate communication channel" do
        create_user_skip_cc_confirm(@site_admin)
      end
    end

    context 'as an account admin' do
      it "should allow account admins to create users and auto-validate communication channel" do
        create_user_skip_cc_confirm(@admin)
      end
    end

    context "as a non-administrator" do
      before :once do
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
        expect(json['name']).to eq 'Test User'
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
      expect(errors['pseudonym']).to be_present
      expect(errors['pseudonym']['unique_id']).to be_present
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
      expect(response).to be_success
      users = User.where(name: "Test User").to_a
      expect(users.size).to eq 1
      expect(users.first.pseudonyms.first.unique_id).to eq "test"
      email = users.first.communication_channels.email.first
      expect(email.path).to eq "test@example.com"
      expect(email.path_type).to eq 'email'
    end
  end

  describe "user account updates" do
    before :once do
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
        birthday = Time.now
        json = api_call(:put, @path, @path_options, {
          :user => {
            :name => 'Tobias Funke',
            :short_name => 'Tobias',
            :sortable_name => 'Funke, Tobias',
            :time_zone => 'Tijuana',
            :birthdate => birthday.iso8601,
            :locale => 'en'
          }
        })
        user = User.find(json['id'])
        avatar_url = json.delete("avatar_url")
        expect(json).to eq({
          'name' => 'Tobias Funke',
          'sortable_name' => 'Funke, Tobias',
          'sis_user_id' => 'sis-user-id',
          'sis_import_id' => nil,
          'id' => user.id,
          'short_name' => 'Tobias',
          'integration_id' => nil,
          'login_id' => 'student@example.com',
          'sis_login_id' => 'student@example.com',
          'locale' => 'en'
        })
        expect(user.birthdate.to_date).to eq birthday.to_date
        expect(user.time_zone.name).to eql 'Tijuana'
      end

      it "should catch invalid dates" do
        birthday = Time.now
        json = api_call(:put, @path, @path_options, {
            :user => {
                :name => 'Tobias Funke',
                :short_name => 'Tobias',
                :sortable_name => 'Funke, Tobias',
                :time_zone => 'Tijuana',
                :birthdate => "-4000-02-01 10:20",
                :locale => 'en'
            }
        }, {}, {:expected_status => 400})
      end

      it "should allow updating without any params" do
        json = api_call(:put, @path, @path_options, {})
        expect(json).not_to be_nil
      end

      it "should update the user's avatar with a token" do
        json = api_call(:get, "/api/v1/users/#{@student.id}/avatars",
                        :controller => "profile", :action => "profile_pics", :user_id => @student.to_param, :format => 'json')
        to_set = json.first

        expect(@student.avatar_image_source).not_to eql to_set['type']
        json = api_call(:put, @path, @path_options, {
          :user => {
            :avatar => {
              :token => to_set['token']
            }
          }
        })
        user = User.find(json['id'])
        expect(user.avatar_image_source).to eql to_set['type']
        expect(user.avatar_state).to eql :approved
      end

      it "should re-lock the avatar after being updated by an admin" do
        json = api_call(:get, "/api/v1/users/#{@student.id}/avatars",
                        :controller => "profile", :action => "profile_pics", :user_id => @student.to_param, :format => 'json')
        to_set = json.first

        old_source = to_set['type'] == 'gravatar' ? 'twitter' : 'gravatar'
        @student.avatar_image_source = old_source
        @student.avatar_state = 'locked'
        @student.save!

        expect(@student.avatar_image_source).not_to eql to_set['type']
        json = api_call(:put, @path, @path_options, {
          :user => {
            :avatar => {
              :token => to_set['token']
            }
          }
        })
        user = User.find(json['id'])
        expect(user.avatar_image_source).to eql to_set['type']
        expect(user.avatar_state).to eql :locked
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
        expect(user.avatar_image_source).to eql 'external'
        expect(user.avatar_image_url).to eql url_to_set
      end
    end

    context "non-account-admin user" do
      before :once do
        user_with_pseudonym name: "Earnest Lambert Watkins"
        course_with_teacher user: @user, active_all: true
      end

      context "with users_can_edit_name enabled" do
        before :once do
          @course.root_account.settings = { users_can_edit_name: true }
          @course.root_account.save!
        end

        it "should allow user to rename self" do
          json = api_call(:put, "/api/v1/users/#{@user.id}", @path_options.merge(id: @user.id),
                          { user: { name: "Blue Ivy Carter" } })
          expect(json["name"]).to eq "Blue Ivy Carter"
        end
      end

      context "with users_can_edit_name disabled" do
        before :once do
          @course.root_account.settings = { users_can_edit_name: false }
          @course.root_account.save!
        end

        it "should not allow user to rename self" do
          api_call(:put, "/api/v1/users/#{@user.id}", @path_options.merge(id: @user.id),
                   { user: { name: "Ovaltine Jenkins" } }, {}, { expected_status: 401 })
        end
      end
    end

    context "an unauthorized user" do
      it "should receive a 401" do
        user
        raw_api_call(:put, @path, @path_options, {
          :user => { :name => 'Gob Bluth' }
        })
        expect(response.code).to eql '401'
      end
    end
  end

  describe "user settings" do
    before :once do
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
        expect(json['manual_mark_as_read']).to be_falsey
      end

      it "should be able to update other users' settings" do
        json = api_call(:put, path, path_options, manual_mark_as_read: true)
        expect(json['manual_mark_as_read']).to be_truthy

        json = api_call(:put, path, path_options, manual_mark_as_read: false)
        expect(json['manual_mark_as_read']).to be_falsey
      end
    end

    context "a student" do
      before do
        @user = @student
      end

      it "should be able to view its own settings" do
        json = api_call(:get, path, path_options)
        expect(json['manual_mark_as_read']).to be_falsey
      end

      it "should be able to update its own settings" do
        json = api_call(:put, path, path_options, manual_mark_as_read: true)
        expect(json['manual_mark_as_read']).to be_truthy

        json = api_call(:put, path, path_options, manual_mark_as_read: false)
        expect(json['manual_mark_as_read']).to be_falsey
      end

      it "should receive 401 if updating another user's settings" do
        @course.enroll_student(user).accept!
        raw_api_call(:put, path, path_options, manual_mark_as_read: true)
        expect(response.code).to eq '401'
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
      expect(body).to eq({'data'=>data})

      body = api_call(:get, path, path_opts_get, {ns: namespace_b})
      expect(body).to eq({'data'=>other_data})

      body = api_call(:get, path2, path_opts_get2, {ns: namespace_a})
      expect(body).to eq({'data'=>data2})

      body = api_call(:get, path2, path_opts_get2, {ns: namespace_b})
      expect(body).to eq({'data'=>other_data2})
    end

    it "turns JSON hashes into scopes" do
      data = JSON.parse '{"a":"nice JSON","b":"dont you think?"}'
      get_path = path + '/b'
      get_scope = scope + '/b'
      api_call(:put, path, path_opts_put, {ns: namespace_a, data: data})
      body = api_call(:get, get_path, path_opts_get.merge({scope: get_scope}), {ns: namespace_a})
      expect(body).to eq({'data'=>'dont you think?'})
    end

    it "is deleteable" do
      data = JSON.parse '{"a":"nice JSON","b":"dont you think?"}'
      del_path = path + '/b'
      del_scope = scope + '/b'
      api_call(:put, path, path_opts_put, {ns: namespace_a, data: data})
      body = api_call(:delete, del_path, path_opts_del.merge({scope: del_scope}), {ns: namespace_a})
      expect(body).to eq({'data'=>'dont you think?'})

      body = api_call(:get, path, path_opts_get, {ns: namespace_a})
      expect(body).to eq({'data'=>{'a'=>'nice JSON'}})
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
        expect(response.code).to eql '409'
      end
    end
  end

  describe "removing user from account" do
    before :once do
      @admin = account_admin_user
      course_with_student(:user => user_with_pseudonym(:name => 'Student', :username => 'student@example.com'))
      @student = @user
      @user = @admin
      @path = "/api/v1/accounts/#{Account.default.id}/users/#{@student.id}"
      @path_options = { :controller => 'accounts', :action => 'remove_user',
        :format => 'json', :user_id => @student.to_param,
        :account_id => Account.default.to_param }
    end

    context "a user with permissions" do
      it "should be able to delete a user" do
        json = api_call(:delete, @path, @path_options)
        expect(@student.associated_accounts).not_to include(Account.default)
        expect(json.to_json).to eq @student.reload.to_json
      end

      it "should be able to delete a user by SIS ID" do
        @student.pseudonym.update_attribute(:sis_user_id, '12345')
        id_param = "sis_user_id:#{@student.pseudonyms.first.sis_user_id}"

        path = "/api/v1/accounts/#{Account.default.id}/users/#{id_param}"
        path_options = @path_options.merge(:user_id => id_param)
        api_call(:delete, path, path_options)
        expect(response.code).to eql '200'
        expect(@student.associated_accounts).not_to include(Account.default)
      end

      it 'should be able to delete itself' do
        path = "/api/v1/accounts/#{Account.default.to_param}/users/#{@user.id}"
        json = api_call(:delete, path, @path_options.merge(:user_id => @user.to_param))
        expect(@user.associated_accounts).not_to include(Account.default)
        expect(json.to_json).to eq @user.reload.to_json
      end
    end

    context 'an unauthorized user' do
      it "should receive a 401" do
        user
        raw_api_call(:delete, @path, @path_options)
        expect(response.code).to eql '401'
      end
    end

    context 'a non-admin user' do
      it 'should not be able to delete itself' do
        path = "/api/v1/accounts/#{Account.default.to_param}/users/#{@student.id}"
        api_call_as_user(@student, :delete, path, @path_options.merge(:user_id => @student.to_param), {}, {}, expected_status: 401)
      end
    end
  end

  context "user files" do
    before :each do
      @context = @user
    end

    include_examples "file uploads api with folders"
    include_examples "file uploads api with quotas"

    def preflight(preflight_params, opts = {})
      api_call(:post, "/api/v1/users/self/files",
        { :controller => "users", :action => "create_file", :format => "json", :user_id => 'self', },
        preflight_params,
        {},
        opts)
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
    before :once do
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
      expect(Pseudonym.where(sis_user_id: 'user_sis_id_02').first.user_id).to eq @user1.id
      expect(@user2.pseudonyms).to be_empty
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
      expect(Pseudonym.where(sis_user_id: 'user_sis_id_02').first.user_id).to eq @user1.id
      expect(@user2.pseudonyms).to be_empty
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
