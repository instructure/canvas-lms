#
# Copyright (C) 2016 Instructure, Inc.
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
    AcademicBenchmark.stubs(:use_new_guid_columns?).returns(false)
    log_data = {migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556", type: "learning_outcome_group",
                title: "Stuff", description: "Detailed stuff"}
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
    AcademicBenchmark.stubs(:use_new_guid_columns?).returns(true)
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
    existing_group = LearningOutcomeGroup.where(migration_id: "3c811a5d-7a39-401b-8db5-9ce5fbd2d556").first
    existing_group.write_attribute('migration_id_2', "779f2c13-ea41-4804-8d2c-64d46e429210")
    existing_group.save!
    log_data[:migration_id] = "779f2c13-ea41-4804-8d2c-64d46e429210"
    Importers::LearningOutcomeGroupImporter.import_from_migration(log_data, @migration)
    expect(@context.learning_outcome_groups.count).to eq 2
  end
end
