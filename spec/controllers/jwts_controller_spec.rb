# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe JwtsController do
  include_context "JWT setup"
  let(:token_user) { user_with_pseudonym }
  let(:other_user) { user_with_pseudonym }
  let(:admin_user) { site_admin_user }
  let(:translate_token) do
    lambda do |resp|
      utf8_token_string = json_parse(resp.body)["token"]
      decoded_crypted_token = Canvas::Security.base64_decode(utf8_token_string)
      CanvasSecurity::ServicesJwt.decrypt(decoded_crypted_token)
    end
  end

  describe "#generate" do
    it "requires being logged in" do
      post "create"
      expect(response).to be_redirect
      expect(response).to have_http_status(:found)
    end

    context "with valid user session" do
      before { user_session(token_user) }

      it "generates a base64 encoded token for a user session with env var secrets" do
        post "create", format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:sub]).to eq(token_user.global_id)
      end

      it "has the users domain in the token" do
        post "create", format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:domain]).to eq("test.host")
      end
    end

    context "with workflows that doesn't require context" do
      before { user_session(token_user) }

      it "generates a token that doesn't have context_id" do
        post "create", params: { workflows: ["ui"] }, format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body).to_not have_key(:context_id)
      end

      it "generates a token that doesn't have context_type" do
        post "create", params: { workflows: ["ui"] }, format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body).to_not have_key(:context_type)
      end
    end

    context "with workflows that require context" do
      before :once do
        course_with_teacher(active_all: true)
        @context_id = @course.id
        @context_uuid = @course.uuid
      end

      before { user_session(@teacher) }

      let(:params) { { workflows: ["ui", "rich_content"], context_type: "Course", context_id: @context_id } }

      it "generates a token that has course context_id" do
        post "create", params:, format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:context_id]).to eq(@context_id.to_s)
      end

      it "generates a token that has course context_type" do
        post "create", params:, format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:context_type]).to eq("Course")
      end

      it "generates a token that has user context_id" do
        post "create", params: params.merge(context_type: "User", context_id: @teacher.id), format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:context_id]).to eq(@teacher.id.to_s)
      end

      it "generates a token that has user context_type" do
        post "create", params: params.merge(context_type: "User", context_id: @teacher.id), format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:context_type]).to eq("User")
      end

      it "generates a token that has account context_id" do
        user_session(admin_user)
        post "create", params: params.merge(context_type: "Account", context_id: Account.last.id), format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:context_id].to_i).to eq(Account.last.id)
      end

      it "generates a token by account context_uuid" do
        user_session(admin_user)
        post "create", params: params.except(:context_id).merge(context_type: "Account", context_uuid: Account.last.uuid), format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:context_id].to_i).to eq(Account.last.id)
      end

      it "generates a token that has account context_type" do
        user_session(admin_user)
        post "create", params: params.merge(context_type: "Account", context_id: Account.last.id), format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:context_type]).to eq("Account")
      end

      context "returns error when" do
        it "context_type param is missing" do
          post "create", params: params.except(:context_type), format: "json"
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to match(/Missing context_type parameter./)
        end

        it "context_id or context_uuid param is missing" do
          post "create", params: params.except(:context_id), format: "json"
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to match(/Missing context_id or context_uuid parameter./)
        end

        it "context_type and context_uuid are passed" do
          post "create", params: params.merge({ context_uuid: @context_uuid }), format: "json"
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to match(/Should provide context_id or context_uuid parameters, but not both./)
        end

        it "context_type is invalid" do
          post "create", params: params.merge({ context_type: "unknown" }), format: "json"
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to match(/Invalid context_type parameter./)
        end

        it "context not found with id" do
          post "create", params: params.merge({ context_id: "unknown" }), format: "json"
          expect(response).to have_http_status(:not_found)
          expect(response.body).to match(/Context not found./)
        end

        it "context not found with uuid" do
          post "create", params: params.except(:context_id).merge({ context_uuid: "unknown" }), format: "json"
          expect(response).to have_http_status(:not_found)
          expect(response.body).to match(/Context not found./)
        end

        it "context is unauthorized" do
          generic_user = user_factory
          user_session(generic_user)
          post "create", params:, format: "json"
          assert_unauthorized
        end

        it "generic user is unauthorized for Account context type" do
          generic_user = user_factory
          user_session(generic_user)
          post "create", params: params.merge(context_type: "Account", context_id: Account.last.id), format: "json"
          assert_unauthorized
        end
      end
    end

    it "doesn't allow using a token to gen a token" do
      token = build_wrapped_token(token_user.global_id)
      @request.headers["Authorization"] = "Bearer #{token}"
      get "create", format: "json"
      expect(response).to have_http_status(:forbidden)
      expect(response.body).to match(/cannot generate a JWT when authorized by a JWT/)
    end
  end

  describe "#refresh" do
    it "requires being logged in" do
      post "refresh"
      expect(response).to be_redirect
      expect(response).to have_http_status(:found)
    end

    it "doesn't allow using a token to gen a token" do
      token = build_wrapped_token(token_user.global_id)
      @request.headers["Authorization"] = "Bearer #{token}"
      get "refresh", format: "json"
      expect(response).to have_http_status(:forbidden)
      expect(response.body).to match(/cannot generate a JWT when authorized by a JWT/)
    end

    context "with valid user session" do
      before do
        user_session(token_user)
        request.env["HTTP_HOST"] = "testhost"
      end

      it "requires a jwt param" do
        post "refresh"
        expect(response).to_not have_http_status(:ok)
      end

      it "returns a refreshed token for user" do
        real_user = site_admin_user(active_user: true)
        user_with_pseudonym(user: other_user, username: "other@example.com")
        user_session(real_user)
        services_jwt = class_double(CanvasSecurity::ServicesJwt).as_stubbed_const
        expect(services_jwt).to receive(:refresh_for_user)
          .with("testjwt", "testhost", other_user, real_user:, symmetric: true)
          .and_return("refreshedjwt")
        post "refresh", params: { jwt: "testjwt", as_user_id: other_user.id }, format: "json"
        token = response.parsed_body["token"]
        expect(token).to eq("refreshedjwt")
      end

      it "returns a different jwt when refresh is called" do
        course_factory
        original_jwt = CanvasSecurity::ServicesJwt.for_user(
          request.host_with_port,
          token_user,
          symmetric: true
        )
        post "refresh", params: { jwt: original_jwt }
        refreshed_jwt = response.parsed_body["token"]
        expect(refreshed_jwt).to_not eq(original_jwt)
      end

      it "returns an error if jwt is invalid for refresh" do
        services_jwt = class_double(CanvasSecurity::ServicesJwt)
                       .as_stubbed_const(transfer_nested_constants: true)
        expect(services_jwt).to receive(:refresh_for_user)
          .and_raise(CanvasSecurity::ServicesJwt::InvalidRefresh)
        post "refresh", params: { jwt: "testjwt" }, format: "json"
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "current_user is different than the sub claim" do
      before do
        enable_default_developer_key!
        allow(CanvasSecurity::ServicesJwt).to receive(:decrypt).and_return({ "sub" => token_user.global_id })
        Setting.set("write_feature_flag_audit_logs", "false")
        Account.site_admin.enable_feature!(:new_quizzes_allow_service_jwt_refresh)
      end

      context "calling user cannot refresh for another user" do
        before do
          access_token = other_user.access_tokens.create!.full_token
          request.headers["Authorization"] = "Bearer #{access_token}"
          post "refresh", params: { jwt: "testjwt" }, format: "json"
        end

        it "returns an invalid refresh error" do
          expect(response.body).to match(/invalid refresh/)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context "calling user is able to refresh for another user" do
        before do
          pseudonym(admin_user)
          access_token = admin_user.access_tokens.create!.full_token
          admin_user.access_tokens.first.developer_key.update!(internal_service: true)
          request.headers["Authorization"] = "Bearer #{access_token}"
          expect(CanvasSecurity::ServicesJwt).to receive(:refresh_for_user)
            .with(
              "testjwt",
              request.host_with_port,
              token_user,
              real_user: nil,
              symmetric: true
            ).and_return("fresh-jwt")

          post "refresh", params: { jwt: "testjwt" }, format: "json"
        end

        it "returns with a fresh JWT" do
          expect(response).to have_http_status(:ok)
          expect(response.body).to match(/fresh-jwt/)
        end
      end

      context "the developer key of the calling user is not an internal service key" do
        before do
          pseudonym(admin_user)
          access_token = admin_user.access_tokens.create!.full_token
          admin_user.access_tokens.first.developer_key.update!(internal_service: false)
          request.headers["Authorization"] = "Bearer #{access_token}"

          post "refresh", params: { jwt: "testjwt" }, format: "json"
        end

        it "returns an invalid refresh error" do
          expect(response.body).to match(/invalid refresh/)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context "incoming JWT is invalid and decryption fails" do
        before do
          allow(CanvasSecurity::ServicesJwt).to receive(:decrypt).and_raise(JSON::JWE::DecryptionFailed)
          pseudonym(admin_user)
          access_token = admin_user.access_tokens.create!.full_token
          admin_user.access_tokens.first.developer_key.update!(internal_service: true)
          request.headers["Authorization"] = "Bearer #{access_token}"

          post "refresh", params: { jwt: "invalid jwt" }, format: "json"
        end

        it "returns an invalid refresh error" do
          expect(response.body).to match(/invalid refresh/)
          expect(response).to have_http_status(:bad_request)
        end

        context "incoming jwt invalid formatting" do
          before do
            allow(CanvasSecurity::ServicesJwt).to receive(:decrypt).and_raise(JSON::JWT::InvalidFormat)
          end

          it "returns an invalid refresh error" do
            expect(response.body).to match(/invalid refresh/)
            expect(response).to have_http_status(:bad_request)
          end
        end
      end
    end
  end
end
