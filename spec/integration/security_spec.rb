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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe "security" do

  describe "session fixation" do
    it "should change the cookie session id after logging in" do
      u = user_with_pseudonym :active_user => true,
                              :username => "nobody@example.com",
                              :password => "asdfasdf"
      u.save!

      https!

      get_via_redirect "/login"
      assert_response :success
      cookie = cookies['_normandy_session']
      cookie.should be_present
      path.should == "/login"

      post_via_redirect "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
                                  "pseudonym_session[password]" => "asdfasdf",
                                  "pseudonym_session[remember_me]" => "1",
                                  "redirect_to_ssl" => "1"
      assert_response :success
      request.fullpath.should eql("/?login_success=1")
      new_cookie = cookies['_normandy_session']
      new_cookie.should be_present
      cookie.should_not eql(new_cookie)
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

      RoleOverride.send(:instance_variable_get, '@cached_permissions').should_not be_empty
      RoleOverride.send(:class_variable_get, '@@role_override_chain').should_not be_empty

      get "/dashboard"
      assert_response 301

      # verify the cache is emptied on every request
      RoleOverride.send(:instance_variable_get, '@cached_permissions').should be_empty
      RoleOverride.send(:class_variable_get, '@@role_override_chain').should be_empty
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

      post "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf"
      assert_response 302
      c = response['Set-Cookie'].lines.grep(/\A_normandy_session=/).first
      c.should_not match(/expires=/)
      reset!
      https!
      post "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf",
        "pseudonym_session[remember_me]" => "1"
      assert_response 302
      c = response['Set-Cookie'].lines.grep(/\A_normandy_session=/).first
      c.should_not match(/expires=/)
    end

    it "should not return pseudonym_credentials when not remember_me" do
      u = user_with_pseudonym :active_user => true,
                              :username => "nobody@example.com",
                              :password => "asdfasdf"
      u.save!
      https!
      post "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf"
      assert_response 302
      c1 = response['Set-Cookie'].lines.grep(/\Apseudonym_credentials=/).first
      c2 = response['Set-Cookie'].lines.grep(/\A_normandy_session=/).first
      c1.should_not be_present
      c2.should be_present
    end
  end

  it "should not prepend login json responses with protection" do
    u = user_with_pseudonym :active_user => true,
      :username => "nobody@example.com",
      :password => "asdfasdf"
    u.save!
    post "/login", { "pseudonym_session[unique_id]" => "nobody@example.com",
      "pseudonym_session[password]" => "asdfasdf",
      "pseudonym_session[remember_me]" => "1" }, { 'HTTP_ACCEPT' => 'application/json' }
    response.should be_success
    response['Content-Type'].should match(%r"^application/json")
    response.body.should_not match(%r{^while\(1\);})
    json = JSON.parse response.body
    json['pseudonym']['unique_id'].should == "nobody@example.com"
  end

  it "should prepend GET JSON responses with protection" do
    course_with_teacher_logged_in
    get "/courses.json"
    response.should be_success
    response['Content-Type'].should match(%r"^application/json")
    response.body.should match(%r{^while\(1\);})
  end

  it "should not prepend GET JSON responses to Accept application/json requests with protection" do
    course_with_teacher_logged_in
    get "/courses.json", nil, { 'HTTP_ACCEPT' => 'application/json' }
    response.should be_success
    response['Content-Type'].should match(%r"^application/json")
    response.body.should_not match(%r{^while\(1\);})
  end

  it "should not prepend non-GET JSON responses with protection" do
    course_with_teacher_logged_in
    delete "/dashboard/ignore_stream_item/1"
    response.should be_success
    response['Content-Type'].should match(%r"^application/json")
    response.body.should_not match(%r{^while\(1\);})
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
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{@p.persistence_token}"
      response.should redirect_to("https://www.example.com/login")
      token = SessionPersistenceToken.generate(@p)
      # correct token id, but nonsense uuid and persistence_token
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{token.id}::blah::blah"
      response.should redirect_to("https://www.example.com/login")
      # correct token id and persistence_token, but nonsense uuid
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{token.id}::#{@p.persistence_token}::blah"
      response.should redirect_to("https://www.example.com/login")
    end

    it "should login via persistence token when no session exists" do
      token = SessionPersistenceToken.generate(@p)
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"
      response.should be_success
      cookies['_normandy_session'].should be_present
      session[:used_remember_me_token].should be_true

      # accessing sensitive areas of canvas require a fresh login
      get "/profile/settings"
      response.should redirect_to login_url
      flash[:warning].should_not be_empty

      post "/login", :pseudonym_session => { :unique_id => @p.unique_id, :password => 'asdfasdf' }
      response.should redirect_to settings_profile_url
      session[:used_remember_me_token].should_not be_true

      follow_redirect!
      response.should be_success
    end

    it "should not allow login via the same valid token twice" do
      token = SessionPersistenceToken.generate(@p)
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"
      response.should be_success
      SessionPersistenceToken.find_by_id(token.id).should be_nil
      reset!
      https!
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"
      response.should redirect_to("https://www.example.com/login")
    end

    it "should generate a new valid token when a token is used" do
      token = SessionPersistenceToken.generate(@p)
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"
      response.should be_success
      s1 = cookies['_normandy_session']
      s1.should be_present
      cookie = cookies['pseudonym_credentials']
      cookie.should be_present
      token2 = SessionPersistenceToken.find_by_pseudonym_credentials(CGI.unescape(cookie))
      token2.should be_present
      token2.should_not == token
      token2.pseudonym.should == @p
      reset!
      https!
      # check that the new token is valid too
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{cookie}"
      response.should be_success
      s2 = cookies['_normandy_session']
      s2.should be_present
      s2.should_not == s1
    end

    it "should generate and return a token when remember_me is checked" do
      post "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf",
        "pseudonym_session[remember_me]" => "1"
      assert_response 302
      cookie = cookies['pseudonym_credentials']
      cookie.should be_present
      token = SessionPersistenceToken.find_by_pseudonym_credentials(CGI.unescape(cookie))
      token.should be_present
      token.pseudonym.should == @p

      # verify that the session is now persisting via the session cookie, not
      # using and re-generating a one-time-use pseudonym_credentials token on each request
      get "/"
      cookies['pseudonym_credentials'].should == cookie
    end

    it "should destroy the token both user agent and server side on logout" do
      expect {
        post "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
          "pseudonym_session[password]" => "asdfasdf",
          "pseudonym_session[remember_me]" => "1"
      }.to change(SessionPersistenceToken, :count).by(1)
      c = cookies['pseudonym_credentials']
      c.should be_present

      expect {
        delete "/logout"
      }.to change(SessionPersistenceToken, :count).by(-1)
      cookies['pseudonym_credentials'].should_not be_present
      SessionPersistenceToken.find_by_pseudonym_credentials(CGI.unescape(c)).should be_nil
    end

    it "should allow multiple remember_me tokens for the same user" do
      s1 = open_session
      s1.https!
      s2 = open_session
      s2.https!
      s1.post "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf",
        "pseudonym_session[remember_me]" => "1"
      c1 = s1.cookies['pseudonym_credentials']
      s2.post "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
        "pseudonym_session[password]" => "asdfasdf",
        "pseudonym_session[remember_me]" => "1"
      c2 = s2.cookies['pseudonym_credentials']
      c1.should_not == c2

      s3 = open_session
      s3.https!
      s3.get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{c1}"
      s3.response.should be_success
      s3.delete "/logout"
      # make sure c2 can still work
      s4 = open_session
      s4.https!
      s4.get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{c2}"
      s4.response.should be_success
    end

    it "should not login if the pseudonym is deleted" do
      token = SessionPersistenceToken.generate(@p)
      @p.destroy
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"
      response.should redirect_to("https://www.example.com/login")
    end

    it "should not login if the pseudonym.persistence_token gets changed (pw change)" do
      token = SessionPersistenceToken.generate(@p)
      creds = token.pseudonym_credentials
      pers1 = @p.persistence_token
      @p.password = @p.password_confirmation = 'newpass'
      @p.save!
      pers2 = @p.persistence_token
      pers1.should_not == pers2
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{creds}"
      response.should redirect_to("https://www.example.com/login")
    end

    context "sharding" do
      specs_require_sharding

      it "should work for an out-of-shard user" do
        @shard1.activate do
          account = Account.create!
          user_with_pseudonym(:account => account)
        end
        token = SessionPersistenceToken.generate(@pseudonym)
        get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"
        response.should be_success
        cookies['_normandy_session'].should be_present
        session[:used_remember_me_token].should be_true
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
        post_via_redirect "/login",
          { "pseudonym_session[unique_id]" => "nobody@example.com", "pseudonym_session[password]" => "failboat" },
          { "REMOTE_ADDR" => ip }
      end

      it "should be limited for the same ip" do
        bad_login("5.5.5.5")
        response.body.should match(/Incorrect username/)
        bad_login("5.5.5.5")
        response.body.should match(/Too many failed login attempts/)
        # should still fail
        post_via_redirect "/login",
          { "pseudonym_session[unique_id]" => "nobody@example.com", "pseudonym_session[password]" => "asdfasdf" },
          { "REMOTE_ADDR" => "5.5.5.5" }
        response.body.should match(/Too many failed login attempts/)
      end

      it "should have a higher limit for other ips" do
        bad_login("5.5.5.5")
        response.body.should match(/Incorrect username/)
        bad_login("5.5.5.6") # different IP, so allowed
        response.body.should match(/Incorrect username/)
        bad_login("5.5.5.7") # different IP, but too many total failures
        response.body.should match(/Too many failed login attempts/)
        # should still fail
        post_via_redirect "/login",
          { "pseudonym_session[unique_id]" => "nobody@example.com", "pseudonym_session[password]" => "asdfasdf" },
          { "REMOTE_ADDR" => "5.5.5.7" }
        response.body.should match(/Too many failed login attempts/)
      end

      it "should not block other users with the same ip" do
        bad_login("5.5.5.5")
        response.body.should match(/Incorrect username/)

        # schools like to NAT hundreds of people to the same IP, so we don't
        # ever block the IP address as a whole
        user_with_pseudonym(:active_user => true, :username => "second@example.com", :password => "12341234").save!
        post_via_redirect "/login",
          { "pseudonym_session[unique_id]" => "second@example.com", "pseudonym_session[password]" => "12341234" },
          { "REMOTE_ADDR" => "5.5.5.5" }
        request.fullpath.should eql("/?login_success=1")
      end

      it "should apply limitations correctly for cross-account logins" do
        account = Account.create!
        Account.any_instance.stubs(:trusted_account_ids).returns([account.id])
        @pseudonym.account = account
        @pseudonym.save!
        bad_login("5.5.5.5")
        response.body.should match(/Incorrect username/)
        bad_login("5.5.5.6") # different IP, so allowed
        response.body.should match(/Incorrect username/)
        bad_login("5.5.5.7") # different IP, but too many total failures
        response.body.should match(/Too many failed login attempts/)
        # should still fail
        post_via_redirect "/login",
          { "pseudonym_session[unique_id]" => "nobody@example.com", "pseudonym_session[password]" => "asdfasdf" },
          { "REMOTE_ADDR" => "5.5.5.5" }
        response.body.should match(/Too many failed login attempts/)
      end
    end
  end

  it "should only allow user list username resolution if the current user has appropriate rights" do
    u = User.create!(:name => 'test user')
    u.pseudonyms.create!(:unique_id => "A1234567", :account => Account.default)
    @course = Account.default.courses.create!
    @course.offer!
    @teacher = user :active_all => true
    @course.enroll_teacher(@teacher).tap do |e|
      e.workflow_state = 'active'
      e.save!
    end
    @student = user :active_all => true
    @course.enroll_student(@student).tap do |e|
      e.workflow_state = 'active'
      e.save!
    end
    @course.reload

    user_session(@student)
    post "/courses/#{@course.id}/user_lists.json", :user_list => "A1234567, A345678"
    response.should_not be_success

    user_session(@teacher)
    post "/courses/#{@course.id}/user_lists.json", :user_list => "A1234567, A345678"
    assert_response :success
    json_parse.should == {
      "duplicates" => [],
      "errored_users" => [{"address" => "A345678", "details" => "not_found", "type" => "pseudonym"}],
      "users" => [{ "address" => "A1234567", "name" => "test user", "type" => "pseudonym", "user_id" => u.id }]
    }
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
      response.location.should match "/users/#{@student.id}/masquerade$"
      session[:masquerade_return_to].should == "/"
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @admin.id
      assigns['real_current_user'].should be_nil

      follow_redirect!
      assert_response 200
      path.should == "/users/#{@student.id}/masquerade"
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @admin.id
      assigns['real_current_user'].should be_nil

      post "/users/#{@student.id}/masquerade"
      assert_response 302
      session[:become_user_id].should == @student.id.to_s

      get "/"
      assert_response 200
      session[:become_user_id].should == @student.id.to_s
      assigns['current_user'].id.should == @student.id
      assigns['current_pseudonym'].should == @student_pseudonym
      assigns['real_current_user'].id.should == @admin.id
    end

    it "should not allow as_user_id for normal requests" do
      user_session(@admin, @admin.pseudonyms.first)

      get "/?as_user_id=#{@student.id}"
      assert_response 200
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @admin.id
      assigns['real_current_user'].should be_nil
    end

    it "should not allow non-admins to become other people" do
      user_session(@student, @student.pseudonyms.first)

      get "/?become_user_id=#{@teacher.id}"
      assert_response 200
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @student.id
      assigns['real_current_user'].should be_nil

      post "/users/#{@teacher.id}/masquerade"
      assert_response 401
      assigns['current_user'].id.should == @student.id
      session[:become_user_id].should be_nil
    end

    it "should record real user in page_views" do
      Setting.set('enable_page_views', 'db')
      user_session(@admin, @admin.pseudonyms.first)

      get "/?become_user_id=#{@student.id}"
      assert_response 302
      response.location.should match "/users/#{@student.id}/masquerade$"
      session[:masquerade_return_to].should == "/"
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @admin.id
      assigns['real_current_user'].should be_nil

      follow_redirect!
      assert_response 200
      path.should == "/users/#{@student.id}/masquerade"
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @admin.id
      assigns['real_current_user'].should be_nil
      PageView.last.user_id.should == @admin.id
      PageView.last.real_user_id.should be_nil

      post "/users/#{@student.id}/masquerade"
      assert_response 302
      session[:become_user_id].should == @student.id.to_s

      get "/"
      assert_response 200
      session[:become_user_id].should == @student.id.to_s
      assigns['current_user'].id.should == @student.id
      assigns['real_current_user'].id.should == @admin.id
      PageView.last.user_id.should == @student.id
      PageView.last.real_user_id.should == @admin.id
    end

    it "should remember the destination with an intervening auth" do
      token = SessionPersistenceToken.generate(@admin.pseudonyms.first)
      get "/", {}, "HTTP_COOKIE" => "pseudonym_credentials=#{token.pseudonym_credentials}"
      response.should be_success
      cookies['_normandy_session'].should be_present
      session[:used_remember_me_token].should be_true

      # accessing sensitive areas of canvas require a fresh login
      get "/conversations?become_user_id=#{@student.id}"
      response.should redirect_to user_masquerade_url(@student)

      follow_redirect!
      response.should redirect_to login_url
      flash[:warning].should_not be_empty

      post "/login", :pseudonym_session => { :unique_id => @admin.pseudonyms.first.unique_id, :password => 'password' }
      response.should redirect_to user_masquerade_url(@student)
      session[:used_remember_me_token].should_not be_true

      post "/users/#{@student.id}/masquerade"
      response.should redirect_to conversations_url

      follow_redirect!
      response.should be_success
      session[:become_user_id].should == @student.id.to_s
    end
  end

  it "should not allow logins to safefiles domains" do
    HostUrl.stubs(:is_file_host?).returns(true)
    HostUrl.stubs(:default_host).returns('test.host')
    get "http://files-test.host/login"
    response.should be_redirect
    uri = URI.parse response['Location']
    uri.host.should == 'test.host'

    HostUrl.stubs(:is_file_host?).returns(false)
    get "http://test.host/login"
    response.should be_success
  end

  describe "admin permissions" do
    before(:each) do
      account_admin_user(:account => Account.site_admin, :membership_type => 'Limited Admin')
      user_session(@admin)
    end

    def add_permission(permission)
      Account.site_admin.role_overrides.create!(:permission => permission.to_s,
        :enrollment_type => 'Limited Admin',
        :enabled => true)
    end

    def remove_permission(permission, enrollment_type)
      Account.default.role_overrides.create!(:permission => permission.to_s,
              :enrollment_type => enrollment_type,
              :enabled => false)
    end

    describe "site admin" do
      it "role_overrides" do
        get "/accounts/#{Account.site_admin.id}/settings"
        response.should be_success
        response.body.should_not match /Permissions/

        get "/accounts/#{Account.site_admin.id}/role_overrides"
        assert_status(401)

        add_permission :manage_role_overrides

        get "/accounts/#{Account.site_admin.id}/role_overrides"
        response.should be_success

        get "/accounts/#{Account.site_admin.id}/settings"
        response.should be_success
        response.body.should match /Permissions/
      end
    end

    describe 'root account' do
      it "read_roster" do
        add_permission :view_statistics

        get "/accounts/#{Account.default.id}/users"
        assert_status(401)

        get "/accounts/#{Account.default.id}/settings"
        response.should be_success
        response.body.should_not match /Find A User/

        get "/accounts/#{Account.default.id}/statistics"
        response.should be_success
        response.body.should_not match /Recently Logged-In Users/

        add_permission :read_roster

        get "/accounts/#{Account.default.id}/users"
        response.should be_success

        get "/accounts/#{Account.default.id}/settings"
        response.should be_success
        response.body.should match /Find A User/

        get "/accounts/#{Account.default.id}/statistics"
        response.should be_success
        response.body.should match /Recently Logged-In Users/
      end

      it "read_course_list" do
        add_permission :view_statistics

        course
        get "/accounts/#{Account.default.id}"
        response.should be_redirect

        get "/accounts/#{Account.default.id}/settings"
        response.should be_success
        response.body.should_not match /Course Filtering/
        response.body.should_not match /Find a Course/

        get "/accounts/#{Account.default.id}/statistics"
        response.should be_success
        response.body.should_not match /Recently Started Courses/
        response.body.should_not match /Recently Ended Courses/

        add_permission :read_course_list

        get "/accounts/#{Account.default.id}"
        response.should be_success
        response.body.should match /Courses/
        response.body.should match /Course Filtering/
        response.body.should match /Find a Course/

        get "/accounts/#{Account.default.id}/statistics"
        response.should be_success
        response.body.should match /Recently Started Courses/
        response.body.should match /Recently Ended Courses/
      end

      it "view_statistics" do
        get "/accounts/#{Account.default.id}/statistics"
        assert_status(401)

        get "/accounts/#{Account.default.id}/settings"
        response.should be_success
        response.body.should_not match /Statistics/

        add_permission :view_statistics

        get "/accounts/#{Account.default.id}/statistics"
        response.should be_success

        get "/accounts/#{Account.default.id}/settings"
        response.should be_success
        response.body.should match /Statistics/
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
        response.should be_success
        response.body.should_not match /Faculty Journal/

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
        response.should be_success

        get "/accounts/#{Account.default.id}/settings"
        response.should be_success
        response.body.should match /Faculty Journal/

        get "/users/#{@student.id}/user_notes"
        response.should be_success

        post "/users/#{@student.id}/user_notes.json"
        response.should be_success

        get "/users/#{@student.id}/user_notes/#{@user_note.id}.json"
        response.should be_success

        delete "/users/#{@student.id}/user_notes/#{@user_note.id}.json"
        response.should be_success
      end

      it "view_jobs" do
        get "/jobs"
        response.should be_redirect

        add_permission :view_jobs

        get "/jobs"
        response.should be_success
      end
    end

    describe 'course' do
      before (:each) do
        course(:active_all => 1)
        Account.default.update_attribute(:settings, { :no_enrollments_can_create_courses => false })
      end

      it 'read_as_admin' do
        get "/courses/#{@course.id}"
        response.should be_redirect

        get "/courses/#{@course.id}/details"
        response.should be_success
        html = Nokogiri::HTML(response.body)
        html.css('.edit_course_link').should be_empty
        html.css('#tab-users').should be_empty
        html.css('#tab-navigation').should be_empty

        @course.enroll_teacher(@admin).accept!
        @admin.reload

        get "/courses/#{@course.id}"
        response.should be_success

        get "/courses/#{@course.id}/details"
        response.should be_success
        html = Nokogiri::HTML(response.body)
        html.css('.edit_course_link').should_not be_empty
        html.css('#tab-navigation').should_not be_empty
      end

      it 'read_roster' do
        get "/courses/#{@course.id}/users"
        assert_status(401)

        get "/courses/#{@course.id}/users/prior"
        assert_status(401)

        get "/courses/#{@course.id}/groups"
        assert_status(401)

        get "/courses/#{@course.id}/details"
        response.should be_success
        response.body.should_not match /People/
        html = Nokogiri::HTML(response.body)
        html.css('#tab-users').should be_empty

        add_permission :read_roster

        get "/courses/#{@course.id}/users"
        response.should be_success
        response.body.should match /View User Groups/
        response.body.should match /View Prior Enrollments/
        response.body.should_not match /Manage Users/

        get "/courses/#{@course.id}/users/prior"
        response.should be_success

        get "/courses/#{@course.id}/groups"
        response.should be_success

        get "/courses/#{@course.id}/details"
        response.should be_success
        response.body.should match /People/
      end

      it "manage_students" do
        get "/courses/#{@course.id}/users"
        assert_status(401)

        get "/courses/#{@course.id}/users/prior"
        assert_status(401)

        get "/courses/#{@course.id}/groups"
        assert_status(401)

        get "/courses/#{@course.id}/details"
        response.should be_success
        response.body.should_not match /People/

        add_permission :manage_students

        get "/courses/#{@course.id}/users"
        response.should be_success
        response.body.should_not match /View User Groups/
        response.body.should match /View Prior Enrollments/

        get "/courses/#{@course.id}/users/prior"
        response.should be_success

        get "/courses/#{@course.id}/groups"
        assert_status(401)

        get "/courses/#{@course.id}/details"
        response.should be_success
        response.body.should match /People/

        @course.tab_configuration = [ { :id => Course::TAB_PEOPLE, :hidden => true } ]
        @course.save!

        # Should still be able to see People tab even if disabled, because we can
        # manage stuff in it
        get "/courses/#{@course.id}/details"
        response.should be_success
        response.body.should match /People/
      end

      it 'view_all_grades' do
        get "/courses/#{@course.id}/grades"
        assert_status(401)

        get "/courses/#{@course.id}/gradebook"
        assert_status(401)

        add_permission :view_all_grades

        get "/courses/#{@course.id}/grades"
        response.should be_redirect

        get "/courses/#{@course.id}/gradebook"
        response.should be_success
      end

      it 'read_course_content' do
        @course.assignments.create!
        @course.wiki.front_page.save!
        @course.quizzes.create!
        @course.attachments.create!(:uploaded_data => default_uploaded_data)

        get "/courses/#{@course.id}"
        response.should be_redirect

        get "/courses/#{@course.id}/assignments"
        assert_status(401)

        get "/courses/#{@course.id}/assignments/syllabus"
        assert_status(401)

        get "/courses/#{@course.id}/wiki"
        response.should be_redirect
        follow_redirect!
        response.should be_redirect

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
        response.should be_success
        html = Nokogiri::HTML(response.body)
        html.css('.section .assignments').should be_empty
        html.css('.section .syllabus').should be_empty
        html.css('.section .pages').should be_empty
        html.css('.section .quizzes').should be_empty
        html.css('.section .discussions').should be_empty
        html.css('.section .files').should be_empty
        response.body.should_not match /Copy this Course/
        response.body.should_not match /Import Content into this Course/
        response.body.should_not match /Export this Course/

        add_permission :read_course_content
        add_permission :read_roster
        add_permission :read_forum

        get "/courses/#{@course.id}"
        response.should be_success
        response.body.should match /People/

        @course.tab_configuration = [ { :id => Course::TAB_PEOPLE, :hidden => true } ]
        @course.save!

        get "/courses/#{@course.id}/assignments"
        response.should be_success
        response.body.should_not match /People/

        get "/courses/#{@course.id}/assignments/syllabus"
        response.should be_success

        get "/courses/#{@course.id}/wiki"
        response.should be_redirect

        follow_redirect!
        response.should be_success

        get "/courses/#{@course.id}/quizzes"
        response.should be_success

        get "/courses/#{@course.id}/discussion_topics"
        response.should be_success

        get "/courses/#{@course.id}/files"
        response.should be_success

        get "/courses/#{@course.id}/copy"
        assert_status(401)

        get "/courses/#{@course.id}/content_exports"
        response.should be_success

        get "/courses/#{@course.id}/details"
        response.should be_success
        html = Nokogiri::HTML(response.body)
        html.css('.section .assignments').should_not be_empty
        html.css('.section .syllabus').should_not be_empty
        html.css('.section .pages').should_not be_empty
        html.css('.section .quizzes').should_not be_empty
        html.css('.section .discussions').should_not be_empty
        html.css('.section .files').should_not be_empty
        response.body.should_not match /Copy this Course/
        response.body.should_not match /Import Content into this Course/
        response.body.should match /Export Course Content/
        response.body.should_not match /Delete this Course/
        response.body.should_not match /End this Course/
        html.css('#course_account_id').should be_empty
        html.css('#course_enrollment_term_id').should be_empty

        delete "/courses/#{@course.id}"
        assert_status(401)

        delete "/courses/#{@course.id}", :event => 'delete'
        assert_status(401)

        add_permission :manage_courses

        get "/courses/#{@course.id}/details"
        response.should be_success
        response.body.should match /Copy this Course/
        response.body.should_not match /Import Content into this Course/
        response.body.should match /Export Course Content/
        response.body.should match /Delete this Course/
        html = Nokogiri::HTML(response.body)
        html.css('#course_account_id').should_not be_empty
        html.css('#course_enrollment_term_id').should_not be_empty

        get "/courses/#{@course.id}/copy"
        response.should be_success

        delete "/courses/#{@course.id}", :event => 'delete'
        response.should be_redirect

        @course.reload.should be_deleted
      end

      it 'manage_content' do
        get "/courses/#{@course.id}/details"
        response.should be_success
        response.body.should_not match /Import Content into this Course/

        get "/courses/#{@course.id}/content_migrations"
        assert_status(401)

        add_permission :manage_content

        get "/courses/#{@course.id}/details"
        response.should be_success
        response.body.should match /Import Content into this Course/

        get "/courses/#{@course.id}/content_migrations"
        response.should be_success
      end

      it 'read_reports' do
        student_in_course(:active_all => 1)
        add_permission :read_roster

        get "/courses/#{@course.id}/users/#{@student.id}"
        response.should be_success
        response.body.should_not match "Access Report"

        get "/courses/#{@course.id}/users/#{@student.id}/usage"
        assert_status(401)

        add_permission :read_reports

        get "/courses/#{@course.id}/users/#{@student.id}"
        response.should be_success
        response.body.should match "Access Report"

        get "/courses/#{@course.id}/users/#{@student.id}/usage"
        response.should be_success
      end

      it 'manage_sections' do
        course_with_teacher_logged_in(:active_all => 1)
        remove_permission(:manage_sections, 'TeacherEnrollment')

        get "/courses/#{@course.id}/settings"
        response.should be_success
        response.body.should_not match 'Add Section'

        post "/courses/#{@course.id}/sections"
        assert_status(401)

        get "/courses/#{@course.id}/sections/#{@course.default_section.id}"
        response.should be_success

        put "/courses/#{@course.id}/sections/#{@course.default_section.id}"
        assert_status(401)
      end

      it 'change_course_state' do
        course_with_teacher_logged_in(:active_all => 1)
        remove_permission(:change_course_state, 'TeacherEnrollment')

        get "/courses/#{@course.id}/settings"
        response.should be_success
        response.body.should_not match 'End this Course'

        delete "/courses/#{@course.id}", :event => 'conclude'
        assert_status(401)
      end

      it 'view_statistics' do
        course_with_teacher_logged_in(:active_all => 1)

        @student = user :active_all => true
        @course.enroll_student(@student).tap do |e|
          e.workflow_state = 'active'
          e.save!
        end

        get "/courses/#{@course.id}/users/#{@student.id}"
        response.should be_success

        get "/users/#{@student.id}"
        assert_status(401)

        admin = account_admin_user :account => Account.site_admin
        user_session(admin)

        get "/users/#{@student.id}"
        response.should be_success
      end
    end
  end
end
