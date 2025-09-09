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

describe AccessVerifier do
  describe "generate" do
    let(:user) { double("user", uuid: "abcd", global_id: 1) }
    let(:developer_key) { double("developer_key", global_id: 1) }
    let(:authorization) { { attachment: double("attachment", global_id: 2), permission: "download" } }

    it "includes an sf_verifier field in the response" do
      expect(AccessVerifier.generate(user:)).to have_key(:sf_verifier)
    end

    it "builds it as a jwt" do
      jwt = AccessVerifier.generate(user:)[:sf_verifier]
      expect(Canvas::Security.decode_jwt(jwt)).to have_key(:user_id)
    end

    it "returns an empty hash if no user or developer_key claimed" do
      expect(AccessVerifier.generate(developer_key: nil, user: nil)).to eql({})
    end

    it "includes an sf_verifier field in the response for developer_key and authorization" do
      expect(AccessVerifier.generate(developer_key:, authorization:)).to have_key(:sf_verifier)
    end

    it "includes attachment_id in the jwt claims" do
      jwt = AccessVerifier.generate(developer_key:, authorization:)[:sf_verifier]
      decoded_jwt = Canvas::Security.decode_jwt(jwt)
      expect(decoded_jwt).to have_key(:attachment_id)
      expect(decoded_jwt[:attachment_id]).to eq("2")
    end

    it "includes skip_redirect_for_inline_content for developer_key in the jwt claims" do
      jwt = AccessVerifier.generate(developer_key:, authorization:)[:sf_verifier]
      decoded_jwt = Canvas::Security.decode_jwt(jwt)
      expect(decoded_jwt).to have_key(:skip_redirect_for_inline_content)
      expect(decoded_jwt[:skip_redirect_for_inline_content]).to be(true)
    end
  end

  describe "validate" do
    let(:user) { user_model }

    it "returns empty set of verified claims if no sf_verifier present" do
      expect(AccessVerifier.validate({})).to eql({})
    end

    it "success on an issued verifier" do
      enable_cache do
        verifier = AccessVerifier.generate(user:)
        expect { AccessVerifier.validate(verifier) }.not_to raise_exception
      end
    end

    it "returns verified user claim on success" do
      enable_cache do
        verifier = AccessVerifier.generate(user:)
        verified = AccessVerifier.validate(verifier)
        expect(verified).to have_key(:user)
        expect(verified[:user]).to eql(user)
      end
    end

    it "returns verified real user claim on success" do
      enable_cache do
        real_user = user_model
        verifier = AccessVerifier.generate(user:, real_user:)
        verified = AccessVerifier.validate(verifier)
        expect(verified).to have_key(:real_user)
        expect(verified[:real_user]).to eql(real_user)
      end
    end

    it "returns verified developer key claim on success" do
      enable_cache do
        developer_key = DeveloperKey.create!
        verifier = AccessVerifier.generate(user:, developer_key:)
        verified = AccessVerifier.validate(verifier)
        expect(verified).to have_key(:developer_key)
        expect(verified[:developer_key]).to eql(developer_key)
      end
    end

    it "returns verified root account claim on success" do
      enable_cache do
        account = Account.default
        verifier = AccessVerifier.generate(user:, root_account: account)
        verified = AccessVerifier.validate(verifier)
        expect(verified).to have_key(:root_account)
        expect(verified[:root_account]).to eql(account)
      end
    end

    it "returns verified oauth host claim on success" do
      enable_cache do
        host = "oauth-host"
        verifier = AccessVerifier.generate(user:, oauth_host: host)
        verified = AccessVerifier.validate(verifier)
        expect(verified).to have_key(:oauth_host)
        expect(verified[:oauth_host]).to eql(host)
      end
    end

    it "raises InvalidVerifier if too old" do
      enable_cache do
        verifier = AccessVerifier.generate(user:)
        Timecop.freeze(10.minutes.from_now) do
          expect { AccessVerifier.validate(verifier) }.to raise_exception(Canvas::Security::TokenExpired)
        end
      end
    end

    it "raises InvalidVerifier if tampered with user" do
      enable_cache do
        verifier = AccessVerifier.generate(user:)
        tampered = verifier.merge(sf_verifier: "tampered")
        expect { AccessVerifier.validate(tampered) }.to raise_exception(AccessVerifier::InvalidVerifier)
      end
    end
  end
end
