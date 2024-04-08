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

describe Loaders::SubmissionGroupIdLoader do
  before do
    account = Account.create!
    course = account.courses.create!
    @first_student = course.enroll_student(User.create!, enrollment_state: "active").user
    @second_student = course.enroll_student(User.create!, enrollment_state: "active").user
    @third_student = course.enroll_student(User.create!, enrollment_state: "active").user
    group_category = course.group_categories.create!(name: "My Category")
    @group_a = course.groups.create!(name: "Group A", group_category:)
    @group_b = course.groups.create!(name: "Group B", group_category:)
    @group_a.add_user(@first_student)
    @group_a.save!
    @group_b.add_user(@second_student)
    @group_b.save!
    @assignment = course.assignments.create!(title: "Example Assignment", group_category:)
  end

  let(:group_a_submission) { @assignment.submissions.find_by(user: @first_student) }
  let(:group_b_submission) { @assignment.submissions.find_by(user: @second_student) }
  let(:ungrouped_submission) { @assignment.submissions.find_by(user: @third_student) }
  let(:loader) { Loaders::SubmissionGroupIdLoader }

  it "returns the group id associated with the user, before the group has submitted" do
    GraphQL::Batch.batch do
      loader.load(group_a_submission).then do |group_id|
        expect(group_id).to eq @group_a.id
      end

      loader.load(group_b_submission).then do |group_id|
        expect(group_id).to eq @group_b.id
      end
    end
  end

  it "returns the group id associated with the user, after the group has submitted" do
    @assignment.submit_homework(@first_student, body: "help my legs are stuck under my desk!")
    @assignment.submit_homework(@second_student, body: "hello world!")

    GraphQL::Batch.batch do
      loader.load(group_a_submission).then do |group_id|
        expect(group_id).to eq @group_a.id
      end

      loader.load(group_b_submission).then do |group_id|
        expect(group_id).to eq @group_b.id
      end
    end
  end

  it "returns nil for users not in groups" do
    GraphQL::Batch.batch do
      loader.load(ungrouped_submission).then do |group_id|
        expect(group_id).to be_nil
      end
    end
  end

  it "returns nil for non-group assignments" do
    @assignment.update!(group_category: nil)
    GraphQL::Batch.batch do
      loader.load(group_a_submission).then do |group_id|
        expect(group_id).to be_nil
      end

      loader.load(group_b_submission).then do |group_id|
        expect(group_id).to be_nil
      end

      loader.load(ungrouped_submission).then do |group_id|
        expect(group_id).to be_nil
      end
    end
  end
end
