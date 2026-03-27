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
#

describe SIS::CSV::InstitutionalTagImporter do
  before(:once) do
    account_model
    @account.enable_feature!(:institutional_tags)
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,First category,active"
    )
    @category = InstitutionalTagCategory.find_by(sis_source_id: "CAT001")
  end

  it "creates institutional tags" do
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,active"
    )
    tag = InstitutionalTag.find_by(sis_source_id: "TAG001")
    expect(tag.name).to eq "Tag One"
    expect(tag.description).to eq "First tag"
    expect(tag.workflow_state).to eq "active"
    expect(tag.category).to eq @category
  end

  it "updates existing tags" do
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Original Name,Original desc,active"
    )
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Updated Name,Updated desc,active"
    )
    tag = InstitutionalTag.find_by(sis_source_id: "TAG001")
    expect(tag.name).to eq "Updated Name"
    expect(tag.description).to eq "Updated desc"
  end

  it "soft-deletes tags when status is deleted" do
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,active"
    )
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,deleted"
    )
    expect(InstitutionalTag.find_by(sis_source_id: "TAG001").workflow_state).to eq "deleted"
  end

  it "does not delete when skip_deletes is set" do
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,active"
    )
    batch = @account.sis_batches.create!(data: {})
    batch.options = { skip_deletes: true }
    batch.save!
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,deleted",
      batch:
    )
    expect(InstitutionalTag.find_by(sis_source_id: "TAG001").workflow_state).to eq "active"
  end

  it "cascades deletion to tag associations when tag is deleted" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "U001,user1,User,One,user1@example.com,active"
    )
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,active"
    )
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,active"
    )
    tag = InstitutionalTag.find_by(sis_source_id: "TAG001")
    assoc = InstitutionalTagAssociation.find_by(institutional_tag: tag)
    expect(assoc.workflow_state).to eq "active"

    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,deleted"
    )

    expect(tag.reload.workflow_state).to eq "deleted"
    expect(assoc.reload.workflow_state).to eq "deleted"
  end

  it "does not create duplicates when imported twice" do
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,active"
    )
    expect do
      process_csv_data_cleanly(
        "institutional_tag_id,category_id,name,description,status",
        "TAG001,CAT001,Tag One,First tag,active"
      )
    end.not_to change(InstitutionalTag, :count)
  end

  it "records errors for bad content" do
    before_count = InstitutionalTag.count
    importer = process_csv_data(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Valid Tag,Valid desc,active",
      ",CAT001,No tag_id,desc,active",
      "TAG002,,No category,desc,active",
      "TAG003,CAT001,,desc,active",
      "TAG004,CAT001,No description,,active",
      "TAG005,CAT001,No status,desc,",
      "TAG006,CAT001,Bad status,desc,blerged",
      "TAG007,MISSING,Unknown category,desc,active"
    )
    expect(importer.errors.map(&:last)).to include(
      "No institutional_tag_id given for an institutional tag",
      "No category_id given for institutional tag TAG002",
      "No name given for institutional tag TAG003",
      "No description given for institutional tag TAG004",
      "No status given for institutional tag TAG005",
      "Improper status \"blerged\" for institutional tag TAG006",
      "Category with id \"MISSING\" didn't exist for institutional tag TAG007"
    )
    expect(InstitutionalTag.count).to eq before_count + 1
  end

  it "creates rollback data" do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,active",
      batch: batch1
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: "non-existent").count).to eq 1

    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,deleted",
      batch: batch2
    )
    expect(batch2.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 1

    batch3 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,active",
      batch: batch3
    )
    expect(batch3.roll_back_data.where(updated_workflow_state: "active").count).to eq 1

    batch3.restore_states_for_batch
    expect(InstitutionalTag.find_by(sis_source_id: "TAG001").workflow_state).to eq "deleted"
  end
end
