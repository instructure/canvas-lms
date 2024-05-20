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

describe SIS::CSV::GroupCategoryImporter do
  before(:once) do
    account_model
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
  end

  it "skips bad content" do
    before_count = GroupCategory.count
    importer = process_csv_data(
      "group_category_id,account_id,category_name,status,course_id",
      "GC001,A001,Group Cat 1,active",
      "Gc002,A001,Group Cat 2,blerged",
      "Gc003,A001,,active",
      "Gc004,invalid,Group Cat 4,active",
      "Gc004,invalid,Group Cat 4,active,invalid",
      ",A001,G1,active"
    )
    err = ["Improper status \"blerged\" for group category Gc002, skipping",
           "No name given for group category Gc003",
           "Account with id \"invalid\" didn't exist for group category Gc004",
           "Only one context is allowed and both course_id and account_id where provided for group category Gc004.",
           "No sis_id given for a group category"]
    expect(importer.errors.map(&:last)).to eq(err)
    expect(GroupCategory.count).to eq before_count + 1
  end

  it "ensures group_category_id is unique" do
    process_csv_data(
      "group_category_id,category_name,status",
      "gc1,Some Category,active",
      "gc1,Other Category,active"
    )
    expect(GroupCategory.all.length).to eq(1)
  end

  it "creates group categories" do
    sub = Account.where(sis_source_id: "A001").take
    process_csv_data_cleanly(
      "group_category_id,account_id,course_id,category_name,status",
      "Gc001,,\"\",Group Cat 1,active",
      "Gc002,A001,,Group Cat 2,active"
    )
    group_category = GroupCategory.where(sis_source_id: "Gc001").take
    expect(group_category.context_id).to eq @account.id
    expect(group_category.sis_source_id).to eq "Gc001"
    expect(group_category.name).to eq "Group Cat 1"
    expect(group_category.deleted_at).to be_nil
    group_category2 = GroupCategory.where(sis_source_id: "Gc002").take
    expect(group_category2.context_id).to eq sub.id
  end

  it "allows moving group categories" do
    sub = Account.where(sis_source_id: "A001").take
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,A001,Group Cat 2,active"
    )
    group_category = GroupCategory.where(sis_source_id: "Gc001").take
    expect(group_category.context_id).to eq @account.id
    group_category2 = GroupCategory.where(sis_source_id: "Gc002").take
    expect(group_category2.context_id).to eq sub.id

    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,A001,Group Cat 1,active",
      "Gc002,,Group Cat 2,active"
    )
    expect(group_category.reload.context_id).to eq sub.id
    expect(group_category2.reload.context_id).to eq @account.id
  end

  it "fails model validations" do
    importer = process_csv_data(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,,Group Cat 1,active"
    )
    expect(importer.errors.map(&:last)).to eq(["A group category did not pass validation (group category: Gc002, error: Name Group Cat 1 is already in use.)"])
  end

  it "creates in a course." do
    course = course_factory(account: @account, sis_source_id: "c01")
    process_csv_data_cleanly(
      "group_category_id,course_id,category_name,status",
      "Gc001,c01,Group Cat 1,active"
    )
    expect(GroupCategory.where(sis_source_id: "Gc001").take.context).to eq course
  end

  it "does not allow moving a group category with groups" do
    gc = @account.group_categories.create(name: "gc1", sis_source_id: "Gc001")
    gc.groups.create!(root_account: @account, context: @account)
    course_factory(account: @account, sis_source_id: "c01")
    importer = process_csv_data(
      "group_category_id,course_id,category_name,status",
      "Gc001,c01,Group Cat 1,active"
    )
    expect(importer.errors.last.last).to eq("Cannot move group category Gc001 because it has groups in it.")
  end

  it "deletes and restore group categories" do
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,A001,Group Cat 2,deleted"
    )
    group_category = GroupCategory.where(sis_source_id: "Gc001").take
    expect(group_category.deleted_at).to be_nil
    group_category2 = GroupCategory.where(sis_source_id: "Gc002").take
    expect(group_category2.deleted_at).to_not be_nil

    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,deleted",
      "Gc002,A001,Group Cat 2,active"
    )
    expect(group_category.reload.deleted_at).to_not be_nil
    expect(group_category2.reload.deleted_at).to be_nil
  end

  it "does not fail on refactored importer" do
    importer = process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc002,A001,Group Cat 2,deleted"
    )
    expect(importer.errors).to eq []
  end

  it "creates rollback data" do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc003,A001,Group Cat 2,active",
      batch: batch1
    )
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc003,A001,Group Cat 2,deleted",
      batch: batch2
    )
    batch3 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc003,A001,Group Cat 2,active",
      batch: batch3
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: "non-existent").count).to eq 1
    expect(batch2.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 1
    expect(batch3.roll_back_data.where(updated_workflow_state: "active").count).to eq 1
    batch3.restore_states_for_batch
    expect(@account.all_group_categories.where(sis_source_id: "Gc003").take.deleted_at).not_to be_nil
  end

  context "group integration" do
    it "ensures consistency of SIS-imported group categories within a course after a course reset and re-import" do
      course_sis_id = "c001"
      group_category_sis_id = "gc001"

      # required fields: group_category_id (aka sis_source_id internally), category_name, status
      group_categories_csv = [
        "group_category_id,course_id,category_name,status",
        "#{group_category_sis_id},#{course_sis_id},Group Category 1,active",
      ]

      # required fields: group_id (aka sis_source_id internally), name, status
      groups_csv = [
        "group_id,group_category_id,course_id,name,status",
        # when adding a group to a sis-created group_category, Canvas will
        # automatically create a default “Student Groups” group_category
        "g001,#{group_category_sis_id},#{course_sis_id},Group 1,available",
      ]

      # create course (sis_source_id is required in order for the
      # SIS-imported data to be associated with the course)
      course = course_factory(account: @account,
                              sis_source_id: course_sis_id)
      expect(course.group_categories).to be_empty
      expect(course.groups).to be_empty

      # SIS import the group_categories and groups
      process_csv_data(*group_categories_csv)
      process_csv_data(*groups_csv)

      expect(course.group_categories.count).to eq 1
      expect(course.groups.count).to eq 1
      expect(course.groups.count do |g|
        g.group_category.name == "Group Category 1"
      end).to eq 1

      group_categories = GroupCategory.where(context_id: course_sis_id)
      groups = Group.where(context_id: course_sis_id)

      group_categories.each do |gc|
        expect(gc.context).to eq course
        # explicitly check the context_id for sanity’s sake
        expect(gc.context_id).to eq course.id
      end
      groups.each do |g|
        expect(g.context).to eq course
        expect(g.context_id).to eq course.id
      end

      # do a course reset and reload potentially-updated objects
      new_course = course.reset_content
      [course, group_categories, groups].map!(&:reload)

      expect(new_course.group_categories).to be_empty
      expect(new_course.groups).to be_empty

      # group_category and group should still be in the old course
      expect(course.group_categories.count).to eq 1
      expect(course.groups.count).to eq 1
      expect(course.groups.count do |g|
        g.group_category.name == "Group Category 1"
      end).to eq 1

      group_categories.each do |gc|
        expect(gc.context).to eq course
        expect(gc.context_id).to eq course.id
      end
      groups.each do |g|
        expect(g.context).to eq course
        expect(g.context_id).to eq course.id
      end

      # SIS import the group_categories and groups (again)
      process_csv_data(*group_categories_csv)
      process_csv_data(*groups_csv)

      [course, new_course, group_categories, groups].map!(&:reload)

      # sis-created group_category can’t be moved “because it has groups in it”
      # the “SIS Import” UI will warn the user and the import will be skipped
      expect(course.group_categories.count).to eq 1
      expect(course.groups.count).to eq 1
      expect(course.groups.count do |g|
        g.group_category.name == "Group Category 1"
      end).to eq 1

      group_categories.each do |gc|
        expect(gc.context).to eq course
        expect(gc.context_id).to eq course.id
      end
      groups.each do |g|
        expect(g.context).to eq course
        expect(g.context_id).to eq course.id
      end

      # because group_category had groups, the new course
      # shouldn’t have any group_categories or groups
      expect(new_course.group_categories).to be_empty
      expect(new_course.groups).to be_empty
    end

    it "does not move a group or group category when the group is modified without providing context" do
      course = course_factory(account: @account, sis_source_id: "c1")
      group_category = course.group_categories.create!(name: "gc1", sis_source_id: "gc1")
      group = course.groups.create!(group_category:, name: "g1", sis_source_id: "g1")
      process_csv_data_cleanly(
        "group_id,name,status",
        "g1,g1frd,available"
      )
      expect(group.reload.context).to eq course
      expect(group_category.reload.context).to eq course
    end
  end
end
