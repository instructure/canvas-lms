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
#

describe UsersHelper do
  describe "#aggregated_login_details" do
    it "returns a blank pseudonym if no pseudonyms are provided" do
      p = UsersHelper.aggregated_login_details([])
      expect(p).to be_a(Pseudonym)
      expect(p).to be_new_record
      expect(p.last_request_at).to be_nil
      expect(p.current_login_at).to be_nil
      expect(p.last_login_at).to be_nil
    end

    it "returns the pseudonym if only one pseudonym is provided" do
      p = Pseudonym.new
      p2 = UsersHelper.aggregated_login_details([p])
      expect(p2).to be p
    end

    it "returns appropriate details for multiple pseudonyms" do
      p1 = Pseudonym.new
      p2 = Pseudonym.new
      p3 = Pseudonym.new
      p1.last_request_at = 1.day.ago
      p2.last_request_at = 2.days.ago
      p1.current_login_at = 1.day.ago
      p2.current_login_at = 2.days.ago
      p1.current_login_ip = "p1"
      p2.current_login_ip = "p2"
      p1.last_login_at = 4.days.ago
      p2.last_login_ip = 3.days.ago
      p1.last_login_ip = "p1l"
      p2.last_login_ip = "p1l"

      result = UsersHelper.aggregated_login_details([p1, p2, p3])
      expect(result).to be_a(Pseudonym)
      expect(result).to be_a_new_record
      expect(result).not_to be p1
      expect(result).not_to be p2
      expect(result).not_to be p3
      expect(result.last_request_at).to eq p1.last_request_at
      expect(result.current_login_at).to eq p1.current_login_at
      expect(result.current_login_ip).to eq "p1"
      expect(result.last_login_at).to eq p2.current_login_at
      expect(result.last_login_ip).to eq "p2"
    end

    it "returns appropriate details for multiple blank pseudonyms" do
      p1 = Pseudonym.new
      p2 = Pseudonym.new

      result = UsersHelper.aggregated_login_details([p1, p2])
      expect(result).to be_a(Pseudonym)
      expect(result).to be_a_new_record
      expect(result).not_to be p1
      expect(result).not_to be p2
      expect(result.last_request_at).to be_nil
      expect(result.current_login_at).to be_nil
      expect(result.current_login_ip).to be_nil
      expect(result.last_login_at).to be_nil
      expect(result.last_login_ip).to be_nil
    end
  end
end
