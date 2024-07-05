# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Canvas::Security::PasswordPolicy do
  describe "validations" do
    def pseudonym_with_policy(policy)
      account = Account.default
      account.settings[:password_policy] = policy
      account.save
      @pseudonym = Pseudonym.new
      @pseudonym.user = user_factory
      @pseudonym.account = Account.default
      @pseudonym.unique_id = "foo"
    end

    it "only enforces minimum length by default" do
      pseudonym_with_policy({})
      @pseudonym.password = @pseudonym.password_confirmation = "aaaaa"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "aaaaaaaa"
      expect(@pseudonym).to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "football"
      expect(@pseudonym).to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "abcdefgh"
      expect(@pseudonym).to be_valid
    end

    it "validates confirmation matches" do
      pseudonym_with_policy({})

      @pseudonym.password = "abcdefgh"
      expect(@pseudonym).not_to be_valid
    end

    it "enforces minimum length" do
      pseudonym_with_policy(minimum_character_length: 10)
      @pseudonym.password = @pseudonym.password_confirmation = "asdfg"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "asdfghijklm"
      expect(@pseudonym).to be_valid
    end

    it "rejects common passwords" do
      pseudonym_with_policy(disallow_common_passwords: true)
      @pseudonym.password = @pseudonym.password_confirmation = "football"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "lacrosse"
      expect(@pseudonym).to be_valid
    end

    it "enforces repeated character limits" do
      pseudonym_with_policy(max_repeats: 4)
      @pseudonym.password = @pseudonym.password_confirmation = "aaaaabbbb"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "aaaabbbb"
      expect(@pseudonym).to be_valid
    end

    it "enforces sequence limits" do
      pseudonym_with_policy(max_sequence: 4)
      @pseudonym.password = @pseudonym.password_confirmation = "edcba1234"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "dcba1234"
      expect(@pseudonym).to be_valid
    end

    it "rejects passwords longer than 255 characters" do
      pseudonym_with_policy({})
      @pseudonym.password = @pseudonym.password_confirmation = "a" * 255
      expect(@pseudonym).to be_valid
      @pseudonym.password = @pseudonym.password_confirmation = "a" * 256
      expect(@pseudonym).not_to be_valid
    end

    context "when requiring at least one number" do
      it "is invalid without a number" do
        pseudonym_with_policy({ require_number_characters: "true" })
        @pseudonym.password = @pseudonym.password_confirmation = "Password"
        expect(@pseudonym).not_to be_valid
      end

      it "is valid with at least one number" do
        pseudonym_with_policy({ require_number_characters: "true" })
        @pseudonym.password = @pseudonym.password_confirmation = "Password1"
        expect(@pseudonym).to be_valid
      end
    end

    context "when requiring at least one symbol" do
      it "is invalid without a symbol" do
        pseudonym_with_policy({ require_symbol_characters: "true" })
        @pseudonym.password = @pseudonym.password_confirmation = "Password"
        expect(@pseudonym).not_to be_valid
      end

      it "is valid with at least one symbol" do
        pseudonym_with_policy({ require_symbol_characters: "true" })
        @pseudonym.password = @pseudonym.password_confirmation = "Password!"
        expect(@pseudonym).to be_valid
      end
    end
  end
end
