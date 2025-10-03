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

describe SIS::CSV::DifferentiationTagSetImporter do
  before(:once) do
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
  end

  it "skips bad content" do
    before_count = GroupCategory.count
    importer = process_csv_data(
      "tag_set_id,course_id,set_name,status",
      "TS001,C001,Tag Set 1,active",
      "TS002,C001,Tag Set 2,blerged",
      "TS003,C001,,active",
      "TS004,,Tag Set 4,active",
      ",C001,Tag Set 6,active",
      "TS007,C003,Tag Set 7,active",
      "TS008,C002,Tag Set 8,active"
    )
    err = ["Improper status \"blerged\" for differentiation tag set TS002, skipping",
           "No name given for differentiation tag set TS003",
           "No course_id given for differentiation tag set TS004",
           "No sis_id given for a differentiation tag set",
           "Course with id \"C003\" didn't exist for differentiation tag set TS007",
           "Differentiation Tags are not enabled for Account #{@no_tags_account.id}."]
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
    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts001,C001,Tag Set 1,active",
      "Ts002,C001,Tag Set 2,deleted"
    )
    tag_set = GroupCategory.non_collaborative.find_by(sis_source_id: "Ts001")
    expect(tag_set.context_id).to eq @course.id
    expect(tag_set.sis_source_id).to eq "Ts001"
    expect(tag_set.name).to eq "Tag Set 1"
    expect(tag_set.deleted_at).to be_nil
    tag_set2 = GroupCategory.non_collaborative.find_by(sis_source_id: "Ts002")
    expect(tag_set2.deleted_at).not_to be_nil
  end

  it "allows moving tag sets" do
    course1 = @course
    course3 = course_model(account: @tags_account)
    course3.update_attribute("sis_source_id", "C003")
    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts001,C001,Tag Set 1,active",
      "Ts002,C001,Tag Set 2,active"
    )
    tag_set = GroupCategory.non_collaborative.find_by(sis_source_id: "Ts001")
    expect(tag_set.context_id).to eq course1.id
    tag_set2 = GroupCategory.non_collaborative.find_by(sis_source_id: "Ts002")
    expect(tag_set2.context_id).to eq course1.id

    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts001,C003,Tag Set 1,active",
      "Ts002,C003,Tag Set 2,active"
    )
    expect(tag_set.reload.context_id).to eq course3.id
    expect(tag_set2.reload.context_id).to eq course3.id
  end

  it "specified course must exist" do
    importer = process_csv_data(
      "tag_set_id,course_id,set_name,status",
      "Ts001,C004,Tag Set 1,active"
    )
    expect(importer.errors.map(&:last)).to eq(["Course with id \"C004\" didn't exist for differentiation tag set Ts001"])
  end

  it "does not allow moving a tag set with tags" do
    ts = @course.differentiation_tag_categories.create(name: "ts1", sis_source_id: "Ts001", non_collaborative: true)
    ts.groups.create!(root_account: @account, context: @course, non_collaborative: true)
    course_factory(account: @tags_account, sis_source_id: "C003")
    importer = process_csv_data(
      "tag_set_id,course_id,set_name,status",
      "Ts001,C003,Tag Set 1,active"
    )
    expect(importer.errors.last.last).to eq("Cannot move differentiation tag set Ts001 because it has tags in it.")
  end

  it "deletes and restore tag sets" do
    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts001,C001,Tag Set 1,active",
      "Ts002,C001,Tag Set 2,deleted"
    )
    tag_set = GroupCategory.non_collaborative.find_by(sis_source_id: "Ts001")
    expect(tag_set.deleted_at).to be_nil
    tag_set2 = GroupCategory.non_collaborative.find_by(sis_source_id: "Ts002")
    expect(tag_set2.deleted_at).to_not be_nil

    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts001,C001,Tag Set 1,deleted",
      "Ts002,C001,Tag Set 2,active"
    )
    expect(tag_set.reload.deleted_at).to_not be_nil
    expect(tag_set2.reload.deleted_at).to be_nil
  end

  it "creates rollback data" do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts003,C001,Tag Set 3,active",
      batch: batch1
    )
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts003,C001,Tag Set 3,deleted",
      batch: batch2
    )
    batch3 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts003,C001,Tag Set 3,active",
      batch: batch3
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: "non-existent").count).to eq 1
    expect(batch2.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 1
    expect(batch3.roll_back_data.where(updated_workflow_state: "active").count).to eq 1
    batch3.restore_states_for_batch
    expect(@account.all_differentiation_tag_categories.find_by(sis_source_id: "Ts003").deleted_at).not_to be_nil
  end

  context "tag integration" do
    it "ensures consistency of SIS-imported tag sets within a course after a course reset and re-import" do
      course_sis_id = "c001"
      tag_set_sis_id = "ts001"

      tag_sets_csv = [
        "tag_set_id,course_id,set_name,status",
        "#{tag_set_sis_id},#{course_sis_id},Tag Set 1,active",
      ]

      tags_csv = [
        "tag_id,tag_set_id,course_id,name,status",
        "t001,#{tag_set_sis_id},#{course_sis_id},Tag 1,available",
      ]

      course = course_factory(account: @tags_account,
                              sis_source_id: course_sis_id)
      expect(course.differentiation_tag_categories).to be_empty
      expect(course.differentiation_tags).to be_empty

      process_csv_data(*tag_sets_csv)
      process_csv_data(*tags_csv)

      expect(course.differentiation_tag_categories.count).to eq 1
      expect(course.differentiation_tags.count).to eq 1
      expect(course.differentiation_tags.count do |t|
        t.group_category.name == "Tag Set 1"
      end).to eq 1

      tag_sets = GroupCategory.non_collaborative.where(context_id: course_sis_id)
      tags = Group.non_collaborative.where(context_id: course_sis_id)

      tag_sets.each do |ts|
        expect(ts.context).to eq course
        # explicitly check the context_id for sanity’s sake
        expect(ts.context_id).to eq course.id
      end
      tags.each do |t|
        expect(t.context).to eq course
        expect(t.context_id).to eq course.id
      end

      # do a course reset and reload potentially-updated objects
      new_course = course.reset_content
      [course, tag_sets, tags].map!(&:reload)

      expect(new_course.differentiation_tag_categories).to be_empty
      expect(new_course.differentiation_tags).to be_empty

      # tag_set and tag should still be in the old course
      expect(course.differentiation_tag_categories.count).to eq 1
      expect(course.differentiation_tags.count).to eq 1
      expect(course.differentiation_tags.count do |t|
        t.group_category.name == "Tag Set 1"
      end).to eq 1

      tag_sets.each do |ts|
        expect(ts.context).to eq course
        expect(ts.context_id).to eq course.id
      end
      tags.each do |t|
        expect(t.context).to eq course
        expect(t.context_id).to eq course.id
      end

      # SIS import the tag_sets and tags (again)
      process_csv_data(*tag_sets_csv)
      process_csv_data(*tags_csv)

      [course, new_course, tag_sets, tags].map!(&:reload)

      # sis-created tag_set can’t be moved “because it has tags in it”
      # the “SIS Import” UI will warn the user and the import will be skipped
      expect(course.differentiation_tag_categories.count).to eq 1
      expect(course.differentiation_tags.count).to eq 1
      expect(course.differentiation_tags.count do |t|
        t.group_category.name == "Tag Set 1"
      end).to eq 1

      tag_sets.each do |ts|
        expect(ts.context).to eq course
        expect(ts.context_id).to eq course.id
      end
      tags.each do |t|
        expect(t.context).to eq course
        expect(t.context_id).to eq course.id
      end

      # because tag_set had tags, the new course
      # shouldn’t have any tag_sets or tags
      expect(new_course.differentiation_tag_categories).to be_empty
      expect(new_course.differentiation_tags).to be_empty
    end

    it "does not move a tag or tag set when the tag is modified without providing context" do
      course = course_factory(account: @tags_account, sis_source_id: "c1")
      tag_set = course.differentiation_tag_categories.create!(name: "ts1", sis_source_id: "ts1")
      tag = course.differentiation_tags.create!(group_category: tag_set, name: "t1", sis_source_id: "t1")
      process_csv_data_cleanly(
        "tag_id,name,status",
        "t1,t1frd,available"
      )
      expect(tag.reload.context).to eq course
      expect(tag_set.reload.context).to eq course
    end
  end
end
