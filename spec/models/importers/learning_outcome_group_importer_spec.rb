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

require File.expand_path(File.dirname(__FILE__) + '../../../import_helper')

describe "Importing Learning Outcome Groups" do
  before :once do
    @context = course_model
    @migration = ContentMigration.create!(:context => @context)
    @migration.migration_ids_to_import = {:copy=>{}}
  end

  it "should not generate a new outcome group when one already exists with the same guid" do
    log_data = {migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556", type: "learning_outcome_group",
                title: "Stuff", description: "Detailed stuff"}
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
    existing_group = LearningOutcomeGroup.where(migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556").first
    existing_group.write_attribute('migration_id', "779f2c13-ea41-4804-8d2c-64d46e429210")
    existing_group.save!
    log_data[:migration_id] = "779f2c13-ea41-4804-8d2c-64d46e429210"
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
  end

  describe "with the outcome_guid_course_exports FF enabled" do
    before(:once) { @context.root_account.enable_feature!(:outcome_guid_course_exports) }
    it "should not duplicate an outcome group with the same vendor_guid when it already exists in the context" do
      log_data = {migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556", type: "learning_outcome_group",
      title: "Stuff", description: "Detailed stuff", vendor_guid: "vendor-guid-1"}
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
      expect(@context.learning_outcome_groups.count).to eq 2
      log_data[:migration_id] = "779f2c13-ea41-4804-8d2c-64d46e429210"
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
      expect(@context.learning_outcome_groups.count).to eq 2
    end

    it "does create the group again if it's under a different parent" do
      course_root_group = LearningOutcomeGroup.find_by(context: @context)
      log_data = {migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556", type: "learning_outcome_group",
        title: "Stuff", description: "Detailed stuff", vendor_guid: "vendor-guid-1"}
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
      expect(@context.learning_outcome_groups.count).to eq 2

      # make a new group within the context and move the imported group into it
      parent_group = LearningOutcomeGroup.create!(:title => "subgroup", context: @context, learning_outcome_group: course_root_group)
      imported_group = LearningOutcomeGroup.find_by(migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556")
      imported_group.update!(learning_outcome_group: parent_group)

      # import a new copy of the group
      log_data[:migration_id] = "779f2c13-ea41-4804-8d2c-64d46e429210"
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
      expect(@context.learning_outcome_groups.count).to eq 4
    end
  end

  describe "with the outcome_guid_course_exports FF disabled" do
    it "duplicates an outcome group with the same vendor_guid when it already exists in the context" do
      log_data = {migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556", type: "learning_outcome_group",
      title: "Stuff", description: "Detailed stuff", vendor_guid: "vendor-guid-1"}
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
      expect(@context.learning_outcome_groups.count).to eq 2
      log_data[:migration_id] = "779f2c13-ea41-4804-8d2c-64d46e429210"
      Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
      expect(@context.learning_outcome_groups.count).to eq 3
    end
  end
end
