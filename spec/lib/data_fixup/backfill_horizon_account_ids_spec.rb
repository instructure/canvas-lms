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

describe DataFixup::BackfillHorizonAccountIds do
  describe "run" do
    let(:root_account) { Account.create! }
    let(:sub_account1) { Account.create!(parent_account: root_account) }
    let(:sub_account2) { Account.create!(parent_account: root_account) }

    it "adds account IDs to root_account's horizon_account_ids when horizon_account setting exists" do
      sub_account1.settings[:horizon_account] = { value: true }
      sub_account1.save!

      sub_account2.settings[:horizon_account] = { value: true }
      sub_account2.save!

      DataFixup::BackfillHorizonAccountIds.run

      root_account.reload
      expect(root_account.settings[:horizon_account_ids]).to match_array([sub_account1.id, sub_account2.id])
    end

    it "preserves existing horizon_account_ids in root_account settings" do
      root_account.settings[:horizon_account_ids] = [999]
      root_account.save!

      sub_account1.settings[:horizon_account] = { value: true }
      sub_account1.save!

      DataFixup::BackfillHorizonAccountIds.run

      root_account.reload
      expect(root_account.settings[:horizon_account_ids]).to match_array([999, sub_account1.id])
    end

    it "ignores accounts without horizon_account setting" do
      DataFixup::BackfillHorizonAccountIds.run

      root_account.reload
      expect(root_account.settings[:horizon_account_ids]).to be_nil
    end

    it "ignores accounts with horizon_account value set to false" do
      sub_account1.settings[:horizon_account] = { value: false }
      sub_account1.save!

      sub_account2.settings[:horizon_account] = { value: true }
      sub_account2.save!

      DataFixup::BackfillHorizonAccountIds.run

      root_account.reload
      expect(root_account.settings[:horizon_account_ids]).to match_array([sub_account2.id])
    end

    it "is idempotent" do
      sub_account1.settings[:horizon_account] = { value: true }
      sub_account1.save!

      sub_account2.settings[:horizon_account] = { value: true }
      sub_account2.save!

      DataFixup::BackfillHorizonAccountIds.run

      root_account.reload
      expect(root_account.settings[:horizon_account_ids]).to match_array([sub_account1.id, sub_account2.id])

      DataFixup::BackfillHorizonAccountIds.run

      root_account.reload
      expect(root_account.settings[:horizon_account_ids]).to match_array([sub_account1.id, sub_account2.id])
    end
  end
end
