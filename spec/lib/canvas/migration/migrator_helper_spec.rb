# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe Canvas::Migration::MigratorHelper do
  subject do
    Class.new do
      include Canvas::Migration::MigratorHelper
      attr_accessor :course
      attr_accessor :settings
    end
  end

  describe "#overview" do
    context "tool profiles" do
      let(:course) do
        {
          tool_profiles: [
            {
              "tool_profile" => {
                "product_instance" => {
                  "product_info" => {
                    "product_name" => {
                      "default_value" => "Test Tool"
                    }
                  }
                }
              },
              "migration_id" => "m_id"
            }
          ]
        }
      end
      let(:content_migration) { ContentMigration.create!(context: course_model) }

      it "returns nothing if there are no tool_profiles" do
        helper = subject.new
        helper.course = {}
        helper.settings = { content_migration: }
        helper.overview
        expect(helper.overview[:tool_profiles]).to be_nil
      end

      it "returns a tool profile overview if there is a tool_profile" do
        helper = subject.new
        helper.course = course
        helper.settings = { content_migration: }
        helper.overview
        expect(helper.overview[:tool_profiles]).to match_array [
          {
            title: "Test Tool",
            migration_id: "m_id"
          }
        ]
      end

      it "returns nothing if the tool_profile data is misconfigured" do
        helper = subject.new
        course[:tool_profiles].first["tool_profile"]["product_instance"] = {}
        helper.course = course
        helper.settings = { content_migration: }
        helper.overview
        expect(helper.overview[:tool_profiles]).to be_empty
      end
    end

    context "learning outcomes" do
      let(:course) do
        {
          learning_outcomes: [{
            type: "learning_outcome_group",
            migration_id: "group_1",
            title: "course outcomes",
            outcomes: [{
              type: "learning_outcome",
              migration_id: "outcome_1",
              title: "standard"
            }]
          }]
        }
      end
      let(:content_migration) { ContentMigration.create!(context: course_model) }

      context "selectable_outcomes_in_course_copy disabled" do
        before do
          content_migration.context.root_account.disable_feature!(:selectable_outcomes_in_course_copy)
        end

        it "does not generate learning_outcome_groups overview section" do
          helper = subject.new
          helper.course = course
          helper.settings = { content_migration: }
          overview = helper.overview
          expect(overview).not_to have_key(:learning_outcome_groups)
        end
      end

      context "selectable_outcomes_in_course_copy enabled" do
        before do
          content_migration.context.root_account.enable_feature!(:selectable_outcomes_in_course_copy)
        end

        it "generates learning_outcome_groups overview section" do
          helper = subject.new
          helper.course = course
          helper.settings = { content_migration: }
          overview = helper.overview
          groups = overview[:learning_outcome_groups]
          outcomes = overview[:learning_outcomes]
          expect(groups.length).to eq 1
          expect(outcomes.length).to eq 1
          expect(groups.first[:migration_id]).to eq outcomes.first[:parent_migration_id]
        end
      end
    end
  end
end
