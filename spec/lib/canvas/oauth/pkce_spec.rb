# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

RSpec.describe Canvas::OAuth::PKCE do # rubocop:disable RSpec/SpecFilePathFormat
  before do
    allow(Account.site_admin).to receive(:feature_enabled?).with(:pkce).and_return(true)
  end

  describe ".use_pkce_in_authorization?" do
    let(:options) { { code_challenge: "challenge", code_challenge_method: "S256" } }

    context "when options are blank" do
      it "returns false" do
        expect(described_class.use_pkce_in_authorization?(nil)).to be_falsey
      end
    end

    context "when PKCE feature is disabled" do
      it "returns false" do
        allow(Account.site_admin).to receive(:feature_enabled?).with(:pkce).and_return(false)
        expect(described_class.use_pkce_in_authorization?(options)).to be_falsey
      end
    end

    context "when required params are missing" do
      it "returns false" do
        expect(described_class.use_pkce_in_authorization?(code_challenge: "challenge")).to be_falsey
      end
    end

    context "when method is unsupported" do
      it "returns false" do
        expect(described_class.use_pkce_in_authorization?(code_challenge: "challenge", code_challenge_method: "unsupported")).to be_falsey
      end
    end

    context "when required params are present and method is supported" do
      it "returns true" do
        expect(described_class.use_pkce_in_authorization?(options)).to be_truthy
      end
    end
  end

  describe ".use_pkce_in_token?" do
    let(:options) { { code_verifier: "verifier" } }

    context "when options are blank" do
      it "returns false" do
        expect(described_class.use_pkce_in_token?(nil)).to be_falsey
      end
    end

    context "when PKCE feature is disabled" do
      it "returns false" do
        allow(Account.site_admin).to receive(:feature_enabled?).with(:pkce).and_return(false)
        expect(described_class.use_pkce_in_token?(options)).to be_falsey
      end
    end

    context "when :code_verifier is not included" do
      it "returns false" do
        expect(described_class.use_pkce_in_token?(code_challenge: "challenge")).to be_falsey
      end
    end

    context "when :code_verifier is included" do
      it "returns true" do
        expect(described_class.use_pkce_in_token?(options)).to be_truthy
      end
    end
  end

  describe ".store_code_challenge" do
    it "stores a code challenge in redis" do
      expect(Canvas.redis).to receive(:setex).with("oauth2/pkce:code", 600, "challenge").and_return("OK")
      expect(described_class.store_code_challenge("challenge", "code")).to eq("OK")
    end
  end

  describe ".valid_code_verifier?" do
    let(:code) { "code" }
    let(:code_verifier) { SecureRandom.uuid }
    let(:code_challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false) }

    context "when code challenge is blank" do
      it "returns false" do
        allow(Canvas.redis).to receive(:get).with("oauth2/pkce:code").and_return(nil)
        expect(described_class.valid_code_verifier?(code:, code_verifier:)).to be_falsey
      end
    end

    context "when code verifier is valid" do
      it "returns true" do
        allow(Canvas.redis).to receive(:get).with("oauth2/pkce:code").and_return(code_challenge)
        allow(Canvas.redis).to receive(:del).with("oauth2/pkce:code")
        expect(described_class.valid_code_verifier?(code:, code_verifier:)).to be_truthy
      end
    end

    context "when code verifier is invalid" do
      it "returns false" do
        allow(Canvas.redis).to receive(:get).with("oauth2/pkce:code").and_return("invalid_challenge")
        allow(Canvas.redis).to receive(:del).with("oauth2/pkce:code")
        expect(described_class.valid_code_verifier?(code:, code_verifier:)).to be_falsey
      end
    end
  end
end
