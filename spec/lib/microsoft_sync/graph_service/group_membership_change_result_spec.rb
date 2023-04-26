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

describe MicrosoftSync::GraphService::GroupMembershipChangeResult do
  before do
    subject.add_issue "members", "abc", :reason1
    subject.add_issue "members", "def", :reason2
    subject.add_issue "owners", "abc", :reason2
  end

  describe "#issues_by_member_type" do
    it "describes all the issues added" do
      expect(subject.issues_by_member_type).to eq(
        "members" => {
          "abc" => :reason1,
          "def" => :reason2,
        },
        "owners" => {
          "abc" => :reason2,
        }
      )
    end
  end

  describe "#to_json" do
    it "is based off issues_by_member_type" do
      expect(JSON.parse(subject.to_json)).to eq(JSON.parse(subject.issues_by_member_type.to_json))
    end
  end

  describe "#blank?" do
    it "returns true when no issues have been added" do
      expect(described_class.new.blank?).to be(true)
    end

    it "returns false when issues have been added" do
      expect(subject.blank?).to be(false)
    end
  end

  describe "#total_unsuccessful" do
    it "returns the total number of issues added" do
      expect(subject.total_unsuccessful).to eq(3)
    end
  end

  describe "#nonexistent_user_ids" do
    before do
      subject.add_issue "members", "ghi", described_class::NONEXISTENT_USER
      subject.add_issue "owners", "def", described_class::NONEXISTENT_USER
      subject.add_issue "owners", "ghi", described_class::NONEXISTENT_USER
    end

    it "returns any users with any issue reason NONEXISTENT_USER" do
      expect(subject.nonexistent_user_ids.sort).to eq(["def", "ghi"])
    end
  end
end
