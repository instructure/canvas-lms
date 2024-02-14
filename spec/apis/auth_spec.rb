# frozen_string_literal: true

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

require_relative "api_spec_helper"

describe "API Authentication", type: :request do
  before :once do
    @key = DeveloperKey.create!
    enable_developer_key_account_binding!(@key)
  end

  before do
    @client_id = @key.id
    @client_secret = @key.api_key
    enable_forgery_protection
  end

  around do |example|
    consider_all_requests_local(false, &example)
  end

  if Canvas.redis_enabled? # eventually we're going to have to just require redis to run the specs
    it "requires a valid client id" do
      get "/login/oauth2/auth", params: { response_type: "code", redirect_uri: "urn:ietf:wg:oauth:2.0:oob" }
      expect(response).to be_client_error
    end

    it "requires a valid code to get an access_token" do
      post "/login/oauth2/token", params: { client_id: @client_id, client_secret: @client_secret, code: "asdf" }
      expect(response).to be_client_error
    end

    describe "session authentication" do
      before :once do
        user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
        course_with_teacher(user: @user)
      end

      before do
        # Trust the referer
        allow_any_instance_of(Account).to receive(:trusted_referer?).and_return(true)
        post "/login/canvas", params: { "pseudonym_session[unique_id]" => "test1@example.com", "pseudonym_session[password]" => "test1234" }
      end

      it "does not need developer key when we have an actual application session" do
        expect(response).to redirect_to("http://www.example.com/?login_success=1")
        get "/api/v1/courses.json", params: {}
        expect(response).to be_successful
      end

      it "does not allow post without authenticity token in application session" do
        post "/api/v1/courses/#{@course.id}/assignments.json",
             params: { assignment: { name: "test assignment", points_possible: "5.3", grading_type: "points" },
                       authenticity_token: "asdf" }
        expect(response.response_code).to eq 422
      end

      it "allows post with cookie authenticity token in application session" do
        get "/"
        post "/api/v1/courses/#{@course.id}/assignments.json",
             params: { assignment: { name: "test assignment", points_possible: "5.3", grading_type: "points" },
                       authenticity_token: cookies["_csrf_token"] }
        expect(response).to be_successful
        expect(@course.assignments.count).to eq 1
      end

      it "does not allow replacing the authenticity token with api_key without basic auth" do
        post "/api/v1/courses/#{@course.id}/assignments.json?api_key=#{@key.api_key}",
             params: { assignment: { name: "test assignment", points_possible: "5.3", grading_type: "points" } }
        expect(response.response_code).to eq 422
      end
    end

    describe "basic authentication" do
      before :once do
        user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
        course_with_teacher(user: @user)
      end

      it "does not allow basic auth with api key" do
        get "/api/v1/courses.json?api_key=#{@key.api_key}",
            headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("test1@example.com", "test1234") }
        expect(response.response_code).to eq 401
      end
    end

    describe "oauth2 native app flow" do
      def flow
        enable_forgery_protection do
          user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
          course_with_teacher(user: @user)

          # step 1
          get "/login/oauth2/auth", params: { response_type: "code", client_id: @client_id, redirect_uri: "urn:ietf:wg:oauth:2.0:oob", purpose: "fun" }
          expect(response).to redirect_to(login_url)

          yield

          # step 3
          expect(response).to be_redirect
          expect(response["Location"]).to match(%r{/login/oauth2/confirm$})
          get response["Location"]
          expect(response).to render_template("oauth2_provider/confirm")

          post "/login/oauth2/accept", params: { authenticity_token: cookies["_csrf_token"] }

          expect(response).to be_redirect
          expect(response["Location"]).to match(%r{/login/oauth2/auth\?})
          code = response["Location"].match(/code=([^?&]+)/)[1]
          expect(code).to be_present

          # we have the code, we can close the browser session
          post "/login/oauth2/token", params: { client_id: @client_id, client_secret: @client_secret, code: }
          expect(response).to be_successful
          expect(response.header[content_type_key]).to eq "application/json; charset=utf-8"
          json = JSON.parse(response.body)
          token = json["access_token"]
          expect(json["user"]).to eq({ "id" => @user.id, "global_id" => @user.global_id.to_s, "name" => "test1@example.com", "effective_locale" => "en" })
          reset!

          # try an api call
          get "/api/v1/courses.json?access_token=1234"
          expect(response.response_code).to eq 401

          get "/api/v1/courses.json?access_token=#{token}"
          expect(response).to be_successful
          json = JSON.parse(response.body)
          expect(json.size).to eq 1
          expect(json.first["enrollments"]).to eq [{ "type" => "teacher",
                                                     "role" => "TeacherEnrollment",
                                                     "role_id" => teacher_role.id,
                                                     "user_id" => @user.id,
                                                     "enrollment_state" => "invited",
                                                     "limit_privileges_to_course_section" => false }]
          expect(AccessToken.authenticate(token)).to eq AccessToken.last
          expect(AccessToken.last.purpose).to eq "fun"

          # post requests should work with nothing but an access token
          post "/api/v1/courses/#{@course.id}/assignments.json?access_token=1234", params: { assignment: { name: "test assignment", points_possible: "5.3", grading_type: "points" } }
          expect(response.response_code).to eq 401
          post "/api/v1/courses/#{@course.id}/assignments.json?access_token=#{token}", params: { assignment: { name: "test assignment", points_possible: "5.3", grading_type: "points" } }
          expect(response).to be_successful
          expect(@course.assignments.count).to eq 1
          expect(@course.assignments.first.title).to eq "test assignment"
          expect(@course.assignments.first.points_possible).to eq 5.3
        end
      end

      it "does not prepend the csrf protection even if the post has a session" do
        user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
        post "/login/canvas", params: { pseudonym_session: { unique_id: "test1@example.com", password: "test1234" } }
        code = SecureRandom.hex(64)
        code_data = { "user" => @user.id, "client_id" => @client_id }
        Canvas.redis.setex("oauth2:#{code}", 1.day, code_data.to_json)
        post "/login/oauth2/token", params: { client_id: @client_id, client_secret: @client_secret, code: }
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(AccessToken.authenticate(json["access_token"])).to eq AccessToken.last
      end

      it "executes for password/ldap login" do
        flow do
          follow_redirect!
          expect(response).to redirect_to(canvas_login_url)
          allow_any_instance_of(Account).to receive(:trusted_referer?).and_return(true)
          post canvas_login_url, params: { pseudonym_session: { unique_id: "test1@example.com", password: "test1234" } }
        end
      end

      it "executes for saml login" do
        skip("requires SAML extension") unless AuthenticationProvider::SAML.enabled?
        account_with_saml(account: Account.default)
        flow do
          response = SAML2::Response.new
          response.issuer = SAML2::NameID.new("saml_entity")
          response.assertions << (assertion = SAML2::Assertion.new)
          assertion.subject = SAML2::Subject.new
          assertion.subject.name_id = SAML2::NameID.new("test1@example.com")
          allow(SAML2::Bindings::HTTP_POST).to receive(:decode).and_return(
            [response, nil]
          )
          allow_any_instance_of(SAML2::Entity).to receive(:valid_response?)

          post "/login/saml", params: { SAMLResponse: "foo" }
        end
      end

      it "executes for cas login" do
        flow do
          account = account_with_cas(account: Account.default)
          # it should *not* redirect to the alternate log_in_url on the config, when doing oauth
          account.authentication_providers.first.update_attribute(:log_in_url, "https://www.example.com/bogus")

          cas = CASClient::Client.new(cas_base_url: account.authentication_providers.first.auth_base)
          cas.instance_variable_set(:@stub_user, @user)
          def cas.validate_service_ticket(st)
            response = CASClient::ValidationResponse.new("yes\n#{@stub_user.pseudonyms.first.unique_id}\n")
            st.user = response.user
            st.success = response.is_success?
            st
          end
          allow(CASClient::Client).to receive(:new).and_return(cas)

          follow_redirect!
          expect(response).to redirect_to("/login/cas")
          follow_redirect!
          expect(response).to redirect_to(cas.add_service_to_login_url(url_for(controller: "login/cas", action: :new)))

          get "/login/cas", params: { ticket: "ST-abcd" }
          expect(response).to be_redirect
        end
      end

      it "does not require logging in again, or log out afterwards" do
        course_with_student_logged_in(active_all: true, user: user_with_pseudonym)
        get "/login/oauth2/auth", params: { response_type: "code", client_id: @client_id, redirect_uri: "urn:ietf:wg:oauth:2.0:oob" }
        expect(response).to be_redirect
        expect(response["Location"]).to match(%r{/login/oauth2/confirm$})
        get response["Location"]
        expect(response).to render_template("oauth2_provider/confirm")
        post "/login/oauth2/accept", params: { authenticity_token: cookies["_csrf_token"] }
        expect(response).to be_redirect
        expect(response["Location"]).to match(%r{/login/oauth2/auth\?})
        code = response["Location"].match(/code=([^?&]+)/)[1]
        expect(code).to be_present
        get response["Location"]
        expect(response).to be_successful
        # verify we're still logged in
        get "/courses/#{@course.id}"
        expect(response).to be_successful
      end

      it "redirects with access_denied if the user doesn't accept" do
        course_with_student_logged_in(active_all: true, user: user_with_pseudonym)
        get "/login/oauth2/auth", params: { response_type: "code", client_id: @client_id, redirect_uri: "urn:ietf:wg:oauth:2.0:oob" }
        expect(response).to be_redirect
        expect(response["Location"]).to match(%r{/login/oauth2/confirm$})
        get response["Location"]
        expect(response).to render_template("oauth2_provider/confirm")
        get "/login/oauth2/deny"
        expect(response).to be_redirect
        expect(response["Location"]).to match(%r{/login/oauth2/auth\?})
        error = response["Location"].match(/error=([^?&]+)/)[1]
        expect(error).to eq "access_denied"
        expect(response["Location"]).not_to match(/code=/)
        get response["Location"]
        expect(response).to be_successful
      end

      it "requires the correct client secret" do
        # step 1
        get "/login/oauth2/auth", params: { response_type: "code", client_id: @client_id, redirect_uri: "urn:ietf:wg:oauth:2.0:oob" }
        expect(response).to redirect_to(login_url)

        follow_redirect!
        expect(response).to be_redirect
        follow_redirect!
        expect(response).to be_successful

        user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
        course_with_teacher(user: @user)
        allow_any_instance_of(Account).to receive(:trusted_referer?).and_return(true)
        post "/login/canvas", params: { pseudonym_session: { unique_id: "test1@example.com", password: "test1234" } }

        # step 2
        expect(response).to be_redirect
        expect(response["Location"]).to match(%r{/login/oauth2/confirm$})
        follow_redirect!
        expect(response).to be_successful

        post "/login/oauth2/accept", params: { authenticity_token: controller.send(:form_authenticity_token) }

        code = response["Location"].match(/code=([^?&]+)/)[1]
        expect(code).to be_present

        # we have the code, we can close the browser session
        post "/login/oauth2/token", params: { client_id: @client_id, client_secret: "nuh-uh", code: }
        expect(response).to be_client_error
      end

      it "works when the user logs in via a session_token" do
        flow do
          follow_redirect!
          expect(response).to redirect_to(canvas_login_url)
          get root_url, params: { session_token: SessionToken.new(@pseudonym.id) }
        end
      end

      context "sharding" do
        specs_require_sharding

        it "creates the access token on the same shard as the user" do
          user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")

          @shard1.activate do
            account = Account.create!
            allow(LoadAccount).to receive(:default_domain_root_account).and_return(account)
            allow(account).to receive(:trusted_account_ids).and_return([Account.default.id])

            # step 1
            get "/login/oauth2/auth", params: { response_type: "code", client_id: @key.id, redirect_uri: "urn:ietf:wg:oauth:2.0:oob" }
            expect(response).to redirect_to(login_url)

            follow_redirect!
            expect(response).to be_redirect
            follow_redirect!
            expect(response).to be_successful
            allow_any_instance_of(Account).to receive(:trusted_referer?).and_return(true)
            post "/login/canvas", params: { pseudonym_session: { unique_id: "test1@example.com", password: "test1234" } }

            # step 3
            expect(response).to be_redirect
            expect(response["Location"]).to match(%r{/login/oauth2/confirm$})
            get response["Location"]
            expect(response).to render_template("oauth2_provider/confirm")
            post "/login/oauth2/accept", params: { authenticity_token: cookies["_csrf_token"] }

            expect(response).to be_redirect
            expect(response["Location"]).to match(%r{/login/oauth2/auth\?})
            code = response["Location"].match(/code=([^?&]+)/)[1]
            expect(code).to be_present

            # we have the code, we can close the browser session
            post "/login/oauth2/token", params: { client_id: @key.id, client_secret: @client_secret, code: }
            expect(response).to be_successful
            expect(response.header[content_type_key]).to eq "application/json; charset=utf-8"
            json = JSON.parse(response.body)
            @token = json["access_token"]
            expect(json["user"]).to eq({ "id" => @user.id, "global_id" => @user.global_id.to_s, "name" => "test1@example.com", "effective_locale" => "en" })
            reset!
          end

          expect(@user.access_tokens.first.shard).to eq Shard.default
          expect(@user.access_tokens.first).to eq AccessToken.authenticate(@token)
        end
      end
    end

    describe "oauth2 web app flow" do
      it "requires the developer key to have a redirect_uri" do
        get "/login/oauth2/auth", params: { response_type: "code", client_id: @client_id, redirect_uri: "http://www.example.com/oauth2response" }
        expect(response).to be_client_error
        expect(response.body).to match(/redirect_uri/)
      end

      it "requires the redirect_uri domains to match" do
        @key.update_attribute :redirect_uri, "http://www.example2.com/oauth2response"
        get "/login/oauth2/auth", params: { response_type: "code", client_id: @client_id, redirect_uri: "http://www.example.com/oauth2response" }
        expect(response).to be_client_error
        expect(response.body).to match(/redirect_uri/)

        @key.update_attribute :redirect_uri, "http://www.example.com/oauth2response"
        get "/login/oauth2/auth", params: { response_type: "code", client_id: @client_id, redirect_uri: "http://www.example.com/oauth2response" }
        expect(response).to be_redirect
      end

      context "untrusted developer key" do
        def login_and_confirm(create_token = false)
          enable_forgery_protection do
            enable_cache do
              user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
              course_with_teacher(user: @user)
              @key.update_attribute :redirect_uri, "http://www.example.com/oauth2response"
              if create_token
                @user.access_tokens.create!(developer_key: @key)
              end

              get "/login/oauth2/auth", params: { response_type: "code", client_id: @client_id, redirect_uri: "http://www.example.com/my_uri" }
              expect(response).to redirect_to(login_url)

              follow_redirect!
              expect(response).to be_redirect
              follow_redirect!
              expect(response).to be_successful
              allow_any_instance_of(Account).to receive(:trusted_referer?).and_return(true)
              post "/login/canvas", params: { pseudonym_session: { unique_id: "test1@example.com", password: "test1234" } }

              expect(response).to be_redirect
              expect(response["Location"]).to match(%r{/login/oauth2/confirm$})
              get response["Location"]
              post "/login/oauth2/accept", params: { authenticity_token: cookies["_csrf_token"] }

              expect(response).to be_redirect
              expect(response["Location"]).to match(%r{http://www.example.com/my_uri?})
              code = response["Location"].match(/code=([^?&]+)/)[1]
              expect(code).to be_present

              # exchange the code for the token
              post "/login/oauth2/token",
                   params: { code: },
                   headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(@client_id, @client_secret) }
              expect(response).to be_successful
              expect(response.header[content_type_key]).to eq "application/json; charset=utf-8"
              json = JSON.parse(response.body)
              token = json["access_token"]
              reset!

              # try an api call
              get "/api/v1/courses.json?access_token=#{token}"
              expect(response).to be_successful
              json = JSON.parse(response.body)
              expect(json.size).to eq 1
              expect(json.first["enrollments"]).to eq [{ "type" => "teacher",
                                                         "role" => "TeacherEnrollment",
                                                         "role_id" => teacher_role.id,
                                                         "user_id" => @user.id,
                                                         "enrollment_state" => "invited",
                                                         "limit_privileges_to_course_section" => false }]
              expect(AccessToken.last).to eq AccessToken.authenticate(token)
            end
          end
        end

        it "enables the web app flow" do
          login_and_confirm
        end

        it "enables the web app flow if token already exists" do
          login_and_confirm(true)
        end

        it "does not allow an account level dev key to auth with other account's user" do
          enable_forgery_protection do
            enable_cache do
              user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
              course_with_teacher(user: @user)

              # create the dev key on a different account
              account2 = Account.create!
              developer_key = DeveloperKey.create!(account: account2, redirect_uri: "http://www.example.com/my_uri")

              get "/login/oauth2/auth", params: { response_type: "code", client_id: developer_key.id, redirect_uri: "http://www.example.com/my_uri" }
              expect(response).to be_redirect
              expect(response.location).to match(/unauthorized_client/)

              @user.access_tokens.create!(developer_key:)

              get "/login/oauth2/auth", params: { response_type: "code", client_id: developer_key.id, redirect_uri: "http://www.example.com/my_uri" }
              expect(response).to be_redirect
              expect(response.location).to match(/unauthorized_client/)
            end
          end
        end
      end

      context "trusted developer key" do
        def trusted_exchange(create_token = false, userinfo: false)
          @key.trusted = true
          @key.save!

          enable_forgery_protection do
            enable_cache do
              user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
              course_with_teacher_logged_in(user: @user)
              @key.update_attribute :redirect_uri, "http://www.example.com/oauth2response"
              if create_token
                token = @user.access_tokens.create!(developer_key: @key, scopes: userinfo ? ["/auth/userinfo"] : [])
                yield token if block_given?
              end

              params = { response_type: "code", client_id: @client_id, redirect_uri: "http://www.example.com/my_uri" }
              params[:scope] = "/auth/userinfo" if userinfo
              get("/login/oauth2/auth", params:)
              expect(response).to be_redirect
              expect(response["Location"]).to match(%r{http://www.example.com/my_uri?})
              code = response["Location"].match(/code=([^?&]+)/)[1]
              expect(code).to be_present

              # exchange the code for the token
              post "/login/oauth2/token",
                   params: { code: },
                   headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(@client_id, @client_secret) }
              expect(response).to be_successful
              expect(response.header[content_type_key]).to eq "application/json; charset=utf-8"
              JSON.parse(response.body)
            end
          end
        end

        it "gives first token" do
          json = trusted_exchange
          expect(json["access_token"]).to_not be_nil
        end

        it "gives second token if not force_token_reuse" do
          json = trusted_exchange(true)
          expect(json["access_token"]).to_not be_nil
          expect(@user.access_tokens.count).to eq 2
        end

        it "does not give second token if force_token_reuse" do
          @key.force_token_reuse = true
          @key.auto_expire_tokens = false
          @key.save!

          json = trusted_exchange(true) do |token|
            expect_any_instantiation_of(token).to receive(:save).at_least(:once).and_call_original
          end
          expect(json["access_token"]).not_to be_nil
          expect(@user.access_tokens.count).to eq 1
        end

        it "does not regenerate if force_token_reuse with userinfo" do
          @key.force_token_reuse = true
          @key.auto_expire_tokens = false
          @key.save!

          json = trusted_exchange(true, userinfo: true) do |token|
            expect_any_instantiation_of(token).not_to receive(:save)
          end
          expect(json["user"]).not_to be_nil
          expect(@user.access_tokens.count).to eq 1
        end
      end
    end
  end

  describe "InstAccess tokens" do
    include_context "InstAccess setup"

    before :once do
      user_obj = user_with_pseudonym
      course_with_teacher(user: user_obj)
    end

    it "allows API access with a valid InstAccess token" do
      token = InstAccess::Token.for_user(user_uuid: @user.uuid, account_uuid: @user.account.uuid).to_unencrypted_token_string
      get "/api/v1/courses", headers: {
        "HTTP_AUTHORIZATION" => "Bearer #{token}"
      }
      assert_status(200)
      expect(JSON.parse(response.body).size).to eq 1
    end

    it "allows API access for a masquerading user" do
      user = @user
      real_user = user_with_pseudonym
      token = InstAccess::Token.for_user(
        user_uuid: user.uuid,
        account_uuid: user.account.uuid,
        real_user_uuid: real_user.uuid,
        real_user_shard_id: real_user.shard.id
      ).to_unencrypted_token_string

      get "/api/v1/courses", headers: {
        "HTTP_AUTHORIZATION" => "Bearer #{token}"
      }
      assert_status(200)
      expect(JSON.parse(response.body).size).to eq 1
      expect(assigns["current_user"]).to eq user
      expect(assigns["real_current_user"]).to eq real_user
    end

    it "errors if the InstAccess token is expired" do
      token = InstAccess::Token.for_user(user_uuid: @user.uuid, account_uuid: @user.account.uuid).to_unencrypted_token_string
      Timecop.travel(3601) do
        get "/api/v1/courses", headers: {
          "HTTP_AUTHORIZATION" => "Bearer #{token}"
        }
        assert_status(401)
        expect(response.body).to match(/Invalid access token/)
      end
    end

    it "requires an active pseudonym" do
      token = InstAccess::Token.for_user(user_uuid: @user.uuid, account_uuid: @user.account.uuid).to_unencrypted_token_string
      @user.pseudonym.destroy
      get "/api/v1/courses", headers: {
        "HTTP_AUTHORIZATION" => "Bearer #{token}"
      }
      assert_status(401)
      expect(response.body).to match(/Invalid access token/)
    end
  end

  describe "services JWT" do
    include_context "JWT setup"

    before :once do
      user_params = {
        active_user: true,
        username: "test1@example.com",
        password: "test1234"
      }
      user_obj = user_with_pseudonym(user_params)
      course_with_teacher(user: user_obj)
    end

    def wrapped_jwt_from_service(payload = { sub: @user.global_id })
      services_jwt = CanvasSecurity::ServicesJwt.generate(payload, false, symmetric: true)
      payload = {
        iss: "some other service",
        user_token: services_jwt
      }
      wrapped_jwt = Canvas::Security.create_jwt(payload, nil, fake_signing_secret)
      Canvas::Security.base64_encode(wrapped_jwt)
    end

    it "allows API access with a wrapped JWT" do
      get "/api/v1/courses", headers: {
        "HTTP_AUTHORIZATION" => "Bearer #{wrapped_jwt_from_service}"
      }
      assert_status(200)
      expect(JSON.parse(response.body).size).to eq 1
    end

    it "allows access for a JWT masquerading user" do
      token = wrapped_jwt_from_service({
                                         sub: @user.global_id,
                                         masq_sub: User.first.global_id
                                       })
      get "/api/v1/courses", headers: {
        "HTTP_AUTHORIZATION" => "Bearer #{token}"
      }
      assert_status(200)
      expect(JSON.parse(response.body).size).to eq 1
      expect(assigns["current_user"]).to eq @user
      expect(assigns["real_current_user"]).to eq User.first
    end

    it "errors if the JWT is expired" do
      expired_services_jwt = nil
      Timecop.travel(3.days.ago) do
        expired_services_jwt = wrapped_jwt_from_service
      end
      auth_header = { "HTTP_AUTHORIZATION" => "Bearer #{expired_services_jwt}" }
      get "/api/v1/courses", headers: auth_header
      assert_status(401)
      expect(response["WWW-Authenticate"]).to eq %(Bearer realm="canvas-lms")
    end

    it "requires an active pseudonym" do
      CanvasPartman::PartitionManager.create(Auditors::ActiveRecord::PseudonymRecord).ensure_partitions
      @user.pseudonym.destroy
      get "/api/v1/courses", headers: {
        "HTTP_AUTHORIZATION" => "Bearer #{wrapped_jwt_from_service}"
      }
      assert_status(401)
      expect(response.body).to match(/Invalid access token/)
    end

    it "falls through to checking access token for non-JWT but JWT-like strings" do
      get "/api/v1/courses", headers: {
        "HTTP_AUTHORIZATION" => "Bearer 1050~LvwezC5Dd3ZK9CR1lusJTRv24dN0263txia3KF3mU6pDjOv5PaoX8Jv4ikdcvoiy"
      }
      # this error message proves that it ended up throwing an AccessTokenError
      # rather than dying mid-jwt-parse. That can only happen if
      #  1) the JWT is good, but no user/pseudony associated with it
      #  2) load_pseudonym_from_access_token parsed it and decided nobody
      #      was associated with it.
      #  Therefore, this is valid proof that we're hitting the access_token loader
      #   because the token provided above is _not_ a valid JWT

      assert_status(401)
      expect(response.body).to match(/Invalid access token/)
    end
  end

  describe "access token" do
    before :once do
      user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
      course_with_teacher(user: @user)
      @token = @user.access_tokens.create!(developer_key: @key)
    end

    def check_used
      expect(@token.last_used_at).to be_nil
      yield
      expect(response).to be_successful
      expect(@token.reload.last_used_at).not_to be_nil
    end

    it "allows passing the access token in the query string" do
      check_used { get "/api/v1/courses?access_token=#{@token.full_token}" }
      expect(JSON.parse(response.body).size).to eq 1
    end

    it "doesn't allow usage of a suspended pseudonym" do
      @pseudonym.update!(workflow_state: "suspended")

      get "/api/v1/courses?access_token=#{@token.full_token}"
      expect(response).to have_http_status :unauthorized
    end

    it "allows passing the access token in the authorization header" do
      check_used { get "/api/v1/courses", headers: { "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" } }
      expect(JSON.parse(response.body).size).to eq 1
    end

    it "allows passing the access token in the post body" do
      @me = @user
      Account.default.account_users.create!(user: @user)
      u2 = user_factory
      Account.default.pseudonyms.create!(unique_id: "user", user: u2)
      @user = @me
      check_used do
        post "/api/v1/accounts/#{Account.default.id}/admins", params: {
          "user_id" => u2.id,
          "access_token" => @token.full_token,
        }
      end
      expect(Account.default.reload.users).to include(u2)
    end

    it "errors if the access token is expired or non-existent" do
      get "/api/v1/courses", headers: { "HTTP_AUTHORIZATION" => "Bearer blahblah" }
      assert_status(401)
      expect(response["WWW-Authenticate"]).to eq %(Bearer realm="canvas-lms")
      @token.update_attribute(:expires_at, 1.hour.ago)
      get "/api/v1/courses", headers: { "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" }
      assert_status(401)
      expect(response["WWW-Authenticate"]).to eq %(Bearer realm="canvas-lms")
    end

    it "errors if the developer key is inactive" do
      @token.developer_key.deactivate!
      get "/api/v1/courses", headers: { "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" }
      assert_status(401)
      expect(response["WWW-Authenticate"]).to eq %(Bearer realm="canvas-lms")
    end

    it "requires an active pseudonym for the access token user" do
      @user.pseudonym.destroy
      get "/api/v1/courses", headers: { "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" }
      assert_status(401)
      expect(response["WWW-Authenticate"]).to eq %(Bearer realm="canvas-lms")
      json = JSON.parse(response.body)
      expect(json["errors"].first["message"]).to eq "Invalid access token."
    end

    it "errors if no access token is given and authorization is required" do
      get "/api/v1/courses"
      assert_status(401)
      expect(response["WWW-Authenticate"]).to eq %(Bearer realm="canvas-lms")
      json = json_parse
      expect(json["errors"].first["message"]).to eq "user authorization required"
    end

    it "is able to log out" do
      get "/api/v1/courses?access_token=#{@token.full_token}"
      expect(response).to be_successful

      delete "/login/oauth2/token?access_token=#{@token.full_token}"
      expect(response).to be_successful

      get "/api/v1/courses?access_token=#{@token.full_token}"
      assert_status(401)
    end

    context "account access" do
      before :once do
        @account = Account.create!

        @sub_account1 = @account.sub_accounts.create!
        @sub_account2 = @account.sub_accounts.create!

        @not_sub_account = Account.create!
        @key = DeveloperKey.create!(redirect_uri: "http://example.com/a/b", account: @account)
      end

      it "allows a token previously linked to a dev key same account to work" do
        enable_forgery_protection do
          enable_cache do
            user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234", account: @account)
            course_with_teacher(user: @user, account: @account)
            developer_key = DeveloperKey.create!(account: @account, redirect_uri: "http://www.example.com/my_uri")
            enable_developer_key_account_binding!(developer_key)
            @token = @user.access_tokens.create!(developer_key:)

            allow(LoadAccount).to receive(:default_domain_root_account).and_return(@account)
            check_used { get "/api/v1/courses", headers: { "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" } }
            expect(JSON.parse(response.body).size).to eq 1
          end
        end
      end

      it "allows a token previously linked to a dev key allowed sub account to work" do
        enable_forgery_protection do
          enable_cache do
            user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234", account: @sub_account1)
            course_with_teacher(user: @user, account: @sub_account1)
            developer_key = DeveloperKey.create!(account: @account, redirect_uri: "http://www.example.com/my_uri")
            enable_developer_key_account_binding!(developer_key)
            @token = @user.access_tokens.create!(developer_key:)

            allow(LoadAccount).to receive(:default_domain_root_account).and_return(@account)
            check_used { get "/api/v1/courses", headers: { "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" } }
            expect(JSON.parse(response.body).size).to eq 1
          end
        end
      end

      it "does not allow a token previously linked to a dev key on foreign account to work" do
        enable_forgery_protection do
          enable_cache do
            user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234", account: @account)
            course_with_teacher(user: @user, account: @account)
            developer_key = DeveloperKey.create!(account: @not_sub_account, redirect_uri: "http://www.example.com/my_uri")
            @token = @user.access_tokens.create!(developer_key:)

            allow(LoadAccount).to receive(:default_domain_root_account).and_return(@account)
            get "/api/v1/courses", headers: { "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" }
            assert_status(401)
          end
        end
      end
    end

    context "sharding" do
      specs_require_sharding

      it "works for an access token from a different shard with the developer key on the default shard" do
        @shard1.activate do
          @account = Account.create!
          enable_default_developer_key!
          user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234", account: @account)
          course_with_teacher(user: @user, account: @account)
          @token = @user.access_tokens.create!(developer_key: DeveloperKey.default)
          expect(@token.developer_key.shard).to be_default
        end
        allow(LoadAccount).to receive(:default_domain_root_account).and_return(@account)

        check_used { get "/api/v1/courses", headers: { "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" } }
        expect(JSON.parse(response.body).size).to eq 1
      end

      it "does not work for an access token from the default shard with the developer key on the different shard" do
        @account = Account.create!
        user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234", account: @account)
        course_with_teacher(user: @user, account: @account)

        @shard1.activate do
          # create the dev key on a different account
          account2 = Account.create!
          developer_key = DeveloperKey.create!(account: account2, redirect_uri: "http://www.example.com/my_uri")
          enable_developer_key_account_binding!(developer_key)
          @token = @user.access_tokens.create!(developer_key:)
          expect(@token.developer_key.shard).to be @shard1
        end

        allow(LoadAccount).to receive(:default_domain_root_account).and_return(@account)
        get "/api/v1/courses", headers: { "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" }
        assert_status(401)
      end
    end
  end

  describe "as_user_id" do
    before :once do
      course_with_teacher(active_all: true)
      @course1 = @course
      course_with_student(user: @user, active_all: true)
      user_with_pseudonym(user: @student, username: "blah@example.com")
      @student_pseudonym = @pseudonym
      @course2 = @course
    end

    it "allows as_user_id" do
      account_admin_user(account: Account.site_admin)
      user_with_pseudonym(user: @user)

      json = api_call(:get,
                      "/api/v1/users/self/profile?as_user_id=#{@student.id}",
                      controller: "profile",
                      action: "settings",
                      user_id: "self",
                      format: "json",
                      as_user_id: @student.id.to_param)
      expect(assigns["current_user"]).to eq @student
      expect(assigns["current_pseudonym"]).to eq @student_pseudonym
      expect(assigns["real_current_user"]).to eq @user
      expect(assigns["real_current_pseudonym"]).to eq @pseudonym
      expect(json).to eq({
                           "id" => @student.id,
                           "name" => "User",
                           "short_name" => "User",
                           "sortable_name" => "User",
                           "login_id" => "blah@example.com",
                           "title" => nil,
                           "bio" => nil,
                           "primary_email" => "blah@example.com",
                           "sis_user_id" => nil,
                           "integration_id" => nil,
                           "time_zone" => "Etc/UTC",
                           "locale" => nil,
                           "effective_locale" => "en",
                           "calendar" => { "ics" => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
                           "k5_user" => false,
                           "use_classic_font_in_k5" => false
                         })

      # as_user_id is ignored if it's not allowed
      @user = @student
      user_with_pseudonym(user: @user, username: "nobody2@example.com")
      raw_api_call(:get,
                   "/api/v1/users/self/profile?as_user_id=#{@admin.id}",
                   controller: "profile",
                   action: "settings",
                   user_id: "self",
                   format: "json",
                   as_user_id: @admin.id.to_param)
      expect(assigns["current_user"]).to eq @student
      expect(assigns["real_current_user"]).to be_nil
      expect(json).to eq({
                           "id" => @student.id,
                           "name" => "User",
                           "short_name" => "User",
                           "sortable_name" => "User",
                           "login_id" => "blah@example.com",
                           "title" => nil,
                           "bio" => nil,
                           "primary_email" => "blah@example.com",
                           "sis_user_id" => nil,
                           "integration_id" => nil,
                           "time_zone" => "Etc/UTC",
                           "locale" => nil,
                           "effective_locale" => "en",
                           "calendar" => { "ics" => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
                           "k5_user" => false,
                           "use_classic_font_in_k5" => false
                         })

      # as_user_id is ignored if it's blank
      raw_api_call(:get,
                   "/api/v1/users/self/profile?as_user_id=",
                   controller: "profile",
                   action: "settings",
                   user_id: "self",
                   format: "json",
                   as_user_id: "")
      expect(assigns["current_user"]).to eq @student
      expect(assigns["real_current_user"]).to be_nil
      expect(json).to eq({
                           "id" => @student.id,
                           "name" => "User",
                           "short_name" => "User",
                           "sortable_name" => "User",
                           "login_id" => "blah@example.com",
                           "title" => nil,
                           "bio" => nil,
                           "primary_email" => "blah@example.com",
                           "sis_user_id" => nil,
                           "integration_id" => nil,
                           "time_zone" => "Etc/UTC",
                           "locale" => nil,
                           "effective_locale" => "en",
                           "calendar" => { "ics" => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
                           "k5_user" => false,
                           "use_classic_font_in_k5" => false
                         })
    end

    it "allows sis_user_id as an as_user_id" do
      account_admin_user(account: Account.site_admin)
      user_with_pseudonym(user: @user)
      @student_pseudonym.update_attribute(:sis_user_id, "1234")

      json = api_call(:get,
                      "/api/v1/users/self/profile?as_user_id=sis_user_id:#{@student.pseudonym.sis_user_id}",
                      controller: "profile",
                      action: "settings",
                      user_id: "self",
                      format: "json",
                      as_user_id: "sis_user_id:#{@student.pseudonym.sis_user_id.to_param}")
      expect(assigns["current_user"]).to eq @student
      expect(assigns["real_current_pseudonym"]).to eq @pseudonym
      expect(assigns["real_current_user"]).to eq @user
      expect(json).to eq({
                           "id" => @student.id,
                           "name" => "User",
                           "short_name" => "User",
                           "sortable_name" => "User",
                           "login_id" => "blah@example.com",
                           "sis_user_id" => "1234",
                           "integration_id" => nil,
                           "bio" => nil,
                           "title" => nil,
                           "primary_email" => "blah@example.com",
                           "time_zone" => "Etc/UTC",
                           "locale" => nil,
                           "effective_locale" => "en",
                           "calendar" => { "ics" => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
                           "k5_user" => false,
                           "use_classic_font_in_k5" => false
                         })
    end

    it "allows integration_id as an as_user_id" do
      account_admin_user(account: Account.site_admin)
      user_with_pseudonym(user: @user)
      @student_pseudonym.update_attribute(:integration_id, "1234")
      @student_pseudonym.update_attribute(:sis_user_id, "1234")

      json = api_call(:get,
                      "/api/v1/users/self/profile?as_user_id=sis_integration_id:#{@student.pseudonym.integration_id}",
                      controller: "profile",
                      action: "settings",
                      user_id: "self",
                      format: "json",
                      as_user_id: "sis_integration_id:#{@student.pseudonym.integration_id.to_param}")
      expect(assigns["current_user"]).to eq @student
      expect(assigns["real_current_pseudonym"]).to eq @pseudonym
      expect(assigns["real_current_user"]).to eq @user
      expect(json).to eq({
                           "id" => @student.id,
                           "name" => "User",
                           "short_name" => "User",
                           "sortable_name" => "User",
                           "login_id" => "blah@example.com",
                           "sis_user_id" => "1234",
                           "integration_id" => "1234",
                           "bio" => nil,
                           "title" => nil,
                           "primary_email" => "blah@example.com",
                           "time_zone" => "Etc/UTC",
                           "locale" => nil,
                           "effective_locale" => "en",
                           "calendar" => { "ics" => "http://www.example.com/feeds/calendars/user_#{@student.uuid}.ics" },
                           "k5_user" => false,
                           "use_classic_font_in_k5" => false
                         })
    end

    it "is not silent about an unknown as_user_id" do
      account_admin_user(account: Account.site_admin)
      user_with_pseudonym(user: @user)

      raw_api_call(:get,
                   "/api/v1/users/self/profile?as_user_id=sis_user_id:bogus",
                   controller: "profile",
                   action: "settings",
                   user_id: "self",
                   format: "json",
                   as_user_id: "sis_user_id:bogus")
      assert_status(401)
      expect(JSON.parse(response.body)).to eq({ "errors" => "Invalid as_user_id" })
    end

    it "does not allow non-admins to become other people" do
      account_admin_user(account: Account.site_admin)

      @user = @student
      raw_api_call(:get,
                   "/api/v1/users/self/profile?as_user_id=#{@admin.id}",
                   controller: "profile",
                   action: "settings",
                   user_id: "self",
                   format: "json",
                   as_user_id: @admin.id.to_param)
      assert_status(401)
      expect(JSON.parse(response.body)).to eq({ "errors" => "Invalid as_user_id" })
    end

    it "401s for a deleted user" do
      account_admin_user(account: Account.site_admin)
      deleted = user_with_pseudonym(active_all: true)
      deleted.destroy
      admin = @user
      user_with_pseudonym(user: admin)

      raw_api_call(:get,
                   "/api/v1/users/self/profile?as_user_id=#{deleted.id}",
                   controller: "profile",
                   action: "settings",
                   user_id: "self",
                   format: "json",
                   as_user_id: deleted.id.to_s)
      assert_status(401)
      expect(JSON.parse(response.body)).to eq({ "errors" => "Invalid as_user_id" })
    end

    it "includes the merged_into_user_id for a merged user" do
      from_user = user_with_pseudonym(active_all: true)
      to_user = user_with_pseudonym(active_all: true)
      UserMerge.from(from_user).into(to_user)

      account_admin_user(account: Account.site_admin)

      raw_api_call(:get,
                   "/api/v1/users/self/profile?as_user_id=#{from_user.id}",
                   controller: "profile",
                   action: "settings",
                   user_id: "self",
                   format: "json",
                   as_user_id: from_user.id.to_s)
      assert_status(401)
      expect(JSON.parse(response.body)).to eq({ "errors" => "Invalid as_user_id", "merged_into_user_id" => to_user.id })
    end
  end
end
