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

require File.expand_path(File.dirname(__FILE__) + '/api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe "API Authentication", type: :request do

  before :once do
    @key = DeveloperKey.create!
  end

  before :each do
    @client_id = @key.id
    @client_secret = @key.api_key
    consider_all_requests_local(false)
    enable_forgery_protection
  end

  after do
    consider_all_requests_local(true)
  end

  if Canvas.redis_enabled? # eventually we're going to have to just require redis to run the specs
    it "should require a valid client id" do
      get "/login/oauth2/auth", :response_type => 'code', :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob'
      expect(response).to be_client_error
    end

    it "should require a valid code to get an access_token" do
      post "/login/oauth2/token", :client_id => @client_id, :client_secret => @client_secret, :code => 'asdf'
      expect(response).to be_client_error
    end

    describe "session authentication" do
      before :once do
        user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
        course_with_teacher(:user => @user)
      end

      before :each do
        # Trust the referer
        Account.any_instance.stubs(:trusted_referer?).returns(true)
        post '/login', 'pseudonym_session[unique_id]' => 'test1@example.com', 'pseudonym_session[password]' => 'test123'
      end

       it "should not need developer key when we have an actual application session" do
        expect(response).to redirect_to("http://www.example.com/?login_success=1")
        get "/api/v1/courses.json", {}
        expect(response).to be_success
      end

       it "should have anti-crsf meausre in normal session" do
        get "/api/v1/courses.json", {}
        # because this is a normal application session, the response is prepended
        # with our anti-csrf measure
        json = response.body
        expect(json).to match(%r{^while\(1\);})
        expect(JSON.parse(json.sub(%r{^while\(1\);}, '')).size).to eq 1
      end

      it "should not allow post without authenticity token in application session" do
        post "/api/v1/courses/#{@course.id}/assignments.json",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' },
               :authenticity_token => 'asdf' }
          expect(response.response_code).to eq 401
      end

      it "should allow post with old authenticity token in application session" do
        session[:_csrf_token] = SecureRandom.base64(32)
        CanvasBreachMitigation::MaskingSecrets.stubs(:valid_authenticity_token?).returns(true)
        post "/api/v1/courses/#{@course.id}/assignments.json",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' },
               :authenticity_token => 'mock csrf token' }
        expect(response).to be_success
        expect(@course.assignments.count).to eq 1
      end

      it "should allow post with cookie authenticity token in application session" do
        get "/"
        post "/api/v1/courses/#{@course.id}/assignments.json",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' },
               :authenticity_token => cookies['_csrf_token'] }
        expect(response).to be_success
        expect(@course.assignments.count).to eq 1
      end

      it "should not allow replacing the authenticity token with api_key without basic auth" do
        post "/api/v1/courses/#{@course.id}/assignments.json?api_key=#{@key.api_key}",
             { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } }
        expect(response.response_code).to eq 401
      end
    end

    describe "basic authentication" do
      before :once do
        user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
        course_with_teacher(:user => @user)
      end

      it "should not allow basic auth with api key" do
        get "/api/v1/courses.json?api_key=#{@key.api_key}", {},
            { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('test1@example.com', 'test123') }
        expect(response.response_code).to eq 401
      end
    end

    describe "oauth2 native app flow" do
      def flow(opts = {})
        enable_forgery_protection do
          user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
          course_with_teacher(:user => @user)

          # step 1
          get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob', :purpose => 'fun'
          expect(response).to redirect_to(login_url)

          yield

          # step 3
          expect(response).to be_redirect
          expect(response['Location']).to match(%r{/login/oauth2/confirm$})
          get response['Location']
          expect(response).to render_template("oauth2_provider/confirm")

          post "/login/oauth2/accept", { :authenticity_token => cookies['_csrf_token'] }

          expect(response).to be_redirect
          expect(response['Location']).to match(%r{/login/oauth2/auth\?})
          code = response['Location'].match(/code=([^\?&]+)/)[1]
          expect(code).to be_present

          # we have the code, we can close the browser session
          post "/login/oauth2/token", :client_id => @client_id, :client_secret => @client_secret, :code => code
          expect(response).to be_success
          expect(response.header[content_type_key]).to eq 'application/json; charset=utf-8'
          json = JSON.parse(response.body)
          token = json['access_token']
          expect(json['user']).to eq({ 'id' => @user.id, 'name' => 'test1@example.com' })
          reset!

          # try an api call
          get "/api/v1/courses.json?access_token=1234"
          expect(response.response_code).to eq 401

          get "/api/v1/courses.json?access_token=#{token}"
          expect(response).to be_success
          json = JSON.parse(response.body)
          expect(json.size).to eq 1
          expect(json.first['enrollments']).to eq [{'type' => 'teacher', 'role' => 'TeacherEnrollment', 'role_id' => teacher_role.id, 'enrollment_state' => 'invited'}]
          expect(AccessToken.authenticate(token)).to eq AccessToken.last
          expect(AccessToken.last.purpose).to eq 'fun'

          # post requests should work with nothing but an access token
          post "/api/v1/courses/#{@course.id}/assignments.json?access_token=1234", { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } }
          expect(response.response_code).to eq 401
          post "/api/v1/courses/#{@course.id}/assignments.json?access_token=#{token}", { :assignment => { :name => 'test assignment', :points_possible => '5.3', :grading_type => 'points' } }
          expect(response).to be_success
          expect(@course.assignments.count).to eq 1
          expect(@course.assignments.first.title).to eq 'test assignment'
          expect(@course.assignments.first.points_possible).to eq 5.3
        end
      end

      it "should not prepend the csrf protection even if the post has a session" do
        user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
        post "/login", :pseudonym_session => { :unique_id => 'test1@example.com', :password => 'test123' }
        code = SecureRandom.hex(64)
        code_data = { 'user' => @user.id, 'client_id' => @client_id }
        Canvas.redis.setex("oauth2:#{code}", 1.day, code_data.to_json)
        post "/login/oauth2/token", :client_id => @client_id, :client_secret => @client_secret, :code => code
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(AccessToken.authenticate(json['access_token'])).to eq AccessToken.last
      end

      it "should execute for password/ldap login" do
        flow do
          follow_redirect!
          expect(response).to redirect_to(canvas_login_url)
          Account.any_instance.stubs(:trusted_referer?).returns(true)
          post canvas_login_url, :pseudonym_session => { :unique_id => 'test1@example.com', :password => 'test123' }
        end
      end

      it "should execute for saml login" do
        skip("requires SAML extension") unless AccountAuthorizationConfig::SAML.enabled?
        account_with_saml(account: Account.default)
        flow do
          Onelogin::Saml::Response.any_instance.stubs(:settings=)
          Onelogin::Saml::Response.any_instance.stubs(:logger=)
          Onelogin::Saml::Response.any_instance.stubs(:is_valid?).returns(true)
          Onelogin::Saml::Response.any_instance.stubs(:success_status?).returns(true)
          Onelogin::Saml::Response.any_instance.stubs(:name_id).returns('test1@example.com')
          Onelogin::Saml::Response.any_instance.stubs(:name_qualifier).returns(nil)
          Onelogin::Saml::Response.any_instance.stubs(:session_index).returns(nil)
          Onelogin::Saml::Response.any_instance.stubs(:issuer).returns("saml_entity")
          Onelogin::Saml::Response.any_instance.stubs(:trusted_roots).returns([])

          post 'saml_consume', :SAMLResponse => "foo"
        end
      end

      it "should execute for cas login" do
        flow do
          account = account_with_cas(:account => Account.default)
          # it should *not* redirect to the alternate log_in_url on the config, when doing oauth
          account.authentication_providers.first.update_attribute(:log_in_url, "https://www.example.com/bogus")

          cas = CASClient::Client.new(:cas_base_url => account.authentication_providers.first.auth_base)
          cas.instance_variable_set(:@stub_user, @user)
          def cas.validate_service_ticket(st)
            response = CASClient::ValidationResponse.new("yes\n#{@stub_user.pseudonyms.first.unique_id}\n")
            st.user = response.user
            st.success = response.is_success?
            return st
          end
          CASClient::Client.stubs(:new).returns(cas)

          follow_redirect!
          expect(response).to redirect_to("/login/cas")
          follow_redirect!
          expect(response).to redirect_to(controller.delegated_auth_redirect_uri(cas.add_service_to_login_url(url_for(controller: 'login/cas', action: :new))))

          get "/login/cas", :ticket => 'ST-abcd'
          expect(response).to be_redirect
        end
      end

      it "should not require logging in again, or log out afterwards" do
        course_with_student_logged_in(:active_all => true, :user => user_with_pseudonym)
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob'
        expect(response).to be_redirect
        expect(response['Location']).to match(%r{/login/oauth2/confirm$})
        get response['Location']
        expect(response).to render_template("oauth2_provider/confirm")
        post "/login/oauth2/accept", { :authenticity_token => cookies['_csrf_token'] }
        expect(response).to be_redirect
        expect(response['Location']).to match(%r{/login/oauth2/auth\?})
        code = response['Location'].match(/code=([^\?&]+)/)[1]
        expect(code).to be_present
        get response['Location']
        expect(response).to be_success
        # verify we're still logged in
        get "/courses/#{@course.id}"
        expect(response).to be_success
      end

      it "should redirect with access_denied if the user doesn't accept" do
        course_with_student_logged_in(:active_all => true, :user => user_with_pseudonym)
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob'
        expect(response).to be_redirect
        expect(response['Location']).to match(%r{/login/oauth2/confirm$})
        get response['Location']
        expect(response).to render_template("oauth2_provider/confirm")
        get "/login/oauth2/deny"
        expect(response).to be_redirect
        expect(response['Location']).to match(%r{/login/oauth2/auth\?})
        error = response['Location'].match(%r{error=([^\?&]+)})[1]
        expect(error).to eq "access_denied"
        expect(response['Location']).not_to match(%r{code=})
        get response['Location']
        expect(response).to be_success
      end

      it "should require the correct client secret" do
        # step 1
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => 'urn:ietf:wg:oauth:2.0:oob'
        expect(response).to redirect_to(login_url)

        follow_redirect!
        expect(response).to be_redirect
        follow_redirect!
        expect(response).to be_success

        user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
        course_with_teacher(:user => @user)
        Account.any_instance.stubs(:trusted_referer?).returns(true)
        post "/login", :pseudonym_session => { :unique_id => 'test1@example.com', :password => 'test123' }

        # step 2
        expect(response).to be_redirect
        expect(response['Location']).to match(%r{/login/oauth2/confirm$})
        follow_redirect!
        expect(response).to be_success

        post "/login/oauth2/accept", { :authenticity_token => controller.send(:form_authenticity_token) }

        code = response['Location'].match(/code=([^\?&]+)/)[1]
        expect(code).to be_present

        # we have the code, we can close the browser session
        post "/login/oauth2/token", :client_id => @client_id, :client_secret => 'nuh-uh', :code => code
        expect(response).to be_client_error
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
            expect(response).to redirect_to(login_url)

            follow_redirect!
            expect(response).to be_redirect
            follow_redirect!
            expect(response).to be_success
            Account.any_instance.stubs(:trusted_referer?).returns(true)
            post "/login", :pseudonym_session => { :unique_id => 'test1@example.com', :password => 'test123' }

            # step 3
            expect(response).to be_redirect
            expect(response['Location']).to match(%r{/login/oauth2/confirm$})
            get response['Location']
            expect(response).to render_template("oauth2_provider/confirm")
            post "/login/oauth2/accept", { :authenticity_token => cookies['_csrf_token'] }

            expect(response).to be_redirect
            expect(response['Location']).to match(%r{/login/oauth2/auth\?})
            code = response['Location'].match(/code=([^\?&]+)/)[1]
            expect(code).to be_present

            # we have the code, we can close the browser session
            post "/login/oauth2/token", :client_id => @key.id, :client_secret => @client_secret, :code => code
            expect(response).to be_success
            expect(response.header[content_type_key]).to eq 'application/json; charset=utf-8'
            json = JSON.parse(response.body)
            @token = json['access_token']
            expect(json['user']).to eq({ 'id' => @user.id, 'name' => 'test1@example.com' })
            reset!
          end

          expect(@user.access_tokens.first.shard).to eq Shard.default
          expect(@user.access_tokens.first).to eq AccessToken.authenticate(@token)
        end
      end
    end

    describe "oauth2 web app flow" do
      it "should require the developer key to have a redirect_uri" do
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => "http://www.example.com/oauth2response"
        expect(response).to be_client_error
        expect(response.body).to match /invalid redirect_uri/
      end

      it "should require the redirect_uri domains to match" do
        @key.update_attribute :redirect_uri, 'http://www.example2.com/oauth2response'
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => "http://www.example.com/oauth2response"
        expect(response).to be_client_error
        expect(response.body).to match /invalid redirect_uri/

        @key.update_attribute :redirect_uri, 'http://www.example.com/oauth2response'
        get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => "http://www.example.com/oauth2response"
        expect(response).to be_redirect
      end

      context "untrusted developer key" do
        def login_and_confirm(create_token=false)
          enable_forgery_protection do
            enable_cache do
              user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
              course_with_teacher(:user => @user)
              @key.update_attribute :redirect_uri, 'http://www.example.com/oauth2response'
              if create_token
                @user.access_tokens.create!(developer_key: @key)
              end

              get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => "http://www.example.com/my_uri"
              expect(response).to redirect_to(login_url)

              follow_redirect!
              expect(response).to be_redirect
              follow_redirect!
              expect(response).to be_success
              Account.any_instance.stubs(:trusted_referer?).returns(true)
              post "/login", :pseudonym_session => {:unique_id => 'test1@example.com', :password => 'test123'}

              expect(response).to be_redirect
              expect(response['Location']).to match(%r{/login/oauth2/confirm$})
              get response['Location']
              post "/login/oauth2/accept", {:authenticity_token => cookies['_csrf_token']}

              expect(response).to be_redirect
              expect(response['Location']).to match(%r{http://www.example.com/my_uri?})
              code = response['Location'].match(/code=([^\?&]+)/)[1]
              expect(code).to be_present

              # exchange the code for the token
              post "/login/oauth2/token", {:code => code}, {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(@client_id, @client_secret)}
              expect(response).to be_success
              expect(response.header[content_type_key]).to eq 'application/json; charset=utf-8'
              json = JSON.parse(response.body)
              token = json['access_token']
              reset!

              # try an api call
              get "/api/v1/courses.json?access_token=#{token}"
              expect(response).to be_success
              json = JSON.parse(response.body)
              expect(json.size).to eq 1
              expect(json.first['enrollments']).to eq [{'type' => 'teacher', 'role' => 'TeacherEnrollment', 'role_id' => teacher_role.id, 'enrollment_state' => 'invited'}]
              expect(AccessToken.last).to eq AccessToken.authenticate(token)
            end
          end
        end

        it "should enable the web app flow" do
          login_and_confirm
        end

        it "should enable the web app flow if token already exists" do
          login_and_confirm(true)
        end

        it "Shouldn't allow an account level dev key to auth with other account's user" do
          enable_forgery_protection do
            enable_cache do

              user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
              course_with_teacher(:user => @user)

              # create the dev key on a different account
              account2 = Account.create!
              developer_key = DeveloperKey.create!(account: account2, redirect_uri: "http://www.example.com/my_uri")

              get "/login/oauth2/auth", :response_type => 'code', :client_id => developer_key.id, :redirect_uri => "http://www.example.com/my_uri"
              assert_status(401)

              @user.access_tokens.create!(developer_key: developer_key)

              get "/login/oauth2/auth", :response_type => 'code', :client_id => developer_key.id, :redirect_uri => "http://www.example.com/my_uri"
              assert_status(401)
            end
          end
        end
      end

      context "trusted developer key" do
        def trusted_exchange(create_token=false)
          @key.trusted = true
          @key.save!

          enable_forgery_protection do
            enable_cache do
              user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
              course_with_teacher_logged_in(:user => @user)
              @key.update_attribute :redirect_uri, 'http://www.example.com/oauth2response'
              if create_token
                @user.access_tokens.create!(developer_key: @key)
              end

              get "/login/oauth2/auth", :response_type => 'code', :client_id => @client_id, :redirect_uri => "http://www.example.com/my_uri"
              expect(response).to be_redirect
              expect(response['Location']).to match(%r{http://www.example.com/my_uri?})
              code = response['Location'].match(/code=([^\?&]+)/)[1]
              expect(code).to be_present

              # exchange the code for the token
              post "/login/oauth2/token", {:code => code}, {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(@client_id, @client_secret)}
              expect(response).to be_success
              expect(response.header[content_type_key]).to eq 'application/json; charset=utf-8'
              JSON.parse(response.body)
            end
          end
        end

        it "should give first token" do
          json = trusted_exchange
          expect(json['access_token']).to_not be_nil
        end

        it "should give second token if not force_token_reuse" do
          json = trusted_exchange(true)
          expect(json['access_token']).to_not be_nil
        end

        it "should not give second token if force_token_reuse" do
          @key.force_token_reuse = true
          @key.save!

          json = trusted_exchange(true)
          expect(json['access_token']).to be_nil
        end
      end
    end
  end

  describe "access token" do
    before :once do
      user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
      course_with_teacher(:user => @user)
      @token = @user.access_tokens.create!
      expect(@token.full_token).not_to be_nil
    end

    def check_used
      expect(@token.last_used_at).to be_nil
      yield
      expect(response).to be_success
      expect(@token.reload.last_used_at).not_to be_nil
    end

    it "should allow passing the access token in the query string" do
      check_used { get "/api/v1/courses?access_token=#{@token.full_token}" }
      expect(JSON.parse(response.body).size).to eq 1
    end

    it "should allow passing the access token in the authorization header" do
      check_used { get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" } }
      expect(JSON.parse(response.body).size).to eq 1
    end

    it "should allow passing the access token in the post body" do
      @me = @user
      Account.default.account_users.create!(user: @user)
      u2 = user
      Account.default.pseudonyms.create!(unique_id: 'user', user: u2)
      @user = @me
      check_used do
        post "/api/v1/accounts/#{Account.default.id}/admins", {
          'user_id' => u2.id,
          'access_token' => @token.full_token,
        }
      end
      expect(Account.default.reload.users).to be_include(u2)
    end

    it "should error if the access token is expired or non-existent" do
      get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer blahblah" }
      assert_status(401)
      expect(response['WWW-Authenticate']).to eq %{Bearer realm="canvas-lms"}
      @token.update_attribute(:expires_at, 1.hour.ago)
      get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" }
      assert_status(401)
      expect(response['WWW-Authenticate']).to eq %{Bearer realm="canvas-lms"}
    end

    it "should require an active pseudonym for the access token user" do
      @user.pseudonym.destroy
      get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" }
      assert_status(401)
      expect(response['WWW-Authenticate']).to eq %{Bearer realm="canvas-lms"}
      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to eq "Invalid access token."
    end

    it "should error if no access token is given and authorization is required" do
      get "/api/v1/courses"
      assert_status(401)
      expect(response['WWW-Authenticate']).to eq %{Bearer realm="canvas-lms"}
      json = json_parse
      expect(json["errors"].first["message"]).to eq "user authorization required"
    end

    it "should be able to log out" do
      get "/api/v1/courses?access_token=#{@token.full_token}"
      expect(response).to be_success

      delete "/login/oauth2/token?access_token=#{@token.full_token}"
      expect(response).to be_success

      get "/api/v1/courses?access_token=#{@token.full_token}"
      assert_status(401)
    end

    context "account access" do
      before :once do
        @account = Account.create!

        @sub_account1 = @account.sub_accounts.create!
        @sub_account2 = @account.sub_accounts.create!

        @not_sub_account = Account.create!
        @key = DeveloperKey.create!(:redirect_uri => "http://example.com/a/b", account: @account)
      end

      it "Should allow a token previously linked to a dev key same account to work" do
        enable_forgery_protection do
          enable_cache do
            user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123', account: @account)
            course_with_teacher(:user => @user, account: @account)
            developer_key = DeveloperKey.create!(account: @account, redirect_uri: "http://www.example.com/my_uri")
            @token = @user.access_tokens.create!(:developer_key => developer_key)

            LoadAccount.stubs(:default_domain_root_account).returns(@account)
            check_used {  get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" } }
            expect(JSON.parse(response.body).size).to eq 1
          end
        end
      end

      it "Should allow a token previously linked to a dev key allowed sub account to work" do
        enable_forgery_protection do
          enable_cache do
            user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123', account: @sub_account1)
            course_with_teacher(:user => @user, account: @sub_account1)
            developer_key = DeveloperKey.create!(account: @account, redirect_uri: "http://www.example.com/my_uri")
            @token = @user.access_tokens.create!(:developer_key => developer_key)

            LoadAccount.stubs(:default_domain_root_account).returns(@account)
            check_used {  get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" } }
            expect(JSON.parse(response.body).size).to eq 1
          end
        end
      end

      it "Shouldn't allow a token previously linked to a dev key on foreign account to work" do
        enable_forgery_protection do
          enable_cache do
            user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123', account: @account)
            course_with_teacher(:user => @user, account: @account)
            developer_key = DeveloperKey.create!(account: @not_sub_account, redirect_uri: "http://www.example.com/my_uri")
            @token = @user.access_tokens.create!(:developer_key => developer_key)

            LoadAccount.stubs(:default_domain_root_account).returns(@account)
            get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" }
            assert_status(401)
          end
        end
      end
    end

    context "sharding" do
      specs_require_sharding

      it "should work for an access token from a different shard with the developer key on the default shard" do
        @shard1.activate do
          @account = Account.create!
          user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123', :account => @account)
          course_with_teacher(:user => @user, :account => @account)
          @token = @user.access_tokens.create!(:developer_key => DeveloperKey.default)
          expect(@token.developer_key.shard).to be_default
        end
        LoadAccount.stubs(:default_domain_root_account).returns(@account)

        check_used { get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" } }
        expect(JSON.parse(response.body).size).to eq 1
      end

      it "shouldn't work for an access token from the default shard with the developer key on the different shard" do
        @account = Account.create!
        user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123', :account => @account)
        course_with_teacher(:user => @user, :account => @account)

        @shard1.activate do

          # create the dev key on a different account
          account2 = Account.create!
          developer_key = DeveloperKey.create!(account: account2, redirect_uri: "http://www.example.com/my_uri")
          @token = @user.access_tokens.create!(:developer_key => developer_key)
          expect(@token.developer_key.shard).to be @shard1

        end

        LoadAccount.stubs(:default_domain_root_account).returns(@account)
        get "/api/v1/courses", nil, { 'HTTP_AUTHORIZATION' => "Bearer #{@token.full_token}" }
        assert_status(401)
      end
    end
  end

  describe "as_user_id" do
    before :once do
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
      expect(assigns['current_user']).to eq @student
      expect(assigns['current_pseudonym']).to eq @student_pseudonym
      expect(assigns['real_current_user']).to eq @user
      expect(assigns['real_current_pseudonym']).to eq @pseudonym
      expect(json).to eq({
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
        'locale' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" }
      })

      # as_user_id is ignored if it's not allowed
      @user = @student
      user_with_pseudonym(:user => @user, :username => "nobody2@example.com")
      raw_api_call(:get, "/api/v1/users/self/profile?as_user_id=#{@admin.id}",
               :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => @admin.id.to_param)
      expect(assigns['current_user']).to eq @student
      expect(assigns['real_current_user']).to be_nil
      expect(json).to eq({
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
          'locale' => nil,
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" }
      })

      # as_user_id is ignored if it's blank
      raw_api_call(:get, "/api/v1/users/self/profile?as_user_id=",
               :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => '')
      expect(assigns['current_user']).to eq @student
      expect(assigns['real_current_user']).to be_nil
      expect(json).to eq({
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
          'locale' => nil,
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" }
      })
    end

    it "should allow sis_user_id as an as_user_id" do
      account_admin_user(:account => Account.site_admin)
      user_with_pseudonym(:user => @user)
      @student_pseudonym.update_attribute(:sis_user_id, "1234")

      json = api_call(:get, "/api/v1/users/self/profile?as_user_id=sis_user_id:#{@student.pseudonym.sis_user_id}",
               :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => "sis_user_id:#{@student.pseudonym.sis_user_id.to_param}")
      expect(assigns['current_user']).to eq @student
      expect(assigns['real_current_pseudonym']).to eq @pseudonym
      expect(assigns['real_current_user']).to eq @user
      expect(json).to eq({
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
        'locale' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
      })
    end

    it "should allow integration_id as an as_user_id" do
      account_admin_user(:account => Account.site_admin)
      user_with_pseudonym(:user => @user)
      @student_pseudonym.update_attribute(:integration_id, "1234")
      @student_pseudonym.update_attribute(:sis_user_id, "1234")

      json = api_call(:get, "/api/v1/users/self/profile?as_user_id=sis_integration_id:#{@student.pseudonym.integration_id}",
                      :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => "sis_integration_id:#{@student.pseudonym.integration_id.to_param}")
      expect(assigns['current_user']).to eq @student
      expect(assigns['real_current_pseudonym']).to eq @pseudonym
      expect(assigns['real_current_user']).to eq @user
      expect(json).to eq({
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
          'locale' => nil,
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
      })
    end

    it "should not be silent about an unknown as_user_id" do
      account_admin_user(:account => Account.site_admin)
      user_with_pseudonym(:user => @user)

      raw_api_call(:get, "/api/v1/users/self/profile?as_user_id=sis_user_id:bogus",
                   :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => "sis_user_id:bogus")
      assert_status(401)
      expect(JSON.parse(response.body)).to eq({ 'errors' => 'Invalid as_user_id' })
    end

    it "should not allow non-admins to become other people" do
      account_admin_user(:account => Account.site_admin)

      @user = @student
      raw_api_call(:get, "/api/v1/users/self/profile?as_user_id=#{@admin.id}",
                   :controller => "profile", :action => "settings", :user_id => 'self', :format => 'json', :as_user_id => @admin.id.to_param)
      assert_status(401)
      expect(JSON.parse(response.body)).to eq({ 'errors' => 'Invalid as_user_id' })
    end
  end

  describe "CSRF protection" do
    before :once do
      course_with_teacher(:active_all => true)
      @course1 = @course
      course_with_student(:user => @user, :active_all => true)
      @course2 = @course
    end

    it "should not prepend the CSRF protection to API requests" do
      user_with_pseudonym(:user => @user)
      raw_api_call(:get, "/api/v1/users/self/profile",
                      :controller => "profile", :action => "settings", :user_id => "self", :format => "json")
      expect(response).to be_success
      raw_json = response.body
      expect(raw_json).not_to match(%r{^while\(1\);})
      json = JSON.parse(raw_json)
      expect(json['id']).to eq @user.id
    end

    it "should prepend the CSRF protection for API endpoints, when session auth is used" do
      user_with_pseudonym(:active_user => true, :username => 'test1@example.com', :password => 'test123')
      Account.any_instance.stubs(:trusted_referer?).returns(true)
      post "/login", "pseudonym_session[unique_id]" => "test1@example.com",
        "pseudonym_session[password]" => "test123"
      assert_response 302
      get "/api/v1/users/self/profile"
      expect(response).to be_success
      raw_json = response.body
      expect(raw_json).to match(%r{^while\(1\);})
      expect { JSON.parse(raw_json) }.to raise_error
      json = JSON.parse(raw_json.sub(%r{^while\(1\);}, ''))
      expect(json['id']).to eq @user.id
    end
  end
end
