# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe Lti::DeepLinkingData do
  describe "::from_jwt" do
    subject { Lti::DeepLinkingData.from_jwt(jwt) }

    let(:jwt) { Lti::DeepLinkingData.jwt_from(data) }
    let(:data) { { hello: "world" }.with_indifferent_access }

    let(:error_string) { subject.errors&.to_s }

    it "returns the jwt payload" do
      expect(subject.data).to eq data
    end

    it "is valid" do
      expect(subject.valid?).to be true
    end

    it "does not have any errors" do
      expect(subject.errors).to be_nil
    end

    context "when jwt is absent" do
      let(:jwt) { nil }

      it "returns an error" do
        expect(error_string).to include("presence_required")
      end
    end

    context "when jwt is malformed" do
      let(:jwt) { "yikes" }

      it "returns an error" do
        expect(error_string).to include("invalid_or_malformed")
      end
    end

    context "when jwt has already been used" do
      before do
        allow(Lti::Security).to receive(:check_and_store_nonce).and_return(false)
      end

      it "returns an error" do
        expect(error_string).to include("already_used")
      end
    end
  end
end
