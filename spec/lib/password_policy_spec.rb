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
      @pseudonym.user = user
      @pseudonym.account = Account.default
      @pseudonym.unique_id = "foo"
    end

    it "should only enforce minimum length by default" do
      pseudonym_with_policy({})
      @pseudonym.password = @pseudonym.password_confirmation = "aaaaa"
      @pseudonym.should_not be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "aaaaaa"
      @pseudonym.should be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "football"
      @pseudonym.should be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "abcdefgh"
      @pseudonym.should be_valid
    end

    it "should enforce minimum length" do
      pseudonym_with_policy(:min_length => 6)
      @pseudonym.password = @pseudonym.password_confirmation = "asdfg"
      @pseudonym.should_not be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "asdfgh"
      @pseudonym.should be_valid
    end

    it "should reject common passwords" do
      pseudonym_with_policy(:disallow_common_passwords => true)
      @pseudonym.password = @pseudonym.password_confirmation = "football"
      @pseudonym.should_not be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "lacrosse"
      @pseudonym.should be_valid
    end

    it "should enforce repeated character limits" do
      pseudonym_with_policy(:max_repeats => 4)
      @pseudonym.password = @pseudonym.password_confirmation = "aaaaabbbb"
      @pseudonym.should_not be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "aaaabbbb"
      @pseudonym.should be_valid
    end

    it "should enforce sequence limits" do
      pseudonym_with_policy(:max_sequence => 4)
      @pseudonym.password = @pseudonym.password_confirmation = "edcba1234"
      @pseudonym.should_not be_valid

      @pseudonym.password = @pseudonym.password_confirmation = "dcba1234"
      @pseudonym.should be_valid
    end
  end
end
