# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe OAuthClientConfig do
  describe "validations" do
    let(:account) { account_model }
    let(:user) { user_model }
    let(:other_account) { account_model }
    let(:config) { OAuthClientConfig.new(root_account: account, type: :token, identifier: "abc123", updated_by: user) }

    it "requires a root_account" do
      config.root_account = nil
      expect(config).not_to be_valid
      expect(config.errors[:root_account]).to include("must exist")
    end

    it "requires a client_identifier" do
      config.identifier = nil
      expect(config).not_to be_valid
      expect(config.errors[:identifier]).to include("can't be blank")
    end

    it "requires a type" do
      config.type = nil
      expect(config).not_to be_valid
      expect(config.errors[:type]).to include("can't be blank")
    end

    it "requires a valid type" do
      config.type = "invalid"
      expect(config).not_to be_valid
      expect(config.errors[:type]).to include("is not included in the list")
    end

    it "requires updated_by" do
      config.updated_by = nil
      expect(config).not_to be_valid
      expect(config.errors[:updated_by]).to include("must exist")
    end

    it "enforces uniqueness of identifier scoped to root_account and type" do
      config.save!
      dup = OAuthClientConfig.new(root_account: account, type: :token, identifier: "abc123", updated_by: user)
      expect(dup).not_to be_valid
      expect(dup.errors[:identifier]).to include("has already been taken")

      # different account is ok
      dup.root_account = other_account
      expect(dup).to be_valid

      # different type is ok
      dup.type = :user
      expect(dup).to be_valid
    end

    it "only allows custom throttle params for certain client types" do
      config.type = "user"
      config.throttle_maximum = 10
      expect(config).not_to be_valid
      expect(config.errors[:type]).to include("custom throttle parameters can only be set for client types: product, client_id, lti_advantage, service_user_key, token")

      config.type = "client_id"
      expect(config).to be_valid
    end
  end
end
