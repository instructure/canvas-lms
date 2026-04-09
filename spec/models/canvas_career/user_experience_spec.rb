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

module CanvasCareer
  describe UserExperience do
    let_once(:root_account) { Account.default }
    let_once(:user) { user_factory(active_all: true) }

    describe "validations" do
      it "requires a user" do
        experience = UserExperience.new(root_account:)
        expect(experience).not_to be_valid
        expect(experience.errors[:user]).to be_present
      end

      it "requires a root_account" do
        experience = UserExperience.new(user:)
        expect(experience).not_to be_valid
        expect(experience.errors[:root_account]).to be_present
      end

      it "enforces uniqueness of user per root_account for active records" do
        UserExperience.create!(user:, root_account:)
        duplicate = UserExperience.new(user:, root_account:)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to be_present
      end

      it "allows re-creation after soft delete" do
        experience = UserExperience.create!(user:, root_account:)
        experience.destroy
        expect(experience.reload).to be_deleted

        new_experience = UserExperience.new(user:, root_account:)
        expect(new_experience).to be_valid
      end
    end

    describe "soft delete" do
      it "sets workflow_state to deleted" do
        experience = UserExperience.create!(user:, root_account:)
        experience.destroy
        expect(experience.reload.workflow_state).to eql("deleted")
      end

      it "can be restored with undestroy" do
        experience = UserExperience.create!(user:, root_account:)
        experience.destroy
        experience.undestroy
        expect(experience.reload.workflow_state).to eql("active")
      end
    end

    describe ".active" do
      it "only returns active records" do
        active = UserExperience.create!(user:, root_account:)
        other_user = user_factory(active_all: true)
        deleted = UserExperience.create!(user: other_user, root_account:)
        deleted.destroy

        expect(UserExperience.active).to contain_exactly(active)
      end
    end
  end
end
