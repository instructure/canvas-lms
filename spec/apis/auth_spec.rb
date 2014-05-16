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

require File.expand_path(File.dirname(__FILE__) + '/api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe "API Authentication", type: :request do

  before do
    @key = DeveloperKey.create!
    @client_id = @key.id
    @client_secret = @key.api_key
    consider_all_requests_local(false)
    enable_forgery_protection
  end

  after do
    consider_all_requests_local(true)
  end

  context "sharding" do
    specs_require_sharding

    it "should use developer key + basic auth access on the default shard from a different shard" do
      @shard1.activate do
        @account = Account.create!
        # this will continue to be supported until we notify api users and explicitly phase it out
        user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123', :account => @account)
        course_with_teacher(:user => @user, :account => @account)
      end
      LoadAccount.stubs(:default_domain_root_account).returns(@account)

      get "/api/v1/courses.json"
      response.response_code.should == 401
      get "/api/v1/courses.json?api_key=#{@key.api_key}"
      response.response_code.should == 401
      get "/api/v1/courses.json?api_key=#{@key.api_key}", {}, { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'failboat') }
      response.response_code.should == 401
      get "/api/v1/courses.json", {}, { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'test123') }
      response.should be_success
      get "/api/v1/courses.json?api_key=#{@key.api_key}", {}, { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'test123') }
      response.should be_success
    end
  end

  if Canvas.redis_enabled? # eventually we're going to have to just require redis to run the specs

    it "should require a valid client id" do
      get "/login/oauth2/auth", :response_type => 'code', :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob'
      response.should be_client_error
    end

    it "should require a valid code to get an access_token" do
      post "/login/oauth2/token", :client_id => @client_id, :client_secret => @client_secret, :code => 'asdf'
      response.should be_client_error
    end

    describe "should continue to allow developer key + basic auth access" do
      # this will continue to be supported until we notify api users and explicitly phase it out
      before do
        user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
        course_with_teacher(:user => @user)
        post '/login', 'pseudonym_session[unique_id]' => 'test1@example.com', 'pseudonym_session[password]' => 'test123'
      end

      it "should allow basic auth" do
        get "/api/v1/courses.json"
        response.should be_success
        get "/api/v1/courses.json?api_key=#{@key.api_key}", {},
            { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'failboat') }
        response.response_code.should == 401
        get "/api/v1/courses.json", {},
            { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'test123') }
        response.should be_success
      end

      it "should allow basic auth with api key" do

        get "/api/v1/courses.json?api_key=#{@key.api_key}", {},
            { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'test123') }
        response.should be_success
      end

      it "should not need developer key when we have an actual application session" do
        response.should redirect_to("http://www.example.com/?login_success=1")
        get "/api/v1/courses.json", {}
        response.should be_success
      end

      it "should have anti-crsf meausre in normal session" do
        get "/api/v1/courses.json", {}
        # because this is a normal application session, the response is prepended
        # with our anti-csrf measure
        json = response.body
        json.should match(%r{^while\(1\);})
        JSON.parse(json.sub(%r{^while\(1\);}, '')).size.should == 1
      end

      it "should fail without api key" do
        post "/api/v1/courses/#{@course.id}/assignments.json",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } }
        response.response_code.should == 401
        post "/api/v1/courses/#{@course.id}/assignments.json",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } },
             { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'test123') }
        response.response_code.should == 401
      end

      it "should allow post with api key and basic auth" do
        post "/api/v1/courses/#{@course.id}/assignments.json?api_key=#{@key.api_key}",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } },
             { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'test123') }
        response.should be_success
        @course.assignments.count.should == 1
        @course.assignments.first.title.should == 'test assignment'
        @course.assignments.first.points_possible.should == 5.3
      end

      it "should not allow post without authenticity token in application session" do
        post "/api/v1/courses/#{@course.id}/assignments.json",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' },
               :authenticity_token => 'asdf' }
          response.response_code.should == 401
      end

      it "should allow post with authenticity token in application session" do
        get "/"
        post "/api/v1/courses/#{@course.id}/assignments.json",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' },
               :authenticity_token => session[:_csrf_token] }
        response.should be_success
        @course.assignments.count.should == 1
      end

      it "should not allow replacing the authenticity token with api_key without basic auth" do
        post "/api/v1/courses/#{@course.id}/assignments.json?api_key=#{@key.api_key}",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } }
        response.response_code.should == 401
      end

      it "should allow replacing the authenticity token with api_key when basic auth is correct" do
        post "/api/v1/courses/#{@course.id}/assignments.json?api_key=#{@key.api_key}",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } },
             { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'badpass') }
        response.response_code.should == 401
        post "/api/v1/courses/#{@course.id}/assignments.json?api_key=#{@key.api_key}",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } },
             { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'test123') }
        response.should be_success
      end
    end

    describe "oauth2 native app flow" do
      def flow(opts = {})
        enable_forgery_protection do
          user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
          course_with_teacher(:user => @user)

          # step 1
          get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob', :purpose => 'fun'
          response.should redirect_to(login_url)

          yield

          # step 3
          response.should be_redirect
          response['Location'].should match(%r{/login/oauth2/confirm$})
          get response['Location']
          response.should render_template("pseudonym_sessions/oauth2_confirm")
          post "/login/oauth2/accept", { :authenticity_token => session[:_csrf_token] }

          response.should be_redirect
          response['Location'].should match(%r{/login/oauth2/auth\?})
          code = response['Location'].match(/code=([^\?&]+)/)[1]
          code.should be_present

          # we have the code, we can close the browser session
          if opts[:basic_auth]
            post "/login/oauth2/token", { :code => code }, { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(@client_id, @client_secret) }
          else
            post "/login/oauth2/token", :client_id => @client_id, :client_secret => @client_secret, :code => code
          end
          response.should be_success
          response.header['content-type'].should == 'application/json; charset=utf-8'
          json = JSON.parse(response.body)
          token = json['access_token']
          json['user'].should == { 'id' => @user.id, 'name' => 'test1@example.com' }
          reset!

          # try an api call
          get "/api/v1/courses.json?access_token=1234"
          response.response_code.should == 401

          get "/api/v1/courses.json?access_token=#{token}"
          response.should be_success
          json = JSON.parse(response.body)
          json.size.should == 1
          json.first['enrollments'].should == [{'type' => 'teacher', 'role' => 'TeacherEnrollment', 'enrollment_state' => 'invited'}]
          AccessToken.authenticate(token).should == AccessToken.last
          AccessToken.last.purpose.should == 'fun'

          # post requests should work with nothing but an access token
          post "/api/v1/courses/#{@course.id}/assignments.json?access_token=1234", { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } }
          response.response_code.should == 401
          post "/api/v1/courses/#{@course.id}/assignments.json?access_token=#{token}", { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } }
          response.should be_success
          @course.assignments.count.should == 1
          @course.assignments.first.title.should == 'test assignment'
          @course.assignments.first.points_possible.should == 5.3
        end
      end

      it "should not prepend the csrf protection even if the post has a session" do
        user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
        post "/login", :pseudonym_session => { :unique_id => 'test1@example.com', :password => 'test123' }
        code = SecureRandom.hex(64)
        code_data = { 'user' => @user.id, 'client_id' => @client_id }
        Canvas.redis.setex("oauth2:#{code}", 1.day, code_data.to_json)
        post "/login/oauth2/token", :client_id => @client_id, :client_secret => @client_secret, :code => code
        response.should be_success
        json = JSON.parse(response.body)
        AccessToken.authenticate(json['access_token']).should == AccessToken.last
      end

      it "should execute for password/ldap login" do
        flow do
          get response['Location']
          response.should be_success
          post "/login", :pseudonym_session => { :unique_id => 'test1@example.com', :password => 'test123' }
        end
      end

      it "should execute for saml login" do
        pending("requires SAML extension") unless AccountAuthorizationConfig.saml_enabled
        ConfigFile.stub('saml', {})
        account = account_with_saml(:account => Account.default)
        flow do
          Onelogin::Saml::Response.any_instance.stubs(:settings=)
          Onelogin::Saml::Response.any_instance.stubs(:logger=)
          Onelogin::Saml::Response.any_instance.stubs(:is_valid?).returns(true)
          Onelogin::Saml::Response.any_instance.stubs(:success_status?).returns(true)
          Onelogin::Saml::Response.any_instance.stubs(:name_id).returns('test1@example.com')
          Onelogin::Saml::Response.any_instance.stubs(:name_qualifier).returns(nil)
          Onelogin::Saml::Response.any_instance.stubs(:session_index).returns(nil)

          get 'saml_consume', :SAMLResponse => "foo"
        end
      end

      it "should execute for cas login" do
        flow do
          account = account_with_cas(:account => Account.default)
          # it should *not* redirect to the alternate log_in_url on the config, when doing oauth
          account.account_authorization_config.update_attribute(:log_in_url, "https://www.example.com/bogus")

          cas = CASClient::Client.new(:cas_base_url => account.account_authorization_config.auth_base)
          cas.instance_variable_set(:@stub_user, @user)
          def cas.validate_service_ticket(st)
            st.response = CASClient::ValidationResponse.new("yes\n#{@stub_user.pseudonyms.first.unique_id}\n")
          end
          CASClient::Client.stubs(:new).returns(cas)

          get response['Location']
          response.should redirect_to(controller.delegated_auth_redirect_uri(cas.add_service_to_login_url(cas_login_url)))

          get '/login', :ticket => 'ST-abcd'
          response.should be_redirect
        end
      end

      it "should not require logging in again, or log out afterwards" do
        course_with_student_logged_in(:active_all => true, :user => user_with_pseudonym)
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob'
        response.should be_redirect
        response['Location'].should match(%r{/login/oauth2/confirm$})
        get response['Location']
        response.should render_template("pseudonym_sessions/oauth2_confirm")
        post "/login/oauth2/accept", { :authenticity_token => session[:_csrf_token] }
        response.should be_redirect
        response['Location'].should match(%r{/login/oauth2/auth\?})
        code = response['Location'].match(/code=([^\?&]+)/)[1]
        code.should be_present
        get response['Location']
        response.should be_success
        # verify we're still logged in
        get "/courses/#{@course.id}"
        response.should be_success
      end

      it "should redirect with access_denied if the user doesn't accept" do
        course_with_student_logged_in(:active_all => true, :user => user_with_pseudonym)
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob'
        response.should be_redirect
        response['Location'].should match(%r{/login/oauth2/confirm$})
        get response['Location']
        response.should render_template("pseudonym_sessions/oauth2_confirm")
        get "/login/oauth2/deny"
        response.should be_redirect
        response['Location'].should match(%r{/login/oauth2/auth\?})
        error = response['Location'].match(%r{error=([^\?&]+)})[1]
        error.should == "access_denied"
        response['Location'].should_not match(%r{code=})
        get response['Location']
        response.should be_success
      end

      it "should allow http basic auth for the app auth" do
        flow(:basic_auth => true) do
          get response['Location']
          response.should be_success
          post "/login", :pseudonym_session => { :unique_id => 'test1@example.com', :password => 'test123' }
        end
      end

      it "should require the correct client secret" do
        # step 1
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob'
        response.should redirect_to(login_url)

        follow_redirect!
        response.should be_success

        user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
        course_with_teacher(:user => @user)
        post "/login", :pseudonym_session => { :unique_id => 'test1@example.com', :password => 'test123' }

        # step 2
        response.should be_redirect
        response['Location'].should match(%r{/login/oauth2/confirm$})
        follow_redirect!
        response.should be_success

        post "/login/oauth2/accept", { :authenticity_token => controller.send(:form_authenticity_token) }

        code = response['Location'].match(/code=([^\?&]+)/)[1]
        code.should be_present

        # we have the code, we can close the browser session
        post "/login/oauth2/token", :client_id => @client_id, :client_secret => 'nuh-uh', :code => code
        response.should be_client_error
      end

      context "sharding" do
        specs_require_sharding

        it "should create the access token on the same shard as the user" do
          user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')

          @shard1.activate do
            account = Account.create!
            LoadAccount.stubs(:default_domain_root_account).returns(account)
            account.stubs(:trusted_account_ids).returns([Account.default.id])

            # step 1
            get "/login/oauth2/auth", :response_type => 'code', :client_id => @key.id, :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob'
            response.should redirect_to(login_url)

            get response['Location']
            response.should be_success
            post "/login", :pseudonym_session => { :unique_id => 'test1@example.com', :password => 'test123' }

            # step 3
            response.should be_redirect
            response['Location'].should match(%r{/login/oauth2/confirm$})
            get response['Location']
            response.should render_template("pseudonym_sessions/oauth2_confirm")
            post "/login/oauth2/accept", { :authenticity_token => session[:_csrf_token] }

            response.should be_redirect
            response['Location'].should match(%r{/login/oauth2/auth\?})
            code = response['Location'].match(/code=([^\?&]+)/)[1]
            code.should be_present

            # we have the code, we can close the browser session
            post "/login/oauth2/token", :client_id => @key.id, :client_secret => @client_secret, :code => code
            response.should be_success
            response.header['content-type'].should == 'application/json; charset=utf-8'
            json = JSON.parse(response.body)
            @token = json['access_token']
            json['user'].should == { 'id' => @user.id, 'name' => 'test1@example.com' }
            reset!
          end

          @user.access_tokens.first.shard.should == Shard.default
          @user.access_tokens.first.should == AccessToken.authenticate(@token)
        end
      end
    end

    describe "oauth2 web app flow" do
      it "should require the developer key to have a redirect_uri" do
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => "http://www.example.com/oauth2response"
        response.should be_client_error
        response.body.should match /invalid redirect_uri/
      end

      it "should require the redirect_uri domains to match" do
        @key.update_attribute :redirect_uri, 'http://www.example2.com/oauth2response'
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => "http://www.example.com/oauth2response"
        response.should be_client_error
        response.body.should match /invalid redirect_uri/

        @key.update_attribute :redirect_uri, 'http://www.example.com/oauth2response'
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => "http://www.example.com/oauth2response"
        response.should be_redirect
      end

      it "should enable the web app flow" do
        enable_forgery_protection do
          enable_cache do
            user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
            course_with_teacher(:user => @user)
            @key.update_attribute :redirect_uri, 'http://www.example.com/oauth2response'

            get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => "http://www.example.com/my_uri"
            response.should redirect_to(login_url)

            get response['Location']
            response.should be_success
            post "/login", :pseudonym_session => { :unique_id => 'test1@example.com', :password => 'test123' }

            response.should be_redirect
            response['Location'].should match(%r{/login/oauth2/confirm$})
            get response['Location']
            post "/login/oauth2/accept", { :authenticity_token => session[:_csrf_token] }

            response.should be_redirect
            response['Location'].should match(%r{http://www.example.com/my_uri?})
            code = response['Location'].match(/code=([^\?&]+)/)[1]
            code.should be_present

            # exchange the code for the token
            post "/login/oauth2/token", { :code => code }, { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(@client_id, @client_secret) }
            response.should be_success
            response.header['content-type'].should == 'application/json; charset=utf-8'
            json = JSON.parse(response.body)
            token = json['access_token']
            reset!

            # try an api call
            get "/api/v1/courses.json?access_token=#{token}"
            response.should be_success
            json = JSON.parse(response.body)
            json.size.should == 1
            json.first['enrollments'].should == [{'type' => 'teacher', 'role' => 'TeacherEnrollment', 'enrollment_state' => 'invited'}]
            AccessToken.last.should == AccessToken.authenticate(token)
          end
        end
      end
    end
  end

  describe "access token" do
    before do
      user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
      course_with_teacher(:user => @user)
      @token = @user.access_tokens.create!
      @token.full_token.should_not be_nil
    end

    def check_used
      @token.last_used_at.should be_nil
      yield
      response.should be_success
      @token.reload.last_used_at.should_not be_nil
    end

    it "should allow passing the access token in the query string" do
      check_used { get "/api/v1/courses?access_token=#{@token.full_token}" }
      JSON.parse(response.body).size.should == 1
    end

    it "should allow passing the access token in the authorization header" do
      check_used { get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" } }
      JSON.parse(response.body).size.should == 1
    end

    it "should allow passing the access token in the post body" do
      @me = @user
      Account.default.add_user(@user)
      u2 = user
      Account.default.pseudonyms.create!(unique_id: 'user', user: u2)
      @user = @me
      check_used do
        post "/api/v1/accounts/#{Account.default.id}/admins", {
          'user_id' => u2.id,
          'access_token' => @token.full_token,
        }
      end
      Account.default.reload.users.should be_include(u2)
    end

    it "should error if the access token is expired or non-existent" do
      get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer blahblah" }
      assert_status(401)
      response['WWW-Authenticate'].should == %{Bearer realm="canvas-lms"}
      @token.update_attribute(:expires_at, 1.hour.ago)
      get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" }
      assert_status(401)
      response['WWW-Authenticate'].should == %{Bearer realm="canvas-lms"}
    end

    it "should require an active pseudonym for the access token user" do
      @user.pseudonym.destroy
      get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" }
      assert_status(401)
      response['WWW-Authenticate'].should == %{Bearer realm="canvas-lms"}
      json = JSON.parse(response.body)
      json['errors'].first['message'].should == "Invalid access token."
    end

    it "should error if no access token is given and authorization is required" do
      get "/api/v1/courses"
      assert_status(401)
      response['WWW-Authenticate'].should == %{Bearer realm="canvas-lms"}
      json = json_parse
      json["errors"].first["message"].should == "user authorization required"
    end

    it "should be able to log out" do
      get "/api/v1/courses?access_token=#{@token.full_token}"
      response.should be_success

      delete "/login/oauth2/token?access_token=#{@token.full_token}"
      response.should be_success

      get "/api/v1/courses?access_token=#{@token.full_token}"
      assert_status(401)
    end

    context "sharding" do
      specs_require_sharding

      it "should work for an access token from a different shard with the developer key on the default shard" do
        @shard1.activate do
          @account = Account.create!
          user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123', :account => @account)
          course_with_teacher(:user => @user, :account => @account)
          @token = @user.access_tokens.create!(:developer_key => DeveloperKey.default)
          @token.developer_key.shard.should be_default
        end
        LoadAccount.stubs(:default_domain_root_account).returns(@account)

        check_used { get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" } }
        JSON.parse(response.body).size.should == 1
      end
    end
  end

  describe "as_user_id" do
    before do
      course_with_teacher(:active_all => true)
      @course1 = @course
      course_with_student(:user => @user, :active_all => true)
      user_with_pseudonym(:user => @student, :username => "blah@example.com")
      @student_pseudonym = @pseudonym
      @course2 = @course
    end

    it "should allow as_user_id" do
      account_admin_user(:account => Account.site_admin)
      user_with_pseudonym(:user => @user)

      json = api_call(:get, "/api/v1/users/self/profile?as_user_id=#{@student.id}",
               :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => @student.id.to_param)
      assigns['current_user'].should == @student
      assigns['current_pseudonym'].should == @student_pseudonym
      assigns['real_current_user'].should == @user
      assigns['real_current_pseudonym'].should == @pseudonym
      json.should == {
        'id' => @student.id,
        'name' => 'User',
        'short_name' => 'User',
        'sortable_name' => 'User',
        'login_id' => "blah@example.com",
        'title' => nil,
        'bio' => nil,
        'primary_email' => "blah@example.com",
        'integration_id' => nil,
        'time_zone' => 'Etc/UTC',
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" }
      }

      # as_user_id is ignored if it's not allowed
      @user = @student
      user_with_pseudonym(:user => @user, :username => "nobody2@example.com")
      raw_api_call(:get, "/api/v1/users/self/profile?as_user_id=#{@admin.id}",
               :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => @admin.id.to_param)
      assigns['current_user'].should == @student
      assigns['real_current_user'].should be_nil
      json.should == {
          'id' => @student.id,
          'name' => 'User',
          'short_name' => 'User',
          'sortable_name' => 'User',
          'login_id' => "blah@example.com",
          'title' => nil,
          'bio' => nil,
          'primary_email' => "blah@example.com",
          'integration_id' => nil,
          'time_zone' => 'Etc/UTC',
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" }
      }

      # as_user_id is ignored if it's blank
      raw_api_call(:get, "/api/v1/users/self/profile?as_user_id=",
               :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => '')
      assigns['current_user'].should == @student
      assigns['real_current_user'].should be_nil
      json.should == {
          'id' => @student.id,
          'name' => 'User',
          'short_name' => 'User',
          'sortable_name' => 'User',
          'login_id' => "blah@example.com",
          'title' => nil,
          'bio' => nil,
          'primary_email' => "blah@example.com",
          'integration_id' => nil,
          'time_zone' => 'Etc/UTC',
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" }
      }
    end

    it "should allow sis_user_id as an as_user_id" do
      account_admin_user(:account => Account.site_admin)
      user_with_pseudonym(:user => @user)
      @student_pseudonym.update_attribute(:sis_user_id, "1234")

      json = api_call(:get, "/api/v1/users/self/profile?as_user_id=sis_user_id:#{@student.pseudonym.sis_user_id}",
               :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => "sis_user_id:#{@student.pseudonym.sis_user_id.to_param}")
      assigns['current_user'].should == @student
      assigns['real_current_pseudonym'].should == @pseudonym
      assigns['real_current_user'].should == @user
      json.should == {
        'id' => @student.id,
        'name' => 'User',
        'short_name' => 'User',
        'sortable_name' => 'User',
        'sis_user_id' => '1234',
        'sis_login_id' => 'blah@example.com',
        'login_id' => "blah@example.com",
        'integration_id' => nil,
        'bio' => nil,
        'title' => nil,
        'primary_email' => "blah@example.com",
        'time_zone' => 'Etc/UTC',
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
      }
    end

    it "should allow integration_id as an as_user_id" do
      account_admin_user(:account => Account.site_admin)
      user_with_pseudonym(:user => @user)
      @student_pseudonym.update_attribute(:integration_id, "1234")
      @student_pseudonym.update_attribute(:sis_user_id, "1234")

      json = api_call(:get, "/api/v1/users/self/profile?as_user_id=sis_integration_id:#{@student.pseudonym.integration_id}",
                      :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => "sis_integration_id:#{@student.pseudonym.integration_id.to_param}")
      assigns['current_user'].should == @student
      assigns['real_current_pseudonym'].should == @pseudonym
      assigns['real_current_user'].should == @user
      json.should == {
          'id' => @student.id,
          'name' => 'User',
          'short_name' => 'User',
          'sortable_name' => 'User',
          'sis_user_id' => '1234',
          'sis_login_id' => 'blah@example.com',
          'login_id' => "blah@example.com",
          'integration_id' => '1234',
          'bio' => nil,
          'title' => nil,
          'primary_email' => "blah@example.com",
          'time_zone' => 'Etc/UTC',
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
      }
    end

    it "should not be silent about an unknown as_user_id" do
      account_admin_user(:account => Account.site_admin)
      user_with_pseudonym(:user => @user)

      raw_api_call(:get, "/api/v1/users/self/profile?as_user_id=sis_user_id:bogus",
                   :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => "sis_user_id:bogus")
      assert_status(401)
      JSON.parse(response.body).should == { 'errors' => 'Invalid as_user_id' }
    end

    it "should not allow non-admins to become other people" do
      account_admin_user(:account => Account.site_admin)

      @user = @student
      raw_api_call(:get, "/api/v1/users/self/profile?as_user_id=#{@admin.id}",
                   :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => @admin.id.to_param)
      assert_status(401)
      JSON.parse(response.body).should == { 'errors' => 'Invalid as_user_id' }
    end
  end

  describe "CSRF protection" do
    before do
      course_with_teacher(:active_all => true)
      @course1 = @course
      course_with_student(:user => @user, :active_all => true)
      @course2 = @course
    end

    it "should not prepend the CSRF protection to API requests" do
      user_with_pseudonym(:user => @user)
      raw_api_call(:get, "/api/v1/users/self/profile",
                      :controller => "profile", :action => "settings", :user_id => "self", :format => "json")
      response.should be_success
      raw_json = response.body
      raw_json.should_not match(%r{^while\(1\);})
      json = JSON.parse(raw_json)
      json['id'].should == @user.id
    end

    it "should not prepend the CSRF protection to HTTP Basic API requests" do
      user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
      get "/api/v1/users/self/profile", {}, { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'test123') }
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
end
