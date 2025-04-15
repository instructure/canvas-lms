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

describe DataFixup::NormalizePseudonyms do
  before do
    account.email_pseudonyms = false

    require_relative "../../../db/migrate/20250417195912_normalize_pseudonyms"
    # we need the new constraints out of the way
    NormalizePseudonyms.new.down
  end

  let(:account) { Account.default }

  describe ".backfill_unique_id_normalized" do
    it "backfills unique_id_normalized" do
      user = User.create!
      p1 = user.pseudonyms.create!(unique_id: "12345", account:)
      p2 = user.pseudonyms.create!(unique_id: "  12    345", account:)
      Pseudonym.where(id: [p1, p2].map(&:id)).update_all(unique_id_normalized: nil)
      expect(p1.reload.unique_id_normalized).to be_nil
      expect(p2.reload.unique_id_normalized).to be_nil

      described_class.backfill_unique_id_normalized

      expect(p1.reload.unique_id_normalized).to eql "12345"
      expect(p2.reload.unique_id_normalized).to eql "12 345"
    end
  end

  describe ".dedup_all" do
    let(:user) { User.create! }
    let(:ap1) { account.authentication_providers.create!(auth_type: "cas") }
    let(:ap2) { account.authentication_providers.create!(auth_type: "openid_connect") }

    def dedup_and_check(renamed, remaining)
      if renamed.is_a?(Hash)
        renamed = user.pseudonyms.create!(unique_id: "12345Ⅳ", account:, **renamed)
        # create it unique first, so we can use all the callbacks, then change it to
        # the collision bypassing validations
        unique_id = remaining.delete(:unique_id) || "12345IV"
        remaining = user.pseudonyms.create!(unique_id: "#{unique_id}2", account:, **remaining)
        remaining.unique_id = unique_id
        remaining.unique_id_normalized = Pseudonym.normalize(unique_id)
        remaining.save(validate: false)
      end

      described_class.dedup_all

      orig_remaining_unique_id = remaining.unique_id
      orig_renamed_unique_id = renamed.unique_id
      expect(remaining.reload.unique_id).to eql(orig_remaining_unique_id)
      expect(renamed.reload.unique_id).to start_with("NORMALIZATION-COLLISION-")
      expect(renamed.reload.unique_id).to end_with("-#{orig_renamed_unique_id}")
    end

    it "dedups collisions with nil auth provider" do
      dedup_and_check({}, {})
    end

    it "dedups collisions in a single auth provider" do
      dedup_and_check({ authentication_provider: ap1 }, { authentication_provider: ap1 })
    end

    it "doesn't dedup across auth providers" do
      # neither of these will get deduped, because they belong to different auth providers
      p1 = user.pseudonyms.create!(unique_id: "123456", account:, authentication_provider: ap1)
      p2 = user.pseudonyms.create!(unique_id: "123456", account:, authentication_provider: ap2)

      described_class.dedup_all

      expect(p1.reload.unique_id).to eql "123456"
      expect(p2.reload.unique_id).to eql "123456"
    end

    it "dedups collisions between nil and cas" do
      dedup_and_check({}, { authentication_provider: ap1 })
    end

    it "doesn't dedup collisions between nil and oidc" do
      p1 = user.pseudonyms.create!(unique_id: "123456", account:)
      p2 = user.pseudonyms.create!(unique_id: "123456", account:, authentication_provider: ap2)

      described_class.dedup_all

      expect(p1.reload.unique_id).to eql "123456"
      expect(p2.reload.unique_id).to eql "123456"
    end

    it "prefers SIS pseudonyms" do
      dedup_and_check({}, { sis_user_id: "12345" })
    end

    it "prefers pseudonyms that have logged in" do
      dedup_and_check({}, { current_login_at: Time.zone.now })
    end

    it "prefers the most recently logged in pseudonym" do
      dedup_and_check({ current_login_at: 1.month.ago }, { current_login_at: Time.zone.now })
    end

    it "prefers an already-normalized pseudonym" do
      # technically it's the same as the base case, but I created them in a different order
      # to ensure it's choosing the normalized one
      p1 = user.pseudonyms.create!(unique_id: "123456IV", account:)
      p2 = user.pseudonyms.create!(unique_id: "123456a", account:)
      p2.unique_id = "123456Ⅳ"
      p2.unique_id_normalized = Pseudonym.normalize(p2.unique_id)
      p2.save(validate: false)

      dedup_and_check(p2, p1)
    end

    it "prefers the newest, all else equal" do
      # technically it's the same as the base case, but I created them in a different order
      # to ensure it's choosing the normalized one

      dedup_and_check({ unique_id: "123456\u2003" }, { unique_id: "123456\u2003\u2003" })
    end
  end
end
