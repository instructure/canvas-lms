# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe SIS::CSV::DifferentiationTagMembershipImporter do
  before { account_model }

  before do
    account_model
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Test Diff Tags,active",
      "A002,,No Diff Tags,active"
    )
    @tags_account = Account.find_by(sis_source_id: "A001")
    @tags_account.settings[:allow_assign_to_differentiation_tags] = { value: true }
    @tags_account.save!
    @no_tags_account = Account.find_by(sis_source_id: "A002")
    @no_tags_account.settings[:allow_assign_to_differentiation_tags] = { value: false }
    @no_tags_account.save!
    process_csv_data_cleanly(
      "course_id,short_name,long_name,status,account_id",
      "C001,C1,Course1,active,A001",
      "C002,C2,Course2,active,A002"
    )
    @course = Course.find_by(sis_source_id: "C001")
    @no_tags_course = Course.find_by(sis_source_id: "C002")
    tag_set = @course.differentiation_tag_categories.create!(name: "Tag Set 1", non_collaborative: true)
    @tag = tag_set.groups.create!(context: @course, sis_source_id: "T001", non_collaborative: true)
    @user1 = user_with_pseudonym(username: "u1@example.com")
    @user1.pseudonym.update_attribute(:sis_user_id, "U001")
    @user1.pseudonym.update_attribute(:account, @account)
    @user2 = user_with_pseudonym(username: "u2@example.com")
    @user2.pseudonym.update_attribute(:sis_user_id, "U002")
    @user2.pseudonym.update_attribute(:account, @account)
    @user3 = user_with_pseudonym(username: "u3@example.com")
    @user3.pseudonym.update_attribute(:sis_user_id, "U003")
    @user3.pseudonym.update_attribute(:account, @account)
    @course.enroll_student(@user1)
    @no_tags_course.enroll_student(@user1)
    @course.enroll_student(@user2)
    @course.enroll_student(@user3)
  end

  it "skips bad content" do
    # enable it to create a tag
    @no_tags_account.settings[:allow_assign_to_differentiation_tags] = { value: true }
    @no_tags_account.save!
    tag_set_2 = @no_tags_course.differentiation_tag_categories.create!(name: "Tag Set 2", non_collaborative: true)
    tag_set_2.groups.create!(context: @no_tags_course, sis_source_id: "T002", non_collaborative: true)
    # then disable it again
    @no_tags_account.settings[:allow_assign_to_differentiation_tags] = { value: false }
    @no_tags_account.save!
    importer = process_csv_data(
      "tag_id,user_id,status",
      ",U001,accepted",
      "T001,,accepted",
      "T001,U001,bogus",
      "T002,U001,accepted"
    )
    expect(GroupMembership.count).to eq 0
    expect(importer.errors.map(&:last)).to eq(
      ["No tag_id given for a differentiation tag user",
       "No user_id given for a differentiation tag user",
       "Improper status \"bogus\" for a differentiation tag user",
       "Differentiation Tags are not enabled for Account #{@no_tags_account.id}."]
    )
  end

  it "adds users to tags" do
    process_csv_data_cleanly(
      "tag_id,user_id,status",
      "T001,U001,accepted",
      "T001,U003,deleted"
    )
    ms = GroupMembership.order(:id).to_a
    expect(ms.map(&:user_id)).to eq [@user1.id, @user3.id]
    expect(ms.map(&:group_id)).to eq [@tag.id, @tag.id]
    expect(ms.map(&:workflow_state)).to eq %w[accepted deleted]

    process_csv_data_cleanly(
      "tag_id,user_id,status",
      "T001,U001,deleted",
      "T001,U003,deleted"
    )
    ms = GroupMembership.order(:id).to_a
    expect(ms.map(&:user_id)).to eq [@user1.id, @user3.id]
    expect(ms.map(&:group_id)).to eq [@tag.id, @tag.id]
    expect(ms.map(&:workflow_state)).to eq %w[deleted deleted]
  end

  it "does not add users to tags in courses they are not enrolled in" do
    course = course_factory(account: @tags_account, sis_source_id: "c002")
    tag_set = course.differentiation_tag_categories.create!(name: "Tag Set 2", non_collaborative: true)
    tag_set.groups.create!(context: course, sis_source_id: "T002", non_collaborative: true)
    importer = process_csv_data(
      "tag_id,user_id,status",
      "T002,U001,accepted"
    )
    expect(importer.errors.last.last).to eq "User U001 doesn't have an enrollment in the course of differentiation tag T002."
  end

  it "finds active gm first" do
    tag_set = @course.differentiation_tag_categories.create!(name: "Tag Set 1", non_collaborative: true)
    tag = tag_set.groups.create!(context: @course, sis_source_id: "T002", non_collaborative: true)
    tag.group_memberships.create!(user: @user1, workflow_state: "accepted")
    tag.group_memberships.create!(user: @user1, workflow_state: "deleted")
    importer = process_csv_data_cleanly(
      "tag_id,user_id,status",
      "T002,U001,accepted"
    )
    expect(importer.errors).to eq []
  end

  it "creates rollback data" do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "tag_id,user_id,status",
      "T001,U001,accepted",
      batch: batch1
    )
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "tag_id,user_id,status",
      "T001,U001,deleted",
      batch: batch2
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: "non-existent").count).to eq 1
    expect(batch2.roll_back_data.first.updated_workflow_state).to eq "deleted"
    batch2.restore_states_for_batch
    expect(@account.all_differentiation_tags.find_by(sis_source_id: "T001").group_memberships.take.workflow_state).to eq "accepted"
  end

  it "handles unique constraint errors rolling back data" do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "tag_id,user_id,status",
      "T001,U001,accepted",
      "T001,U002,accepted",
      batch: batch1
    )
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "tag_id,user_id,status",
      "T001,U001,deleted",
      "T001,U002,deleted",
      batch: batch2
    )
    tag = @account.all_differentiation_tags.find_by(sis_source_id: "T001")
    deleted_gm = GroupMembership.find_by(group_id: tag, user_id: @user1)
    tag.group_memberships.create!(workflow_state: "accepted", user: @user1)
    batch2.restore_states_for_batch
    expect(batch2.sis_batch_errors.last.message).to include("Couldn't rollback SIS batch data for row")
    expect(batch2.roll_back_data.find_by(context_type: "GroupMembership", context_id: deleted_gm.id).workflow_state).to eq "failed"
    expect(tag.group_memberships.find_by(user_id: @user2).workflow_state).to eq "accepted" # should restore the one still
  end
end
