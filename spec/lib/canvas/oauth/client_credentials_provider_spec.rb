#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path('../../../spec_helper', File.dirname(__FILE__))
require_dependency "canvas/oauth/client_credentials_provider"

RSA_KEY_PAIR = Lti::RSAKeyPair.new

module Canvas::Oauth
  describe ClientCredentialsProvider do
    let(:provider) { described_class.new jws, 'example.com' }
    let(:alg) { :RS256 }
    let(:aud) { Rails.application.routes.url_helpers.oauth2_token_url }
    let(:iat) { 1.minute.ago.to_i }
    let(:exp) { 10.minutes.from_now.to_i }
    let(:signing_key) { JSON::JWK.new(RSA_KEY_PAIR.to_jwk) }
    let(:jwt) do
      {
        iss: 'someiss',
        sub: dev_key.id,
        aud: aud,
        iat: iat,
        exp: exp,
        jti: SecureRandom.uuid
      }
    end
    let(:jws) { JSON::JWT.new(jwt).sign(signing_key, alg).to_s }
    let_once(:dev_key) { DeveloperKey.create! public_jwk: RSA_KEY_PAIR.public_jwk }

    before { Rails.application.routes.default_url_options[:host] = 'example.com' }

    describe 'generate_token' do
      subject { provider.generate_token }

      it { is_expected.to be_a Hash }

      it 'has the correct expected keys' do
        %i(access_token token_type expires_in scope).each do |key|
          expect(subject).to have_key key
        end
      end
    end

    describe '#error_message' do
      subject { provider.error_message }

      before do |ex|
        unless ex.metadata[:skip_before]
          provider.valid?
        end
      end

      it { is_expected.to be_empty }

      context 'with unsupported algorithm' do
        let(:alg) { :HS256 }
        let(:signing_key) { 'lowentropy' }

        it { is_expected.not_to be_empty }
      end

      context 'with bad aud' do
        let(:aud) { 'doesnotexist' }

        it { is_expected.not_to be_empty }
      end

      context 'with bad exp' do
        let(:exp) { 1.minute.ago.to_i }

        it { is_expected.not_to be_empty }
      end

      context 'with bad iat' do
        let(:iat) { 1.minute.from_now.to_i }

        it { is_expected.not_to be_empty }

        context 'with iat too far in future' do
          let(:iat) { 6.minutes.from_now.to_i }

        it { is_expected.not_to be_empty }
        end
      end

      context 'with bad signing key' do
        let(:signing_key) { JSON::JWK.new(Lti::RSAKeyPair.new.to_jwk) }

        it { is_expected.not_to be_empty }
      end

      context 'with missing assertion' do
        (Canvas::Security::JwtValidator::REQUIRED_ASSERTIONS + ['iss']).each do |assertion|
          before do
            jwt.delete assertion.to_sym
            provider.valid?
          end

          it "returns an error message when #{assertion} missing", skip_before: true do
            expect(subject).not_to be_empty
          end
        end
      end
    end

    describe '#valid?' do
      subject { provider.valid? }

      it { is_expected.to be true }

      context 'with unsupported algorithm' do
        let(:alg) { :HS256 }
        let(:signing_key) { 'lowentropy' }

        it { is_expected.to be false }
      end

      context 'with bad aud' do
        let(:aud) { 'doesnotexist' }

        it { is_expected.to be false }
      end

      context 'with bad exp' do
        let(:exp) { 1.minute.ago.to_i }

        it { is_expected.to be false }
      end

      context 'with bad iat' do
        let(:iat) { 1.minute.from_now.to_i }

        it { is_expected.to be false }

        context 'with iat too far in future' do
          let(:iat) { 6.minutes.from_now.to_i }

        it { is_expected.to be false }
        end
      end

      context 'jti check' do
        it 'is true when when validated twice' do
          enable_cache do
            subject
            expect(subject).to eq true
          end
        end
      end

      context 'with missing assertion' do
        (Canvas::Security::JwtValidator::REQUIRED_ASSERTIONS + ['iss']).each do |assertion|
          it "is invalid when #{assertion} missing" do
            jwt.delete assertion.to_sym
            expect(subject).to be false
          end
        end
      end
    end
  end
end
