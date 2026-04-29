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

describe SIS::CSV::InstitutionalTagCategoryImporter do
  before(:once) do
    account_model
    @account.enable_feature!(:institutional_tags)
  end

  it "creates institutional tag categories" do
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,First category,active",
      "CAT002,Category Two,,active"
    )
    cat1 = InstitutionalTagCategory.find_by(sis_source_id: "CAT001")
    expect(cat1.name).to eq "Category One"
    expect(cat1.description).to eq "First category"
    expect(cat1.workflow_state).to eq "active"
    expect(cat1.account).to eq @account

    cat2 = InstitutionalTagCategory.find_by(sis_source_id: "CAT002")
    expect(cat2.name).to eq "Category Two"
    expect(cat2.workflow_state).to eq "active"
  end

  it "updates existing categories" do
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Original Name,Original desc,active"
    )
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Updated Name,Updated desc,active"
    )
    cat = InstitutionalTagCategory.find_by(sis_source_id: "CAT001")
    expect(cat.name).to eq "Updated Name"
    expect(cat.description).to eq "Updated desc"
  end

  it "soft-deletes categories when status is deleted" do
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,active"
    )
    expect(InstitutionalTagCategory.find_by(sis_source_id: "CAT001").workflow_state).to eq "active"

    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,deleted"
    )
    expect(InstitutionalTagCategory.find_by(sis_source_id: "CAT001").workflow_state).to eq "deleted"
  end

  it "restores deleted categories" do
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,deleted"
    )
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,active"
    )
    expect(InstitutionalTagCategory.find_by(sis_source_id: "CAT001").workflow_state).to eq "active"
  end

  it "does not delete when skip_deletes is set" do
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,active"
    )
    batch = @account.sis_batches.create!(data: {})
    batch.options = { skip_deletes: true }
    batch.save!
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,deleted",
      batch:
    )
    expect(InstitutionalTagCategory.find_by(sis_source_id: "CAT001").workflow_state).to eq "active"
  end

  it "cascades deletion to associated tags when category is deleted" do
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,active"
    )
    process_csv_data_cleanly(
      "institutional_tag_id,category_id,name,description,status",
      "TAG001,CAT001,Tag One,First tag,active"
    )
    expect(InstitutionalTag.find_by(sis_source_id: "TAG001").workflow_state).to eq "active"

    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,deleted"
    )

    expect(InstitutionalTagCategory.find_by(sis_source_id: "CAT001").workflow_state).to eq "deleted"
    expect(InstitutionalTag.find_by(sis_source_id: "TAG001").workflow_state).to eq "deleted"
  end

  it "does not create duplicates when imported twice" do
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,First category,active"
    )
    expect do
      process_csv_data_cleanly(
        "category_id,name,description,status",
        "CAT001,Category One,First category,active"
      )
    end.not_to change(InstitutionalTagCategory, :count)
  end

  it "records errors for bad content" do
    before_count = InstitutionalTagCategory.count
    importer = process_csv_data(
      "category_id,name,description,status",
      "CAT001,Valid Category,,active",
      ",Missing ID,,active",
      "CAT002,,No Name,active",
      "CAT003,No Status,,",
      "CAT004,Bad Status,,blerged"
    )
    expect(importer.errors.map(&:last)).to include(
      "No category_id given for an institutional tag category",
      "No name given for institutional tag category CAT002",
      "No status given for institutional tag category CAT003",
      "Improper status \"blerged\" for institutional tag category CAT004"
    )
    expect(InstitutionalTagCategory.count).to eq before_count + 1
  end

  it "creates rollback data" do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,active",
      batch: batch1
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: "non-existent").count).to eq 1

    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,deleted",
      batch: batch2
    )
    expect(batch2.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 1

    batch3 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "category_id,name,description,status",
      "CAT001,Category One,,active",
      batch: batch3
    )
    expect(batch3.roll_back_data.where(updated_workflow_state: "active").count).to eq 1

    batch3.restore_states_for_batch
    expect(InstitutionalTagCategory.find_by(sis_source_id: "CAT001").workflow_state).to eq "deleted"
  end

  context "when the institutional_tags feature flag is disabled" do
    before { @account.disable_feature!(:institutional_tags) }

    it "does not process the CSV and records one dispatcher-level error" do
      importer = process_csv_data(
        "category_id,name,description,status",
        "CAT001,Category One,First category,active",
        "CAT002,Category Two,,active"
      )
      expect(importer.errors.map(&:last)).to contain_exactly(
        "Couldn't find Canvas CSV import headers"
      )
      expect(InstitutionalTagCategory.where(sis_source_id: %w[CAT001 CAT002])).to be_empty
    end
  end
end
