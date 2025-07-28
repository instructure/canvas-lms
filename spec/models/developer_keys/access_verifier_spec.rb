# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module DeveloperKeys
  describe AccessVerifier do
    describe "generate" do
      subject(:generate) { DeveloperKeys::AccessVerifier.generate(developer_key:, authorization:) }

      let(:developer_key) { double("developer_key", global_id: 1) }
      let(:authorization) { { attachment: double("attachment", global_id: 2), permission: "download" } }

      it "returns an empty hash if no developer_key claimed" do
        expect(DeveloperKeys::AccessVerifier.generate(developer_key: nil)).to eql({})
      end

      it "includes an sf_verifier field in the response" do
        expect(generate).to have_key(:sf_verifier)
      end

      it "builds it as a jwt" do
        jwt = generate[:sf_verifier]
        expect(Canvas::Security.decode_jwt(jwt)).to have_key(:developer_key_id)
      end

      it "includes attachment_id in the jwt claims" do
        jwt = generate[:sf_verifier]
        decoded_jwt = Canvas::Security.decode_jwt(jwt)
        expect(decoded_jwt).to have_key(:attachment_id)
        expect(decoded_jwt[:attachment_id]).to eq("2")
      end
    end
  end
end
