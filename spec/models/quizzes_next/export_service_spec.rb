# frozen_string_literal: true

# Copyright (C) 2018 - present Instructure, Inc.
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

describe QuizzesNext::ExportService do
  describe ".applies_to_course?" do
    let(:course) { double("course") }

    context "service enabled for context" do
      it "returns true" do
        allow(QuizzesNext::Service).to receive(:enabled_in_context?).and_return(true)
        expect(described_class.applies_to_course?(course)).to be(true)
      end
    end

    context "service not enabled for context" do
      it "returns false" do
        allow(QuizzesNext::Service).to receive(:enabled_in_context?).and_return(false)
        expect(described_class.applies_to_course?(course)).to be(false)
      end
    end
  end

  describe ".begin_export" do
    let(:course) { double("course") }

    before do
      allow(course).to receive(:uuid).and_return(1234)
    end

    context "no assignments" do
      it "does nothing" do
        allow(QuizzesNext::Service).to receive(:active_lti_assignments_for_course).and_return([])

        expect(described_class.begin_export(course, {})).to be_nil
      end
    end

    it "filters to selected assignments with selective exports" do
      export_opts = { selective: true, exported_assets: ["assignment_42", "wiki_page_84"] }
      expect(QuizzesNext::Service).to receive(:active_lti_assignments_for_course).with(course, selected_assignment_ids: ["42"]).and_return([])
      described_class.begin_export(course, export_opts)
    end

    it "returns metadata for each assignment" do
      assignment1 = double("assignment")
      assignment2 = double("assignment")
      lti_assignments = [
        assignment1,
        assignment2
      ]

      lti_assignments.each_with_index do |assignment, index|
        allow(assignment).to receive_messages(lti_resource_link_id: "link-id-#{index}", id: index)
      end

      allow(QuizzesNext::Service).to receive(:active_lti_assignments_for_course).and_return(lti_assignments)

      expect(described_class.begin_export(course, {})).to eq(
        {
          original_course_uuid: 1234,
          assignments: [
            { original_resource_link_id: "link-id-0", "$canvas_assignment_id": 0, original_assignment_id: 0 },
            { original_resource_link_id: "link-id-1", "$canvas_assignment_id": 1, original_assignment_id: 1 }
          ]
        }
      )
    end
  end

  describe ".retrieve_export" do
    it "returns what is sent in" do
      expect(described_class.retrieve_export("foo")).to eq("foo")
    end
  end

  describe ".send_imported_content" do
    let(:old_course) { course_model(uuid: "100005") }
    let(:new_course) { course_model(uuid: "100006") }
    let(:root_account) { account_model }
    let(:content_migration) { double(started_at: 1.hour.ago, migration_type: "some_type", asset_map_url: "http://example.com/resource_map.json") }
    let(:new_assignment1) { assignment_model(id: 1, context: new_course) }
    let(:new_assignment2) { assignment_model(id: 2, context: new_course) }
    let(:old_assignment1) { assignment_model(id: 3, context: old_course) }
    let(:old_assignment2) { assignment_model(id: 4, context: old_course) }
    let(:basic_import_content) do
      {
        original_course_uuid: old_course.uuid,
        assignments: [
          {
            original_resource_link_id: "link-1234",
            "$canvas_assignment_id": new_assignment1.id,
            original_assignment_id: old_assignment1.id
          }
        ]
      }
    end

    before do
      allow(old_course).to receive(:root_account).and_return(root_account)
      allow(new_course).to receive_messages(lti_context_id: "ctx-1234", name: "Course Name", root_account:)

      allow(root_account).to receive(:domain).and_return("canvas.instructure.com")
    end

    it "emits a single live event when there are copied assignments" do
      payload = {
        original_course_uuid: "100005",
        new_course_uuid: "100006",
        new_course_resource_link_id: "ctx-1234",
        domain: "canvas.instructure.com",
        new_course_name: "Course Name",
        created_on_blueprint_sync: false,
        resource_map_url: "http://example.com/resource_map.json",
        remove_alignments: false,
        status: "duplicating"
      }

      basic_import_content[:assignments] << {
        original_resource_link_id: "link-5678",
        "$canvas_assignment_id": new_assignment2.id,
        original_assignment_id: old_assignment2.id
      }

      expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).with(payload).once
      described_class.send_imported_content(new_course, content_migration, basic_import_content)
    end

    it "ignores assignments when the original assignment cannot be found as a child of the original course" do
      course_model(uuid: "100007")
      basic_import_content[:original_course_uuid] = "100007"

      expect(Canvas::LiveEvents).not_to receive(:quizzes_next_quiz_duplicated)
    end

    it "ignores assignments if the original course doesn't exist" do
      basic_import_content[:original_course_uuid] = "100007"

      expect(Canvas::LiveEvents).not_to receive(:quizzes_next_quiz_duplicated)
    end

    it "ignores not found assignments" do
      basic_import_content[:assignments] << {
        original_resource_link_id: "5678",
        "$canvas_assignment_id": Canvas::Migration::ExternalContent::Translator::NOT_FOUND
      }

      expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).once
      described_class.send_imported_content(new_course, content_migration, basic_import_content)
    end

    it "skips assignments created prior to the current migration" do
      Assignment.where(id: new_assignment1).update_all(created_at: 1.day.ago)
      expect(Canvas::LiveEvents).not_to receive(:quizzes_next_quiz_duplicated)
      described_class.send_imported_content(new_course, content_migration, basic_import_content)
    end

    it 'puts new assignments in the "duplicating" state' do
      allow(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated)

      described_class.send_imported_content(new_course, content_migration, basic_import_content)
      expect(new_assignment1.reload.workflow_state).to eq("duplicating")
    end

    it "sets the new assignment as duplicate of the old assignment" do
      allow(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated)

      described_class.send_imported_content(new_course, content_migration, basic_import_content)
      expect(new_assignment1.reload.duplicate_of).to eq(old_assignment1)
    end

    it "sets the external_tool_tag to be the same as the old tag" do
      allow(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated)

      described_class.send_imported_content(new_course, content_migration, basic_import_content)
      expect(new_assignment1.reload.external_tool_tag).to eq(old_assignment1.external_tool_tag)
    end

    it "skips assignments that are not duplicates" do
      basic_import_content[:assignments] << {
        original_resource_link_id: "5678",
        "$canvas_assignment_id": new_assignment2.id
      }

      expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).once
      # The specific error I care about here is `KeyError`, because that is what
      # is raised when we try to access a key that is not present in the
      # assignment hash, which is what has led to this fix.
      expect { described_class.send_imported_content(new_course, content_migration, basic_import_content) }.not_to raise_error
    end

    context "when the assignment is created as part of a blueprint sync" do
      let(:content_migration) { double(started_at: 1.hour.ago, migration_type: "master_course_import", asset_map_url: "http://example.com/resource_map.json") }

      before do
        course = course_model
        @master_template = MasterCourses::MasterTemplate.create!(course:)
        @child_course = course_model
        @child_subscription = MasterCourses::ChildSubscription.create!(master_template: @master_template, child_course: @child_course)

        allow(@child_course).to receive(:root_account).and_return(root_account)
      end

      it "emits a live event with the field created_on_blueprint_sync set as true" do
        basic_import_content[:assignments] << {
          original_resource_link_id: "link-5678",
          "$canvas_assignment_id": new_assignment2.id,
          original_assignment_id: old_assignment2.id
        }

        expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).with(
          hash_including(created_on_blueprint_sync: true)
        ).once
        described_class.send_imported_content(@child_course, content_migration, basic_import_content)
      end

      it "doesn't mark downstream changes when updating duplicating assignments" do
        tag = @master_template.create_content_tag_for!(old_assignment2)
        new_assignment2.migration_id = tag.migration_id
        new_assignment2.save!

        child_content_tag = MasterCourses::ChildContentTag.create!(
          child_subscription: @child_subscription,
          content: new_assignment2
        )

        basic_import_content[:assignments] << {
          original_resource_link_id: "link-5678",
          "$canvas_assignment_id": new_assignment2.id,
          original_assignment_id: old_assignment2.id
        }

        allow(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated)

        described_class.send_imported_content(new_course, content_migration, basic_import_content)
        expect(child_content_tag.reload.downstream_changes).to be_empty
      end
    end

    context "when an assignment is imported into a blueprint child course" do
      let(:content_migration) { double(started_at: 1.hour.ago, migration_type: "common_cartridge_importer", asset_map_url: "http://example.com/resource_map.json") }

      before do
        course = course_model
        master_template = MasterCourses::MasterTemplate.create!(course:)
        @child_course = course_model
        MasterCourses::ChildSubscription.create!(master_template:, child_course: @child_course)
        allow(@child_course).to receive(:root_account).and_return(root_account)
      end

      it "emits a live event with the field created_on_blueprint_sync set as false" do
        basic_import_content[:assignments] << {
          original_resource_link_id: "link-5678",
          "$canvas_assignment_id": new_assignment2.id,
          original_assignment_id: old_assignment2.id
        }

        expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).with(
          hash_including(created_on_blueprint_sync: false)
        ).once
        described_class.send_imported_content(@child_course, content_migration, basic_import_content)
      end
    end

    context "when an assignment is imported into a non-blueprint course" do
      let(:content_migration) { double(started_at: 1.hour.ago, migration_type: "common_cartridge_importer", asset_map_url: "http://example.com/resource_map.json") }

      it "emits a live event with the field created_on_blueprint_sync set as false" do
        basic_import_content[:assignments] << {
          original_resource_link_id: "link-5678",
          "$canvas_assignment_id": new_assignment2.id,
          original_assignment_id: old_assignment2.id
        }

        expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).with(
          hash_including(created_on_blueprint_sync: false)
        ).once
        described_class.send_imported_content(new_course, content_migration, basic_import_content)
      end
    end

    context "when an assignment is imported using course copy" do
      it "emits a live event with the field remove_alignments set as false" do
        cm = double({ started_at: 1.hour.ago, migration_type: "course_copy_importer", copy_options: { everything: true }, asset_map_url: "http://example.com/resource_map.json" })

        expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).with(
          hash_including(remove_alignments: false)
        ).once

        described_class.send_imported_content(new_course, cm, basic_import_content)
      end

      it "emits a live event with the field remove_alignments set as true" do
        cm = double({ started_at: 1.hour.ago, migration_type: "course_copy_importer", copy_options: { all_course_settings: "1", all_assignments: "1" }, asset_map_url: "http://example.com/resource_map.json" })

        expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).with(
          hash_including(remove_alignments: true)
        ).once

        described_class.send_imported_content(new_course, cm, basic_import_content)
      end

      it "emits a live event with the field remove_alignments set as false (selected outcomes in course content)" do
        cm = double({ started_at: 1.hour.ago, migration_type: "course_copy_importer", copy_options: { all_course_settings: "1", all_assignments: "1", all_learning_outcomes: "1" }, asset_map_url: "http://example.com/resource_map.json" })

        expect(Canvas::LiveEvents).to receive(:quizzes_next_quiz_duplicated).with(
          hash_including(remove_alignments: false)
        ).once

        described_class.send_imported_content(new_course, cm, basic_import_content)
      end
    end
  end
end
