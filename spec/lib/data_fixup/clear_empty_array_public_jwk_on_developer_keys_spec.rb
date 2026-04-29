# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

RSpec.describe DataFixup::ClearEmptyArrayPublicJwkOnDeveloperKeys do
  def execute_fixup
    fixup = described_class.new
    fixup.run
    run_jobs
  end

  describe "#run" do
    it "sets public_jwk to nil when it is an empty array" do
      dk = developer_key_model
      DeveloperKey.where(id: dk.id).update_all("public_jwk = '[]'::jsonb")

      expect(dk.reload.public_jwk).to eq([])
      execute_fixup
      expect(dk.reload.public_jwk).to be_nil
    end

    it "does not affect DeveloperKeys with a valid public_jwk hash" do
      valid_jwk = {
        "kty" => "RSA",
        "e" => "AQAB",
        "n" => "test_value",
        "kid" => "2018-09-25T18:02:38Z",
        "alg" => "RS256",
        "use" => "sig"
      }
      dk = developer_key_model(public_jwk: valid_jwk)

      expect { execute_fixup }.not_to change { dk.reload.public_jwk }
    end

    it "does not affect DeveloperKeys with public_jwk already nil" do
      dk = developer_key_model(public_jwk: nil)

      expect { execute_fixup }.not_to change { dk.reload.public_jwk }
    end

    it "handles multiple records properly" do
      invalid = developer_key_model(public_jwk: [])
      valid = developer_key_model(public_jwk: { "kty" => "RSA", "e" => "AQAB", "n" => "test_value", "kid" => "2018-09-25T18:02:38Z", "alg" => "RS256", "use" => "sig" })

      invalid.update_column(:public_jwk, [])

      execute_fixup

      expect(invalid.reload.public_jwk).to be_nil
      expect(valid.reload.public_jwk).to eq({ "kty" => "RSA", "e" => "AQAB", "n" => "test_value", "kid" => "2018-09-25T18:02:38Z", "alg" => "RS256", "use" => "sig" })
    end
  end
end
