#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Canvas::PasswordPolicy do
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

    it "should only enforce minimum length by default" do
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

    it "should enforce minimum length" do
      pseudonym_with_policy(:min_length => 10)
      @pseudonym.password = @pseudonym.password_confirmation = "asdfg"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "asdfghijklm"
      expect(@pseudonym).to be_valid
    end

    it "should reject common passwords" do
      pseudonym_with_policy(:disallow_common_passwords => true)
      @pseudonym.password = @pseudonym.password_confirmation = "football"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "lacrosse"
      expect(@pseudonym).to be_valid
    end

    it "should enforce repeated character limits" do
      pseudonym_with_policy(:max_repeats => 4)
      @pseudonym.password = @pseudonym.password_confirmation = "aaaaabbbb"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "aaaabbbb"
      expect(@pseudonym).to be_valid
    end

    it "should enforce sequence limits" do
      pseudonym_with_policy(:max_sequence => 4)
      @pseudonym.password = @pseudonym.password_confirmation = "edcba1234"
      expect(@pseudonym).not_to be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "dcba1234"
      expect(@pseudonym).to be_valid
    end

    it "should reject passwords longer than 255 characters" do
      pseudonym_with_policy({})
      @pseudonym.password = @pseudonym.password_confirmation = "a" * 255
      expect(@pseudonym).to be_valid
      @pseudonym.password = @pseudonym.password_confirmation = "a" * 256
      expect(@pseudonym).not_to be_valid
    end
  end
end
