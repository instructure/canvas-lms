#
# Copyright (C) 2011 Instructure, Inc.
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

describe "Importing Learning Outcomes" do
  before :once do
    @context = course_model
    @migration = ContentMigration.create!(:context => @context)
    @migration.migration_ids_to_import = {:copy=>{}}
    @data = get_import_data [], 'outcomes'
    @data = {'learning_outcomes'=>@data}

    Importers::LearningOutcomeImporter.process_migration(@data, @migration)
  end

  it "should import" do
    lo1 = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    expect(lo1.description).to eq "Outcome 1: Read stuff"
    lo2 = LearningOutcome.where(migration_id: "fa67b467-37c7-4fb9-aef4-21a33a06d0be").first
    expect(lo2.description).to eq "Outcome 2: follow directions"
    log = @context.root_outcome_group

    expect(@context.learning_outcomes.count).to eq 2
    expect(log.child_outcome_links.detect{ |link| link.content == lo1 }).not_to be_nil
    expect(log.child_outcome_links.detect{ |link| link.content == lo2 }).not_to be_nil
  end

  it "should not fail when passing an outcome that already exists" do
    existing_outcome = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    identifier = existing_outcome.migration_id
    lo_data = @data["learning_outcomes"].find{|lo| lo["migration_id"] == identifier }
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, existing_outcome)
    expect(@context.learning_outcomes.count).to eq 2
  end

  it "should not generate a new outcome when one already exists with the same guid" do
    existing_outcome = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    identifier = existing_outcome.migration_id
    lo_data = @data["learning_outcomes"].find{|lo| lo["migration_id"] == identifier }
    AcademicBenchmark.stubs(:use_new_guid_columns?).returns(true)
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration)
    expect(@context.learning_outcomes.count).to eq 2
    existing_outcome.write_attribute('migration_id_2', "7321d12e-3705-430d-9dfd-2511b0c73c14")
    existing_outcome.save!
    lo_data[:migration_id] = "7321d12e-3705-430d-9dfd-2511b0c73c14"
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration)
    expect(@context.learning_outcomes.count).to eq 2
  end

  it "change calculation method, calculation int and rubric criterion" do
    existing_outcome = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    expect(existing_outcome.calculation_method).to eq "highest"
    expect(existing_outcome.calculation_int).to eq nil
    expect(existing_outcome.data).to eq nil
    identifier = existing_outcome.migration_id
    lo_data = @data["learning_outcomes"].find{|lo| lo["migration_id"] == identifier }
    lo_data[:calculation_method] = "decaying_average"
    lo_data[:calculation_int] = 65
    lo_data[:points_possible] = 5
    lo_data[:mastery_points] = 3
    lo_data[:ratings] = [
      { points: 5, description: "Exceeds Expectations" },
      { points: 3, description: "Meets Expectations" },
      { points: 0, description: "Does Not Meet Expectations" }
    ]
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, existing_outcome)
    expect(existing_outcome.calculation_method).to eq "decaying_average"
    expect(existing_outcome.calculation_int).to eq 65
    expect(existing_outcome.data[:rubric_criterion][:mastery_points]).to eq 3
    expect(existing_outcome.data[:rubric_criterion][:points_possible]).to eq 5
    expect(existing_outcome.data[:rubric_criterion][:ratings][0][:points]).to eq 5
    expect(existing_outcome.data[:rubric_criterion][:ratings][0][:description]).to eq "Exceeds Expectations"
    expect(existing_outcome.data[:rubric_criterion][:ratings][1][:points]).to eq 3
    expect(existing_outcome.data[:rubric_criterion][:ratings][1][:description]).to eq "Meets Expectations"
    expect(existing_outcome.data[:rubric_criterion][:ratings][2][:points]).to eq 0
    expect(existing_outcome.data[:rubric_criterion][:ratings][2][:description]).to eq "Does Not Meet Expectations"
    lo_data[:calculation_method] = "highest"
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, existing_outcome)
    expect(existing_outcome.calculation_method).to eq "highest"
    expect(existing_outcome.calculation_int).to eq nil
  end

  it "assessed outcomes cannot change calculation method, calculation int and rubric criterion" do
    existing_outcome = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    lor = LearningOutcomeResult.new(
      alignment: ContentTag.create!({
        title: 'content',
        context: @course,
        learning_outcome: existing_outcome})
      )
    lor.save!
    expect(existing_outcome.calculation_method).to eq "highest"
    expect(existing_outcome.calculation_int).to eq nil
    expect(existing_outcome.data).to eq nil
    identifier = existing_outcome.migration_id
    lo_data = @data["learning_outcomes"].find{|lo| lo["migration_id"] == identifier }
    lo_data[:calculation_method] = "decaying_average"
    lo_data[:calculation_int] = 65
    lo_data[:points_possible] = 5
    lo_data[:mastery_points] = 3
    lo_data[:ratings] = [
      { points: 5, description: "Exceeds Expectations" },
      { points: 3, description: "Meets Expectations" },
      { points: 0, description: "Does Not Meet Expectations" }
    ]
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, existing_outcome)
    expect(existing_outcome.calculation_method).to eq "highest"
    expect(existing_outcome.calculation_int).to eq nil
    expect(existing_outcome.data[:rubric_criterion][:description]).to eq existing_outcome.short_description
  end
end
