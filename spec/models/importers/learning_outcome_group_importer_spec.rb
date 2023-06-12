# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../../import_helper"

describe "Importing Learning Outcome Groups" do
  before :once do
    @context = course_model
    @migration = ContentMigration.create!(context: @context)
    @migration.migration_ids_to_import = { copy: {} }
    @migration.outcome_to_id_map = {}
  end

  def outcome_data(overrides = {})
    {
      migration_id: "6a240bdc-957b-11ea-bb37-0242ac130002",
      type: "learning_outcome",
      title: "Standard",
    }.merge(overrides)
  end

  def group_data(overrides = {})
    {
      migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556",
      type: "learning_outcome_group",
      title: "Stuff",
      description: "Detailed stuff"
    }.merge(overrides)
  end

  it "does not import an outcome group if skip import enabled" do
    log_data = group_data
    expect do
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration, nil, true)
    end.not_to change { @context.learning_outcome_groups.count }
  end

  it "imports outcome group contents if skip import enabled on group" do
    log_data = group_data(outcomes: [
                            outcome_data,
                            group_data(
                              outcomes: [
                                outcome_data(migration_id: "73b696ec-957b-11ea-bb37-0242ac130002")
                              ]
                            )
                          ])
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration, nil, true)
    expect(@context.learning_outcome_groups.count).to eq 2
    expect(@context.learning_outcomes.count).to eq 2
  end

  it "does not generate a new outcome group when one already exists with the same guid" do
    log_data = group_data
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
    existing_group = LearningOutcomeGroup.where(migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556").first
    existing_group.write_attribute("migration_id", "779f2c13-ea41-4804-8d2c-64d46e429210")
    existing_group.save!
    log_data[:migration_id] = "779f2c13-ea41-4804-8d2c-64d46e429210"
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
  end

  it "does not generate a new outcome group when already exists a group with the same name in the same folder" do
    Importers::LearningOutcomeGroupImporter.import_from_migration(group_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
    log_data = group_data(migration_id: "other-migration-id")
    expect do
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    end.not_to change(@context.learning_outcome_groups, :count)
  end

  it "generates a new outcome group when already exists a deleted group with the same name in the same folder" do
    Importers::LearningOutcomeGroupImporter.import_from_migration(group_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
    LearningOutcomeGroup.find_by(title: "Stuff").destroy
    log_data = group_data(migration_id: "other-migration-id")
    expect do
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    end.to change(@context.learning_outcome_groups, :count).by(1)
  end

  it "does not duplicate an outcome group with the same vendor_guid when it already exists in the context" do
    log_data = group_data(vendor_guid: "vendor-guid-1")
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
    log_data[:migration_id] = "779f2c13-ea41-4804-8d2c-64d46e429210"
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
  end

  it "does create the group again if it's under a different parent" do
    course_root_group = LearningOutcomeGroup.find_by(context: @context)
    log_data = group_data(vendor_guid: "vendor-guid-1")
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2

    # make a new group within the context and move the imported group into it
    parent_group = LearningOutcomeGroup.create!(title: "subgroup", context: @context, learning_outcome_group: course_root_group)
    imported_group = LearningOutcomeGroup.find_by(migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556")
    imported_group.update!(learning_outcome_group: parent_group)

    # import a new copy of the group
    log_data[:migration_id] = "779f2c13-ea41-4804-8d2c-64d46e429210"
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 4
  end

  context "source_outcome_group" do
    it "stores source_outcome_group when titles are equal" do
      source_group = outcome_group_model(context: Account.default, title: "Stuff")
      log_data = group_data(source_outcome_group_id: source_group.id)
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
      imported_group = LearningOutcomeGroup.find_by(migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556")
      expect(imported_group.source_outcome_group).to eql(source_group)
    end

    it "does not store source_outcome_group when titles are different" do
      source_group = outcome_group_model(context: Account.default, title: "Different")
      log_data = group_data(source_outcome_group_id: source_group.id)
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
      imported_group = LearningOutcomeGroup.find_by(migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556")
      expect(imported_group.source_outcome_group).to be_nil
    end

    it "does not store source_outcome_group when it belongs to different account" do
      source_group = outcome_group_model(context: Account.create!)
      log_data = group_data(source_outcome_group_id: source_group.id)
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
      imported_group = LearningOutcomeGroup.find_by(migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556")
      expect(imported_group.source_outcome_group).to be_nil
    end

    it "skips when source group cant be found" do
      source_group = outcome_group_model(context: Account.default)
      source_group.destroy
      log_data = group_data(source_outcome_group_id: source_group.id)
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
      imported_group = LearningOutcomeGroup.find_by(migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556")
      expect(imported_group.source_outcome_group).to be_nil
    end
  end
end
