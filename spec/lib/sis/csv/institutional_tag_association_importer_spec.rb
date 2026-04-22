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

describe SIS::CSV::InstitutionalTagAssociationImporter do
  before(:once) do
    account_model
    @account.enable_feature!(:institutional_tags)
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "U001,user1,User,One,user1@example.com,active"
    )
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,First category,active"
    )
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,active"
    )
    @tag = InstitutionalTag.find_by(sis_source_id: "TAG001")
    @user = Pseudonym.find_by(sis_user_id: "U001").user
  end

  it "creates institutional tag associations" do
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,active"
    )
    assoc = InstitutionalTagAssociation.find_by(institutional_tag: @tag, context: @user)
    expect(assoc).not_to be_nil
    expect(assoc.workflow_state).to eq "active"
    expect(assoc.root_account_id).to eq @account.id
  end

  it "soft-deletes associations when status is deleted" do
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,active"
    )
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,deleted"
    )
    assoc = InstitutionalTagAssociation.find_by(institutional_tag: @tag, context: @user)
    expect(assoc.workflow_state).to eq "deleted"
  end

  it "restores deleted associations" do
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,active"
    )
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,deleted"
    )
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,active"
    )
    assoc = InstitutionalTagAssociation.find_by(institutional_tag: @tag, context: @user)
    expect(assoc.workflow_state).to eq "active"
  end

  it "does not delete when skip_deletes is set" do
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,active"
    )
    batch = @account.sis_batches.create!(data: {})
    batch.options = { skip_deletes: true }
    batch.save!
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,deleted",
      batch:
    )
    assoc = InstitutionalTagAssociation.find_by(institutional_tag: @tag, context: @user)
    expect(assoc.workflow_state).to eq "active"
  end

  it "does not create duplicates when imported twice" do
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,active"
    )
    expect do
      process_csv_data_cleanly(
        "institutional_tag_id,user_id,status",
        "TAG001,U001,active"
      )
    end.not_to change(InstitutionalTagAssociation, :count)
  end

  it "records errors for bad content" do
    before_count = InstitutionalTagAssociation.count
    importer = process_csv_data(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,active",
      ",U001,active",
      "TAG001,,active",
      "TAG001,U001,",
      "TAG001,U001,blerged",
      "MISSING,U001,active",
      "TAG001,MISSING,active"
    )
    expect(importer.errors.map(&:last)).to include(
      "No institutional_tag_id given for an institutional tag association",
      "No user_id given for institutional tag association with tag TAG001",
      "No status given for institutional tag association (tag: TAG001, user: U001)",
      "Improper status \"blerged\" for institutional tag association (tag: TAG001, user: U001)",
      "Institutional tag with id \"MISSING\" didn't exist",
      "User with sis_user_id \"MISSING\" didn't exist for institutional tag association with tag TAG001"
    )
    expect(InstitutionalTagAssociation.count).to eq before_count + 1
  end

  it "creates rollback data" do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,active",
      batch: batch1
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: "non-existent").count).to eq 1

    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,deleted",
      batch: batch2
    )
    expect(batch2.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 1

    batch3 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "institutional_tag_id,user_id,status",
      "TAG001,U001,active",
      batch: batch3
    )
    expect(batch3.roll_back_data.where(updated_workflow_state: "active").count).to eq 1

    batch3.restore_states_for_batch
    assoc = InstitutionalTagAssociation.find_by(institutional_tag: @tag, context: @user)
    expect(assoc.workflow_state).to eq "deleted"
  end

  context "when the institutional_tags feature flag is disabled" do
    before { @account.disable_feature!(:institutional_tags) }

    it "does not process the CSV and records one dispatcher-level error" do
      importer = process_csv_data(
        "institutional_tag_id,user_id,status",
        "TAG001,U001,active"
      )
      expect(importer.errors.map(&:last)).to contain_exactly(
        "Couldn't find Canvas CSV import headers"
      )
      expect(InstitutionalTagAssociation.where(institutional_tag: @tag)).to be_empty
    end
  end
end
