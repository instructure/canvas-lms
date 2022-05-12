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
  let(:translate_token) do
    lambda do |resp|
      utf8_token_string = json_parse(resp.body)["token"]
      decoded_crypted_token = Canvas::Security.base64_decode(utf8_token_string)
      return CanvasSecurity::ServicesJwt.decrypt(decoded_crypted_token)
    end
  end

  describe "#generate" do
    it "requires being logged in" do
      post "create"
      expect(response).to be_redirect
      expect(response.status).to eq(302)
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
        post "create", params: params, format: "json"
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:context_id]).to eq(@context_id.to_s)
      end

      it "generates a token that has course context_type" do
        post "create", params: params, format: "json"
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

      context "returns error when" do
        it "context_type param is missing" do
          post "create", params: params.except(:context_type), format: "json"
          expect(response.status).to eq(400)
          expect(response.body).to match(/Missing context_type parameter./)
        end

        it "context_id or context_uuid param is missing" do
          post "create", params: params.except(:context_id), format: "json"
          expect(response.status).to eq(400)
          expect(response.body).to match(/Missing context_id or context_uuid parameter./)
        end

        it "context_type and context_uuid are passed" do
          post "create", params: params.merge({ context_uuid: @context_uuid }), format: "json"
          expect(response.status).to eq(400)
          expect(response.body).to match(/Should provide context_id or context_uuid parameters, but not both./)
        end

        it "context_type is invalid" do
          post "create", params: params.merge({ context_type: "unknown" }), format: "json"
          expect(response.status).to eq(400)
          expect(response.body).to match(/Invalid context_type parameter./)
        end

        it "context not found with id" do
          post "create", params: params.merge({ context_id: "unknown" }), format: "json"
          expect(response.status).to eq(404)
          expect(response.body).to match(/Context not found./)
        end

        it "context not found with uuid" do
          post "create", params: params.except(:context_id).merge({ context_uuid: "unknown" }), format: "json"
          expect(response.status).to eq(404)
          expect(response.body).to match(/Context not found./)
        end

        it "context is unauthorized" do
          generic_user = user_factory
          user_session(generic_user)
          post "create", params: params, format: "json"
          assert_unauthorized
        end
      end
    end

    it "doesn't allow using a token to gen a token" do
      token = build_wrapped_token(token_user.global_id)
      @request.headers["Authorization"] = "Bearer #{token}"
      get "create", format: "json"
      expect(response.status).to eq(403)
      expect(response.body).to match(/cannot generate a JWT when authorized by a JWT/)
    end
  end

  describe "#refresh" do
    it "requires being logged in" do
      post "refresh"
      expect(response).to be_redirect
      expect(response.status).to eq(302)
    end

    it "doesn't allow using a token to gen a token" do
      token = build_wrapped_token(token_user.global_id)
      @request.headers["Authorization"] = "Bearer #{token}"
      get "refresh", format: "json"
      expect(response.status).to eq(403)
      expect(response.body).to match(/cannot generate a JWT when authorized by a JWT/)
    end

    context "with valid user session" do
      before do
        user_session(token_user)
        request.env["HTTP_HOST"] = "testhost"
      end

      it "requires a jwt param" do
        post "refresh"
        expect(response.status).to_not eq(200)
      end

      it "returns a refreshed token for user" do
        real_user = site_admin_user(active_user: true)
        user_with_pseudonym(user: other_user, username: "other@example.com")
        user_session(real_user)
        services_jwt = class_double(CanvasSecurity::ServicesJwt).as_stubbed_const
        expect(services_jwt).to receive(:refresh_for_user)
          .with("testjwt", "testhost", other_user, real_user: real_user, symmetric: true)
          .and_return("refreshedjwt")
        post "refresh", params: { jwt: "testjwt", as_user_id: other_user.id }, format: "json"
        token = JSON.parse(response.body)["token"]
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
        refreshed_jwt = JSON.parse(response.body)["token"]
        expect(refreshed_jwt).to_not eq(original_jwt)
      end

      it "returns an error if jwt is invalid for refresh" do
        services_jwt = class_double(CanvasSecurity::ServicesJwt)
                       .as_stubbed_const(transfer_nested_constants: true)
        expect(services_jwt).to receive(:refresh_for_user)
          .and_raise(CanvasSecurity::ServicesJwt::InvalidRefresh)
        post "refresh", params: { jwt: "testjwt" }, format: "json"
        expect(response.status).to eq(400)
      end
    end
  end
end
