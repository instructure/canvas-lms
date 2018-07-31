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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

require 'nokogiri'

describe "security" do

  describe "session fixation" do
    it "should change the cookie session id after logging in" do
      u = user_with_pseudonym :active_user => true,
                              :username => "nobody@example.com",
                              :password => "asdfasdf"
      u.save!

      https!

      get "/login"
      follow_redirect! while response.redirect?
      assert_response :success
      cookie = cookies['_normandy_session']
      expect(cookie).to be_present
      expect(path).to eq "/login/canvas"

      post "/login/canvas", params: {"pseudonym_session[unique_id]" => "nobody@example.com",
                                  "pseudonym_session[password]" => "asdfasdf",
                                  "pseudonym_session[remember_me]" => "1",
                                  "redirect_to_ssl" => "1"}
      follow_redirect! while response.redirect?
      assert_response :success
      expect(request.fullpath).to eql("/?login_success=1")
      new_cookie = cookies['_normandy_session']
      expect(new_cookie).to be_present
      expect(cookie).not_to eql(new_cookie)
    end
  end

  describe "permissions" do
    # if we end up moving the permissions cache to memcache, this test won't be
    # valid anymore and we need some more extensive tests for actual cache
    # invalidation. right now, though, this is the only really valid way to
    # test that we're actually flushing on every request.
    it "should flush the role_override caches on every request" do
      course_with_teacher_logged_in

      get "/courses/#{@course.to_param}/users"
      assert_response :success

      expect(RoleOverride.send(:instance_variable_get, '@cached_permissions')).not_to be_empty
      expect(RoleOverride.send(:class_variable_get, '@@role_override_chain')).not_to be_empty

      get "/dashboard"
      assert_response 301

      # verify the cache is emptied on every request
      expect(RoleOverride.send(:instance_variable_get, '@cached_permissions')).to be_empty
      expect(RoleOverride.send(:class_variable_get, '@@role_override_chain')).to be_empty
    end
  end

  describe 'session cookies' do
    it "should always set the primary cookie to session expiration" do
      # whether they select "stay logged in" or not, the actual session cookie
      # should go away with the user agent session. the secondary
      # pseudonym_credentials cookie will stick around and authenticate them
      # again (there's separate specs for that).
      u = user_with_pseudonym :active_user => true,
                              :username => "nobody@example.com",
                              :password => "asdfasdf"
      u.save!
      https!

      post "/login/canvas", params: {"pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf"}
      assert_response 302
      c = response['Set-Cookie'].lines.grep(/\A_normandy_session=/).first
      expect(c).not_to match(/expires=/)
      reset!
      https!
      post "/login/canvas", params: {"pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf",
        "pseudonym_session[remember_me]" => "1"}
      assert_response 302
      c = response['Set-Cookie'].lines.grep(/\A_normandy_session=/).first
      expect(c).not_to match(/expires=/)
    end

    it "should not return pseudonym_credentials when not remember_me" do
      u = user_with_pseudonym :active_user => true,
                              :username => "nobody@example.com",
                              :password => "asdfasdf"
      u.save!
      https!
      post "/login/canvas", params: {"pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf"}
      assert_response 302
      c1 = response['Set-Cookie'].lines.grep(/\Apseudonym_credentials=/).first
      c2 = response['Set-Cookie'].lines.grep(/\A_normandy_session=/).first
      expect(c1).not_to be_present
      expect(c2).to be_present
    end
  end

  it "should not prepend login json responses with protection" do
    u = user_with_pseudonym :active_user => true,
      :username => "nobody@example.com",
      :password => "asdfasdf"
    u.save!
    post "/login/canvas", params: { "pseudonym_session[unique_id]" => "nobody@example.com",
      "pseudonym_session[password]" => "asdfasdf",
      "pseudonym_session[remember_me]" => "1" },
      headers: { 'HTTP_ACCEPT' => 'application/json' }
    expect(response).to be_successful
    expect(response['Content-Type']).to match(%r"^application/json")
    expect(response.body).not_to match(%r{^while\(1\);})
    json = JSON.parse response.body
    expect(json['pseudonym']['unique_id']).to eq "nobody@example.com"
  end

  it "should prepend GET JSON responses with protection" do
    course_with_teacher_logged_in
    get "/courses.json"
    expect(response).to be_successful
    expect(response['Content-Type']).to match(%r"^application/json")
    expect(response.body).to match(%r{^while\(1\);})
  end

  it "should not prepend GET JSON responses to Accept application/json requests with protection" do
    course_with_teacher_logged_in
    get "/courses.json", headers: { 'HTTP_ACCEPT' => 'application/json' }
    expect(response).to be_successful
    expect(response['Content-Type']).to match(%r"^application/json")
    expect(response.body).not_to match(%r{^while\(1\);})
  end

  it "should not prepend non-GET JSON responses with protection" do
    course_with_teacher_logged_in
    delete "/dashboard/ignore_stream_item/1"
    expect(response).to be_successful
    expect(response['Content-Type']).to match(%r"^application/json")
    expect(response.body).not_to match(%r{^while\(1\);})
  end

  describe "remember me" do
    before do
      @u = user_with_pseudonym :active_all => true,
                              :username => "nobody@example.com",
                              :password => "asdfasdf"
      @u.save!
      @p = @u.pseudonym
      https!
    end

    it "should not remember me when the wrong token is given" do
      # plain persistence_token no longer works
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{@p.persistence_token}"}
      expect(response).to redirect_to("https://www.example.com/login")
      token = SessionPersistenceToken.generate(@p)
      # correct token id, but nonsense uuid and persistence_token
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{token.id}::blah::blah"}
      expect(response).to redirect_to("https://www.example.com/login")
      # correct token id and persistence_token, but nonsense uuid
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{token.id}::#{@p.persistence_token}::blah"}
      expect(response).to redirect_to("https://www.example.com/login")
    end

    it "should login via persistence token when no session exists" do
      token = SessionPersistenceToken.generate(@p)
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"}
      expect(response).to be_successful
      expect(cookies['_normandy_session']).to be_present
      expect(session[:used_remember_me_token]).to be_truthy

      # accessing sensitive areas of canvas require a fresh login
      get "/profile/settings"
      expect(response).to redirect_to login_url
      expect(flash[:warning]).not_to be_empty

      post "/login/canvas", params: {:pseudonym_session => { :unique_id => @p.unique_id, :password => 'asdfasdf' }}
      expect(response).to redirect_to settings_profile_url
      expect(session[:used_remember_me_token]).not_to be_truthy

      follow_redirect!
      expect(response).to be_successful
    end

    it "should not allow login via the same valid token twice" do
      token = SessionPersistenceToken.generate(@p)
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"}
      expect(response).to be_successful
      expect(SessionPersistenceToken.find_by_id(token.id)).to be_nil
      reset!
      https!
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"}
      expect(response).to redirect_to("https://www.example.com/login")
    end

    it "should generate a new valid token when a token is used" do
      token = SessionPersistenceToken.generate(@p)
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"}
      expect(response).to be_successful
      s1 = cookies['_normandy_session']
      expect(s1).to be_present
      cookie = cookies['pseudonym_credentials']
      expect(cookie).to be_present
      token2 = SessionPersistenceToken.find_by_pseudonym_credentials(CGI.unescape(cookie))
      expect(token2).to be_present
      expect(token2).not_to eq token
      expect(token2.pseudonym).to eq @p
      reset!
      https!
      # check that the new token is valid too
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{cookie}"}
      expect(response).to be_successful
      s2 = cookies['_normandy_session']
      expect(s2).to be_present
      expect(s2).not_to eq s1
    end

    it "should generate and return a token when remember_me is checked" do
      post "/login/canvas", params: {"pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf",
        "pseudonym_session[remember_me]" => "1"}
      assert_response 302
      cookie = cookies['pseudonym_credentials']
      expect(cookie).to be_present
      token = SessionPersistenceToken.find_by_pseudonym_credentials(CGI.unescape(cookie))
      expect(token).to be_present
      expect(token.pseudonym).to eq @p

      # verify that the session is now persisting via the session cookie, not
      # using and re-generating a one-time-use pseudonym_credentials token on each request
      get "/"
      expect(cookies['pseudonym_credentials']).to eq cookie
    end

    it "should destroy the token both user agent and server side on logout" do
      expect {
        post "/login/canvas", params: {"pseudonym_session[unique_id]" => "nobody@example.com",
          "pseudonym_session[password]" => "asdfasdf",
          "pseudonym_session[remember_me]" => "1"}
      }.to change(SessionPersistenceToken, :count).by(1)
      c = cookies['pseudonym_credentials']
      expect(c).to be_present

      expect {
        delete "/logout"
      }.to change(SessionPersistenceToken, :count).by(-1)
      expect(cookies['pseudonym_credentials']).not_to be_present
      expect(SessionPersistenceToken.find_by_pseudonym_credentials(CGI.unescape(c))).to be_nil
    end

    it "should allow multiple remember_me tokens for the same user" do
      s1 = open_session
      s1.https!
      s2 = open_session
      s2.https!
      s1.post "/login/canvas", params: {"pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf",
        "pseudonym_session[remember_me]" => "1"}
      c1 = s1.cookies['pseudonym_credentials']
      s2.post "/login/canvas", params: {"pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf",
        "pseudonym_session[remember_me]" => "1"}
      c2 = s2.cookies['pseudonym_credentials']
      expect(c1).not_to eq c2

      s3 = open_session
      s3.https!
      s3.get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{c1}"}
      expect(s3.response).to be_successful
      s3.delete "/logout"
      # make sure c2 can still work
      s4 = open_session
      s4.https!
      s4.get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{c2}"}
      expect(s4.response).to be_successful
    end

    it "should not login if the pseudonym is deleted" do
      token = SessionPersistenceToken.generate(@p)
      @p.destroy
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"}
      expect(response).to redirect_to("https://www.example.com/login")
    end

    it "should not login if the pseudonym.persistence_token gets changed (pw change)" do
      token = SessionPersistenceToken.generate(@p)
      creds = token.pseudonym_credentials
      pers1 = @p.persistence_token
      @p.password = @p.password_confirmation = 'newpass1'
      @p.save!
      pers2 = @p.persistence_token
      expect(pers1).not_to eq pers2
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{creds}"}
      expect(response).to redirect_to("https://www.example.com/login")
    end

    context "sharding" do
      specs_require_sharding

      it "should work for an out-of-shard user" do
        @shard1.activate do
          account = Account.create!
          user_with_pseudonym(:account => account)
        end
        token = SessionPersistenceToken.generate(@pseudonym)
        get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"}
        expect(response).to be_successful
        expect(cookies['_normandy_session']).to be_present
        expect(session[:used_remember_me_token]).to be_truthy
      end
    end
  end

  if Canvas.redis_enabled?
    describe "max login attempts" do
      before do
        Setting.set('login_attempts_total', '2')
        Setting.set('login_attempts_per_ip', '1')
        u = user_with_pseudonym :active_user => true,
          :username => "nobody@example.com",
          :password => "asdfasdf"
        u.save!
      end

      def bad_login(ip)
        post "/login/canvas",
          params: { "pseudonym_session[unique_id]" => "nobody@example.com", "pseudonym_session[password]" => "failboat" },
          headers: { "REMOTE_ADDR" => ip }
        follow_redirect! while response.redirect?
      end

      it "should be limited for the same ip" do
        bad_login("5.5.5.5")
        expect(response.body).to match(/Invalid username/)
        bad_login("5.5.5.5")
        expect(response.body).to match(/Too many failed login attempts/)
        # should still fail
        post "/login/canvas",
          params: { "pseudonym_session[unique_id]" => "nobody@example.com", "pseudonym_session[password]" => "asdfasdf" },
          headers: { "REMOTE_ADDR" => "5.5.5.5" }
        follow_redirect! while response.redirect?
        expect(response.body).to match(/Too many failed login attempts/)
      end

      it "should have a higher limit for other ips" do
        bad_login("5.5.5.5")
        expect(response.body).to match(/Invalid username/)
        bad_login("5.5.5.6") # different IP, so allowed
        expect(response.body).to match(/Invalid username/)
        bad_login("5.5.5.7") # different IP, but too many total failures
        expect(response.body).to match(/Too many failed login attempts/)
        # should still fail
        post "/login/canvas",
          params: { "pseudonym_session[unique_id]" => "nobody@example.com", "pseudonym_session[password]" => "asdfasdf" },
          headers: { "REMOTE_ADDR" => "5.5.5.7" }
        follow_redirect! while response.redirect?
        expect(response.body).to match(/Too many failed login attempts/)
      end

      it "should not block other users with the same ip" do
        bad_login("5.5.5.5")
        expect(response.body).to match(/Invalid username/)

        # schools like to NAT hundreds of people to the same IP, so we don't
        # ever block the IP address as a whole
        user_with_pseudonym(:active_user => true, :username => "second@example.com", :password => "12341234").save!
        post "/login/canvas",
          params: { "pseudonym_session[unique_id]" => "second@example.com", "pseudonym_session[password]" => "12341234" },
          headers:  { "REMOTE_ADDR" => "5.5.5.5" }
        follow_redirect! while response.redirect?
        expect(request.fullpath).to eql("/?login_success=1")
      end

      it "should apply limitations correctly for cross-account logins" do
        account = Account.create!
        allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([account.id])
        @pseudonym.account = account
        @pseudonym.save!
        bad_login("5.5.5.5")
        expect(response.body).to match(/Invalid username/)
        bad_login("5.5.5.6") # different IP, so allowed
        expect(response.body).to match(/Invalid username/)
        bad_login("5.5.5.7") # different IP, but too many total failures
        expect(response.body).to match(/Too many failed login attempts/)
        # should still fail
        post "/login/canvas",
          params: { "pseudonym_session[unique_id]" => "nobody@example.com", "pseudonym_session[password]" => "asdfasdf" },
          headers: { "REMOTE_ADDR" => "5.5.5.5" }
        follow_redirect! while response.redirect?
        expect(response.body).to match(/Too many failed login attempts/)
      end
    end
  end

  it "should only allow user list username resolution if the current user has appropriate rights" do
    u = User.create!(:name => 'test user')
    u.pseudonyms.create!(:unique_id => "A1234567", :account => Account.default)
    @course = Account.default.courses.create!
    @course.offer!
    @teacher = user_factory :active_all => true
    @course.enroll_teacher(@teacher).tap do |e|
      e.workflow_state = 'active'
      e.save!
    end
    @student = user_factory :active_all => true
    @course.enroll_student(@student).tap do |e|
      e.workflow_state = 'active'
      e.save!
    end
    @course.reload

    user_session(@student)
    post "/courses/#{@course.id}/user_lists.json", params: {:user_list => "A1234567, A345678"}
    expect(response).not_to be_success

    user_session(@teacher)
    post "/courses/#{@course.id}/user_lists.json", params: {:user_list => "A1234567, A345678"}
    assert_response :success
    expect(json_parse).to eq({
      "duplicates" => [],
      "errored_users" => [{"address" => "A345678", "details" => "not_found", "type" => "pseudonym"}],
      "users" => [{ "address" => "A1234567", "name" => "test user", "type" => "pseudonym", "user_id" => u.id }]
    })
  end

  describe "user masquerading" do
    before(:each) do
      course_with_teacher
      @teacher = @user

      student_in_course
      @student = @user
      user_with_pseudonym :user => @student, :username => 'student@example.com', :password => 'password'
      @student_pseudonym = @pseudonym

      account_admin_user :account => Account.site_admin
      @admin = @user
      user_with_pseudonym :user => @admin, :username => 'admin@example.com', :password => 'password'
    end

    it "should require confirmation for becoming a user" do
      user_session(@admin, @admin.pseudonyms.first)

      get "/?become_user_id=#{@student.id}"
      assert_response 302
      expect(response.location).to match "/users/#{@student.id}/masquerade$"
      expect(session[:masquerade_return_to]).to eq "/"
      expect(session[:become_user_id]).to be_nil
      expect(assigns['current_user'].id).to eq @admin.id
      expect(assigns['real_current_user']).to be_nil

      follow_redirect!
      assert_response 200
      expect(path).to eq "/users/#{@student.id}/masquerade"
      expect(session[:become_user_id]).to be_nil
      expect(assigns['current_user'].id).to eq @admin.id
      expect(assigns['real_current_user']).to be_nil

      post "/users/#{@student.id}/masquerade"
      assert_response 302
      expect(session[:become_user_id]).to eq @student.id.to_s

      get "/"
      assert_response 200
      expect(session[:become_user_id]).to eq @student.id.to_s
      expect(assigns['current_user'].id).to eq @student.id
      expect(assigns['current_pseudonym']).to eq @student_pseudonym
      expect(assigns['real_current_user'].id).to eq @admin.id
    end

    it "should not allow as_user_id for normal requests" do
      user_session(@admin, @admin.pseudonyms.first)

      get "/?as_user_id=#{@student.id}"
      assert_response 200
      expect(session[:become_user_id]).to be_nil
      expect(assigns['current_user'].id).to eq @admin.id
      expect(assigns['real_current_user']).to be_nil
    end

    it "should not allow non-admins to become other people" do
      user_session(@student, @student.pseudonyms.first)

      get "/?become_user_id=#{@teacher.id}"
      assert_response 200
      expect(session[:become_user_id]).to be_nil
      expect(assigns['current_user'].id).to eq @student.id
      expect(assigns['real_current_user']).to be_nil

      post "/users/#{@teacher.id}/masquerade"
      assert_response 401
      expect(assigns['current_user'].id).to eq @student.id
      expect(session[:become_user_id]).to be_nil
    end

    it "should record real user in page_views" do
      Setting.set('enable_page_views', 'db')
      user_session(@admin, @admin.pseudonyms.first)

      get "/?become_user_id=#{@student.id}"
      assert_response 302
      expect(response.location).to match "/users/#{@student.id}/masquerade$"
      expect(session[:masquerade_return_to]).to eq "/"
      expect(session[:become_user_id]).to be_nil
      expect(assigns['current_user'].id).to eq @admin.id
      expect(assigns['real_current_user']).to be_nil

      follow_redirect!
      assert_response 200
      expect(path).to eq "/users/#{@student.id}/masquerade"
      expect(session[:become_user_id]).to be_nil
      expect(assigns['current_user'].id).to eq @admin.id
      expect(assigns['real_current_user']).to be_nil
      pv1 = PageView.last
      expect(pv1.user_id).to eq @admin.id
      expect(pv1.real_user_id).to be_nil

      post "/users/#{@student.id}/masquerade"
      assert_response 302
      expect(session[:become_user_id]).to eq @student.id.to_s

      get "/"
      assert_response 200
      expect(session[:become_user_id]).to eq @student.id.to_s
      expect(assigns['current_user'].id).to eq @student.id
      expect(assigns['real_current_user'].id).to eq @admin.id
      pv2 = PageView.all.detect{|pv| pv != pv1}
      expect(pv2.user_id).to eq @student.id
      expect(pv2.real_user_id).to eq @admin.id
    end

    it "should remember the destination with an intervening auth" do
      token = SessionPersistenceToken.generate(@admin.pseudonyms.first)
      get "/", headers: {"HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"}
      expect(response).to be_successful
      expect(cookies['_normandy_session']).to be_present
      expect(session[:used_remember_me_token]).to be_truthy

      # accessing sensitive areas of canvas require a fresh login
      get "/conversations?become_user_id=#{@student.id}"
      expect(response).to redirect_to user_masquerade_url(@student)

      follow_redirect!
      expect(response).to redirect_to login_url
      expect(flash[:warning]).not_to be_empty

      post "/login/canvas", params: {:pseudonym_session => { :unique_id => @admin.pseudonyms.first.unique_id, :password => 'password' }}
      expect(response).to redirect_to user_masquerade_url(@student)
      expect(session[:used_remember_me_token]).not_to be_truthy

      post "/users/#{@student.id}/masquerade"
      expect(response).to redirect_to conversations_url

      follow_redirect!
      expect(response).to be_successful
      expect(session[:become_user_id]).to eq @student.id.to_s
    end
  end

  it "should not allow logins to safefiles domains" do
    allow(HostUrl).to receive(:is_file_host?).and_return(true)
    allow(HostUrl).to receive(:default_host).and_return('test.host')
    get "http://files-test.host/login"
    expect(response).to be_redirect
    uri = URI.parse response['Location']
    expect(uri.host).to eq 'test.host'

    allow(HostUrl).to receive(:is_file_host?).and_return(false)
    get "http://test.host/login"
    expect(response).to redirect_to('http://test.host/login/canvas')
  end

  describe "admin permissions" do
    before(:each) do
      @role = custom_account_role('Limited Admin', :account => Account.site_admin)
      account_admin_user(:account => Account.site_admin, :role => @role)
      user_session(@admin)
    end

    def add_permission(permission)
      Account.site_admin.role_overrides.create!(:permission => permission.to_s,
        :role => @role,
        :enabled => true)
    end

    def remove_permission(permission, role)
      Account.default.role_overrides.create!(:permission => permission.to_s,
              :role => role,
              :enabled => false)
    end

    describe "site admin" do
      it "role_overrides" do
        get "/accounts/#{Account.site_admin.id}/settings"
        expect(response).to be_successful
        expect(response.body).not_to match /Permissions/

        get "/accounts/#{Account.site_admin.id}/role_overrides"
        assert_status(401)

        add_permission :manage_role_overrides

        get "/accounts/#{Account.site_admin.id}/role_overrides"
        expect(response).to be_successful

        get "/accounts/#{Account.site_admin.id}/settings"
        expect(response).to be_successful
        expect(response.body).to match /Permissions/
      end
    end

    describe 'root account' do
      it "read_roster" do
        add_permission :view_statistics

        get "/accounts/#{Account.default.id}/users"
        assert_status(401)

        get "/accounts/#{Account.default.id}/settings"
        expect(response).to be_successful

        get "/accounts/#{Account.default.id}/statistics"
        expect(response).to be_successful
        expect(response.body).not_to match /Recently Logged-In Users/

        add_permission :read_roster

        get "/accounts/#{Account.default.id}/users"
        expect(response).to be_successful

        get "/accounts/#{Account.default.id}/settings"
        expect(response).to be_successful

        get "/accounts/#{Account.default.id}/statistics"
        expect(response).to be_successful
        expect(response.body).to match /Recently Logged-In Users/
      end

      it "read_course_list" do
        add_permission :view_statistics

        course_factory

        get "/accounts/#{Account.default.id}/settings"
        expect(response).to be_successful

        get "/accounts/#{Account.default.id}/statistics"
        expect(response).to be_successful
        expect(response.body).not_to match /Recently Started Courses/
        expect(response.body).not_to match /Recently Ended Courses/

        add_permission :read_course_list

        get "/accounts/#{Account.default.id}"
        expect(response).to be_successful
        expect(response.body).to match /Courses/

        get "/accounts/#{Account.default.id}/statistics"
        expect(response).to be_successful
        expect(response.body).to match /Recently Started Courses/
        expect(response.body).to match /Recently Ended Courses/
      end

      it "view_statistics" do
        get "/accounts/#{Account.default.id}/statistics"
        assert_status(401)

        get "/accounts/#{Account.default.id}/settings"
        expect(response).to be_successful
        expect(response.body).not_to match /Statistics/

        add_permission :view_statistics

        get "/accounts/#{Account.default.id}/statistics"
        expect(response).to be_successful

        get "/accounts/#{Account.default.id}/settings"
        expect(response).to be_successful
        expect(response.body).to match /Statistics/
      end

      it "manage_user_notes" do
        Account.default.update_attribute(:enable_user_notes, true)
        course_with_teacher
        student_in_course
        @student.update_account_associations
        @user_note = UserNote.create!(:creator => @teacher, :user => @student)

        get "/accounts/#{Account.default.id}/user_notes"
        assert_status(401)

        get "/accounts/#{Account.default.id}/settings"
        expect(response).to be_successful
        expect(response.body).not_to match /Faculty Journal/

        get "/users/#{@student.id}/user_notes"
        assert_status(401)

        post "/users/#{@student.id}/user_notes"
        assert_status(401)

        get "/users/#{@student.id}/user_notes/#{@user_note.id}"
        assert_status(401)

        delete "/users/#{@student.id}/user_notes/#{@user_note.id}"
        assert_status(401)

        add_permission :manage_user_notes

        get "/accounts/#{Account.default.id}/user_notes"
        expect(response).to be_successful

        get "/accounts/#{Account.default.id}/settings"
        expect(response).to be_successful
        expect(response.body).to match /Faculty Journal/

        get "/users/#{@student.id}/user_notes"
        expect(response).to be_successful

        post "/users/#{@student.id}/user_notes.json"
        expect(response).to be_successful

        get "/users/#{@student.id}/user_notes/#{@user_note.id}.json"
        expect(response).to be_successful

        delete "/users/#{@student.id}/user_notes/#{@user_note.id}.json"
        expect(response).to be_successful
      end

      it "view_jobs" do
        get "/jobs"
        expect(response).to be_redirect

        add_permission :view_jobs

        get "/jobs"
        expect(response).to be_successful
      end
    end

    describe 'course' do
      before (:each) do
        course_factory(active_all: true)
        Account.default.update_attribute(:settings, { :no_enrollments_can_create_courses => false })
      end

      it 'read_as_admin' do
        get "/courses/#{@course.id}"
        expect(response).to be_redirect

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        html = Nokogiri::HTML(response.body)
        expect(html.css('.edit_course_link')).to be_empty
        expect(html.css('#tab-users')).to be_empty
        expect(html.css('#tab-navigation')).to be_empty

        @course.enroll_teacher(@admin).accept!
        @admin.reload

        get "/courses/#{@course.id}"
        expect(response).to be_successful

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        html = Nokogiri::HTML(response.body)
        expect(html.css('#course_form')).not_to be_empty
        expect(html.css('#tab-navigation')).not_to be_empty
      end

      it 'read_roster' do
        get "/courses/#{@course.id}/users"
        assert_status(401)

        get "/courses/#{@course.id}/users/prior"
        assert_status(401)

        get "/courses/#{@course.id}/groups"
        assert_status(401)

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        expect(response.body).not_to match /People/
        html = Nokogiri::HTML(response.body)
        expect(html.css('#tab-users')).to be_empty

        add_permission :read_roster

        get "/courses/#{@course.id}/users"
        expect(response).to be_successful
        expect(response.body).to match /View User Groups/
        expect(response.body).to match /View Prior Enrollments/
        expect(response.body).not_to match /Manage Users/

        get "/courses/#{@course.id}/users/prior"
        expect(response).to be_successful

        get "/courses/#{@course.id}/groups"
        expect(response).to be_successful

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        expect(response.body).to match /People/
      end

      it "manage_students" do
        get "/courses/#{@course.id}/users"
        assert_status(401)

        get "/courses/#{@course.id}/users/prior"
        assert_status(401)

        get "/courses/#{@course.id}/groups"
        assert_status(401)

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        expect(response.body).not_to match /People/

        add_permission :manage_students

        get "/courses/#{@course.id}/users"
        assert_status(401)

        get "/courses/#{@course.id}/groups"
        assert_status(401)

        add_permission :read_roster

        get "/courses/#{@course.id}/users"
        expect(response).to be_successful
        expect(response.body).to match /View User Groups/
        expect(response.body).to match /View Prior Enrollments/

        get "/courses/#{@course.id}/users/prior"
        expect(response).to be_successful

        get "/courses/#{@course.id}/groups"
        expect(response).to be_successful

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        expect(response.body).to match /People/

        @course.tab_configuration = [ { :id => Course::TAB_PEOPLE, :hidden => true } ]
        @course.save!

        # Should still be able to see People tab even if disabled, because we can
        # manage stuff in it
        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        expect(response.body).to match /People/
      end

      it 'view_all_grades' do
        get "/courses/#{@course.id}/grades"
        assert_status(401)

        get "/courses/#{@course.id}/gradebook"
        assert_status(401)

        add_permission :view_all_grades

        get "/courses/#{@course.id}/grades"
        expect(response).to be_redirect

        get "/courses/#{@course.id}/gradebook"
        expect(response).to be_successful
      end

      it 'read_course_content' do
        @course.assignments.create!
        @course.wiki.set_front_page_url!("front-page")
        @course.wiki.front_page.save!
        @course.quizzes.create!
        @course.attachments.create!(:uploaded_data => default_uploaded_data)

        get "/courses/#{@course.id}"
        expect(response).to be_redirect

        get "/courses/#{@course.id}/assignments"
        assert_status(401)

        get "/courses/#{@course.id}/assignments/syllabus"
        assert_status(401)

        get "/courses/#{@course.id}/wiki"
        assert_status(401)

        get "/courses/#{@course.id}/quizzes"
        assert_status(401)

        get "/courses/#{@course.id}/discussion_topics"
        assert_status(401)

        get "/courses/#{@course.id}/files"
        assert_status(401)

        get "/courses/#{@course.id}/copy"
        assert_status(401)

        get "/courses/#{@course.id}/content_exports"
        assert_status(401)

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        html = Nokogiri::HTML(response.body)
        expect(html.css('.section .assignments')).to be_empty
        expect(html.css('.section .syllabus')).to be_empty
        expect(html.css('.section .pages')).to be_empty
        expect(html.css('.section .quizzes')).to be_empty
        expect(html.css('.section .discussions')).to be_empty
        expect(html.css('.section .files')).to be_empty
        expect(response.body).not_to match /Copy this Course/
        expect(response.body).not_to match /Import Course Content/
        expect(response.body).not_to match /Export this Course/

        add_permission :read_course_content
        add_permission :read_roster
        add_permission :read_forum

        get "/courses/#{@course.id}"
        expect(response).to be_successful
        expect(response.body).to match /People/

        @course.tab_configuration = [ { :id => Course::TAB_PEOPLE, :hidden => true } ]
        @course.save!

        get "/courses/#{@course.id}/assignments"
        expect(response).to be_successful
        expect(response.body).to match /People/ # still has read_as_admin rights

        get "/courses/#{@course.id}/assignments/syllabus"
        expect(response).to be_successful

        get "/courses/#{@course.id}/wiki"
        expect(response).to be_successful

        get "/courses/#{@course.id}/quizzes"
        expect(response).to be_successful

        get "/courses/#{@course.id}/discussion_topics"
        expect(response).to be_successful

        get "/courses/#{@course.id}/files"
        expect(response).to be_successful

        get "/courses/#{@course.id}/copy"
        assert_status(401)

        get "/courses/#{@course.id}/content_exports"
        expect(response).to be_successful

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        html = Nokogiri::HTML(response.body)
        expect(html.css('.section .assignments')).not_to be_empty
        expect(html.css('.section .syllabus')).not_to be_empty
        expect(html.css('.section .pages')).not_to be_empty
        expect(html.css('.section .quizzes')).not_to be_empty
        expect(html.css('.section .discussions')).not_to be_empty
        expect(html.css('.section .files')).not_to be_empty
        expect(response.body).not_to match /Copy this Course/
        expect(response.body).not_to match /Import Course Content/
        expect(response.body).to match /Export Course Content/
        expect(response.body).not_to match /Delete this Course/
        expect(response.body).not_to match /End this Course/
        expect(html.css('input#course_account_id')).to be_empty
        expect(html.css('input#course_enrollment_term_id')).to be_empty

        delete "/courses/#{@course.id}"
        assert_status(401)

        delete "/courses/#{@course.id}", params: {:event => 'delete'}
        assert_status(401)

        add_permission :manage_courses

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        expect(response.body).to match /Copy this Course/
        expect(response.body).not_to match /Import Course Content/
        expect(response.body).to match /Export Course Content/
        expect(response.body).to_not match /Delete this Course/

        add_permission :change_course_state

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        expect(response.body).to match /Delete this Course/

        html = Nokogiri::HTML(response.body)
        expect(html.css('#course_account_id')).not_to be_empty
        expect(html.css('#course_enrollment_term_id')).not_to be_empty

        get "/courses/#{@course.id}/copy"
        expect(response).to be_successful

        delete "/courses/#{@course.id}", params: {:event => 'delete'}
        expect(response).to be_redirect

        expect(@course.reload).to be_deleted
      end

      it 'manage_content' do
        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        expect(response.body).not_to match /Import Course Content/

        get "/courses/#{@course.id}/content_migrations"
        assert_status(401)

        add_permission :manage_content

        get "/courses/#{@course.id}/details"
        expect(response).to be_successful
        expect(response.body).to match /Import Course Content/

        get "/courses/#{@course.id}/content_migrations"
        expect(response).to be_successful
      end

      it 'read_reports' do
        student_in_course(:active_all => 1)
        add_permission :read_roster

        get "/courses/#{@course.id}/users/#{@student.id}"
        expect(response).to be_successful
        expect(response.body).not_to match "Access Report"

        get "/courses/#{@course.id}/users/#{@student.id}/usage"
        assert_status(401)

        add_permission :read_reports

        get "/courses/#{@course.id}/users/#{@student.id}"
        expect(response).to be_successful
        expect(response.body).to match "Access Report"

        get "/courses/#{@course.id}/users/#{@student.id}/usage"
        expect(response).to be_successful
      end

      it 'manage_sections' do
        course_with_teacher_logged_in(:active_all => 1)
        remove_permission(:manage_sections, teacher_role)

        get "/courses/#{@course.id}/settings"
        expect(response).to be_successful
        expect(response.body).not_to match 'Add Section'

        post "/courses/#{@course.id}/sections"
        assert_status(401)

        get "/courses/#{@course.id}/sections/#{@course.default_section.id}"
        expect(response).to be_successful

        put "/courses/#{@course.id}/sections/#{@course.default_section.id}"
        assert_status(401)
      end

      it 'change_course_state' do
        course_with_teacher_logged_in(:active_all => 1)
        remove_permission(:change_course_state, teacher_role)

        get "/courses/#{@course.id}/settings"
        expect(response).to be_successful
        expect(response.body).not_to match 'End this Course'

        delete "/courses/#{@course.id}", params: {:event => 'conclude'}
        assert_status(401)
      end

      it 'view_statistics' do
        course_with_teacher_logged_in(:active_all => 1)

        @student = user_factory :active_all => true
        @course.enroll_student(@student).tap do |e|
          e.workflow_state = 'active'
          e.save!
        end

        get "/courses/#{@course.id}/users/#{@student.id}"
        expect(response).to be_successful

        get "/users/#{@student.id}"
        assert_status(401)

        admin = account_admin_user :account => Account.site_admin
        user_session(admin)

        get "/users/#{@student.id}"
        expect(response).to be_successful
      end
    end
  end
end
