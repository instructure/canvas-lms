# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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
require "timecop"
require "spec_helper"

describe CanvasSecurity::JWKKeyPair do
  describe "#to_jwk" do
    it "has the private key in the JWK format" do
      Timecop.freeze do
        keys = CanvasSecurity::RSAKeyPair.new
        jwk = keys.to_jwk
        expect(jwk).to include(keys.private_key.to_jwk(kid: jwk["kid"]))
        expect(jwk["kid"]).to include(Time.now.utc.iso8601)
      end
    end
  end

  describe "#public_jwk" do
    it "includes the public key in JWK format" do
      Timecop.freeze do
        keys = CanvasSecurity::RSAKeyPair.new
        jwk = keys.public_jwk
        expect(jwk).to include(keys.private_key.public_key.to_jwk(kid: jwk["kid"]))
        expect(jwk["kid"]).to include(Time.now.utc.iso8601)
      end
    end

    it "does not include the private key claims in JWK format" do
      Timecop.freeze do
        keys = CanvasSecurity::RSAKeyPair.new
        expect(keys.public_jwk.keys).not_to include "d", "p", "q", "dp", "dq", "qi"
      end
    end
  end

  describe ".time_from_kid" do
    subject { described_class.time_from_kid(key["kid"]) }

    let(:key) { CanvasSecurity::RSAKeyPair.new.public_jwk }

    it "returns the time the JWK was created" do
      expect(subject).to be_within(29).of(Time.zone.now)
    end

    it "handles kids which happen to have date-like strings in the random uuid" do
      # NOTE: the 4feb-9 -- Time.zone.parse will pick this up as February 4, year 9
      expect(SecureRandom).to receive(:uuid).and_return "d2fe13a4-b3f7-4feb-9a1a-2160e8b044f"
      expect(key["kid"]).to include("4feb-9")
      expect(subject).to be_within(29).of(Time.zone.now)
    end
  end
end
