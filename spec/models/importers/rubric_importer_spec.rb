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

require File.expand_path(File.dirname(__FILE__) + '../../../import_helper')

describe "Importing Rubrics" do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'rubric'
      it "should import from #{system}" do
        data = get_import_data(system, 'rubric')
        context = get_import_context(system)
        migration = double()
        allow(migration).to receive(:context).and_return(context)
        allow(migration).to receive(:add_imported_item)

        data[:rubrics_to_import] = {}
        expect(Importers::RubricImporter.import_from_migration(data, migration)).to be_nil
        expect(context.rubrics.count).to eq 0

        data[:rubrics_to_import][data[:migration_id]] = true
        Importers::RubricImporter.import_from_migration(data, migration)
        Importers::RubricImporter.import_from_migration(data, migration)
        expect(context.rubrics.count).to eq 1
        r = Rubric.where(migration_id: data[:migration_id]).first

        expect(r.title).to eq data[:title]
        expect(r.description).to include(data[:description]) if data[:description]
        expect(r.points_possible).to eq data[:points_possible].to_f

        crit_ids = r.data.map{|rub|rub[:ratings].first[:criterion_id]}

        data[:data].each do |crit|
          id = crit[:migration_id] || crit[:id]
          expect(crit_ids.member?(id)).to be_truthy
        end
      end
    end
  end

  context "with the account_level_mastery_scales FF" do
    before do
      @data = get_import_data('vista', 'rubric')
      @context = get_import_context('vista')
      @migration = @context.content_migrations.create!
      outcome_proficiency_model(@context.root_account)
      outcome_with_rubric({mastery_points: 3, context: @context})
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
        expect(outcome_criterion[:ratings].map { |rating| rating[:description] }).to eq ['best', 'worst']
        expect(outcome_criterion[:mastery_points]).to eq 10
      end
    end

    context "disabled" do
      it "uses imported course's mastery scales for rubrics with learning_outcomes" do
        @context.root_account.disable_feature!(:account_level_mastery_scales)
        Importers::RubricImporter.import_from_migration(@data, @migration)
        rubric = Rubric.where(migration_id: @data[:migration_id]).first
        outcome_criterion = rubric.data[0]
        expect(outcome_criterion[:ratings].map { |rating| rating[:description] }).to eq ['Rating 1']
      end
    end
  end
end
