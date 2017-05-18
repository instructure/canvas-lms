#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"

describe CanvasBreachMitigation::MaskingSecrets do
  before do
    Rails = double("Rails") unless defined? Rails
  end

  let(:masking_secrets) { CanvasBreachMitigation::MaskingSecrets }

  describe ".csrf_token" do
    it "puts :_csrf_token into the supplied object" do
      hash = {}
      masking_secrets.masked_authenticity_token(hash)
      expect(hash['_csrf_token']).not_to be nil
    end

    it "returns a byte string" do
      expect(masking_secrets.masked_authenticity_token({})).not_to be nil
    end
  end

  describe ".valid_authenticity_token?" do
    let(:unmasked_token) { SecureRandom.base64(32) }
    let(:cookies) { {'_csrf_token' => masking_secrets.masked_token(unmasked_token)} }

    it "returns true for a valid masked token" do
      valid_masked = masking_secrets.masked_token(unmasked_token)
      expect(masking_secrets.valid_authenticity_token?(cookies, valid_masked)).to be true
    end

    it "returns false for an invalid masked token" do
      expect(masking_secrets.valid_authenticity_token?(cookies, SecureRandom.base64(64))).to be false
    end

    it "returns false for a token of the wrong length" do
      expect(masking_secrets.valid_authenticity_token?(cookies, SecureRandom.base64(2))).to be false
    end
  end

  describe ".masked_authenticity_token" do
    let(:cookies) { {} }

    it "initializes the _csrf_token cookie" do
      token = masking_secrets.masked_authenticity_token(cookies)
      expect(cookies['_csrf_token'][:value]).to eq token
    end

    it "initializes the _csrf_token cookie without explicit domain by default" do
      masking_secrets.masked_authenticity_token(cookies)
      expect(cookies['_csrf_token']).not_to be_has_key(:domain)
    end

    it "initializes the _csrf_token cookie without explicit httponly by default" do
      masking_secrets.masked_authenticity_token(cookies)
      expect(cookies['_csrf_token']).not_to be_has_key(:httponly)
    end

    it "initializes the _csrf_token cookie without explicit secure by default" do
      masking_secrets.masked_authenticity_token(cookies)
      expect(cookies['_csrf_token']).not_to be_has_key(:secure)
    end

    it "copies domain option to _csrf_token cookie" do
      masking_secrets.masked_authenticity_token(cookies, domain: "domain")
      expect(cookies['_csrf_token'][:domain]).to eq "domain"
    end

    it "copies httponly option to _csrf_token cookie" do
      masking_secrets.masked_authenticity_token(cookies, httponly: true)
      expect(cookies['_csrf_token'][:httponly]).to be true
    end

    it "copies secure option to _csrf_token cookie" do
      masking_secrets.masked_authenticity_token(cookies, secure: true)
      expect(cookies['_csrf_token'][:secure]).to be true
    end

    it "remasks an existing _csrf_token cookie" do
      original_token = masking_secrets.masked_token(SecureRandom.base64(32))
      cookies['_csrf_token'] = original_token
      token = masking_secrets.masked_authenticity_token(cookies)
      expect(token).not_to eq original_token
      expect(cookies['_csrf_token'][:value]).to eq token
      expect(masking_secrets.valid_authenticity_token?({'_csrf_token' => token}, original_token)).to be true
    end
  end
end
