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

require 'spec_helper'
require_dependency "users/access_verifier"

module Users
  describe AccessVerifier do
    describe "generate" do
      let(:user) { double("user", uuid: "abcd", global_id: 1) }

      it "returns an empty hash if no user claimed" do
        expect(Users::AccessVerifier.generate(user: nil)).to eql({})
      end

      it "includes an sf_verifier field in the response" do
        expect(Users::AccessVerifier.generate(user: user)).to have_key(:sf_verifier)
      end
    end

    describe "validate" do
      let(:user) { user_model }

      it "returns empty set of verified claims if no sf_verifier present" do
        expect(Users::AccessVerifier.validate({})).to eql({})
      end

      it "success on an issued verifier" do
        verifier = Users::AccessVerifier.generate(user: user)
        expect{ Users::AccessVerifier.validate(verifier) }.not_to raise_exception
      end

      it "returns verified user claim on success" do
        verifier = Users::AccessVerifier.generate(user: user)
        verified = Users::AccessVerifier.validate(verifier)
        expect(verified).to have_key(:user)
        expect(verified[:user]).to eql(user)
      end

      it "raises InvalidVerifier if too old" do
        verifier = Users::AccessVerifier.generate(user: user)
        Timecop.freeze(10.minutes.from_now) do
          expect{ Users::AccessVerifier.validate(verifier) }.to raise_exception(Users::AccessVerifier::InvalidVerifier)
        end
      end

      it "raises InvalidVerifier if tampered with user" do
        verifier = Users::AccessVerifier.generate(user: user)
        tampered = verifier.merge(sf_verifier: 'tampered')
        expect{ Users::AccessVerifier.validate(tampered) }.to raise_exception(Users::AccessVerifier::InvalidVerifier)
      end
    end
  end
end
