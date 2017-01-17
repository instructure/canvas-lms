#
# Copyright (C) 2011-2016 Instructure, Inc.
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

require_relative '../sharding_spec_helper'

describe UsersController do
  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }

  describe "external_tool" do
    let(:account) { Account.default }

    let :tool do
      tool = account.context_external_tools.new({
        name: "bob",
        consumer_key: "bob",
        shared_secret: "bob",
        tool_id: 'some_tool',
        privacy_level: 'public'
      })
      tool.url = "http://www.example.com/basic_lti?first=john&last=smith"
      tool.resource_selection = {
        :url => "http://#{HostUrl.default_host}/selection_test",
        :selection_width => 400,
        :selection_height => 400
      }
      user_navigation = {
        :text => 'example',
        :labels => {
          'en' => 'English Label',
          'sp' => 'Spanish Label'
        }
      }
      tool.settings[:user_navigation] = user_navigation
      tool.save!
      tool
    end

    it "removes query string when post_only = true" do
      u = user_factory(active_all: true)
      account.account_users.create!(user: u)
      user_session(@user)
      tool.user_navigation = { text: "example" }
      tool.settings['post_only'] = 'true'
      tool.save!

      get :external_tool, {id:tool.id, user_id:u.id}
      expect(assigns[:lti_launch].resource_url).to eq 'http://www.example.com/basic_lti'
    end

    it "does not remove query string from url" do
      u = user_factory(active_all: true)
      account.account_users.create!(user: u)
      user_session(@user)
      tool.user_navigation = { text: "example" }
      tool.save!

      get :external_tool, {id:tool.id, user_id:u.id}
      expect(assigns[:lti_launch].resource_url).to eq 'http://www.example.com/basic_lti?first=john&last=smith'
    end

    it "uses localized labels" do
      u = user_factory(active_all: true)
      account.account_users.create!(user: u)
      user_session(@user)

      get :external_tool, {id:tool.id, user_id:u.id}
      expect(tool.label_for(:user_navigation, :en)).to eq 'English Label'
    end
  end

  describe "index" do
    before :each do
      @a = Account.default
      @u = user_factory(active_all: true)
      @a.account_users.create!(user: @u)
      user_session(@user)
      @t1 = @a.default_enrollment_term
      @t2 = @a.enrollment_terms.create!(:name => 'Term 2')

      @e1 = course_with_student(:active_all => true)
      @c1 = @e1.course
      @c1.update_attributes!(:enrollment_term => @t1)
      @e2 = course_with_student(:active_all => true)
      @c2 = @e2.course
      @c2.update_attributes!(:enrollment_term => @t2)
      @c3 = course_with_student(:active_all => true, :user => @e1.user).course
      @c3.update_attributes!(:enrollment_term => @t1)

      User.update_account_associations(User.all.map(&:id))
      # NOTE: A controller test should only call the action 1 time per test.
      # this breaks use a js_env as it attempts to set a frozen hash multiple times.
      # This was refactored out to 3 tests to keep it from breaking but should
      # probably be refactored as integration test.
    end

    it "should filter account users by term - default" do
      get 'index', :account_id => @a.id
      expect(assigns[:users].map(&:id).sort).to eq [@u, @e1.user, @c1.teachers.first, @e2.user, @c2.teachers.first, @c3.teachers.first].map(&:id).sort
    end

    it "should filter account users by term - term 1" do
      get 'index', :account_id => @a.id, :enrollment_term_id => @t1.id
      expect(assigns[:users].map(&:id).sort).to eq [@e1.user, @c1.teachers.first, @c3.teachers.first].map(&:id).sort # 1 student, enrolled twice, and 2 teachers
    end

    it "should filter account users by term - term 2" do
      get 'index', :account_id => @a.id, :enrollment_term_id => @t2.id
      expect(assigns[:users].map(&:id).sort).to eq [@e2.user, @c2.teachers.first].map(&:id).sort
    end
  end

  describe "GET oauth" do
    it "sets up oauth for google_drive" do
      state = nil
      settings_mock = mock()
      settings_mock.stubs(:settings).returns({})
      settings_mock.stubs(:enabled?).returns(true)

      user_factory(active_all: true)
      user_session(@user)

      Canvas::Plugin.stubs(:find).returns(settings_mock)
      SecureRandom.stubs(:hex).returns('abc123')
      GoogleDrive::Client.expects(:auth_uri).with() {|_c, s| state = s and true}.returns("http://example.com/redirect")

      get :oauth, {service: "google_drive", return_to: "http://example.com"}

      expect(response).to redirect_to "http://example.com/redirect"
      json = Canvas::Security.decode_jwt(state)
      expect(session[:oauth_gdrive_nonce]).to eq 'abc123'
      expect(json['redirect_uri']).to eq oauth_success_url(:service => 'google_drive')
      expect(json['return_to_url']).to eq "http://example.com"
      expect(json['nonce']).to eq session[:oauth_gdrive_nonce]
    end

  end

  describe "GET oauth_success" do
    it "handles google_drive oauth_success for a logged_in_user" do
      settings_mock = mock()
      settings_mock.stubs(:settings).returns({})
      authorization_mock = mock('authorization', :code= => nil, fetch_access_token!: nil, refresh_token:'refresh_token', access_token: 'access_token')
      drive_mock = mock('drive_mock', about: mock(get: nil))
      client_mock = mock("client", discovered_api:drive_mock, :execute! => mock('result', status: 200, data:{'permissionId' => 'permission_id', 'user' => {'emailAddress' => 'blah@blah.com'}}))
      client_mock.stubs(:authorization).returns(authorization_mock)
      GoogleDrive::Client.stubs(:create).returns(client_mock)

      session[:oauth_gdrive_nonce] = 'abc123'
      state = Canvas::Security.create_jwt({'return_to_url' => 'http://localhost.com/return', 'nonce' => 'abc123'})
      course_with_student_logged_in

      get :oauth_success, state: state, service: "google_drive", code: "some_code"

      service = UserService.where(user_id: @user, service: 'google_drive', service_domain: 'drive.google.com').first
      expect(service.service_user_id).to eq 'permission_id'
      expect(service.service_user_name).to eq 'blah@blah.com'
      expect(service.token).to eq 'refresh_token'
      expect(service.secret).to eq 'access_token'
      expect(session[:oauth_gdrive_nonce]).to be_nil
    end

    it "handles google_drive oauth_success for a non logged in user" do
      settings_mock = mock()
      settings_mock.stubs(:settings).returns({})
      authorization_mock = mock('authorization', :code= => nil, fetch_access_token!: nil, refresh_token:'refresh_token', access_token: 'access_token')
      drive_mock = mock('drive_mock', about: mock(get: nil))
      client_mock = mock("client", discovered_api:drive_mock, :execute! => mock('result', status: 200, data:{'permissionId' => 'permission_id'}))
      client_mock.stubs(:authorization).returns(authorization_mock)
      GoogleDrive::Client.stubs(:create).returns(client_mock)

      session[:oauth_gdrive_nonce] = 'abc123'
      state = Canvas::Security.create_jwt({'return_to_url' => 'http://localhost.com/return', 'nonce' => 'abc123'})

      get :oauth_success, state: state, service: "google_drive", code: "some_code"

      expect(session[:oauth_gdrive_access_token]).to eq 'access_token'
      expect(session[:oauth_gdrive_refresh_token]).to eq 'refresh_token'
      expect(session[:oauth_gdrive_nonce]).to be_nil
    end

    it "rejects invalid state" do
      settings_mock = mock()
      settings_mock.stubs(:settings).returns({})
      authorization_mock = mock('authorization')
      authorization_mock.stubs(:code= => nil, fetch_access_token!: nil, refresh_token:'refresh_token', access_token: 'access_token')
      drive_mock = mock('drive_mock', about: mock(get: nil))
      client_mock = mock("client", discovered_api:drive_mock, :execute! => mock('result', status: 200, data:{'permissionId' => 'permission_id'}))
      client_mock.stubs(:authorization).returns(authorization_mock)
      GoogleDrive::Client.stubs(:create).returns(client_mock)

      state = Canvas::Security.create_jwt({'return_to_url' => 'http://localhost.com/return', 'nonce' => 'abc123'})
      get :oauth_success, state: state, service: "google_drive", code: "some_code"

      assert_unauthorized
      expect(session[:oauth_gdrive_access_token]).to be_nil
      expect(session[:oauth_gdrive_refresh_token]).to be_nil
    end
  end

  it "should not include deleted courses in manageable courses" do
    course_with_teacher_logged_in(:course_name => "MyCourse1", :active_all => 1)
    course1 = @course
    course1.destroy
    course_with_teacher(:course_name => "MyCourse2", :user => @teacher, :active_all => 1)
    course2 = @course

    get 'manageable_courses', :user_id => @teacher.id, :term => "MyCourse"
    expect(response).to be_success

    courses = json_parse
    expect(courses.map { |c| c['id'] }).to eq [course2.id]
  end

  it "should sort the results of manageable_courses by name" do
    course_with_teacher_logged_in(:course_name => "B", :active_all => 1)
    %w(c d a).each do |name|
      course_with_teacher(:course_name => name, :user => @teacher, :active_all => 1)
    end

    get 'manageable_courses', :user_id => @teacher.id
    expect(response).to be_success

    courses = json_parse
    expect(courses.map { |c| c['label'] }).to eq %w(a B c d)
  end

  describe "POST 'create'" do
    it "should not allow creating when self_registration is disabled and you're not an admin'" do
      post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
      expect(response).not_to be_success
    end

    context 'self registration' do
      before :each do
        Account.default.canvas_authentication_provider.update_attribute(:self_registration, true)
      end

      context 'self registration for observers only' do
        before :each do
          Account.default.canvas_authentication_provider.update_attribute(:self_registration, 'observer')
        end

        it "should not allow teachers to self register" do
          post 'create', :pseudonym => { :unique_id => 'jane@example.com' }, :user => { :name => 'Jane Teacher', :terms_of_use => '1', :initial_enrollment_type => 'teacher' }, :format => 'json'
          assert_status(403)
        end

        it "should not allow students to self register" do
          course_factory(active_all: true)
          @course.update_attribute(:self_enrollment, true)

          post 'create', :pseudonym => { :unique_id => 'jane@example.com', :password => 'lolwut12', :password_confirmation => 'lolwut12' }, :user => { :name => 'Jane Student', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'username', :self_enrollment => '1', :format => 'json'
          assert_status(403)
        end

        it "should allow observers to self register" do
          user_with_pseudonym(:active_all => true, :password => 'lolwut12')
          course_with_student(:user => @user, :active_all => true)

          post 'create', :pseudonym => { :unique_id => 'jane@example.com' }, :observee => { :unique_id => @pseudonym.unique_id, :password => 'lolwut12' }, :user => { :name => 'Jane Observer', :terms_of_use => '1', :initial_enrollment_type => 'observer' }, :format => 'json'
          expect(response).to be_success
          new_pseudo = Pseudonym.where(unique_id: 'jane@example.com').first
          new_user = new_pseudo.user
          expect(new_user.observed_users).to eq [@user]
          oe = new_user.observer_enrollments.first
          expect(oe.course).to eq @course
          expect(oe.associated_user).to eq @user
        end

        it "should redirect 'new' action to root_url" do
          get 'new'
          expect(response).to redirect_to root_url
        end
      end

      it "should create a pre_registered user" do
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        expect(response).to be_success

        p = Pseudonym.where(unique_id: 'jacob@instructure.com').first
        expect(p).to be_active
        expect(p.user).to be_pre_registered
        expect(p.user.name).to eq 'Jacob Fugal'
        expect(p.user.communication_channels.length).to eq 1
        expect(p.user.communication_channels.first).to be_unconfirmed
        expect(p.user.communication_channels.first.path).to eq 'jacob@instructure.com'
        expect(p.user.associated_accounts).to eq [Account.default]
        expect(p.user.preferences[:accepted_terms]).to be_truthy
      end

      it "should mark user as having accepted the terms of use if specified" do
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        json = JSON.parse(response.body)
        accepted_terms = json["user"]["user"]["preferences"]["accepted_terms"]
        expect(response).to be_success
        expect(accepted_terms).to be_present
        expect(Time.parse(accepted_terms)).to be_within(1.minute).of(Time.now.utc)
      end

      it "should create a registered user if the skip_registration flag is passed in" do
        post('create', {
          :pseudonym => { :unique_id => 'jacob@instructure.com'},
          :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :skip_registration => '1' }
        })
        expect(response).to be_success

        p = Pseudonym.where(unique_id: 'jacob@instructure.com').first
        expect(p).to be_active
        expect(p.user).to be_registered
        expect(p.user.name).to eq 'Jacob Fugal'
        expect(p.user.communication_channels.length).to eq 1
        expect(p.user.communication_channels.first).to be_unconfirmed
        expect(p.user.communication_channels.first.path).to eq 'jacob@instructure.com'
        expect(p.user.associated_accounts).to eq [Account.default]
      end

      it "should complain about conflicting unique_ids" do
        u = User.create! { |user| user.workflow_state = 'registered' }
        p = u.pseudonyms.create!(:unique_id => 'jacob@instructure.com')
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["pseudonym"]["unique_id"]).to be_present
        expect(Pseudonym.by_unique_id('jacob@instructure.com')).to eq [p]
      end

      it "should not complain about conflicting ccs, in any state" do
        user1, user2, user3 = User.create!, User.create!, User.create!
        cc1 = user1.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email')
        cc2 = user2.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state == 'confirmed' }
        cc3 = user3.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state == 'retired' }

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        expect(response).to be_success

        p = Pseudonym.where(unique_id: 'jacob@instructure.com').first
        expect(p).to be_active
        expect(p.user).to be_pre_registered
        expect(p.user.name).to eq 'Jacob Fugal'
        expect(p.user.communication_channels.length).to eq 1
        expect(p.user.communication_channels.first).to be_unconfirmed
        expect(p.user.communication_channels.first.path).to eq 'jacob@instructure.com'
        expect([cc1, cc2, cc3]).not_to be_include(p.user.communication_channels.first)
      end

      it "should re-use 'conflicting' unique_ids if it hasn't been fully registered yet" do
        u = User.create! { |u| u.workflow_state = 'creation_pending' }
        p = Pseudonym.create!(:unique_id => 'jacob@instructure.com', :user => u)
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        expect(response).to be_success

        expect(Pseudonym.by_unique_id('jacob@instructure.com')).to eq [p]
        p.reload
        expect(p).to be_active
        expect(p.user).to be_pre_registered
        expect(p.user.name).to eq 'Jacob Fugal'
        expect(p.user.communication_channels.length).to eq 1
        expect(p.user.communication_channels.first).to be_unconfirmed
        expect(p.user.communication_channels.first.path).to eq 'jacob@instructure.com'

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        expect(response).not_to be_success
      end

      it "should validate acceptance of the terms" do
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["user"]["terms_of_use"]).to be_present
      end

      it "should not validate acceptance of the terms if not required by system" do
        Setting.set('terms_required', 'false')
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
        expect(response).to be_success
      end

      it "should not validate acceptance of the terms if not required by account" do
        default_account = Account.default
        default_account.settings[:account_terms_required] = false
        default_account.save!

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
        expect(response).to be_success
      end

      it "should require email pseudonyms by default" do
        post 'create', :pseudonym => { :unique_id => 'jacob' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["pseudonym"]["unique_id"]).to be_present
      end

      it "should require email pseudonyms if not self enrolling" do
        post 'create', :pseudonym => { :unique_id => 'jacob' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }, :pseudonym_type => 'username'
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["pseudonym"]["unique_id"]).to be_present
      end

      it "should validate the self enrollment code" do
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => 'omg ... not valid', :initial_enrollment_type => 'student' }, :self_enrollment => '1'
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["user"]["self_enrollment_code"]).to be_present
      end

      it "should ignore the password if not self enrolling" do
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :initial_enrollment_type => 'student' }
        expect(response).to be_success
        u = User.where(name: 'Jacob Fugal').first
        expect(u).to be_pre_registered
        expect(u.pseudonym).to be_password_auto_generated
      end

      context "self enrollment" do
        before(:once) do
          Account.default.allow_self_enrollment!
          course_factory(active_all: true)
          @course.update_attribute(:self_enrollment, true)
        end

        it "should strip the self enrollment code before validation" do
          post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code + ' ', :initial_enrollment_type => 'student' }, :self_enrollment => '1'
          expect(response).to be_success
        end

        it "should ignore the password if self enrolling with an email pseudonym" do
          post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'email', :self_enrollment => '1'
          expect(response).to be_success
          u = User.where(name: 'Jacob Fugal').first
          expect(u).to be_pre_registered
          expect(u.pseudonym).to be_password_auto_generated
        end

        it "should require a password if self enrolling with a non-email pseudonym" do
          post 'create', :pseudonym => { :unique_id => 'jacob' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'username', :self_enrollment => '1'
          assert_status(400)
          json = JSON.parse(response.body)
          expect(json["errors"]["pseudonym"]["password"]).to be_present
          expect(json["errors"]["pseudonym"]["password_confirmation"]).to be_present
        end

        it "should auto-register the user if self enrolling" do
          post 'create', :pseudonym => { :unique_id => 'jacob', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'username', :self_enrollment => '1'
          expect(response).to be_success
          u = User.where(name: 'Jacob Fugal').first
          expect(@course.students).to include(u)
          expect(u).to be_registered
          expect(u.pseudonym).not_to be_password_auto_generated
        end
      end

      it "should validate the observee's credentials" do
        user_with_pseudonym(:active_all => true, :password => 'lolwut12')

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :observee => { :unique_id => @pseudonym.unique_id, :password => 'not it' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :initial_enrollment_type => 'observer' }
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["observee"]["unique_id"]).to be_present
      end

      it "should link the user to the observee" do
        user_with_pseudonym(:active_all => true, :password => 'lolwut12')

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :observee => { :unique_id => @pseudonym.unique_id, :password => 'lolwut12' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :initial_enrollment_type => 'observer' }
        expect(response).to be_success
        u = User.where(name: 'Jacob Fugal').first
        expect(u).to be_pre_registered
        expect(response).to be_success
        expect(u.observed_users).to include(@user)
      end
    end

    context 'account admin creating users' do

      describe 'successfully' do
        let!(:account) { Account.create! }

        before do
          user_with_pseudonym(:account => account)
          account.account_users.create!(user: @user)
          user_session(@user, @pseudonym)
        end

        it "should create a pre_registered user (in the correct account)" do
          post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :sis_user_id => 'testsisid' }, :user => { :name => 'Jacob Fugal' }
          expect(response).to be_success
          p = Pseudonym.where(unique_id: 'jacob@instructure.com').first
          expect(p.account_id).to eq account.id
          expect(p).to be_active
          expect(p.sis_user_id).to eq 'testsisid'
          expect(p.user).to be_pre_registered
        end

        it "should create users with non-email pseudonyms" do
          post 'create', format: 'json', account_id: account.id, pseudonym: { unique_id: 'jacob', sis_user_id: 'testsisid', integration_id: 'abc', path: '' }, user: { name: 'Jacob Fugal' }
          expect(response).to be_success
          p = Pseudonym.where(unique_id: 'jacob').first
          expect(p.account_id).to eq account.id
          expect(p).to be_active
          expect(p.sis_user_id).to eq 'testsisid'
          expect(p.integration_id).to eq 'abc'
          expect(p.user).to be_pre_registered
        end


        it "should not require acceptance of the terms" do
          post 'create', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
          expect(response).to be_success
        end

        it "should allow setting a password" do
          post 'create', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal' }
          u = User.where(name: 'Jacob Fugal').first
          expect(u).to be_present
          expect(u.pseudonym).not_to be_password_auto_generated
        end

        it "allows admins to force the self-registration workflow for a given user" do
          Pseudonym.any_instance.expects(:send_confirmation!)
          post 'create', account_id: account.id,
            pseudonym: {
              unique_id: 'jacob@instructure.com', password: 'asdfasdf',
              password_confirmation: 'asdfasdf', force_self_registration: "1",
            }, user: { name: 'Jacob Fugal' }
          expect(response).to be_success
          u = User.where(name: 'Jacob Fugal').first
          expect(u).to be_present
          expect(u.pseudonym).not_to be_password_auto_generated
        end

        it "should not throw a 500 error without user params'" do
          post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, account_id: account.id
          expect(response).to be_success
        end

        it "should not throw a 500 error without pseudonym params'" do
          post 'create', :user => { :name => 'Jacob Fugal' }, account_id: account.id
          assert_status(400)
          expect(response).not_to be_success
        end
      end

      it "should not allow an admin to set the sis id when creating a user if they don't have privileges to manage sis" do
        account = Account.create!
        admin = account_admin_user_with_role_changes(:account => account, :role_changes => {'manage_sis' => false})
        user_session(admin)
        post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :sis_user_id => 'testsisid' }, :user => { :name => 'Jacob Fugal' }
        expect(response).to be_success
        p = Pseudonym.where(unique_id: 'jacob@instructure.com').first
        expect(p.account_id).to eq account.id
        expect(p).to be_active
        expect(p.sis_user_id).to be_nil
        expect(p.user).to be_pre_registered
      end

      it "should notify the user if a merge opportunity arises" do
        account = Account.create!
        user_with_pseudonym(:account => account)
        account.account_users.create!(user: @user)
        user_session(@user, @pseudonym)
        @admin = @user

        u = User.create! { |u| u.workflow_state = 'registered' }
        u.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
        u.pseudonyms.create!(:unique_id => 'jon@instructure.com')
        CommunicationChannel.any_instance.expects(:send_merge_notification!)
        post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :send_confirmation => '0' }, :user => { :name => 'Jacob Fugal' }
        expect(response).to be_success
      end

      it "should not notify the user if the merge opportunity can't log in'" do
        notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')

        account = Account.create!
        user_with_pseudonym(:account => account)
        account.account_users.create!(user: @user)
        user_session(@user, @pseudonym)
        @admin = @user

        u = User.create! { |u| u.workflow_state = 'registered' }
        u.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
        post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :send_confirmation => '0' }, :user => { :name => 'Jacob Fugal' }
        expect(response).to be_success
        p = Pseudonym.where(unique_id: 'jacob@instructure.com').first
        expect(Message.where(:communication_channel_id => p.user.email_channel, :notification_id => notification).first).to be_nil
      end
    end
  end

  describe "GET 'grades_for_student'" do
    let(:test_course) do
      test_course = course_factory(active_all: true)
      test_course
    end
    let(:student) { user_factory(active_all: true) }
    let!(:student_enrollment) do
      course_with_user('StudentEnrollment', course: test_course, user: student, active_all: true)
    end
    let(:grading_period_group) { group_helper.legacy_create_for_course(test_course) }
    let(:grading_period) do
      grading_period_group.grading_periods.create!(
        title: "Some Semester",
        start_date: 3.months.ago,
        end_date: 2.months.from_now)
    end
    let!(:assignment1) do
      assignment = assignment_model(course: test_course, due_at: Time.zone.now, points_possible: 10)
      assignment.grade_student(student, grade: '40%', grader: @teacher)
    end

    let!(:assignment2) do
      assignment = assignment_model(course: test_course, due_at: 3.months.from_now, points_possible: 100)
      assignment.grade_student(student, grade: '100%', grader: @teacher)
    end

    context "as a student" do
      it "returns the grade for the student, filtered by the grading period" do
        user_session(student)
        get('grades_for_student', grading_period_id: grading_period.id,
          enrollment_id: student_enrollment.id)

        expect(response).to be_ok
        expected_response = {'grade' => 40.0, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response

        grading_period.end_date = 4.months.from_now
        grading_period.close_date = 4.months.from_now
        grading_period.save!
        get('grades_for_student', grading_period_id: grading_period.id,
          enrollment_id: student_enrollment.id)

        expect(response).to be_ok
        expected_response = {'grade' => 94.55, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response
      end

      it "does not filter the grades by a grading period if " \
      "'All Grading Periods' is selected" do
        all_grading_periods_id = 0
        user_session(student)
        get('grades_for_student', grading_period_id: all_grading_periods_id,
          enrollment_id: student_enrollment.id)

        expect(response).to be_ok
        expected_response = {'grade' => 94.55, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response
      end

      it "returns unauthorized if a student is trying to get grades for " \
      "another student (and is not observing that student)" do
        snooping_student = user_factory(active_all: true)
        course_with_user('StudentEnrollment', course: test_course, user: snooping_student, active_all: true)
        user_session(snooping_student)
        get('grades_for_student', grading_period_id: grading_period.id,
          enrollment_id: student_enrollment.id)

        expect(response).to_not be_ok
      end
    end

    context "as an observer" do
      let(:observer) { user_with_pseudonym(active_all: true) }

      it "returns the grade and the total for a student, filtered by grading period" do
        student.observers << observer
        user_session(observer)
        get('grades_for_student', enrollment_id: student_enrollment.id,
          grading_period_id: grading_period.id)

        expect(response).to be_ok
        expected_response = {'grade' => 40.0, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response

        grading_period.end_date = 4.months.from_now
        grading_period.close_date = 4.months.from_now
        grading_period.save!
        get('grades_for_student', grading_period_id: grading_period.id,
          enrollment_id: student_enrollment.id)

        expect(response).to be_ok
        expected_response = {'grade' => 94.55, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response
      end

      it "does not filter the grades by a grading period if " \
      "'All Grading Periods' is selected" do
        student.observers << observer
        all_grading_periods_id = 0
        user_session(observer)
        get('grades_for_student', grading_period_id: all_grading_periods_id,
          enrollment_id: student_enrollment.id)

        expect(response).to be_ok
        expected_response = {'grade' => 94.55, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response
      end

      it "returns unauthorized if the student is not an observee of the observer" do
        user_session(observer)
        get('grades_for_student', enrollment_id: student_enrollment.id,
          grading_period_id: grading_period.id)

        expect(response).to_not be_ok
      end
    end
  end

  describe "GET 'grades'" do
    context "grading periods" do
      let(:test_course) { course_factory(active_all: true) }
      let(:student1) { user_factory(active_all: true) }
      let(:student2) { user_factory(active_all: true) }
      let(:grading_period_group) { group_helper.legacy_create_for_course(test_course) }
      let!(:grading_period) do
        grading_period_group.grading_periods.create!(
          title: "Some Semester",
          start_date: 3.months.ago,
          end_date: 2.months.from_now)
      end

      context "as an observer" do
        let(:observer) do
          observer = user_with_pseudonym(active_all: true)
          course_with_user('StudentEnrollment', course: test_course, user: student1, active_all: true)
          course_with_user('StudentEnrollment', course: test_course, user: student2, active_all: true)
          student1.observers << observer
          student2.observers << observer
          observer
        end

        context "with grading periods" do
          it "returns the grading periods" do
            user_session(observer)
            get 'grades'

            grading_periods = assigns[:grading_periods][test_course.id][:periods]
            expect(grading_periods).to include grading_period
          end

          context "selected_period_id" do
            it "returns the id of a current grading period, if one " \
            "exists and no grading period parameter is passed in" do
              user_session(observer)
              get 'grades'

              selected_period_id = assigns[:grading_periods][test_course.id][:selected_period_id]
              expect(selected_period_id).to eq grading_period.global_id
            end

            it "returns 0 (signifying 'All Grading Periods') if no current " \
            "grading period exists and no grading period parameter is passed in" do
              grading_period.start_date = 1.month.from_now
              grading_period.save!
              user_session(observer)
              get 'grades'

              selected_period_id = assigns[:grading_periods][test_course.id][:selected_period_id]
              expect(selected_period_id).to eq 0
            end

            it "returns the grading_period_id passed in, if one is provided along with a course_id" do
              user_session(observer)
              get 'grades', course_id: test_course.id, grading_period_id: 2939

              selected_period_id = assigns[:grading_periods][test_course.id][:selected_period_id]
              expect(selected_period_id).to eq 2939
            end
          end
        end
      end

      context "as a student" do
        let(:another_test_course) { course_factory(active_all: true) }
        let(:test_student) do
          student = user_factory(active_all: true)
          course_with_user('StudentEnrollment', course: test_course, user: student, active_all: true)
          course_with_user('StudentEnrollment', course: another_test_course, user: student, active_all: true)
          student
        end

        context "with grading periods" do
          it "returns the grading periods" do
            user_session(test_student)
            get 'grades'

            grading_periods = assigns[:grading_periods][test_course.id][:periods]
            expect(grading_periods).to include grading_period
          end

          context "selected_period_id" do
            it "returns the id of a current grading period, if one " \
            "exists and no grading period parameter is passed in" do
              user_session(test_student)
              get 'grades'

              selected_period_id = assigns[:grading_periods][test_course.id][:selected_period_id]
              expect(selected_period_id).to eq grading_period.global_id
            end

            it "returns the grade for the current grading period, if one exists " \
              "and no grading period is passed in" do
              assignment = test_course.assignments.create!(
                due_at: 3.days.from_now(grading_period.end_date),
                points_possible: 10
              )
              assignment.grade_student(test_student, grader: test_course.teachers.first, grade: 10)
              user_session(test_student)
              get :grades
              expect(assigns[:grades][:student_enrollments][test_course.id]).to be_nil
            end

            it "returns 0 (signifying 'All Grading Periods') if no current " \
            "grading period exists and no grading period parameter is passed in" do
              grading_period.start_date = 1.month.from_now
              grading_period.save!
              user_session(test_student)
              get 'grades'

              selected_period_id = assigns[:grading_periods][test_course.id][:selected_period_id]
              expect(selected_period_id).to eq 0
            end

            it "returns the grade for 'All Grading Periods' if no current " \
              "grading period exists and no grading period is passed in" do
              grading_period.update!(start_date: 1.month.from_now)
              assignment = test_course.assignments.create!(
                due_at: 3.days.from_now(grading_period.end_date),
                points_possible: 10
              )
              assignment.grade_student(test_student, grader: test_course.teachers.first, grade: 10)
              user_session(test_student)
              get :grades
              expect(assigns[:grades][:student_enrollments][test_course.id]).to eq(100.0)
            end

            it "returns the grading_period_id passed in, if one is provided along with a course_id" do
              user_session(test_student)
              get 'grades', course_id: test_course.id, grading_period_id: 2939

              selected_period_id = assigns[:grading_periods][test_course.id][:selected_period_id]
              expect(selected_period_id).to eq 2939
            end

            context 'across shards' do
              specs_require_sharding

              it 'uses global ids for grading periods' do
                course_with_user('StudentEnrollment', course: test_course, user: student1, active_all: true)
                @shard1.activate do
                  account = Account.create!
                  @course2 = course_factory(active_all: true, account: account)
                  course_with_user('StudentEnrollment', course: @course2, user: student1, active_all: true)
                  grading_period_group2 = group_helper.legacy_create_for_course(@course2)
                  @grading_period2 = grading_period_group2.grading_periods.create!(
                    title: "Some Semester",
                    start_date: 3.months.ago,
                    end_date: 2.months.from_now)
                end

                user_session(student1)

                get 'grades'
                expect(response).to be_success
                selected_period_id = assigns[:grading_periods][@course2.id][:selected_period_id]
                expect(selected_period_id).to eq @grading_period2.id
              end
            end
          end
        end
      end
    end

    it "does not include designers in the teacher enrollments" do
      # teacher needs to be in two courses to get to the point where teacher
      # enrollments are queried
      @course1 = course_factory(active_all: true)
      @course2 = course_factory(active_all: true)
      @teacher = user_factory(active_all: true)
      @designer = user_factory(active_all: true)
      @course1.enroll_teacher(@teacher).accept!
      @course2.enroll_teacher(@teacher).accept!
      @course2.enroll_designer(@designer).accept!

      user_session(@teacher)
      get 'grades', :course_id => @course.id
      expect(response).to be_success

      teacher_enrollments = assigns[:presenter].teacher_enrollments
      expect(teacher_enrollments).not_to be_nil
      teachers = teacher_enrollments.map{ |e| e.user }
      expect(teachers).to be_include(@teacher)
      expect(teachers).not_to be_include(@designer)
    end

    it "does not redirect to an observer enrollment with no observee" do
      @course1 = course_factory(active_all: true)
      @course2 = course_factory(active_all: true)
      @user = user_factory(active_all: true)
      @course1.enroll_user(@user, 'ObserverEnrollment')
      @course2.enroll_student(@user).accept!

      user_session(@user)
      get 'grades'
      expect(response).to redirect_to course_grades_url(@course2)
    end

    it "does not include student view students in the grade average calculation" do
      course_with_teacher_logged_in(:active_all => true)
      course_with_teacher(:active_all => true, :user => @teacher)
      @s1 = student_in_course(:active_user => true).user
      @s2 = student_in_course(:active_user => true).user
      @test_student = @course.student_view_student
      @assignment = assignment_model(:course => @course, :points_possible => 5)
      @assignment.grade_student(@s1, grade: 3, grader: @teacher)
      @assignment.grade_student(@s2, grade: 4, grader: @teacher)
      @assignment.grade_student(@test_student, grade: 5, grader: @teacher)

      get 'grades'
      expect(assigns[:presenter].course_grade_summaries[@course.id]).to eq({ :score => 70, :students => 2 })
    end

    context 'across shards' do
      specs_require_sharding

      it 'loads courses from all shards' do
        course_with_teacher_logged_in :active_all => true
        @shard1.activate do
          account = Account.create!
          course = account.courses.create!
          @e2 = course.enroll_teacher(@teacher)
          @e2.update_attribute(:workflow_state, 'active')
        end

        get 'grades'
        expect(response).to be_success
        enrollments = assigns[:presenter].teacher_enrollments
        expect(enrollments).to include(@e2)
      end
    end
  end

  describe "GET 'avatar_image'" do
    it "should redirect to no-pic if avatars are disabled" do
      course_with_student_logged_in(:active_all => true)
      get 'avatar_image', :user_id  => @user.id
      expect(response).to redirect_to User.default_avatar_fallback
    end

    it "should redirect to avatar silhouette if no avatar is set and avatars are enabled" do
      course_with_student_logged_in(:active_all => true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.settings[:avatars] = 'enabled_pending'
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get 'avatar_image', :user_id  => @user.id
      expect(response).to redirect_to User.default_avatar_fallback
    end

    it "should pass along the default fallback to gravatar" do
      course_with_student_logged_in(:active_all => true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get 'avatar_image', :user_id  => @user.id
      expect(response).to redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI.escape("http://test.host/images/messages/avatar-50.png")}"
    end

    it "should take an invalid id and return silhouette" do
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get 'avatar_image', :user_id  => 'a'
      expect(response).to redirect_to 'http://test.host/images/messages/avatar-50.png'
    end

    it "should take an invalid id with a hyphen and return silhouette" do
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get 'avatar_image', :user_id  => 'a-1'
      expect(response).to redirect_to 'http://test.host/images/messages/avatar-50.png'
    end
  end

  describe "GET 'public_feed.atom'" do
    before(:each) do
      course_with_student(:active_all => true)
      assignment_model(:course => @course)
      @course.discussion_topics.create!(:title => "hi", :message => "blah", :user => @student)
      wiki_page_model(:course => @course)
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code + 'x'
      expect(assigns[:problem]).to match /The verification code is invalid/
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.links.first.rel).to match(/self/)
      expect(feed.links.first.href).to match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.entries.all?{|e| e.authors.present?}).to be_truthy
    end
  end

  describe "GET 'admin_merge'" do
    let(:account) { Account.create! }

    before do
      account_admin_user
      user_session(@admin)
    end

    describe 'as site admin' do
      before { Account.site_admin.account_users.create!(user: @admin) }

      it 'warns about merging a user with itself' do
        user = User.create!
        pseudonym(user)
        get 'admin_merge', :user_id => user.id, :pending_user_id => user.id
        expect(flash[:error]).to eq 'You can\'t merge an account with itself.'
      end

      it 'does not issue warning if the users are different' do
        user = User.create!
        other_user = User.create!
        get 'admin_merge', :user_id => user.id, :pending_user_id => other_user.id
        expect(flash[:error]).to be_nil
      end
    end

    it "should not allow you to view any user by id" do
      pseudonym(@admin)
      user_with_pseudonym(:account => account)
      get 'admin_merge', :user_id => @admin.id, :pending_user_id => @user.id
      expect(response).to be_success
      expect(assigns[:pending_other_user]).to be_nil
    end
  end

  describe "GET 'show'" do
    context "sharding" do
      specs_require_sharding

      it "should include enrollments from all shards for the actual user" do
        course_with_teacher(:active_all => 1)
        @shard1.activate do
          account = Account.create!
          course = account.courses.create!
          @e2 = course.enroll_teacher(@teacher)
        end
        account_admin_user(:user => @teacher)
        user_session(@teacher)

        get 'show', :id => @teacher.id
        expect(response).to be_success
        expect(assigns[:enrollments].sort_by(&:id)).to eq [@enrollment, @e2]
      end

      it "should include enrollments from all shards for trusted account admins" do
        skip "granting read permissions to trusted accounts"
        course_with_teacher(:active_all => 1)
        @shard1.activate do
          account = Account.create!
          course = account.courses.create!
          @e2 = course.enroll_teacher(@teacher)
        end
        account_admin_user
        user_session(@user)

        get 'show', :id => @teacher.id
        expect(response).to be_success
        expect(assigns[:enrollments].sort_by(&:id)).to eq [@enrollment, @e2]
      end
    end

    it "should not let admins see enrollments from other accounts" do
      @enrollment1 = course_with_teacher(:active_all => 1)
      @enrollment2 = course_with_teacher(:active_all => 1, :user => @user)

      other_root_account = Account.create!(:name => 'other')
      @enrollment3 = course_with_teacher(:active_all => 1, :user => @user, :account => other_root_account)

      account_admin_user
      user_session(@admin)

      get 'show', :id => @teacher.id
      expect(response).to be_success
      expect(assigns[:enrollments].sort_by(&:id)).to eq [@enrollment1, @enrollment2]
    end

    it "should respond to JSON request" do
      account = Account.create!
      course_with_student(:active_all => true, :account => account)
      account_admin_user(:account => account)
      user_with_pseudonym(:user => @admin, :account => account)
      user_session(@admin)
      get 'show', :id  => @student.id, :format => 'json'
      expect(response).to be_success
      user = json_parse
      expect(user['name']).to eq @student.name
    end
  end

  describe "PUT 'update'" do
    it "does not leak information about arbitrary users" do
      other_user = User.create! :name => 'secret'
      user_with_pseudonym
      user_session(@user)
      put 'update', :id => other_user.id, :format => 'json'
      expect(response.body).not_to include 'secret'
      expect(response.status).to eq 401
    end
  end

  describe "POST 'masquerade'" do
    specs_require_sharding

    it "should associate the user with target user's shard" do
      PageView.stubs(:page_view_method).returns(:db)
      user_with_pseudonym
      admin = @user
      Account.site_admin.account_users.create!(user: admin)
      user_session(admin)
      @shard1.activate do
        account = Account.create!
        user2 = user_with_pseudonym(account: account)
        LoadAccount.stubs(:default_domain_root_account).returns(account)
        post 'masquerade', user_id: user2.id
        expect(response).to be_redirect

        expect(admin.associated_shards(:shadow)).to be_include(@shard1)
      end
    end

    it "should not associate the user with target user's shard if masquerading failed" do
      PageView.stubs(:page_view_method).returns(:db)
      user_with_pseudonym
      admin = @user
      user_session(admin)
      @shard1.activate do
        account = Account.create!
        user2 = user_with_pseudonym(account: account)
        LoadAccount.stubs(:default_domain_root_account).returns(account)
        post 'masquerade', user_id: user2.id
        expect(response).not_to be_redirect

        expect(admin.associated_shards(:shadow)).not_to be_include(@shard1)
      end
    end

    it "should not associate the user with target user's shard for non-db page views" do
      user_with_pseudonym
      admin = @user
      Account.site_admin.account_users.create!(user: admin)
      user_session(admin)
      @shard1.activate do
        account = Account.create!
        user2 = user_with_pseudonym(account: account)
        LoadAccount.stubs(:default_domain_root_account).returns(account)
        post 'masquerade', user_id: user2.id
        expect(response).to be_redirect

        expect(admin.associated_shards(:shadow)).not_to be_include(@shard1)
      end
    end
  end

  describe 'GET media_download' do
    let(:kaltura_client) do
      kaltura_client = mock('CanvasKaltura::ClientV3').responds_like_instance_of(CanvasKaltura::ClientV3)
      CanvasKaltura::ClientV3.stubs(:new).returns(kaltura_client)
      kaltura_client
    end

    let(:media_source_fetcher) {
      media_source_fetcher = mock('MediaSourceFetcher').responds_like_instance_of(MediaSourceFetcher)
      MediaSourceFetcher.expects(:new).with(kaltura_client).returns(media_source_fetcher)
      media_source_fetcher
    }

    before do
      account = Account.create!
      course_with_student(:active_all => true, :account => account)
      user_session(@student)
    end

    it 'should pass type and media_type params down to the media fetcher' do
      media_source_fetcher.expects(:fetch_preferred_source_url).
        with(media_id: 'someMediaId', file_extension: 'mp4', media_type: 'video').
        returns('http://example.com/media.mp4')

      get 'media_download', user_id: @student.id, entryId: 'someMediaId', type: 'mp4', media_type: 'video'
    end

    context 'when redirect is set to 1' do
      it 'should redirect to the url' do
        media_source_fetcher.stubs(:fetch_preferred_source_url).
          returns('http://example.com/media.mp4')

        get 'media_download', user_id: @student.id, entryId: 'someMediaId', type: 'mp4', redirect: '1'

        expect(response).to redirect_to 'http://example.com/media.mp4'
      end
    end

    context 'when redirect does not equal 1' do
      it 'should render the url in json' do
        media_source_fetcher.stubs(:fetch_preferred_source_url).
          returns('http://example.com/media.mp4')

        get 'media_download', user_id: @student.id, entryId: 'someMediaId', type: 'mp4'

        expect(json_parse['url']).to eq 'http://example.com/media.mp4'
      end
    end

    context 'when asset is not found' do
      it 'should render a 404 and error message' do
        media_source_fetcher.stubs(:fetch_preferred_source_url).
          returns(nil)

        get 'media_download', user_id: @student.id, entryId: 'someMediaId', type: 'mp4'

        expect(response.code).to eq '404'
        expect(response.body).to eq 'Could not find download URL'
      end
    end
  end

  describe "login hooks" do
    before :each do
      Account.default.canvas_authentication_provider.update_attribute(:self_registration, true)
    end

    it "should hook on new" do
      controller.expects(:run_login_hooks).once
      get "new"
    end

    it "should hook on failed create" do
      controller.expects(:run_login_hooks).once
      post "create"
    end
  end

  describe "teacher_activity" do
    it "finds submission comment interaction" do
      course_with_student_submissions
      sub = @course.assignments.first.submissions.
        where(user_id: @student).first
      sub.add_comment(comment: 'hi', author: @teacher)

      get 'teacher_activity', user_id: @teacher.id, course_id: @course.id

      expect(assigns[:courses][@course][0][:last_interaction]).not_to be_nil
    end
  end

  describe '#toggle_recent_activity_dashboard' do
    it 'updates user preference based on value provided' do
      course_factory
      user_factory(active_all: true)
      user_session(@user)

      expect(@user.preferences[:recent_activity_dashboard]).to be_falsy

      post :toggle_recent_activity_dashboard

      expect(@user.reload.preferences[:recent_activity_dashboard]).to be_truthy
      expect(response).to be_success
      expect(JSON.parse(response.body)).to be_empty
    end
  end

  describe "#invite_users" do
    it 'does not work without ability to manage students or admins on course' do
      Account.default.tap{|a| a.settings[:open_registration] = true; a.save!}
      course_with_student_logged_in(:active_all => true)

      post 'invite_users', :course_id => @course.id

      assert_unauthorized
    end

    it 'does not work without open registration or manage_user_logins rights' do
      course_with_teacher_logged_in(:active_all => true)

      post 'invite_users', :course_id => @course.id

      assert_unauthorized
    end

    it 'works with an admin with manage_login_rights' do
      course_factory
      account_admin_user(:active_all => true)
      user_session(@user)

      post 'invite_users', :course_id => @course.id
      expect(response).to be_success # yes, even though we didn't do anything
    end

    it 'works with a teacher with open_registration' do
      Account.default.any_instantiation.stubs(:open_registration?).returns(true)
      course_with_teacher_logged_in(:active_all => true)

      post 'invite_users', :course_id => @course.id
      expect(response).to be_success
    end

    it 'invites a bunch of users' do
      Account.default.any_instantiation.stubs(:open_registration?).returns(true)
      course_with_teacher_logged_in(:active_all => true)

      user_list = [{'email' => 'example1@example.com'}, {'email' => 'example2@example.com', 'name' => 'Hurp Durp'}]

      post 'invite_users', :course_id => @course.id, :users => user_list
      expect(response).to be_success
      json = JSON.parse(response.body)
      expect(json['invited_users'].count).to eq 2

      new_user1 = User.where(:name => 'example1@example.com').first
      new_user2 = User.where(:name => 'Hurp Durp').first
      expect(json['invited_users'].map{|u| u['id']}).to match_array([new_user1.id, new_user2.id])
    end

    it 'checks for pre-existing users' do
      existing_user = user_with_pseudonym(:active_all => true, :username => "example1@example.com")

      Account.default.any_instantiation.stubs(:open_registration?).returns(true)
      course_with_teacher_logged_in(:active_all => true)

      user_list = [{'email' => 'example1@example.com'}]

      post 'invite_users', :course_id => @course.id, :users => user_list
      expect(response).to be_success

      json = JSON.parse(response.body)
      expect(json['invited_users']).to be_empty
      expect(json['errored_users'].count).to eq 1
      expect(json['errored_users'].first['existing_users'].first['user_id']).to eq existing_user.id
    end
  end
end
