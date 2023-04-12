# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe "EmailAddressValidator" do
  it "accepts good addresses with domains" do
    ["user@example.com", '"non\@triv"/ial@example.com'].each do |addr|
      expect(EmailAddressValidator.valid?(addr)).to be true
    end
  end

  it "rejects bad, local, or multiple addresses" do
    ["None", "@example.com", "user@", "user1@example.com, user2@example.com"].each do |addr|
      expect(EmailAddressValidator.valid?(addr)).to be false
    end
  end
end
