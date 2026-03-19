# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe DataFixup::DeleteDuplicateRows do
  let_once(:account) { Account.default }
  let_once(:user1) { User.create! }
  let_once(:user2) { User.create! }
  let_once(:keeper) { Pseudonym.create!(unique_id: "user1a@example.com", user: user1, account:) }
  let_once(:duplicate) { Pseudonym.create!(unique_id: "user1b@example.com", user: user1, account:) }
  let_once(:unique) { Pseudonym.create!(unique_id: "user2@example.com", user: user2, account:) }

  describe ".run" do
    it "deletes duplicate rows" do
      DataFixup::DeleteDuplicateRows.run(Pseudonym, :account_id, :user_id)
      expect(Pseudonym.where(id: [keeper.id, duplicate.id, unique.id]).pluck(:id).sort)
        .to eq [keeper.id, unique.id].sort
    end

    it "keeps the row with the lowest primary key" do
      DataFixup::DeleteDuplicateRows.run(Pseudonym, :account_id, :user_id)
      expect(Pseudonym.find_by(id: keeper.id)).to be_present
      expect(Pseudonym.find_by(id: duplicate.id)).to be_nil
    end

    it "does not delete non-duplicate rows" do
      DataFixup::DeleteDuplicateRows.run(Pseudonym, :account_id, :user_id)
      expect(Pseudonym.find_by(id: unique.id)).to be_present
    end

    context "with reassign_references" do
      let_once(:keeper_token) do
        SessionPersistenceToken.create!(pseudonym: keeper, token_salt: SecureRandom.hex(8), crypted_token: SecureRandom.hex(32))
      end
      let_once(:duplicate_token) do
        SessionPersistenceToken.create!(pseudonym: duplicate, token_salt: SecureRandom.hex(8), crypted_token: SecureRandom.hex(32))
      end
      let_once(:unique_token) do
        SessionPersistenceToken.create!(pseudonym: unique, token_salt: SecureRandom.hex(8), crypted_token: SecureRandom.hex(32))
      end

      it "reassigns references from duplicate rows to the keeper before deleting" do
        DataFixup::DeleteDuplicateRows.run(
          Pseudonym,
          :account_id,
          :user_id,
          reassign_references: { SessionPersistenceToken => :pseudonym_id }
        )
        expect(duplicate_token.reload.pseudonym_id).to eq keeper.id
      end

      it "does not change references that already point to the keeper" do
        DataFixup::DeleteDuplicateRows.run(
          Pseudonym,
          :account_id,
          :user_id,
          reassign_references: { SessionPersistenceToken => :pseudonym_id }
        )
        expect(keeper_token.reload.pseudonym_id).to eq keeper.id
      end

      it "does not change references to non-duplicate rows" do
        DataFixup::DeleteDuplicateRows.run(
          Pseudonym,
          :account_id,
          :user_id,
          reassign_references: { SessionPersistenceToken => :pseudonym_id }
        )
        expect(unique_token.reload.pseudonym_id).to eq unique.id
      end

      it "deletes the duplicate rows after reassigning references" do
        DataFixup::DeleteDuplicateRows.run(
          Pseudonym,
          :account_id,
          :user_id,
          reassign_references: { SessionPersistenceToken => :pseudonym_id }
        )
        expect(Pseudonym.find_by(id: duplicate.id)).to be_nil
        expect(SessionPersistenceToken.where(id: [keeper_token.id, duplicate_token.id, unique_token.id]).count).to eq 3
      end

      it "reassigns multiple references from the same duplicate" do
        extra_token = SessionPersistenceToken.create!(
          pseudonym: duplicate,
          token_salt: SecureRandom.hex(8),
          crypted_token: SecureRandom.hex(32)
        )
        DataFixup::DeleteDuplicateRows.run(
          Pseudonym,
          :account_id,
          :user_id,
          reassign_references: { SessionPersistenceToken => :pseudonym_id }
        )
        expect(duplicate_token.reload.pseudonym_id).to eq keeper.id
        expect(extra_token.reload.pseudonym_id).to eq keeper.id
      end
    end
  end
end
