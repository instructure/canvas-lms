# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "Importing Learning Outcomes" do
  before :once do
    @context = course_model
    @migration = ContentMigration.create!(context: @context)
    @migration.migration_ids_to_import = { copy: {} }
    @data = get_import_data [], "outcomes"
    @data = { "learning_outcomes" => @data }

    Importers::LearningOutcomeImporter.process_migration(@data, @migration)
  end

  it "imports" do
    lo1 = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    expect(lo1.description).to eq "Outcome 1: Read stuff"
    lo2 = LearningOutcome.where(migration_id: "fa67b467-37c7-4fb9-aef4-21a33a06d0be").first
    expect(lo2.description).to eq "Outcome 2: follow directions"
    log = @context.root_outcome_group

    expect(@context.learning_outcomes.count).to eq 2
    expect(log.child_outcome_links.detect { |link| link.content == lo1 }).not_to be_nil
    expect(log.child_outcome_links.detect { |link| link.content == lo2 }).not_to be_nil
  end

  context "selectable_outcomes_in_course_copy enabled" do
    before do
      @context.root_account.enable_feature!(:selectable_outcomes_in_course_copy)
    end

    after do
      @context.root_account.disable_feature!(:selectable_outcomes_in_course_copy)
    end

    it "imports group" do
      migration = ContentMigration.create!(context: @context)
      migration.migration_ids_to_import = { copy: {} }
      data = [{ type: "learning_outcome_group", title: "hey", migration_id: "x" }.with_indifferent_access]
      data = { "learning_outcomes" => data }
      expect do
        Importers::LearningOutcomeImporter.process_migration(data, migration)
      end.to change { LearningOutcomeGroup.count }.by 1
    end
  end

  it "does not fail when passing an outcome that already exists" do
    existing_outcome = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    identifier = existing_outcome.migration_id
    lo_data = @data["learning_outcomes"].find { |lo| lo["migration_id"] == identifier }
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, existing_outcome)
    expect(@context.learning_outcomes.count).to eq 2
  end

  it "does not generate a new outcome when one already exists with the same guid" do
    existing_outcome = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    identifier = existing_outcome.migration_id
    lo_data = @data["learning_outcomes"].find { |lo| lo["migration_id"] == identifier }
    existing_outcome.write_attribute("migration_id", "7321d12e-3705-430d-9dfd-2511b0c73c14")
    existing_outcome.save!
    lo_data[:migration_id] = "7321d12e-3705-430d-9dfd-2511b0c73c14"
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration)
    expect(@context.learning_outcomes.count).to eq 2
  end

  it "creates an OutcomeFriendlyDescription if the outcome has a friendly description" do
    Account.site_admin.enable_feature! :outcomes_friendly_description
    existing_outcome = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    identifier = existing_outcome.migration_id
    lo_data = @data["learning_outcomes"].find { |lo| lo["migration_id"] == identifier }
    friendly_description = "a friendly description"
    lo_data[:friendly_description] = friendly_description
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, existing_outcome)
    expect(OutcomeFriendlyDescription.find_by(context_id: @context.id).description).to eq friendly_description
  end

  it "creates a new OutcomeFriendlyDescription if the outcome is being imported to a new context" do
    context2 = course_model
    outcome = context2.created_learning_outcomes.create!({ title: "new outcome" })
    friendly_description = "a friendly description"
    OutcomeFriendlyDescription.create!({
                                         learning_outcome: outcome,
                                         context: context2,
                                         description: friendly_description
                                       })
    outcome.write_attribute("migration_id", "bdf6dc13-5d8f-43a8-b426-03380c9b6781")
    identifier = outcome.migration_id
    lo_data = @data["learning_outcomes"].find { |lo| lo["migration_id"] == identifier }
    Account.site_admin.enable_feature! :outcomes_friendly_description
    lo_data[:friendly_description] = friendly_description
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, outcome)
    expect(OutcomeFriendlyDescription.count).to eq 2
    expect(OutcomeFriendlyDescription.find_by(context_id: @context.id).description).to eq friendly_description
  end

  it "updates an OutcomeFriendlyDescription if there is a friendly description in the database" do
    Account.site_admin.enable_feature! :outcomes_friendly_description
    existing_outcome = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    OutcomeFriendlyDescription.create!({
                                         learning_outcome: existing_outcome,
                                         context: existing_outcome.context,
                                         description: "I will be updated to a new friendly description"
                                       })
    identifier = existing_outcome.migration_id
    lo_data = @data["learning_outcomes"].find { |lo| lo["migration_id"] == identifier }
    friendly_description = "I was updated to a new friendly description"
    lo_data[:friendly_description] = friendly_description
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, existing_outcome)
    expect(OutcomeFriendlyDescription.where(learning_outcome_id: existing_outcome.id).count).to eq 1
    expect(OutcomeFriendlyDescription.find_by(learning_outcome_id: existing_outcome.id).description).to eq friendly_description
  end

  it "change calculation method, calculation int and rubric criterion" do
    existing_outcome = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    expect(existing_outcome.calculation_method).to eq "decaying_average"
    expect(existing_outcome.calculation_int).to eq 65
    expect(existing_outcome.data).to be_nil
    identifier = existing_outcome.migration_id
    lo_data = @data["learning_outcomes"].find { |lo| lo["migration_id"] == identifier }
    lo_data[:calculation_method] = "highest"
    lo_data[:calculation_int] = nil
    lo_data[:points_possible] = 5
    lo_data[:mastery_points] = 3
    lo_data[:ratings] = [
      { points: 5, description: "Exceeds Expectations" },
      { points: 3, description: "Meets Expectations" },
      { points: 0, description: "Does Not Meet Expectations" }
    ]
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, existing_outcome)
    expect(existing_outcome.calculation_method).to eq "highest"
    expect(existing_outcome.calculation_int).to be_nil
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
    expect(existing_outcome.calculation_int).to be_nil
  end

  it "assessed outcomes cannot change calculation method, calculation int and rubric criterion" do
    student = @course.enroll_student(User.create!, active_all: true).user
    existing_outcome = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    identifier = existing_outcome.migration_id
    lo_data = @data["learning_outcomes"].find { |lo| lo["migration_id"] == identifier }
    lo_data[:calculation_method] = "decaying_average"
    lo_data[:calculation_int] = 65
    lo_data[:points_possible] = 5
    lo_data[:mastery_points] = 3
    current_ratings = [
      { points: 5, description: "Exceeds Expectations" },
      { points: 3, description: "Meets Expectations" },
      { points: 0, description: "Does Not Meet Expectations" }
    ]
    lo_data[:ratings] = current_ratings
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, existing_outcome)
    expect(existing_outcome.calculation_method).to eq lo_data[:calculation_method]
    expect(existing_outcome.calculation_int).to eq lo_data[:calculation_int]
    expect(existing_outcome.data[:rubric_criterion][:description]).to eq existing_outcome.short_description
    expect(existing_outcome.data[:rubric_criterion][:mastery_points]).to eq lo_data[:mastery_points]
    expect(existing_outcome.data[:rubric_criterion][:points_possible]).to eq lo_data[:points_possible]
    expect(existing_outcome.data[:rubric_criterion][:ratings]).to eq current_ratings
    lor = LearningOutcomeResult.new(
      alignment: ContentTag.create!({
                                      title: "content",
                                      context: @course,
                                      learning_outcome: existing_outcome
                                    }),
      user: student
    )
    lor.save!
    lo_data[:calculation_method] = "n_mastery"
    lo_data[:calculation_int] = 5
    lo_data[:points_possible] = 10
    lo_data[:mastery_points] = 7
    lo_data[:ratings] = [
      { points: 10, description: "Excellent" },
      { points: 0, description: "Fail" }
    ]
    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration, existing_outcome)
    expect(existing_outcome.calculation_method).to eq "decaying_average"
    expect(existing_outcome.calculation_int).to eq 65
    expect(existing_outcome.data[:rubric_criterion][:description]).to eq existing_outcome.short_description
    expect(existing_outcome.data[:rubric_criterion][:mastery_points]).to eq 3
    expect(existing_outcome.data[:rubric_criterion][:points_possible]).to eq 5
    expect(existing_outcome.data[:rubric_criterion][:ratings]).to eq current_ratings
  end

  it "does not duplicate outcomes in a context with different external_identifiers and the same vendor_guid" do
    lo1 = LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first
    lo1.update!(vendor_guid: "vendor-guid-1")

    lo_data = @data["learning_outcomes"].find { |lo| lo["migration_id"] == "bdf6dc13-5d8f-43a8-b426-03380c9b6781" }
    lo_data[:vendor_guid] = "vendor-guid-1"
    lo_data[:migration_id] = "7321d12e-3705-430d-9dfd-2511b0c73c14"
    lo_data[:external_identifier] = "0"

    Importers::LearningOutcomeImporter.import_from_migration(lo_data, @migration)
    expect(@context.learning_outcomes.count).to eq 2 # lo1 is not duplicated
  end

  it "does not duplicate learning outcomes with vendor_guid on common cartidge import" do
    context2 = course_model
    outcome1 = context2.created_learning_outcomes.create!({ title: "cci outcome 1", description: "cci outcome 1: desc", vendor_guid: "xyz" })

    mig = ContentMigration.create!(context: context2).tap do |m|
      m.migration_ids_to_import = { copy: { everything: true } }
      m.migration_type = "common_cartridge_importer"
    end

    course_content = { "learning_outcomes" =>
      [
        {
          "migration_id" => "z",
          "title" => outcome1.title,
          "description" => outcome1.description,
          "vendor_guid" => outcome1.vendor_guid,
          "copied_from_outcome_id" => outcome1.id
        },
      ] }
    Importers::LearningOutcomeImporter.process_migration(course_content, mig)
    duplicate_check = LearningOutcome.where(vendor_guid: outcome1.vendor_guid)
    expect(duplicate_check.count).to eq 1
  end

  it "fills the copied_from_outcome_id for course copy" do
    context2 = course_model
    outcome1 = context2.created_learning_outcomes.create!({ title: "cc outcome 1", description: "cc outcome 1: desc" })
    outcome2 = context2.created_learning_outcomes.create!({ title: "cc outcome 2", description: "cc outcome 2: desc" })

    mig = ContentMigration.create!(context: context2).tap do |m|
      m.migration_ids_to_import = { copy: { everything: true } }
      m.migration_type = "course_copy_importer"
    end

    course_content = { "learning_outcomes" =>
      [
        {
          "migration_id" => "x",
          "title" => outcome1.title,
          "description" => outcome1.description,
          "copied_from_outcome_id" => outcome1.id
        },
        {
          "migration_id" => "y",
          "title" => outcome2.title,
          "description" => outcome2.description,
          "copied_from_outcome_id" => outcome2.id
        }
      ] }
    Importers::LearningOutcomeImporter.process_migration(course_content, mig)
    outcomes = mig.imported_migration_items_hash(LearningOutcome).with_indifferent_access
    expect(outcomes.count).to eq 2
    expect(outcomes[:x][:copied_from_outcome_id]).to eq outcome1.id
    expect(outcomes[:y][:copied_from_outcome_id]).to eq outcome2.id
  end

  it "does not fill the copied_from_outcome_id for another migration type" do
    context2 = course_model
    outcome1 = context2.created_learning_outcomes.create!({ title: "cci outcome 1", description: "cci outcome 1: desc" })
    outcome2 = context2.created_learning_outcomes.create!({ title: "cci outcome 2", description: "cci outcome 2: desc" })

    mig = ContentMigration.create!(context: context2).tap do |m|
      m.migration_ids_to_import = { copy: { everything: true } }
      m.migration_type = "common_cartridge_importer"
    end

    course_content = { "learning_outcomes" =>
      [
        {
          "migration_id" => "z",
          "title" => outcome1.title,
          "description" => outcome1.description,
          "copied_from_outcome_id" => outcome1.id
        },
        {
          "migration_id" => "zz",
          "title" => outcome2.title,
          "description" => outcome2.description,
          "copied_from_outcome_id" => outcome2.id
        }
      ] }
    Importers::LearningOutcomeImporter.process_migration(course_content, mig)
    outcomes = mig.imported_migration_items_hash(LearningOutcome).with_indifferent_access
    expect(outcomes.count).to eq 2
    expect(outcomes[:z][:copied_from_outcome_id]).to be_nil
    expect(outcomes[:zz][:copied_from_outcome_id]).to be_nil
  end

  describe "with the outcome_alignments_course_migration FF enabled" do
    before(:once) { @context.root_account.enable_feature!(:outcome_alignments_course_migration) }

    let(:migration) do
      ContentMigration.create!(context: @context).tap do |m|
        m.migration_ids_to_import = { copy: {} }
      end
    end

    context "with global and account outcomes" do
      let(:global_outcome) { LearningOutcome.where(migration_id: "bdf6dc13-5d8f-43a8-b426-03380c9b6781").first }
      let(:account_outcome) { LearningOutcome.where(migration_id: "fa67b467-37c7-4fb9-aef4-21a33a06d0be").first }

      before do
        global_outcome.update(vendor_guid: "vendor-guid-1", context: nil)
        account_outcome.update(vendor_guid: "vendor-guid-2", context: @context.root_account)
      end

      it "includes non-imported outcomes as imported items" do
        @data["learning_outcomes"].find { |lo| lo["migration_id"] == global_outcome.migration_id }.tap do |data|
          data[:vendor_guid] = "vendor-guid-1"
          data[:external_identifier] = global_outcome.id.to_s
          data[:is_global_outcome] = true
        end
        @data["learning_outcomes"].find { |lo| lo["migration_id"] == account_outcome.migration_id }.tap do |data|
          data[:vendor_guid] = "vendor-guid-2"
          data[:external_identifier] = account_outcome.id.to_s
        end
        Importers::LearningOutcomeImporter.process_migration(@data, migration)
        outcomes = migration.imported_migration_items_hash(LearningOutcome)
        expect(outcomes.count).to eq 2
      end
    end
  end
end
