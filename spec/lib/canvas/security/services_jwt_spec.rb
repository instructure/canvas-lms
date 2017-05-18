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

require_relative '../../../spec_helper'
require_dependency "canvas/security/services_jwt"

module Canvas::Security
  describe ServicesJwt do
    include_context "JWT setup"

    def build_wrapped_token(user_id, real_user_id: nil)
      payload = { sub: user_id }
      payload[:masq_sub] = real_user_id if real_user_id
      crypted_token = ServicesJwt.generate(payload, false)
      payload = {
        iss: "some other service",
        user_token: crypted_token
      }
      wrapper_token = Canvas::Security.create_jwt(payload, nil, fake_signing_secret)
      # because it will come over base64 encoded from any other service
      Canvas::Security.base64_encode(wrapper_token)
    end

    let(:translate_token) do
      ->(jwt){
        decoded_crypted_token = Canvas::Security.base64_decode(jwt)
        return Canvas::Security.decrypt_services_jwt(decoded_crypted_token)
      }
    end

    it "has secrets accessors" do
      expect(ServicesJwt.encryption_secret).to eq(fake_encryption_secret)
      expect(ServicesJwt.signing_secret).to eq(fake_signing_secret)
    end

    describe "#initialize" do
      it "throws an error for nil token string" do
        expect{ ServicesJwt.new(nil) }.to raise_error(ArgumentError)
      end
    end

    describe "#wrapper_token" do
      let(:user_id){ 42 }

      it "is the body of the wrapper token if wrapped" do
        base64_encoded_wrapper = build_wrapped_token(user_id)
        jwt = ServicesJwt.new(base64_encoded_wrapper)
        expect(jwt.wrapper_token[:iss]).to eq("some other service")
      end

      it "is an empty hash if an unwrapped token" do
        original_token = ServicesJwt.generate(sub: user_id)
        jwt = ServicesJwt.new(original_token, false)
        expect(jwt.wrapper_token).to eq({})
      end
    end

    describe "user ids" do
      let(:user_id){ 42 }

      it "can get the user_id out of a wrapped issued token" do
        base64_encoded_wrapper = build_wrapped_token(user_id)
        jwt = ServicesJwt.new(base64_encoded_wrapper)
        expect(jwt.user_global_id).to eq(user_id)
      end

      it "can pull out the masquerading user if provided" do
        real_user_id = 24
        base64_encoded_wrapper = build_wrapped_token(user_id, real_user_id: real_user_id)
        jwt = ServicesJwt.new(base64_encoded_wrapper)
        expect(jwt.masquerading_user_global_id).to eq(real_user_id)
      end
    end

    describe "initialization" do
      let(:jwt_string){ ServicesJwt.generate(sub: 1) }

      it "uses SecureRandom for generating the JWT" do
        SecureRandom.stubs(uuid: "some-secure-random-string")
        jwt = ServicesJwt.new(jwt_string, false)
        expect(jwt.id).to eq("some-secure-random-string")
      end

      it "expires in an hour" do
        Timecop.freeze(Time.utc(2013,3,13,9,12)) do
          jwt = ServicesJwt.new(jwt_string, false)
          expect(jwt.expires_at).to eq(1363169520)
        end
      end

      describe "via .generate" do

        let(:base64_regex) do
          %r{^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$}
        end

        let(:jwt_string){ ServicesJwt.generate(sub: 1) }

        it "builds an encoded token out" do
          expect(jwt_string).to match(base64_regex)
        end

        it "can return just the encrypted token without base64 encoding" do
          jwt = ServicesJwt.generate({ sub: 1 }, false)
          expect(jwt).to_not match(base64_regex)
        end

        it "allows the introduction of arbitrary data" do
          jwt = ServicesJwt.generate(sub: 2, foo: "bar")
          decoded_crypted_token = Canvas::Security.base64_decode(jwt)
          decrypted_token_body = Canvas::Security.decrypt_services_jwt(decoded_crypted_token)
          expect(decrypted_token_body[:foo]).to eq("bar")
        end

        it "errors if you try to pass data without a sub entry" do
          expect{ ServicesJwt.generate(foo: "bar", bang: "baz") }.
            to raise_error(ArgumentError)
        end

      end

      describe "via .for_user" do
        let(:user){ stub(global_id: 42) }
        let(:ctx){ stub(id: 47) }
        let(:host){ "example.instructure.com" }
        let(:masq_user){ stub(global_id: 24) }

        it "can build from a user and host" do
          jwt = ServicesJwt.for_user(host, user)
          decrypted_token_body = translate_token.call(jwt)
          expect(decrypted_token_body[:sub]).to eq(42)
          expect(decrypted_token_body[:domain]).to eq("example.instructure.com")
        end

        it "includes masquerading user if given" do
          jwt = ServicesJwt.for_user(host, user, real_user: masq_user)
          decrypted_token_body = translate_token.call(jwt)
          expect(decrypted_token_body[:sub]).to eq(42)
          expect(decrypted_token_body[:masq_sub]).to eq(24)
        end

        it "doesn't include the masq key if there is no real user" do
          jwt = ServicesJwt.for_user(host, user, real_user: nil)
          decrypted_token_body = translate_token.call(jwt)
          expect(decrypted_token_body.keys.include?(:masq_sub)).to eq(false)
        end

        it "includes workflows if given" do
          workflows = ['foo']
          jwt = ServicesJwt.for_user(host, user, workflows: workflows)
          decrypted_token_body = translate_token.call(jwt)
          expect(decrypted_token_body[:workflows]).to eq workflows
        end

        it "does not include a workflow if not given" do
          jwt = ServicesJwt.for_user(host, user)
          decrypted_token_body = translate_token.call(jwt)
          expect(decrypted_token_body).not_to have_key :workflow
        end

        it "does not include a workflow if empty array" do
          workflows = []
          jwt = ServicesJwt.for_user(host, user, workflows: workflows)
          decrypted_token_body = translate_token.call(jwt)
          expect(decrypted_token_body).not_to have_key :workflow
        end

        it 'includes workflow_state if workflows is given' do
          workflows = [:foo]
          state = {'a' => 123}
          Canvas::JWTWorkflow.expects(:state_for).with(workflows, ctx, user).returns(state)
          jwt = ServicesJwt.for_user(host, user, workflows: workflows, context: ctx)
          decrypted_token_body = translate_token.call(jwt)
          expect(decrypted_token_body[:workflow_state]).to eq(state)
        end

        it 'does not include workflow_state if empty' do
          workflows = [:foo]
          Canvas::JWTWorkflow.expects(:state_for).returns({})
          jwt = ServicesJwt.for_user(host, user, workflows: workflows, context: ctx)
          decrypted_token_body = translate_token.call(jwt)
          expect(decrypted_token_body).not_to have_key :workflow_state
        end

        it 'includes context type and id if context is given' do
          ctx = Course.new
          ctx.id = 47
          jwt = ServicesJwt.for_user(host, user, context: ctx)
          decrypted_token_body = translate_token.call(jwt)
          expect(decrypted_token_body[:context_type]).to eq 'Course'
          expect(decrypted_token_body[:context_id]).to eq '47'
        end

        it "errors without a host" do
          expect{ ServicesJwt.for_user(nil, user) }.
            to raise_error(ArgumentError)
        end

        it "errors without a user" do
          expect{ ServicesJwt.for_user(host, nil) }.
            to raise_error(ArgumentError)
        end
      end

      describe "refresh_for_user" do
        let(:user1){ stub(global_id: 42) }
        let(:user2){ stub(global_id: 43) }
        let(:host) { 'testhost' }
        
        it 'is invalid if jwt cannot be decoded' do
          expect{ ServicesJwt.refresh_for_user('invalidjwt', host, user1) }
            .to raise_error(ServicesJwt::InvalidRefresh)
        end

        it 'is invlaid if user id is different' do
          jwt = ServicesJwt.for_user(host, user1)
          expect{ ServicesJwt.refresh_for_user(jwt, host, user2) }
            .to raise_error(ServicesJwt::InvalidRefresh)
        end

        it 'is invlaid if host is different' do
          jwt = ServicesJwt.for_user('differenthost', user1)
          expect{ ServicesJwt.refresh_for_user(jwt, host, user1) }
            .to raise_error(ServicesJwt::InvalidRefresh)
        end

        it 'is invlaid masquerading user is different' do
          masq_user = stub(global_id: 44)
          jwt = ServicesJwt.for_user(host, user1, real_user: masq_user)
          expect{ ServicesJwt.refresh_for_user(jwt, host, user1, real_user: user2) }
            .to raise_error(ServicesJwt::InvalidRefresh)
        end

        it 'is invalid if masquerading and token does not have masq_sub' do
          jwt = ServicesJwt.for_user(host, user1)
          expect{ ServicesJwt.refresh_for_user(jwt, host, user1, real_user: user2) }
            .to raise_error(ServicesJwt::InvalidRefresh)
        end

        it 'is invalid if more than 6 hours past token expiration' do
          jwt = ServicesJwt.for_user(host, user1)
          Timecop.freeze(7.hours.from_now) do
            expect{ ServicesJwt.refresh_for_user(jwt, host, user1) }
              .to raise_error(ServicesJwt::InvalidRefresh)
          end
        end

        it 'generates a token with the same user id and host' do
          jwt = ServicesJwt.for_user(host, user1)
          refreshed = ServicesJwt.refresh_for_user(jwt, host, user1)
          payload = translate_token.call(refreshed)
          expect(payload[:sub]).to eq(user1.global_id)
          expect(payload[:domain]).to eq(host)
          expect(payload[:masq_sub]).to be_nil
        end

        it 'generates a token with masq_sub for masquerading users' do
          jwt = ServicesJwt.for_user(host, user1, real_user: user2)
          refreshed = ServicesJwt.refresh_for_user(jwt, host, user1, real_user: user2)
          payload = translate_token.call(refreshed)
          expect(payload[:masq_sub]).to eq(user2.global_id)
        end

        it 'generates a token with same workflows as original' do
          workflows = ['rich_content', 'ui']
          jwt = ServicesJwt.for_user(host, user1, workflows: workflows)
          refreshed = ServicesJwt.refresh_for_user(jwt, host, user1)
          payload = translate_token.call(refreshed)
          expect(payload[:workflows]).to eq(workflows)
        end

        it 'generates a token with same context as original' do
          context = course_factory
          jwt = ServicesJwt.for_user(host, user1, context: context)
          refreshed = ServicesJwt.refresh_for_user(jwt, host, user1)
          payload = translate_token.call(refreshed)
          expect(payload[:context_type]).to eq(context.class.name)
          expect(payload[:context_id]).to eq(context.id.to_s)
        end

        it 'generates a new token even if the original token has expired' do
          jwt = ServicesJwt.for_user(host, user1)
          Timecop.freeze(61.minutes.from_now) do
            refreshed = ServicesJwt.refresh_for_user(jwt, host, user1)
            payload = translate_token.call(refreshed)
            expect(payload[:sub]).to eq(user1.global_id)
          end
        end
      end
    end
  end
end
