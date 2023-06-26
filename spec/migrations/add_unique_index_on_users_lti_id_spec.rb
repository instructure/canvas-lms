# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../db/migrate/20230626174031_add_unique_index_on_users_lti_id"

describe "AddUniqueIndexOnUsersLtiId" do
  subject { AddUniqueIndexOnUsersLtiId.new }

  context "with no non-deleted users" do
    it "prioritizes the most recently updated user" do
      subject.down
      u1 = User.create!(lti_id: "123", workflow_state: "deleted")
      u2 = User.create!(lti_id: "123", workflow_state: "deleted")
      u2.update_attribute(:updated_at, 1.day.ago)

      subject.up
      expect(u1.reload.read_attribute(:lti_id)).to eq "123"
      expect(u2.reload.read_attribute(:lti_id)).to be_nil
    end
  end

  context "with one non-deleted user" do
    it "prioritizes the non-deleted user" do
      subject.down
      u1 = User.create!(lti_id: "123", workflow_state: "deleted")
      u2 = User.create!(lti_id: "123", workflow_state: "active")
      u2.update_attribute(:updated_at, 1.day.ago)

      subject.up
      expect(u1.reload.read_attribute(:lti_id)).to be_nil
      expect(u2.reload.read_attribute(:lti_id)).to eq "123"
    end
  end

  context "multiple non-deleted users" do
    before do
      subject.down
      @u1 = User.create!(lti_id: "123", workflow_state: "active")
      @u2 = User.create!(lti_id: "123", workflow_state: "active")
      @u2.update_attribute(:updated_at, 1.day.ago)
    end

    it "leaves non-deleted records alone by default" do
      expect(subject).to receive(:at_exit) # suppress the exit message
      expect { subject.up }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "modifies non-deleted records if ENV['AGGRESSIVE_UUID_CLEANUP'] is set" do
      expect(ENV).to receive(:fetch).with("AGGRESSIVE_UUID_CLEANUP", "0").and_return("1")
      subject.up
      expect(@u1.reload.read_attribute(:lti_id)).to eq "123"
      expect(@u2.reload.read_attribute(:lti_id)).to be_nil
    end
  end
end
