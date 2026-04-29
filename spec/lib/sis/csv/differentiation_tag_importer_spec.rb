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

describe SIS::CSV::DifferentiationTagImporter do
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
    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts001,C001,Tag Set 1,active",
      "Ts002,C001,Tag Set 2,active"
    )
    before_count = Group.non_collaborative.count
    importer = process_csv_data(
      "tag_id,tag_set_id,course_id,name,status",
      "T001,,C001,Tag 1,available",
      "T001,,invalid,Tag 1,available",
      "T002,,C001,Tag 1,blerged",
      "T003,,C001,,available",
      ",,C001,T1,available,",
      "T006,invalid,C001,Tag 6,available",
      "T007,invalid,,Tag7,available",
      "T008,,C002,Tag 8,available"
    )
    err = ["Course with sis id invalid didn't exist for differentiation tag T001.",
           "Improper status \"blerged\" for differentiation tag T002.",
           "No name given for differentiation tag T003.",
           "No tag_id given for a differentiation tag.",
           "Differentiation Tag Set invalid didn't exist in course C001 for differentiation tag T006.",
           "Differentiation Tag Set invalid didn't exist for differentiation tag T007.",
           "Differentiation Tags are not enabled for Account #{@no_tags_account.id}."]
    expect(importer.errors.map(&:last)).to eq err
    expect(Group.count).to eq before_count + 1
  end

  it "creates tags" do
    process_csv_data_cleanly(
      "tag_id,tag_set_id,course_id,name,status",
      "T001,,C001,Tag 1,available",
      "T002,,C001,Tag 2,deleted"
    )
    tags = Group.non_collaborative.order(:id).to_a
    expect(tags.map(&:context_id)).to eq [@course.id, @course.id]
    expect(tags.map(&:sis_source_id)).to eq %w[T001 T002]
    expect(tags.map(&:name)).to eq ["Tag 1", "Tag 2"]
    expect(tags.map(&:workflow_state)).to eq %w[available deleted]
  end

  it "creates tags within given tag_set_id" do
    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts001,C001,Tag Set 1,active"
    )
    process_csv_data_cleanly(
      "tag_id,tag_set_id,name,status",
      "T001,Ts001,Tag 1,available"
    )
    GroupCategory.non_collaborative.find_by(sis_source_id: "Ts001")
    tags = Group.non_collaborative.order(:id).to_a
    expect(tags.map(&:context_id)).to eq [@course.id]
    expect(tags.map(&:sis_source_id)).to eq %w[T001]
    expect(tags.map(&:name)).to eq ["Tag 1"]
    expect(tags.map(&:workflow_state)).to eq %w[available]
  end

  it "creates rollback data" do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "tag_id,course_id,name,status",
      "T001,C001,Tag 1,available",
      batch: batch1
    )
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "U001,user1,User,Uno,user@example.com,active"
    )
    @course.enroll_student(@account.pseudonyms.find_by(sis_user_id: "U001").user)
    process_csv_data_cleanly(
      "tag_id,user_id,status",
      "T001,U001,accepted",
      batch: batch2
    )
    batch3 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "tag_id,name,status",
      "T001,Troup 1,deleted",
      batch: batch3
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: "non-existent").count).to eq 1
    expect(batch3.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 2
    batch3.restore_states_for_batch
    expect(@account.all_differentiation_tags.find_by(sis_source_id: "T001").workflow_state).to eq "available"
  end

  it "updates tag attributes" do
    process_csv_data_cleanly(
      "tag_id,course_id,name,status",
      "T001,C001,Tag 1,available",
      "T002,C001,Tag 2,available"
    )
    expect(Group.non_collaborative.count).to eq 2
    Group.non_collaborative.where(sis_source_id: "T001").first.update_attribute(:name, "Tag 1-1")
    process_csv_data_cleanly(
      "tag_id,course_id,name,status",
      "T001,C001,Tag 1-b,available",
      "T002,C001,Tag 2-b,deleted"
    )
    # tag 1's name won't change because it was manually changed
    tags = Group.non_collaborative.order(:id).to_a
    expect(tags.map(&:name)).to eq ["Tag 1-1", "Tag 2-b"]
    expect(tags.map(&:context)).to eq [@course, @course]
    expect(tags.map(&:workflow_state)).to eq %w[available deleted]
  end

  it "uses tag_set_id and set sis_id" do
    process_csv_data_cleanly(
      "tag_set_id,course_id,set_name,status",
      "Ts001,C001,Tag Set 1,active",
      "Ts002,C001,Tag Set 2,active"
    )
    process_csv_data_cleanly(
      "tag_id,tag_set_id,name,status",
      "T001,Ts001,Tag 1,available",
      "T002,Ts002,Tag 2,available"
    )
    tag1 = Group.non_collaborative.find_by(sis_source_id: "T001")
    tag2 = Group.non_collaborative.find_by(sis_source_id: "T002")
    tags = [tag1, tag2]
    expect(tags.map(&:context)).to eq [@course, @course]
    expect(tags.map(&:group_category)).to eq GroupCategory.non_collaborative.order(:id).to_a
  end

  it "does not allow changing course_id with tag memberships" do
    course1 = course_factory(account: @tags_account, sis_source_id: "c003")
    course_factory(account: @tags_account, sis_source_id: "c004")
    tag_set = course1.group_categories.create!(name: "Tag Set 1", non_collaborative: true)
    tag = tag_set.groups.create!(context: course1, sis_source_id: "T001", non_collaborative: true)
    tag.group_memberships.create!(user: user_model)

    importer = process_csv_data(
      "tag_id,course_id,name,status",
      "T001,c004,Tag 1,available"
    )
    expect(importer.errors.last.last).to eq "Cannot move differentiation tag T001 because it has differentiation_tag_memberships."
  end

  context "tag_set integration" do
    it "ensures consistency of SIS-imported tags within a course after a course reset and re-import" do
      course_sis_id = "c001"

      tags_csv = [
        "tag_id,course_id,name,status",
        "t001,#{course_sis_id},Tag 1,available",
        "t002,#{course_sis_id},Tag 2,available",
        "t003,#{course_sis_id},Tag 3,available",
      ]

      course = course_factory(account: @tags_account,
                              sis_source_id: course_sis_id)
      expect(course.differentiation_tag_categories).to be_empty
      expect(course.differentiation_tags).to be_empty

      # SIS import the tags
      process_csv_data(*tags_csv)

      expect(course.differentiation_tag_categories.count).to eq 3
      expect(course.differentiation_tags.count).to eq 3
      expect(course.differentiation_tags.count do |t|
        # when a tag_set is not defined, the tag is
        # created as a "single tag"
        t.group_category.name == t.name
      end).to eq 3

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

      # tag_sets and tags should still be in the old course
      expect(course.differentiation_tag_categories.count).to eq 3
      expect(course.differentiation_tags.count).to eq 3
      expect(course.differentiation_tags.count do |t|
        t.group_category.name == t.name
      end).to eq 3

      tag_sets.each do |ts|
        expect(ts.context).to eq course
        expect(ts.context_id).to eq course.id
      end
      tags.each do |t|
        expect(t.context).to eq course
        expect(t.context_id).to eq course.id
      end

      # SIS import the tags (again)
      process_csv_data(*tags_csv)

      [course, new_course, tag_sets, tags].map!(&:reload)

      # old course no longer has the updated tag_set and tag
      expect(course.differentiation_tag_categories).to be_empty
      expect(course.differentiation_tags).to be_empty

      # new_course should have the updated tag_set and tag
      expect(new_course.differentiation_tag_categories.count).to eq 3
      expect(new_course.differentiation_tags.count).to eq 3
      expect(new_course.differentiation_tags.count do |t|
        t.group_category.name == t.name
      end).to eq 3

      tag_sets.each do |ts|
        expect(ts.context).to eq new_course
        expect(ts.context_id).to eq new_course.id
      end
      tags.each do |t|
        expect(t.context).to eq new_course
        expect(t.context_id).to eq new_course.id
      end
    end

    it "does not update the tag_set when a tag with a matching tag_set and context_id is created" do
      course_sis_id = "c001"
      tag_set_sis_id = "ts001"
      tag_sis_id = "t001"

      tags_csv = [
        "tag_id,tag_set_id,course_id,name,status",
        "#{tag_sis_id},#{tag_set_sis_id},#{course_sis_id},Tag 1,available",
      ]

      course = course_factory(account: @tags_account,
                              sis_source_id: course_sis_id)
      tag_set = course.differentiation_tag_categories.create(name: "Tag Set 1", sis_source_id: tag_set_sis_id, non_collaborative: true)

      tag_set_context_id = tag_set&.context_id
      expect(tag_set_context_id).to eq course.id

      process_csv_data(*tags_csv)

      # the tag set should not be updated
      expect(tag_set.context_id).to eq tag_set_context_id
    end

    it "creates a single tag when a tag_set_id is not provided" do
      course_sis_id = "c001"
      tag_sis_id = "t001"

      tags_csv = [
        "tag_id,tag_set_id,course_id,name,status",
        "#{tag_sis_id},,#{course_sis_id},Tag 1,available",
      ]

      course_factory(account: @tags_account,
                     sis_source_id: course_sis_id)

      process_csv_data(*tags_csv)

      tag = Group.non_collaborative.find_by(sis_source_id: tag_sis_id)
      expect(tag.group_category.name).to eq tag.name
    end

    it "updates the context_id of tag_set to match the course for an existing tag" do
      course_sis_id = "c001"
      tag_sis_id = "t001"

      tags_csv = [
        "tag_id,tag_set_id,course_id,name,status",
        "#{tag_sis_id},,#{course_sis_id},Tag 1,available",
      ]

      course = course_factory(account: @tags_account,
                              sis_source_id: course_sis_id)
      course2 = course_factory(account: @tags_account)
      tag_set = course.differentiation_tag_categories.create(name: "Tag 1", non_collaborative: true)
      tag_set.groups.create(name: "Tag 1", sis_source_id: tag_sis_id, non_collaborative: true)

      tag_set&.update_attribute(:context_id, course2.id)
      expect(tag_set&.context_id).to eq course2.id

      process_csv_data(*tags_csv)

      tag_set&.reload

      # the context_id of the tag_set
      # should be updated to match the course the tag belongs to
      expect(tag_set&.context_id).to eq course.id
    end
  end
end
