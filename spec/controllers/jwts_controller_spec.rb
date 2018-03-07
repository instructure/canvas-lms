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

require_relative '../spec_helper'

describe JwtsController do
  include_context "JWT setup"
  let(:token_user){ user_factory(active_user: true) }
  let(:other_user){ user_factory(active_user: true) }
  let(:translate_token) do
    ->(resp){
      utf8_token_string = json_parse(resp.body)['token']
      decoded_crypted_token = Canvas::Security.base64_decode(utf8_token_string)
      return Canvas::Security.decrypt_services_jwt(decoded_crypted_token)
    }
  end

  describe "#generate" do
    it "requires being logged in" do
      post 'create'
      expect(response).to be_redirect
      expect(response.status).to eq(302)
    end

    context "with valid user session" do
      before(:each){ user_session(token_user) }
      let(:translate_token) do
        ->(resp){
          utf8_token_string = json_parse(resp.body)['token']
          decoded_crypted_token = Canvas::Security.base64_decode(utf8_token_string)
          return Canvas::Security.decrypt_services_jwt(decoded_crypted_token)
        }
      end

      it "generates a base64 encoded token for a user session with env var secrets" do
        post 'create', format: 'json'
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:sub]).to eq(token_user.global_id)
      end

      it "has the users domain in the token" do
        post 'create', format: 'json'
        decrypted_token_body = translate_token.call(response)
        expect(decrypted_token_body[:domain]).to eq("test.host")
      end
    end

    it "doesn't allow using a token to gen a token" do
      token = Canvas::Security::ServicesJwt.generate({ sub: token_user.global_id })
      @request.headers['Authorization'] = "Bearer #{token}"
      get 'create', format: 'json'
      expect(response.status).to_not eq(200)
    end
  end

  describe "#refresh" do
    it "requires being logged in" do
      post 'refresh'
      expect(response).to be_redirect
      expect(response.status).to eq(302)
    end

    it "doesn't allow using a token to gen a token" do
      token = Canvas::Security::ServicesJwt.generate({ sub: token_user.global_id })
      @request.headers['Authorization'] = "Bearer #{token}"
      get 'refresh', format: 'json'
      expect(response.status).to_not eq(200)
    end

    context "with valid user session" do
      before(:each) do
        user_session(token_user)
        request.env['HTTP_HOST'] = 'testhost'
      end

      it "requires a jwt param" do
        post 'refresh'
        expect(response.status).to_not eq(200)
      end

      it "returns a refreshed token for user" do
        real_user = site_admin_user(active_user: true)
        user_with_pseudonym(:user => other_user, :username => "other@example.com")
        user_session(real_user)
        services_jwt = class_double(Canvas::Security::ServicesJwt).as_stubbed_const
        expect(services_jwt).to receive(:refresh_for_user)
          .with('testjwt', 'testhost', other_user, real_user: real_user)
          .and_return('refreshedjwt')
        post 'refresh', params: {jwt: 'testjwt', as_user_id: other_user.id}, format: 'json'
        token = JSON.parse(response.body)['token']
        expect(token).to eq('refreshedjwt')
      end

      it "returns a different jwt when refresh is called" do
        course = course_factory
        original_jwt = Canvas::Security::ServicesJwt.for_user(
          request.env['HTTP_HOST'],
          token_user
        )
        post 'refresh', params: {jwt: original_jwt}
        refreshed_jwt = JSON.parse(response.body)['token']
        expect(refreshed_jwt).to_not eq(original_jwt)
      end

      it "returns an error if jwt is invalid for refresh" do
        services_jwt = class_double(Canvas::Security::ServicesJwt)
          .as_stubbed_const(transfer_nested_constants: true)
        expect(services_jwt).to receive(:refresh_for_user)
          .and_raise(Canvas::Security::ServicesJwt::InvalidRefresh)
        post 'refresh', params: {jwt: 'testjwt'}, format: 'json'
        expect(response.status).to eq(400)
      end
    end
  end
end
