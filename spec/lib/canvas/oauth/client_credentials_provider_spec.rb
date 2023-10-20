# frozen_string_literal: true

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

module Canvas::OAuth
  describe ClientCredentialsProvider do
    let(:dev_key) { DeveloperKey.create! }
    let(:provider) { described_class.new dev_key.id, "example.com" }

    before do
      allow(Rails.application.routes).to receive(:default_url_options).and_return({ host: "example.com" })
    end

    describe "generate_token" do
      subject { provider.generate_token }

      it { is_expected.to be_a Hash }

      it "has the correct expected keys" do
        %i[access_token token_type expires_in scope].each do |key|
          expect(subject).to have_key key
        end
      end

      context "with iat in the future by a small amount" do
        let(:future_iat_time) { 5.seconds.from_now }
        let(:iat) { future_iat_time.to_i }

        it "returns an access token" do
          Timecop.freeze(future_iat_time - 5.seconds) do
            expect(subject).to be_a Hash
          end
        end
      end

      describe "with account scoped dev_key" do
        before do
          @account = Account.create!
          dev_key.update!(account_id: @account)
        end

        it "includes a custom canvas account_id claim in the token" do
          token = subject[:access_token]
          claims = Canvas::Security.decode_jwt(token)
          expect(claims).to have_key "canvas.instructure.com"
          expect(claims["canvas.instructure.com"]["account_uuid"]).to eq @account.uuid
        end
      end
    end
  end

  describe AsymmetricClientCredentialsProvider do
    let(:provider) { described_class.new jws, "example.com" }
    let(:alg) { :RS256 }
    let(:aud) { Rails.application.routes.url_helpers.oauth2_token_url }
    let(:iat) { 1.minute.ago.to_i }
    let(:exp) { 10.minutes.from_now.to_i }
    let(:rsa_key_pair) { CanvasSecurity::RSAKeyPair.new }
    let(:signing_key) { JSON::JWK.new(rsa_key_pair.to_jwk) }
    let(:jwt) do
      {
        iss: "someiss",
        sub: dev_key.id,
        aud:,
        iat:,
        exp:,
        jti: SecureRandom.uuid
      }
    end
    let(:jws) { JSON::JWT.new(jwt).sign(signing_key, alg).to_s }
    let(:dev_key) { DeveloperKey.create! public_jwk: rsa_key_pair.public_jwk }

    before do
      allow(Rails.application.routes).to receive(:default_url_options).and_return({ host: "example.com" })
    end

    describe "using public jwk url" do
      subject { provider.valid? }

      let(:url) { "https://get.public.jwk" }
      let(:public_jwk_url_response) do
        {
          keys: [
            rsa_key_pair.public_jwk
          ]
        }.to_json
      end
      let(:stubbed_response) { instance_double(Net::HTTPOK, { body: public_jwk_url_response }) }

      context "when there is no public jwk" do
        before do
          dev_key.update!(public_jwk: nil, public_jwk_url: url)
        end

        it do
          expected_url_called(url, :get, stubbed_response)
          expect(subject).to be true
        end
      end

      context "when there is a public jwk" do
        before do
          dev_key.update!(public_jwk_url: url)
        end

        it do
          expected_url_called(url, :get, stubbed_response)
          expect(subject).to be true
        end
      end

      context "when an empty object is returned" do
        let(:public_jwk_url_response) { {}.to_json }

        before do
          dev_key.update!(public_jwk_url: url)
        end

        it do
          expected_url_called(url, :get, stubbed_response)
          expect(subject).to be false
        end
      end

      context "when invalid json is returned" do
        let(:public_jwk_url_response) { "<html></html>" }

        before do
          dev_key.update!(public_jwk_url: url)
        end

        it do
          expected_url_called(url, :get, stubbed_response)
          expect(subject).to be false
          expect(provider.error_message).to be("JWK Error: Invalid JSON")
        end
      end

      context "when the url is not valid giving a 404" do
        let(:stubbed_response) { instance_double(Net::HTTPNotFound, body: public_jwk_url_response) }

        before do
          dev_key.update!(public_jwk_url: url)
        end

        let(:public_jwk_url_response) do
          {
            success?: false, code: "404"
          }.to_json
        end

        it do
          expected_url_called(url, :get, stubbed_response)
          expect(subject).to be false
        end
      end

      def expected_url_called(url, type, response)
        expect(CanvasHttp).to receive(type).with(url).and_return(response)
      end
    end

    describe "generate_token" do
      subject { provider.generate_token }

      it { is_expected.to be_a Hash }

      it "has the correct expected keys" do
        %i[access_token token_type expires_in scope].each do |key|
          expect(subject).to have_key key
        end
      end
    end

    describe "#error_message" do
      subject { provider.error_message }

      before do |ex|
        unless ex.metadata[:skip_before]
          provider.valid?
        end
      end

      it { is_expected.to be_empty }

      context "with unsupported algorithm" do
        let(:alg) { :HS256 }
        let(:signing_key) { "lowentropy" }

        it { is_expected.not_to be_empty }
      end

      context "with bad aud" do
        let(:aud) { "doesnotexist" }

        it { is_expected.not_to be_empty }
      end

      context "with bad exp" do
        let(:exp) { 1.minute.ago.to_i }

        it { is_expected.not_to be_empty }
      end

      context "with bad iat" do
        let(:iat) { 1.minute.from_now.to_i }

        it { is_expected.not_to be_empty }

        context "with iat too far in future" do
          let(:iat) { 6.minutes.from_now.to_i }

          it { is_expected.not_to be_empty }
        end
      end

      context "with bad signing key" do
        let(:signing_key) { JSON::JWK.new(CanvasSecurity::RSAKeyPair.new.to_jwk) }

        it { is_expected.not_to be_empty }
      end

      context "with missing assertion" do
        (Canvas::Security::JwtValidator::REQUIRED_ASSERTIONS + ["iss"]).each do |assertion|
          before do
            jwt.delete assertion.to_sym
            provider.valid?
          end

          it "returns an error message when #{assertion} missing", :skip_before do
            expect(subject).not_to be_empty
          end
        end
      end
    end

    describe "#valid?" do
      subject { provider.valid? }

      it { is_expected.to be true }

      context "with unsupported algorithm" do
        let(:alg) { :HS256 }
        let(:signing_key) { "lowentropy" }

        it { is_expected.to be false }
      end

      context "with bad aud" do
        let(:aud) { "doesnotexist" }

        it { is_expected.to be false }
      end

      context "with bad exp" do
        let(:exp) { 1.minute.ago.to_i }

        it { is_expected.to be false }
      end

      context "with bad iat" do
        let(:iat) { 1.minute.from_now.to_i }

        it { is_expected.to be false }

        context "with iat too far in future" do
          let(:iat) { 6.minutes.from_now.to_i }

          it { is_expected.to be false }
        end
      end

      context "jti check" do
        it "is true when when validated twice" do
          enable_cache do
            subject
            expect(subject).to be true
          end
        end
      end

      context "with missing assertion" do
        (Canvas::Security::JwtValidator::REQUIRED_ASSERTIONS + ["iss"]).each do |assertion|
          it "is invalid when #{assertion} missing" do
            jwt.delete assertion.to_sym
            expect(subject).to be false
          end
        end
      end
    end
  end

  describe SymmetricClientCredentialsProvider do
    let(:dev_key) { DeveloperKey.create! client_credentials_audience: "external" }
    let(:provider) { described_class.new dev_key.id, "example.com" }

    before do
      allow(Rails.application.routes).to receive(:default_url_options).and_return({ host: "example.com" })
    end

    context "with valid client_id" do
      describe "#error_message" do
        subject { provider.error_message }

        it { is_expected.to be_empty }
      end

      describe "#valid?" do
        subject { provider.valid? }

        it { is_expected.to be true }
      end

      describe "generate_token" do
        subject { provider.generate_token }

        it { is_expected.to be_a Hash }

        it "has the correct expected keys" do
          %i[access_token token_type expires_in scope].each do |key|
            expect(subject).to have_key key
          end
        end
      end
    end

    context "with invalid client_id" do
      let(:provider) { described_class.new "invalid", "example.com" }

      describe "#error_message" do
        subject { provider.error_message }

        it { is_expected.to eq("Unknown client_id") }
      end

      describe "#valid?" do
        subject { provider.valid? }

        it { is_expected.to be false }
      end
    end
  end
end
