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
      "group_category_id,account_id,category_name,status",
      "GC001,A001,Group Cat 1,active",
      "Gc002,A001,Group Cat 2,blerged",
      "Gc003,A001,,active",
      "Gc004,invalid,Group Cat 4,active",
      ",A001,G1,active")
    expect(importer.errors).to eq []
    expect(importer.warnings.map(&:last)).to eq(
                                               ["Improper status \"blerged\" for group category Gc002, skipping",
                                                "No name given for group category Gc003",
                                                "Account with id \"invalid\" didn't exist for group category Gc004",
                                                "No sis_id given for a group category"]
                                             )
    expect(GroupCategory.count).to eq before_count + 1
  end

  it "should create group categories" do
    @sub = Account.where(sis_source_id: 'A001').take
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,A001,Group Cat 2,active")
    group_category = GroupCategory.where(sis_source_id: 'Gc001').take
    expect(group_category.context_id).to eq @account.id
    expect(group_category.sis_source_id).to eq 'Gc001'
    expect(group_category.name).to eq "Group Cat 1"
    expect(group_category.deleted_at).to be_nil
    group_category2 = GroupCategory.where(sis_source_id: 'Gc002').take
    expect(group_category2.context_id).to eq @sub.id
  end

  it "should allow moving group categories" do
    @sub = Account.where(sis_source_id: 'A001').take
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,A001,Group Cat 2,active")
    group_category = GroupCategory.where(sis_source_id: 'Gc001').take
    expect(group_category.context_id).to eq @account.id
    group_category2 = GroupCategory.where(sis_source_id: 'Gc002').take
    expect(group_category2.context_id).to eq @sub.id

    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,A001,Group Cat 1,active",
      "Gc002,,Group Cat 2,active")
    expect(group_category.reload.context_id).to eq @sub.id
    expect(group_category2.reload.context_id).to eq @account.id
  end

  it "should fail model validations" do
    @sub = Account.where(sis_source_id: 'A001').take
    importer = process_csv_data(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,,Group Cat 1,active")
    expect(importer.errors).to eq []
    expect(importer.warnings.map(&:last)).to eq(["A group category did not pass validation (group category: Gc002, error: Name Group Cat 1 is already in use.)"])
  end

  it "should delete and restore group categories" do
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,A001,Group Cat 2,deleted")
    group_category= GroupCategory.where(sis_source_id: 'Gc001').take
    expect(group_category.deleted_at).to be_nil
    group_category2= GroupCategory.where(sis_source_id: 'Gc002').take
    expect(group_category2.deleted_at).to_not be_nil

    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,deleted",
      "Gc002,A001,Group Cat 2,active")
    expect(group_category.reload.deleted_at).to_not be_nil
    expect(group_category2.reload.deleted_at).to be_nil
  end
end
