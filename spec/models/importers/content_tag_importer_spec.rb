# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe "ContentTagImporter" do
  describe "process_migration" do
    subject { Importers::ContentTagImporter.process_migration(data, migration) }

    let(:course) { course_model }
    let(:horizon_course) { true }
    let(:mod) { course.context_modules.create!(name: "Module 1", migration_id: "mod1") }
    let(:tag) do
      mod.content_tags.create!(
        migration_id: "CT",
        context: @course,
        tag_type: "context_module",
        content_type: "ExternalUrl",
        url: "http://v1"
      )
    end
    let(:migration) { course.content_migrations.create! }
    let(:module_data) do
      {
        "migration_id" => mod.migration_id,
        "items" => [
          {
            "item_migration_id" => tag.migration_id,
            "url" => "http://v2",
            "linked_resource_type" => "URL_TYPE"
          }
        ]
      }
    end
    let(:data) { { "modules" => [module_data] } }

    before do
      course.account.enable_feature!(:horizon_course_setting)
      course.update!(horizon_course:)
    end

    context "when the module is being imported" do
      let(:migration) do
        course.content_migrations.create!(
          migration_settings: {
            migration_ids_to_import: {
              copy: { everything: true }
            }
          }
        )
      end

      it "does not update the content tags" do
        expect { subject }.not_to change { tag.reload.url }
      end
    end

    context "when the module is not being imported but the item is" do
      let(:migration) do
        course.content_migrations.create!(
          migration_settings: {
            migration_ids_to_import: {
              copy: { "all_module_items" => true }
            }
          }
        )
      end

      it "updates the content tag" do
        expect { subject }.to change { tag.reload.url }.from("http://v1").to("http://v2")
      end

      it "updates matching content tags in other modules" do
        mod2 = course.context_modules.create!(name: "Module 2")
        tag2 = mod2.content_tags.create!(
          migration_id: tag.migration_id,
          context: @course,
          tag_type: "context_module",
          content_type: "ExternalUrl",
          url: "http://v1"
        )
        subject
        expect(tag.reload.url).to eq "http://v2"
        expect(tag2.reload.url).to eq "http://v2"
      end

      context "not a horizon course" do
        let(:horizon_course) { false }

        it "does not update the content tag" do
          expect { subject }.not_to change { tag.reload.url }
        end
      end
    end

    context "when there are no items" do
      let(:module_data) do
        {
          "migration_id" => "123"
        }
      end

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when the item migration id is missing" do
      let(:module_data) do
        {
          "migration_id" => "123",
          "items" => [
            {
              "url" => "http://v2",
              "linked_resource_type" => "URL_TYPE"
            }
          ]
        }
      end

      it "does not create a content tag" do
        expect { subject }.not_to change { ContentTag.count }
      end
    end
  end
end
