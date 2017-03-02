require "spec_helper"
require_dependency "lti/oauth2/access_token"
require 'json/jwt'

module Lti
  module Oauth2
    describe AccessToken do

      let(:aud){'http://example.com'}
      let(:sub) {'12084434-0c58-4058-b8c0-4af2da9c2ef8'}
      let(:body) do
        {
          iss: 'Canvas',
          sub: sub,
          exp: 5.minutes.from_now.to_i,
          aud: aud,
          iat: Time.zone.now.to_i,
          nbf: 30.seconds.ago,
          jti: '34084434-0c58-405a-b8c0-4af2da9c2efd'
        }
      end

      describe "#to_s" do
        let(:access_token) {Lti::Oauth2::AccessToken.create_jwt(aud: aud, sub: sub)}

        it "is signed by the canvas secret" do
          expect{Canvas::Security.decode_jwt(access_token.to_s)}.to_not raise_error
        end

        it "has an 'iss' set to 'Canvas'" do
          expect(Canvas::Security.decode_jwt(access_token.to_s)['iss']).to eq('Canvas')
        end

        it "has an 'aud' set to the current domain" do
          expect(Canvas::Security.decode_jwt(access_token.to_s)['aud']).to eq aud
        end

        it "has an 'exp' that is derived from the settings" do
          Timecop.freeze do
            Setting.set('lti.oauth2.access_token.exp', 2.hours)
            expect(Canvas::Security.decode_jwt(access_token.to_s)['exp']).to eq 2.hours.from_now.to_i
          end
        end

        it "has a default 'exp' of 1 hour" do
          Timecop.freeze do
            expect(Canvas::Security.decode_jwt(access_token.to_s)['exp']).to eq 1.hours.from_now.to_i
          end
        end

        it "has an 'iat' set to the current time" do
          Timecop.freeze do
            expect(Canvas::Security.decode_jwt(access_token.to_s)['iat']).to eq Time.zone.now.to_i
          end
        end

        it "has a 'nbf' derived from the settings" do
          Timecop.freeze do
            Setting.set('lti.oauth2.access_token.nbf', 2.minutes)
            expect(Canvas::Security.decode_jwt(access_token.to_s)['nbf']).to eq 2.minutes.ago.to_i
          end
        end

        it "has a default 'nbf' 30 seconds ago" do
          Timecop.freeze do
            expect(Canvas::Security.decode_jwt(access_token.to_s)['nbf']).to eq 30.seconds.ago.to_i
          end
        end

        it "has a 'jti' that is uniquely generated" do
          jti_1 = Canvas::Security.decode_jwt(access_token.to_s)['jti']
          jti_2 = Canvas::Security.decode_jwt(AccessToken.create_jwt(aud: aud, sub: sub).to_s)['jti']
          expect(jti_1).not_to eq jti_2
        end

        it "memoizes the jwt" do
          expect(access_token.to_s).to eq access_token.to_s
        end

        it "has a 'sub' that is set to the ToolProxy guid" do
          expect(Canvas::Security.decode_jwt(access_token.to_s)['sub']).to eq sub
        end

        it "includes the reg_key if passed in" do
          access_token = Lti::Oauth2::AccessToken.create_jwt(aud: aud, sub: sub, reg_key: 'reg_key')
          expect(Canvas::Security.decode_jwt(access_token.to_s)['reg_key']).to eq('reg_key')
        end

      end

      describe ".from_jwt" do
        it "raises an InvalidTokenError if not signed by the correct secret" do
          invalid_token = Canvas::Security.create_jwt(body, nil, 'invalid')
          expect{ Lti::Oauth2::AccessToken.from_jwt(aud: aud, jwt: invalid_token)}.to raise_error InvalidTokenError
        end
      end

      describe "#validate!" do
        let(:token) {Canvas::Security.create_jwt(body)}
        let(:access_token) {Lti::Oauth2::AccessToken.from_jwt(aud: aud, jwt: token)}

        it "returns true if there are no errors" do
          expect(access_token.validate!).to eq true
        end

        it "raises InvalidTokenError if any of the assertions are missing" do
          body.delete :jti
          expect { access_token.validate! }.to raise_error InvalidTokenError, "the following assertions are missing: jti"
        end

        it "raises an InvalidTokenError if 'iss' is not 'Canvas'" do
          body[:iss] = 'invalid iss'
          expect{ access_token.validate! }.to raise_error InvalidTokenError, 'invalid iss'
        end

        it "raises an InvalidTokenError if the 'exp' is in the past" do
          body[:exp] = 1.hour.ago
          expect{ access_token.validate! }.to raise_error InvalidTokenError, 'token has expired'
        end

        it "raises an InvalidTokenError if the 'aud' is different than the passed in 'aud'" do
          body[:aud] = 'invalid aud'
          expect{ access_token.validate! }.to raise_error InvalidTokenError, 'invalid aud'
        end

        it "raises an InvalidTokenError if the 'iat' is in the future" do
          body[:iat] = 1.hour.from_now
          expect{ access_token.validate! }.to raise_error InvalidTokenError, 'iat must be in the past'
        end

        it "raises an InvalidTokenError if the 'nbf' is in the future" do
          body[:nbf] = 1.hour.from_now
          expect{ access_token.validate! }.to raise_error InvalidTokenError
        end

      end

    end
  end
end
