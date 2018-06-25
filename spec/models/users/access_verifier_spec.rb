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

      it "builds it as a jwt" do
        jwt = Users::AccessVerifier.generate(user: user)[:sf_verifier]
        expect(Canvas::Security.decode_jwt(jwt)).to have_key(:user_id)
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

      it "returns verified real user claim on success" do
        real_user = user_model
        verifier = Users::AccessVerifier.generate(user: user, real_user: real_user)
        verified = Users::AccessVerifier.validate(verifier)
        expect(verified).to have_key(:real_user)
        expect(verified[:real_user]).to eql(real_user)
      end

      it "returns verified developer key claim on success" do
        developer_key = DeveloperKey.create!
        verifier = Users::AccessVerifier.generate(user: user, developer_key: developer_key)
        verified = Users::AccessVerifier.validate(verifier)
        expect(verified).to have_key(:developer_key)
        expect(verified[:developer_key]).to eql(developer_key)
      end

      it "returns verified root account claim on success" do
        account = Account.default
        verifier = Users::AccessVerifier.generate(user: user, root_account: account)
        verified = Users::AccessVerifier.validate(verifier)
        expect(verified).to have_key(:root_account)
        expect(verified[:root_account]).to eql(account)
      end

      it "returns verified oauth host claim on success" do
        host = 'oauth-host'
        verifier = Users::AccessVerifier.generate(user: user, oauth_host: host)
        verified = Users::AccessVerifier.validate(verifier)
        expect(verified).to have_key(:oauth_host)
        expect(verified[:oauth_host]).to eql(host)
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
