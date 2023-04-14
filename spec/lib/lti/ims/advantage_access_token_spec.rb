# frozen_string_literal: true

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

require_relative "advantage_access_token_shared_context"

describe Lti::IMS::AdvantageAccessToken do
  include_context "advantage access token context"

  describe "#validate!" do
    let(:token) { described_class.new(access_token_jwt) }

    it "returns 'self' when the token is valid" do
      expect(token.validate!(access_token_aud)).to eq(token)
    end

    it "tries all aud values passed in" do
      acceptable_auds = ["http://example.com/", access_token_aud, "http://example2.com/"]
      expect(token.validate!(acceptable_auds)).to eq(token)
    end

    it "raises a specific type of AdvantageClientError if the aud is invalid" do
      acceptable_auds = ["http://example.com/", "http://example2.com/"]
      expect { token.validate!(acceptable_auds) }
        .to raise_error(Lti::IMS::AdvantageErrors::InvalidAccessTokenClaims, /\Waud\W.*invalid/)
      expect(Lti::IMS::AdvantageErrors::InvalidAccessTokenClaims)
        .to be < Lti::IMS::AdvantageErrors::AdvantageClientError
    end

    it "raises a specific type of AdvantageClientError when the token is malformed" do
      token = described_class.new("garbage")
      expect { token.validate!(access_token_aud) }
        .to raise_error(Lti::IMS::AdvantageErrors::MalformedAccessToken)
      expect(Lti::IMS::AdvantageErrors::MalformedAccessToken)
        .to be < Lti::IMS::AdvantageErrors::AdvantageClientError
    end

    it "raises a specific type of AdvantageClientError when decoding the JWT raises a JSON::JWT::Exception" do
      expect(Canvas::Security::JwtValidator)
        .to receive(:new).and_raise(JSON::JWT::Exception)
      expect { token.validate!(access_token_aud) }
        .to raise_error(Lti::IMS::AdvantageErrors::InvalidAccessToken)
      expect(Lti::IMS::AdvantageErrors::InvalidAccessToken)
        .to be < Lti::IMS::AdvantageErrors::AdvantageClientError
    end
  end
end
