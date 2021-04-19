# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Canvas::Security::Recryption do

  describe ".execute" do
    it "keeps the same value with a different salt" do
      key_val = "abcdefg1234567"
      user = user_model(otp_secret_key: key_val)
      first_salt = user.read_attribute(:otp_secret_key_salt)
      expect(first_salt).to_not be_nil
      expect(user.otp_secret_key).to eq(key_val)
      Canvas::Security::Recryption.execute(Shard.current.settings[:encryption_key])
      user.reload
      expect(user.otp_secret_key).to eq(key_val)
      other_salt = user.read_attribute(:otp_secret_key_salt)
      expect(first_salt).to_not eq(other_salt)
    end
  end
end
