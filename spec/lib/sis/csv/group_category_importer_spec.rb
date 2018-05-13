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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::CSV::GroupCategoryImporter do

  before(:once) do
    account_model
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
  end

  it "should skip bad content" do
    before_count = GroupCategory.count
    importer = process_csv_data(
      "group_category_id,account_id,category_name,status,course_id",
      "GC001,A001,Group Cat 1,active",
      "Gc002,A001,Group Cat 2,blerged",
      "Gc003,A001,,active",
      "Gc004,invalid,Group Cat 4,active",
      "Gc004,invalid,Group Cat 4,active,invalid",
      ",A001,G1,active")
    err = ["Improper status \"blerged\" for group category Gc002, skipping",
           "No name given for group category Gc003",
           "Account with id \"invalid\" didn't exist for group category Gc004",
           "Only one context is allowed and both course_id and account_id where provided for group category Gc004.",
           "No sis_id given for a group category"]
    expect(importer.errors.map(&:last)).to eq(err)
    expect(GroupCategory.count).to eq before_count + 1
  end

  it "should ensure group_category_id is unique" do
    importer = process_csv_data(
      "group_category_id,category_name,status",
      "gc1,Some Category,active",
      "gc1,Other Category,active",
    )
    expect(GroupCategory.all.length).to eq(1)
  end

  it "should create group categories" do
    sub = Account.where(sis_source_id: 'A001').take
    process_csv_data_cleanly(
      "group_category_id,account_id,course_id,category_name,status",
      "Gc001,,\"\",Group Cat 1,active",
      "Gc002,A001,,Group Cat 2,active"
    )
    group_category = GroupCategory.where(sis_source_id: 'Gc001').take
    expect(group_category.context_id).to eq @account.id
    expect(group_category.sis_source_id).to eq 'Gc001'
    expect(group_category.name).to eq "Group Cat 1"
    expect(group_category.deleted_at).to be_nil
    group_category2 = GroupCategory.where(sis_source_id: 'Gc002').take
    expect(group_category2.context_id).to eq sub.id
  end

  it "should allow moving group categories" do
    sub = Account.where(sis_source_id: 'A001').take
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,A001,Group Cat 2,active")
    group_category = GroupCategory.where(sis_source_id: 'Gc001').take
    expect(group_category.context_id).to eq @account.id
    group_category2 = GroupCategory.where(sis_source_id: 'Gc002').take
    expect(group_category2.context_id).to eq sub.id

    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,A001,Group Cat 1,active",
      "Gc002,,Group Cat 2,active")
    expect(group_category.reload.context_id).to eq sub.id
    expect(group_category2.reload.context_id).to eq @account.id
  end

  it "should fail model validations" do
    importer = process_csv_data(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,,Group Cat 1,active")
    expect(importer.errors.map(&:last)).to eq(["A group category did not pass validation (group category: Gc002, error: Name Group Cat 1 is already in use.)"])
  end

  it "should create in a course." do
    course = course_factory(account: @account, sis_source_id: 'c01')
    process_csv_data_cleanly(
      "group_category_id,course_id,category_name,status",
      "Gc001,c01,Group Cat 1,active")
    expect(GroupCategory.where(sis_source_id: 'Gc001').take.context).to eq course
  end

  it "should not allow moving a group category with groups" do
    gc = @account.group_categories.create(name: 'gc1', sis_source_id: 'Gc001')
    gc.groups.create!(root_account: @account, context: @account)
    course_factory(account: @account, sis_source_id: 'c01')
    importer = process_csv_data(
      "group_category_id,course_id,category_name,status",
      "Gc001,c01,Group Cat 1,active")
    expect(importer.errors.last.last).to eq("Cannot move group category Gc001 because it has groups in it.")
  end

  it "should delete and restore group categories" do
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,A001,Group Cat 2,deleted")
    group_category = GroupCategory.where(sis_source_id: 'Gc001').take
    expect(group_category.deleted_at).to be_nil
    group_category2 = GroupCategory.where(sis_source_id: 'Gc002').take
    expect(group_category2.deleted_at).to_not be_nil

    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,deleted",
      "Gc002,A001,Group Cat 2,active")
    expect(group_category.reload.deleted_at).to_not be_nil
    expect(group_category2.reload.deleted_at).to be_nil
  end

  it "should not fail on refactored importer" do
    @account.enable_feature!(:refactor_of_sis_imports)
    importer = process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc002,A001,Group Cat 2,deleted")
    expect(importer.errors).to eq []
  end

  it 'should create rollback data' do
    @account.enable_feature!(:refactor_of_sis_imports)
    batch1 = @account.sis_batches.create! {|sb| sb.data = {}}
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
    batch3 = @account.sis_batches.create! {|sb| sb.data = {}}
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc003,A001,Group Cat 2,active",
      batch: batch3
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: 'non-existent').count).to eq 1
    expect(batch2.roll_back_data.where(updated_workflow_state: 'deleted').count).to eq 1
    expect(batch3.roll_back_data.where(updated_workflow_state: 'active').count).to eq 1
    batch3.restore_states_for_batch
    expect(@account.all_group_categories.where(sis_source_id: 'Gc003').take.deleted_at).not_to be_nil
  end

end
