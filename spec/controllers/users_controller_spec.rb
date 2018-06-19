#
# Copyright (C) 2011 - present Instructure, Inc.
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

      get :external_tool, params: {id:tool.id, user_id:u.id}
      expect(assigns[:lti_launch].resource_url).to eq 'http://www.example.com/basic_lti'
    end

    it "does not remove query string from url" do
      u = user_factory(active_all: true)
      account.account_users.create!(user: u)
      user_session(@user)
      tool.user_navigation = { text: "example" }
      tool.save!

      get :external_tool, params: {id:tool.id, user_id:u.id}
      expect(assigns[:lti_launch].resource_url).to eq 'http://www.example.com/basic_lti?first=john&last=smith'
    end

    it "uses localized labels" do
      u = user_factory(active_all: true)
      account.account_users.create!(user: u)
      user_session(@user)

      get :external_tool, params: {id:tool.id, user_id:u.id}
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
      get 'index', params: {:account_id => @a.id}
      expect(assigns[:users].map(&:id).sort).to eq [@u, @e1.user, @c1.teachers.first, @e2.user, @c2.teachers.first, @c3.teachers.first].map(&:id).sort
    end

    it "should filter account users by term - term 1" do
      get 'index', params: {:account_id => @a.id, :enrollment_term_id => @t1.id}
      expect(assigns[:users].map(&:id).sort).to eq [@e1.user, @c1.teachers.first, @c3.teachers.first].map(&:id).sort # 1 student, enrolled twice, and 2 teachers
    end

    it "should filter account users by term - term 2" do
      get 'index', params: {:account_id => @a.id, :enrollment_term_id => @t2.id}
      expect(assigns[:users].map(&:id).sort).to eq [@e2.user, @c2.teachers.first].map(&:id).sort
    end
  end

  describe "GET oauth" do
    it "sets up oauth for google_drive" do
      state = nil
      settings_mock = double()
      allow(settings_mock).to receive(:settings).and_return({})
      allow(settings_mock).to receive(:enabled?).and_return(true)

      user_factory(active_all: true)
      user_session(@user)

      allow(Canvas::Plugin).to receive(:find).and_return(settings_mock)
      allow(SecureRandom).to receive(:hex).and_return('abc123')
      expect(GoogleDrive::Client).to receive(:auth_uri) { |_c, s| state = s; "http://example.com/redirect" }

      get :oauth, params: {service: "google_drive", return_to: "http://example.com"}

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
      settings_mock = double()
      allow(settings_mock).to receive(:settings).and_return({})
      authorization_mock = double('authorization', :code= => nil, fetch_access_token!: nil, refresh_token:'refresh_token', access_token: 'access_token')
      drive_mock = double('drive_mock', about: double(get: nil))
      client_mock = double("client", discovered_api:drive_mock, :execute! => double('result', status: 200, data:{'permissionId' => 'permission_id', 'user' => {'emailAddress' => 'blah@blah.com'}}))
      allow(client_mock).to receive(:authorization).and_return(authorization_mock)
      allow(GoogleDrive::Client).to receive(:create).and_return(client_mock)

      session[:oauth_gdrive_nonce] = 'abc123'
      state = Canvas::Security.create_jwt({'return_to_url' => 'http://localhost.com/return', 'nonce' => 'abc123'})
      course_with_student_logged_in

      get :oauth_success, params: {state: state, service: "google_drive", code: "some_code"}

      service = UserService.where(user_id: @user, service: 'google_drive', service_domain: 'drive.google.com').first
      expect(service.service_user_id).to eq 'permission_id'
      expect(service.service_user_name).to eq 'blah@blah.com'
      expect(service.token).to eq 'refresh_token'
      expect(service.secret).to eq 'access_token'
      expect(session[:oauth_gdrive_nonce]).to be_nil
    end

    it "handles google_drive oauth_success for a non logged in user" do
      settings_mock = double()
      allow(settings_mock).to receive(:settings).and_return({})
      authorization_mock = double('authorization', :code= => nil, fetch_access_token!: nil, refresh_token:'refresh_token', access_token: 'access_token')
      drive_mock = double('drive_mock', about: double(get: nil))
      client_mock = double("client", discovered_api:drive_mock, :execute! => double('result', status: 200, data:{'permissionId' => 'permission_id'}))
      allow(client_mock).to receive(:authorization).and_return(authorization_mock)
      allow(GoogleDrive::Client).to receive(:create).and_return(client_mock)

      session[:oauth_gdrive_nonce] = 'abc123'
      state = Canvas::Security.create_jwt({'return_to_url' => 'http://localhost.com/return', 'nonce' => 'abc123'})

      get :oauth_success, params: {state: state, service: "google_drive", code: "some_code"}

      expect(session[:oauth_gdrive_access_token]).to eq 'access_token'
      expect(session[:oauth_gdrive_refresh_token]).to eq 'refresh_token'
      expect(session[:oauth_gdrive_nonce]).to be_nil
    end

    it "rejects invalid state" do
      settings_mock = double()
      allow(settings_mock).to receive(:settings).and_return({})
      authorization_mock = double('authorization')
      allow(authorization_mock).to receive_messages(:code= => nil, fetch_access_token!: nil, refresh_token:'refresh_token', access_token: 'access_token')
      drive_mock = double('drive_mock', about: double(get: nil))
      client_mock = double("client", discovered_api:drive_mock, :execute! => double('result', status: 200, data:{'permissionId' => 'permission_id'}))

      allow(client_mock).to receive(:authorization).and_return(authorization_mock)
      allow(GoogleDrive::Client).to receive(:create).and_return(client_mock)

      state = Canvas::Security.create_jwt({'return_to_url' => 'http://localhost.com/return', 'nonce' => 'abc123'})
      get :oauth_success, params: {state: state, service: "google_drive", code: "some_code"}

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

    get 'manageable_courses', params: {:user_id => @teacher.id, :term => "MyCourse"}
    expect(response).to be_success

    courses = json_parse
    expect(courses.map { |c| c['id'] }).to eq [course2.id]
  end

  it "should sort the results of manageable_courses by name" do
    course_with_teacher_logged_in(:course_name => "B", :active_all => 1)
    %w(c d a).each do |name|
      course_with_teacher(:course_name => name, :user => @teacher, :active_all => 1)
    end

    get 'manageable_courses', params: {:user_id => @teacher.id}
    expect(response).to be_success

    courses = json_parse
    expect(courses.map { |c| c['label'] }).to eq %w(a B c d)
  end

  describe "POST 'create'" do
    it "should not allow creating when self_registration is disabled and you're not an admin'" do
      post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }}
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
          post 'create', params: {:pseudonym => { :unique_id => 'jane@example.com' }, :user => { :name => 'Jane Teacher', :terms_of_use => '1', :initial_enrollment_type => 'teacher' }}, format: 'json'
          assert_status(403)
        end

        it "should not allow students to self register" do
          course_factory(active_all: true)
          @course.update_attribute(:self_enrollment, true)

          post 'create', params: {:pseudonym => { :unique_id => 'jane@example.com', :password => 'lolwut12', :password_confirmation => 'lolwut12' }, :user => { :name => 'Jane Student', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'username', :self_enrollment => '1'}, format: 'json'
          assert_status(403)
        end

        it "should allow observers to self register" do
          user_with_pseudonym(:active_all => true, :password => 'lolwut12')
          course_with_student(:user => @user, :active_all => true)

          post 'create', params: {:pseudonym => { :unique_id => 'jane@example.com' }, :observee => { :unique_id => @pseudonym.unique_id, :password => 'lolwut12' }, :user => { :name => 'Jane Observer', :terms_of_use => '1', :initial_enrollment_type => 'observer' }}, format: 'json'
          expect(response).to be_success
          new_pseudo = Pseudonym.where(unique_id: 'jane@example.com').first
          new_user = new_pseudo.user
          expect(new_user.linked_students).to eq [@user]
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
        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }}
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
        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }}
        json = JSON.parse(response.body)
        accepted_terms = json["user"]["user"]["preferences"]["accepted_terms"]
        expect(response).to be_success
        expect(accepted_terms).to be_present
        expect(Time.parse(accepted_terms)).to be_within(1.minute.to_i).of(Time.now.utc)
      end

      it "should create a registered user if the skip_registration flag is passed in" do
        post('create', params: {
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
        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }}
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

        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }}
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
        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }}
        expect(response).to be_success

        expect(Pseudonym.by_unique_id('jacob@instructure.com')).to eq [p]
        p.reload
        expect(p).to be_active
        expect(p.user).to be_pre_registered
        expect(p.user.name).to eq 'Jacob Fugal'
        expect(p.user.communication_channels.length).to eq 1
        expect(p.user.communication_channels.first).to be_unconfirmed
        expect(p.user.communication_channels.first.path).to eq 'jacob@instructure.com'

        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }}
        expect(response).not_to be_success
      end

      it "should validate acceptance of the terms" do
        Account.default.create_terms_of_service!(terms_type: "default", passive: false)
        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }}
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["user"]["terms_of_use"]).to be_present
      end

      it "should not validate acceptance of the terms if terms are passive" do
        Account.default.create_terms_of_service!(terms_type: "default")
        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }}
        expect(response).to be_success
      end

      it "should not validate acceptance of the terms if not required by account" do
        default_account = Account.default
        Account.default.create_terms_of_service!(terms_type: "default")
        default_account.save!

        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }}
        expect(response).to be_success
      end

      it "should require email pseudonyms by default" do
        post 'create', params: {:pseudonym => { :unique_id => 'jacob' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }}
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["pseudonym"]["unique_id"]).to be_present
      end

      it "should require email pseudonyms if not self enrolling" do
        post 'create', params: {:pseudonym => { :unique_id => 'jacob' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }, :pseudonym_type => 'username'}
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["pseudonym"]["unique_id"]).to be_present
      end

      it "should validate the self enrollment code" do
        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => 'omg ... not valid', :initial_enrollment_type => 'student' }, :self_enrollment => '1'}
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["user"]["self_enrollment_code"]).to be_present
      end

      it "should ignore the password if not self enrolling" do
        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :initial_enrollment_type => 'student' }}
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
          post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code + ' ', :initial_enrollment_type => 'student' }, :self_enrollment => '1'}
          expect(response).to be_success
        end

        it "should ignore the password if self enrolling with an email pseudonym" do
          post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'email', :self_enrollment => '1'}
          expect(response).to be_success
          u = User.where(name: 'Jacob Fugal').first
          expect(u).to be_pre_registered
          expect(u.pseudonym).to be_password_auto_generated
        end

        it "should require a password if self enrolling with a non-email pseudonym" do
          post 'create', params: {:pseudonym => { :unique_id => 'jacob' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'username', :self_enrollment => '1'}
          assert_status(400)
          json = JSON.parse(response.body)
          expect(json["errors"]["pseudonym"]["password"]).to be_present
          expect(json["errors"]["pseudonym"]["password_confirmation"]).to be_present
        end

        it "should auto-register the user if self enrolling" do
          post 'create', params: {:pseudonym => { :unique_id => 'jacob', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'username', :self_enrollment => '1'}
          expect(response).to be_success
          u = User.where(name: 'Jacob Fugal').first
          expect(@course.students).to include(u)
          expect(u).to be_registered
          expect(u.pseudonym).not_to be_password_auto_generated
        end
      end

      it "should validate the observee's credentials" do
        user_with_pseudonym(:active_all => true, :password => 'lolwut12')

        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :observee => { :unique_id => @pseudonym.unique_id, :password => 'not it' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :initial_enrollment_type => 'observer' }}
        assert_status(400)
        json = JSON.parse(response.body)
        expect(json["errors"]["observee"]["unique_id"]).to be_present
      end

      it "should link the user to the observee" do
        user_with_pseudonym(:active_all => true, :password => 'lolwut12')

        post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, :observee => { :unique_id => @pseudonym.unique_id, :password => 'lolwut12' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :initial_enrollment_type => 'observer' }}
        expect(response).to be_success
        u = User.where(name: 'Jacob Fugal').first
        expect(u).to be_pre_registered
        expect(response).to be_success
        expect(u.linked_students).to include(@user)
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
          post 'create', params: {:account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :sis_user_id => 'testsisid' }, :user => { :name => 'Jacob Fugal' }}, format: 'json'
          expect(response).to be_success
          p = Pseudonym.where(unique_id: 'jacob@instructure.com').first
          expect(p.account_id).to eq account.id
          expect(p).to be_active
          expect(p.sis_user_id).to eq 'testsisid'
          expect(p.user).to be_pre_registered
        end

        it "should create users with non-email pseudonyms" do
          post 'create', params: {account_id: account.id, pseudonym: { unique_id: 'jacob', sis_user_id: 'testsisid', integration_id: 'abc', path: '' }, user: { name: 'Jacob Fugal' }}, format: 'json'
          expect(response).to be_success
          p = Pseudonym.where(unique_id: 'jacob').first
          expect(p.account_id).to eq account.id
          expect(p).to be_active
          expect(p.sis_user_id).to eq 'testsisid'
          expect(p.integration_id).to eq 'abc'
          expect(p.user).to be_pre_registered
        end

        it "should create users with non-email pseudonyms and an email" do
          post 'create', params: {account_id: account.id, pseudonym: { unique_id: 'testid', path: 'testemail@example.com' }, user: { name: 'test' }}, format: 'json'
          expect(response).to be_success
          p = Pseudonym.where(unique_id: 'testid').first
          expect(p.user.email).to eq "testemail@example.com"
        end

        it "should not require acceptance of the terms" do
          post 'create', params: {:account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }}
          expect(response).to be_success
        end

        it "should allow setting a password" do
          post 'create', params: {:account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal' }}
          u = User.where(name: 'Jacob Fugal').first
          expect(u).to be_present
          expect(u.pseudonym).not_to be_password_auto_generated
        end

        it "allows admins to force the self-registration workflow for a given user" do
          expect_any_instance_of(Pseudonym).to receive(:send_confirmation!)
          post 'create', params: {account_id: account.id,
            pseudonym: {
              unique_id: 'jacob@instructure.com', password: 'asdfasdf',
              password_confirmation: 'asdfasdf', force_self_registration: "1",
            }, user: { name: 'Jacob Fugal' }}
          expect(response).to be_success
          u = User.where(name: 'Jacob Fugal').first
          expect(u).to be_present
          expect(u.pseudonym).not_to be_password_auto_generated
        end

        it "should not throw a 500 error without user params'" do
          post 'create', params: {:pseudonym => { :unique_id => 'jacob@instructure.com' }, account_id: account.id}
          expect(response).to be_success
        end

        it "should not throw a 500 error without pseudonym params'" do
          post 'create', params: {:user => { :name => 'Jacob Fugal' }, account_id: account.id}
          assert_status(400)
          expect(response).not_to be_success
        end

        it "strips whitespace from the unique_id" do
          post 'create', params: {:account_id => account.id, :pseudonym => { :unique_id => 'spaceman@example.com ' }, :user => { :name => 'Spaceman' }}, format: 'json'
          expect(response).to be_success
          json = JSON.parse(response.body)
          p = Pseudonym.find(json["pseudonym"]["pseudonym"]["id"])
          expect(p.unique_id).to eq 'spaceman@example.com'
          expect(p.user.email).to eq 'spaceman@example.com'
        end
      end

      it "should not allow an admin to set the sis id when creating a user if they don't have privileges to manage sis" do
        account = Account.create!
        admin = account_admin_user_with_role_changes(:account => account, :role_changes => {'manage_sis' => false})
        user_session(admin)
        post 'create', params: {:account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :sis_user_id => 'testsisid' }, :user => { :name => 'Jacob Fugal' }}, format: 'json'
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
        notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')

        post 'create', params: {:account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :send_confirmation => '0' }, :user => { :name => 'Jacob Fugal' }}, format: 'json'
        expect(response).to be_success
        p = Pseudonym.where(unique_id: 'jacob@instructure.com').first
        expect(Message.where(:communication_channel_id => p.user.email_channel, :notification_id => notification).first).to be_present
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
        post 'create', params: {:account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :send_confirmation => '0' }, :user => { :name => 'Jacob Fugal' }}, format: 'json'
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
        get('grades_for_student', params: {grading_period_id: grading_period.id,
          enrollment_id: student_enrollment.id})

        expect(response).to be_ok
        expected_response = {'grade' => 40.0, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response

        grading_period.end_date = 4.months.from_now
        grading_period.close_date = 4.months.from_now
        grading_period.save!
        get('grades_for_student', params: {grading_period_id: grading_period.id,
          enrollment_id: student_enrollment.id})

        expect(response).to be_ok
        expected_response = {'grade' => 94.55, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response
      end

      it "does not filter the grades by a grading period if " \
      "'All Grading Periods' is selected" do
        all_grading_periods_id = 0
        user_session(student)
        get('grades_for_student', params: {grading_period_id: all_grading_periods_id,
          enrollment_id: student_enrollment.id})

        expect(response).to be_ok
        expected_response = {'grade' => 94.55, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response
      end

      it "returns unauthorized if a student is trying to get grades for " \
      "another student (and is not observing that student)" do
        snooping_student = user_factory(active_all: true)
        course_with_user('StudentEnrollment', course: test_course, user: snooping_student, active_all: true)
        user_session(snooping_student)
        get('grades_for_student', params: {grading_period_id: grading_period.id,
          enrollment_id: student_enrollment.id})

        expect(response).to_not be_ok
      end
    end

    context "with unposted assignments" do
      before(:each) do
        unposted_assignment = assignment_model(
          course: test_course, due_at: Time.zone.now,
          points_possible: 90, muted: true
        )
        unposted_assignment.grade_student(student, grade: '100%', grader: @teacher)

        user_session(@teacher)
      end

      let(:response) do
        get('grades_for_student', params: {enrollment_id: student_enrollment.id})
      end

      let(:parsed_response) do
        json_parse(response.body)
      end

      context "when the requester can manage grades" do
        before(:each) do
          test_course.root_account.role_overrides.create!(
            permission: 'view_all_grades', role: teacher_role, enabled: false
          )
          RoleOverride.create!(
            permission: 'manage_grades', role: teacher_role, enabled: true
          )
        end

        it "allows access" do
          expect(response).to be_ok
        end

        it "returns the grade" do
          expect(parsed_response['grade']).to eq 94.55
        end

        it "returns the unposted_grade" do
          expect(parsed_response['unposted_grade']).to eq 97
        end
      end

      context "when the requester can view all grades" do
        before(:each) do
          test_course.root_account.role_overrides.create!(
            permission: 'view_all_grades', role: teacher_role, enabled: true
          )
          test_course.root_account.role_overrides.create!(
            permission: 'manage_grades', role: teacher_role, enabled: false
          )
        end

        it "allows access" do
          expect(response).to be_ok
        end

        it "returns the grade" do
          expect(parsed_response['grade']).to eq 94.55
        end

        it "returns the unposted_grade" do
          expect(parsed_response['unposted_grade']).to eq 97
        end
      end

      context "when the requester does not have permissions to see unposted grades" do
        before(:each) do
          test_course.root_account.role_overrides.create!(
            permission: 'view_all_grades', role: teacher_role, enabled: false
          )
          test_course.root_account.role_overrides.create!(
            permission: 'manage_grades', role: teacher_role, enabled: false
          )
        end

        it "returns unauthorized" do
          expect(response).to have_http_status(401)
        end
      end
    end

    context "as an observer" do
      let(:observer) { user_with_pseudonym(active_all: true) }

      it "returns the grade and the total for a student, filtered by grading period" do
        student.linked_observers << observer
        user_session(observer)
        get('grades_for_student', params: {enrollment_id: student_enrollment.id,
          grading_period_id: grading_period.id})

        expect(response).to be_ok
        expected_response = {'grade' => 40.0, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response

        grading_period.end_date = 4.months.from_now
        grading_period.close_date = 4.months.from_now
        grading_period.save!
        get('grades_for_student', params: {grading_period_id: grading_period.id,
          enrollment_id: student_enrollment.id})

        expect(response).to be_ok
        expected_response = {'grade' => 94.55, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response
      end

      it "does not filter the grades by a grading period if " \
      "'All Grading Periods' is selected" do
        student.linked_observers << observer
        all_grading_periods_id = 0
        user_session(observer)
        get('grades_for_student', params: {grading_period_id: all_grading_periods_id,
          enrollment_id: student_enrollment.id})

        expect(response).to be_ok
        expected_response = {'grade' => 94.55, 'hide_final_grades' => false}
        expect(json_parse(response.body)).to eq expected_response
      end

      it "returns unauthorized if the student is not an observee of the observer" do
        user_session(observer)
        get('grades_for_student', params: {enrollment_id: student_enrollment.id,
          grading_period_id: grading_period.id})

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
      let(:assignment_due_in_grading_period) do
        test_course.assignments.create!(
          due_at: 10.days.from_now(grading_period.start_date),
          points_possible: 10
        )
      end
      let(:assignment_due_outside_of_grading_period) do
        test_course.assignments.create!(
          due_at: 10.days.ago(grading_period.start_date),
          points_possible: 10
        )
      end
      let(:teacher) { test_course.teachers.active.first }

      context "as an observer" do
        let(:observer) do
          observer = user_with_pseudonym(active_all: true)
          course_with_user('StudentEnrollment', course: test_course, user: student1, active_all: true)
          course_with_user('StudentEnrollment', course: test_course, user: student2, active_all: true)
          student1.linked_observers << observer
          student2.linked_observers << observer
          observer
        end

        context "with grading periods" do
          it "returns the grading periods" do
            user_session(observer)
            get 'grades'

            grading_periods = assigns[:grading_periods][test_course.id][:periods]
            expect(grading_periods).to include grading_period
          end

          it "returns the grade for the current grading period for observed students" do
            user_session(observer)
            assignment_due_in_grading_period.grade_student(student1, grade: 5, grader: teacher)
            assignment_due_outside_of_grading_period.grade_student(student1, grade: 10, grader: teacher)
            get 'grades'

            grade = assigns[:grades][:observed_enrollments][test_course.id][student1.id]
            # 5/10 on assignment in grading period -> 50%
            expect(grade).to eq(50.0)
          end

          it "returns the course grade for observed students if there is no current grading period" do
            user_session(observer)
            assignment_due_in_grading_period.grade_student(student1, grade: 5, grader: teacher)
            assignment_due_outside_of_grading_period.grade_student(student1, grade: 10, grader: teacher)
            grading_period.update!(end_date: 1.month.ago)
            get 'grades'

            grade = assigns[:grades][:observed_enrollments][test_course.id][student1.id]
            # 5/10 on assignment in grading period + 10/10 on assignment outside of grading period -> 15/20 -> 75%
            expect(grade).to eq(75.0)
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
              get 'grades', params: {course_id: test_course.id, grading_period_id: 2939}

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
              get 'grades', params: {course_id: test_course.id, grading_period_id: 2939}

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
      get 'grades', params: {:course_id => @course.id}
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
      get 'avatar_image', params: {:user_id  => @user.id}
      expect(response).to redirect_to User.default_avatar_fallback
    end

    it "should redirect to avatar silhouette if no avatar is set and avatars are enabled" do
      course_with_student_logged_in(:active_all => true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.settings[:avatars] = 'enabled_pending'
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get 'avatar_image', params: {:user_id  => @user.id}
      expect(response).to redirect_to User.default_avatar_fallback
    end

    it "should pass along the default fallback to placeholder image" do
      course_with_student_logged_in(:active_all => true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get 'avatar_image', params: {:user_id  => @user.id}
      expect(response).to redirect_to "http://test.host/images/messages/avatar-50.png"
    end

    it "should take an invalid id and return silhouette" do
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get 'avatar_image', params: {:user_id  => 'a'}
      expect(response).to redirect_to 'http://test.host/images/messages/avatar-50.png'
    end

    it "should take an invalid id with a hyphen and return silhouette" do
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get 'avatar_image', params: {:user_id  => 'a-1'}
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
      get 'public_feed', params: {:feed_code => @user.feed_code + 'x'}, format: 'atom'
      expect(assigns[:problem]).to match /The verification code is invalid/
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', params: {:feed_code => @user.feed_code}, format: 'atom'
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.links.first.rel).to match(/self/)
      expect(feed.links.first.href).to match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', params: {:feed_code => @user.feed_code}, format: 'atom'
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
        get 'admin_merge', params: {:user_id => user.id, :pending_user_id => user.id}
        expect(flash[:error]).to eq 'You can\'t merge an account with itself.'
      end

      it 'does not issue warning if the users are different' do
        user = User.create!
        other_user = User.create!
        get 'admin_merge', params: {:user_id => user.id, :pending_user_id => other_user.id}
        expect(flash[:error]).to be_nil
      end
    end

    it "should not allow you to view any user by id" do
      pseudonym(@admin)
      user_with_pseudonym(:account => account)
      get 'admin_merge', params: {:user_id => @admin.id, :pending_user_id => @user.id}
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

        get 'show', params: {:id => @teacher.id}
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

        get 'show', params: {:id => @teacher.id}
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

      get 'show', params: {:id => @teacher.id}
      expect(response).to be_success
      expect(assigns[:enrollments].sort_by(&:id)).to eq [@enrollment1, @enrollment2]
    end

    it "should respond to JSON request" do
      account = Account.create!
      course_with_student(:active_all => true, :account => account)
      account_admin_user(:account => account)
      user_with_pseudonym(:user => @admin, :account => account)
      user_session(@admin)
      get 'show', params: {:id  => @student.id}, format: 'json'
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
      put 'update', params: {:id => other_user.id}, format: 'json'
      expect(response.body).not_to include 'secret'
      expect(response.status).to eq 401
    end
  end

  describe "POST 'masquerade'" do
    specs_require_sharding

    it "should associate the user with target user's shard" do
      allow(PageView).to receive(:page_view_method).and_return(:db)
      user_with_pseudonym
      admin = @user
      Account.site_admin.account_users.create!(user: admin)
      user_session(admin)
      @shard1.activate do
        account = Account.create!
        user2 = user_with_pseudonym(account: account)
        allow(LoadAccount).to receive(:default_domain_root_account).and_return(account)
        post 'masquerade', params: {user_id: user2.id}
        expect(response).to be_redirect

        expect(admin.associated_shards(:shadow)).to be_include(@shard1)
      end
    end

    it "should not associate the user with target user's shard if masquerading failed" do
      allow(PageView).to receive(:page_view_method).and_return(:db)
      user_with_pseudonym
      admin = @user
      user_session(admin)
      @shard1.activate do
        account = Account.create!
        user2 = user_with_pseudonym(account: account)
        allow(LoadAccount).to receive(:default_domain_root_account).and_return(account)
        post 'masquerade', params: {user_id: user2.id}
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
        allow(LoadAccount).to receive(:default_domain_root_account).and_return(account)
        post 'masquerade', params: {user_id: user2.id}
        expect(response).to be_redirect

        expect(admin.associated_shards(:shadow)).not_to be_include(@shard1)
      end
    end
  end

  describe 'GET masquerade' do
    let(:user2) do
      user2 = user_with_pseudonym(name: "user2", short_name: "u2")
      user2.pseudonym.sis_user_id = "user2_sisid1"
      user2.pseudonym.integration_id = "user2_intid1"
      user2.pseudonym.unique_id = "user2_login1@foo.com"
      user2.pseudonym.save!
      user2
    end

    before do
      user_session(site_admin_user)
    end

    it 'should set the js_env properly with act as user data' do
      get 'masquerade', params: {user_id: user2.id}
      assert_response(:success)
      act_as_user_data = controller.js_env[:act_as_user_data][:user]
      expect(act_as_user_data).to include({
        name: user2.name,
        short_name: user2.short_name,
        id: user2.id,
        avatar_image_url: user2.avatar_image_url,
        sortable_name: user2.sortable_name,
        email: user2.email,
        pseudonyms: [
          { login_id: user2.pseudonym.unique_id,
            sis_id: user2.pseudonym.sis_user_id,
            integration_id: user2.pseudonym.integration_id }
        ]
      })
    end
  end

  describe 'GET media_download' do
    let(:kaltura_client) do
      kaltura_client = instance_double('CanvasKaltura::ClientV3')
      allow(CanvasKaltura::ClientV3).to receive(:new).and_return(kaltura_client)
      kaltura_client
    end

    let(:media_source_fetcher) {
      media_source_fetcher = instance_double('MediaSourceFetcher')
      expect(MediaSourceFetcher).to receive(:new).with(kaltura_client).and_return(media_source_fetcher)
      media_source_fetcher
    }

    before do
      account = Account.create!
      course_with_student(:active_all => true, :account => account)
      user_session(@student)
    end

    it 'should pass type and media_type params down to the media fetcher' do
      expect(media_source_fetcher).to receive(:fetch_preferred_source_url).
        with(media_id: 'someMediaId', file_extension: 'mp4', media_type: 'video').
        and_return('http://example.com/media.mp4')

      get 'media_download', params: {user_id: @student.id, entryId: 'someMediaId', type: 'mp4', media_type: 'video'}
    end

    context 'when redirect is set to 1' do
      it 'should redirect to the url' do
        allow(media_source_fetcher).to receive(:fetch_preferred_source_url).
          and_return('http://example.com/media.mp4')

        get 'media_download', params: {user_id: @student.id, entryId: 'someMediaId', type: 'mp4', redirect: '1'}

        expect(response).to redirect_to 'http://example.com/media.mp4'
      end
    end

    context 'when redirect does not equal 1' do
      it 'should render the url in json' do
        allow(media_source_fetcher).to receive(:fetch_preferred_source_url).
          and_return('http://example.com/media.mp4')

        get 'media_download', params: {user_id: @student.id, entryId: 'someMediaId', type: 'mp4'}

        expect(json_parse['url']).to eq 'http://example.com/media.mp4'
      end
    end

    context 'when asset is not found' do
      it 'should render a 404 and error message' do
        allow(media_source_fetcher).to receive(:fetch_preferred_source_url).
          and_return(nil)

        get 'media_download', params: {user_id: @student.id, entryId: 'someMediaId', type: 'mp4'}

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
      expect(controller).to receive(:run_login_hooks).once
      get "new"
    end

    it "should hook on failed create" do
      expect(controller).to receive(:run_login_hooks).once
      post "create"
    end
  end

  describe "teacher_activity" do
    it "finds submission comment interaction" do
      course_with_student_submissions
      sub = @course.assignments.first.submissions.
        where(user_id: @student).first
      sub.add_comment(comment: 'hi', author: @teacher)

      get 'teacher_activity', params: {user_id: @teacher.id, course_id: @course.id}

      expect(assigns[:courses][@course][0][:last_interaction]).not_to be_nil
    end

    it "finds ungraded submissions but not if the assignment is deleted" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course(:active_all => true)

      type = "online_text_entry"
      a1 = @course.assignments.create!(:title => "a1", :submission_types => "online_text_entry")
      s1 = a1.submit_homework(@student, :body => "blah1")
      a2 = @course.assignments.create!(:title => "a2", :submission_types => "online_text_entry")
      s2 = a2.submit_homework(@student, :body => "blah2")
      a2.destroy!

      get 'teacher_activity', params: {user_id: @teacher.id, course_id: @course.id}

      expect(assigns[:courses][@course][0][:ungraded]).to eq [s1]
    end
  end

  describe '#toggle_hide_dashcard_color_overlays' do
    it 'updates user preference based on value provided' do
      course_factory
      user_factory(active_all: true)
      user_session(@user)

      expect(@user.preferences[:hide_dashcard_color_overlays]).to be_falsy

      post :toggle_hide_dashcard_color_overlays

      expect(@user.reload.preferences[:hide_dashcard_color_overlays]).to be_truthy
      expect(response).to be_success
      expect(JSON.parse(response.body)).to be_empty
    end
  end

  describe '#dashboard_view' do
    before(:each) do
      course_factory
      user_factory(active_all: true)
      user_session(@user)
    end

    it 'sets the proper user preference on PUT requests' do
      put :dashboard_view, params: {:dashboard_view => 'cards'}
      expect(@user.dashboard_view).to eql('cards')
    end

    it 'does not allow arbitrary values to be set' do
      put :dashboard_view, params: {:dashboard_view => 'a non-whitelisted value'}
      assert_status(400)
    end
  end

  describe "#invite_users" do
    it 'does not work without ability to manage students or admins on course' do
      Account.default.tap{|a| a.settings[:open_registration] = true; a.save!}
      course_with_student_logged_in(:active_all => true)

      post 'invite_users', params: {:course_id => @course.id}

      assert_unauthorized
    end

    it 'does not work without open registration or manage_user_logins rights' do
      course_with_teacher_logged_in(:active_all => true)

      post 'invite_users', params: {:course_id => @course.id}

      assert_unauthorized
    end

    it 'works with an admin with manage_login_rights' do
      course_factory
      account_admin_user(:active_all => true)
      user_session(@user)

      post 'invite_users', params: {:course_id => @course.id}
      expect(response).to be_success # yes, even though we didn't do anything
    end

    it 'works with a teacher with open_registration' do
      allow_any_instantiation_of(Account.default).to receive(:open_registration?).and_return(true)
      course_with_teacher_logged_in(:active_all => true)

      post 'invite_users', params: {:course_id => @course.id}
      expect(response).to be_success
    end

    it 'invites a bunch of users' do
      allow_any_instantiation_of(Account.default).to receive(:open_registration?).and_return(true)
      course_with_teacher_logged_in(:active_all => true)

      user_list = [{'email' => 'example1@example.com'}, {'email' => 'example2@example.com', 'name' => 'Hurp Durp'}]

      post 'invite_users', params: {:course_id => @course.id, :users => user_list}
      expect(response).to be_success
      json = JSON.parse(response.body)
      expect(json['invited_users'].count).to eq 2

      new_user1 = User.where(:name => 'example1@example.com').first
      new_user2 = User.where(:name => 'Hurp Durp').first
      expect(json['invited_users'].map{|u| u['id']}).to match_array([new_user1.id, new_user2.id])
      expect(json['invited_users'].map{|u| u['user_token']}).to match_array([new_user1.token, new_user2.token])
    end

    it 'checks for pre-existing users' do
      existing_user = user_with_pseudonym(:active_all => true, :username => "example1@example.com")

      allow_any_instantiation_of(Account.default).to receive(:open_registration?).and_return(true)
      course_with_teacher_logged_in(:active_all => true)

      user_list = [{'email' => 'example1@example.com'}]

      post 'invite_users', params: {:course_id => @course.id, :users => user_list}
      expect(response).to be_success

      json = JSON.parse(response.body)
      expect(json['invited_users']).to be_empty
      expect(json['errored_users'].count).to eq 1
      expect(json['errored_users'].first['existing_users'].first['user_id']).to eq existing_user.id
      expect(json['errored_users'].first['existing_users'].first['user_token']).to eq existing_user.token
    end
  end

  describe "#user_dashboard" do
    context "with student planner feature enabled" do
      before(:once) do
        @account = Account.default
        @account.enable_feature! :student_planner
      end

      it "sets ENV.STUDENT_PLANNER_ENABLED to false when user has no student enrollments" do
        user_factory(active_all: true)
        user_session(@user)
        @current_user = @user
        get 'user_dashboard'
        expect(assigns[:js_env][:STUDENT_PLANNER_ENABLED]).to be_falsey
      end

      it "sets ENV.STUDENT_PLANNER_ENABLED to true when user has a student enrollment" do
        course_with_student_logged_in(active_all: true)
        @current_user = @user
        get 'user_dashboard'
        expect(assigns[:js_env][:STUDENT_PLANNER_ENABLED]).to be_truthy
      end

      it "sets ENV.STUDENT_PLANNER_COURSES" do
        course_with_student_logged_in(active_all: true)
        @current_user = @user
        get 'user_dashboard'
        courses = assigns[:js_env][:STUDENT_PLANNER_COURSES]
        expect(courses.map {|c| c[:id]}).to eq [@course.id]
      end

      it "sets ENV.STUDENT_PLANNER_GROUPS" do
        course_with_student_logged_in(active_all: true)
        @current_user = @user
        group = @account.groups.create! :name => 'Account group'
        group.add_user(@current_user, 'accepted', true)
        get 'user_dashboard'
        groups = assigns[:js_env][:STUDENT_PLANNER_GROUPS]
        expect(groups.map {|g| g[:id]}).to eq [group.id]
      end

    end
  end

end
