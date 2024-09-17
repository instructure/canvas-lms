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

describe "Importing Rubrics" do
  SYSTEMS.each do |system|
    next unless import_data_exists? system, "rubric"

    it "imports from #{system}" do
      data = get_import_data(system, "rubric")
      context = get_import_context(system)
      assignment = Assignment.create!(course: @course)
      migration = double
      allow(migration).to receive(:add_imported_item)
      allow(migration).to receive_messages(context:, migration_settings: {})

      data[:rubrics_to_import] = {}
      expect(Importers::RubricImporter.import_from_migration(data, migration)).to be_nil
      expect(context.rubrics.count).to eq 0

      data[:rubrics_to_import][data[:migration_id]] = true
      Importers::RubricImporter.import_from_migration(data, migration)
      Importers::RubricImporter.import_from_migration(data, migration)
      expect(context.rubrics.count).to eq 1
      r = Rubric.where(migration_id: data[:migration_id]).first

      assignment.reload
      expect(assignment.rubric_association).to be_nil

      expect(r.title).to eq data[:title]
      expect(r.description).to include(data[:description]) if data[:description]
      expect(r.points_possible).to eq data[:points_possible].to_f
      # make sure we can reconstitute whatever the importer stuffed into the hash
      expect(r.criteria_object).to be_a(Array)

      crit_ids = r.data.map { |rub| rub[:ratings].first[:criterion_id] }

      data[:data].each do |crit|
        id = crit[:migration_id] || crit[:id]
        expect(crit_ids.member?(id)).to be_truthy
      end
    end

    context "when rubric has an assessment" do
      let(:migration_id) { "g74ae39cd0bf07b03d73506c457f437b0" }

      before do
        course_with_teacher(active_all: true)
        course_with_student(active_all: true, course: @course)
        @context = @course
        @assignment = @context.assignments.create!(
          title: "some assignment",
          workflow_state: "published"
        )

        submission_model assignment: @assignment, user: @student
        @viewing_user = @teacher
        @assessed_user = @student
        rubric_association_model association_object: @assignment, purpose: "grading"
        @rubric.update(migration_id:)
        [@teacher, @student].each do |user|
          @rubric_association.rubric_assessments.create!({
                                                           artifact: @submission,
                                                           assessment_type: "grading",
                                                           assessor: user,
                                                           rubric: @rubric,
                                                           user: @assessed_user
                                                         })
        end
      end

      it "doesn't import from #{system}" do
        data = get_import_data(system, "rubric")

        migration = double
        allow(migration).to receive(:add_imported_item)
        allow(migration).to receive_messages(context: @context, migration_settings: {})
        expect(migration).to receive(:add_import_warning).once

        data[:rubrics_to_import] = { "#{migration_id}": true }
        data[:migration_id] = migration_id
        Importers::RubricImporter.import_from_migration(data, migration)
      end
    end

    it "imports from #{system} with associated assignment" do
      data = get_import_data(system, "rubric")
      context = get_import_context(system)
      assignment = Assignment.create!(course: @course)
      migration = double
      allow(migration).to receive(:add_imported_item)
      allow(migration).to receive_messages(context:, migration_settings: { associate_with_assignment_id: assignment.id })

      data[:rubrics_to_import] = {}
      data[:rubrics_to_import][data[:migration_id]] = true
      Importers::RubricImporter.import_from_migration(data, migration)
      Importers::RubricImporter.import_from_migration(data, migration)
      expect(context.rubrics.count).to eq 1
      r = Rubric.where(migration_id: data[:migration_id]).first

      assignment.reload
      expect(assignment.rubric_association.purpose).to eq "grading"
      expect(assignment.rubric_association.rubric_id).to eq r.id
    end
  end

  context "with the account_level_mastery_scales FF" do
    before do
      @data = get_import_data("vista", "rubric")
      @context = get_import_context("vista")
      @migration = @context.content_migrations.create!
      outcome_proficiency_model(@context.root_account)
      outcome_with_rubric({ mastery_points: 3, context: @context })
      @data[:data] = [{ learning_outcome_id: @outcome.id, points_possible: 5, ratings: [{ description: "Rating 1" }] }]
      @data[:rubrics_to_import] = {}
      @data[:rubrics_to_import][@data[:migration_id]] = true
    end

    context "enabled" do
      it "uses imported course's mastery scales for rubrics with learning_outcomes" do
        @context.root_account.enable_feature!(:account_level_mastery_scales)
        Importers::RubricImporter.import_from_migration(@data, @migration)
        rubric = Rubric.where(migration_id: @data[:migration_id]).first
        outcome_criterion = rubric.data[0]
        expect(outcome_criterion[:ratings].pluck(:description)).to eq ["best", "worst"]
        expect(outcome_criterion[:mastery_points]).to eq 10
      end
    end

    context "disabled" do
      it "uses imported course's mastery scales for rubrics with learning_outcomes" do
        @context.root_account.disable_feature!(:account_level_mastery_scales)
        Importers::RubricImporter.import_from_migration(@data, @migration)
        rubric = Rubric.where(migration_id: @data[:migration_id]).first
        outcome_criterion = rubric.data[0]
        expect(outcome_criterion[:ratings].pluck(:description)).to eq ["Rating 1"]
      end
    end
  end
end
