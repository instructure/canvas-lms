#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Schemas::Lti::PublicJwk do
  describe "valid?" do
    subject{ Schemas::Lti::PublicJwk.new.valid?(json_hash) }

    let(:valid_json_hash) do
      {
        "kty"=>"RSA",
        "e"=>"AQAB",
        "n"=>"mt8fDBX7hZ3Qn29UzRyHns9vUOH...",
        "kid"=>"2018-09-25T18:02:38Z",
        "alg"=>"RS256",
        "use"=>"sig"
      }
    end

    context 'when the json is valid' do
      let(:json_hash) { valid_json_hash }

      it { is_expected.to eq true }
    end

    context "when required properties are missing" do
      let(:json_hash) { {} }

      it { is_expected.to eq false }
    end

    context "when 'kty' is not 'RSA'" do
      let(:json_hash) { valid_json_hash.merge({"kty" => "bad value"}) }

      it { is_expected.to eq false }
    end

    context "when 'alg' is not 'RS256'" do
      let(:json_hash) { valid_json_hash.merge({"alg" => "bad value"}) }

      it { is_expected.to eq false }
    end
  end
end