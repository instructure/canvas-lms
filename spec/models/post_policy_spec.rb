# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe PostPolicy do
  describe "relationships" do
    it { is_expected.to belong_to(:course).required.inverse_of(:post_policies) }
    it { is_expected.to validate_presence_of(:course) }

    it { is_expected.to belong_to(:assignment).inverse_of(:post_policy) }
    it { is_expected.not_to validate_presence_of(:assignment) }
  end

  describe "validation" do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(title: "!!!") }

    it "is valid if a valid course and assignment are specified" do
      post_policy = PostPolicy.new(course:, assignment:)
      expect(post_policy).to be_valid
    end

    it "is valid if a valid course is specified without an assignment" do
      post_policy = PostPolicy.new(course:)
      expect(post_policy).to be_valid
    end

    it "sets the course based on the associated assignment if no course is specified" do
      expect(assignment.post_policy.course).to eq(course)
    end
  end

  describe "callbacks" do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(title: "!!!") }

    context "when the policy is for a specific assignment" do
      let(:policy) { assignment.post_policy }

      it "updates the assignment's updated_at date when saved" do
        assignment.update!(updated_at: 1.day.ago)

        save_time = Time.zone.now
        Timecop.freeze(save_time) do
          expect do
            policy.update!(post_manually: true)
          end.to change { assignment.updated_at }.to(save_time)
        end
      end

      it "does not update the owning course's updated_at date when saved" do
        course.update!(updated_at: 1.day.ago)

        Timecop.freeze do
          expect do
            policy.update!(post_manually: true)
          end.not_to change { course.updated_at }
        end
      end
    end

    context "when the policy is the default policy for a course" do
      let(:policy) { course.default_post_policy }

      it "updates the course's updated_at date when saved" do
        course.update!(updated_at: 1.day.ago)
        save_time = Time.zone.now

        Timecop.freeze(save_time) do
          expect do
            policy.update!(post_manually: true)
          end.to change { course.updated_at }.to(save_time)
        end
      end
    end
  end

  describe "root account ID" do
    let_once(:root_account) { Account.create! }
    let_once(:subaccount) { Account.create(root_account:) }
    let_once(:course) { Course.create!(account: subaccount) }

    context "for a post policy associated with a course" do
      it "is set to the course's root account ID" do
        expect(course.default_post_policy.root_account_id).to eq root_account.id
      end
    end

    context "for a post policy associated with an assignment" do
      it "is set to the associated course's root account ID" do
        assignment = course.assignments.create!
        expect(assignment.post_policy.root_account_id).to eq root_account.id
      end
    end
  end
end
