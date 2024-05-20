# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::Lti::RestoreMigratedLineItems do
  let(:course) { course_model }
  let(:dest_course) { course_model }
  let(:tool) { external_tool_1_3_model(context: course) }
  let(:assignment) do
    course.assignments.create!(
      submission_types: "external_tool",
      external_tool_tag_attributes: {
        url: tool.url,
        content_type: "ContextExternalTool",
        content_id: tool.id
      },
      points_possible: 42
    )
  end
  let(:other_lti_assignment) do
    course.assignments.create!(
      submission_types: "external_tool",
      external_tool_tag_attributes: {
        url: tool.url,
        content_type: "ContextExternalTool",
        content_id: tool.id
      },
      points_possible: 42
    )
  end
  let(:other_copied_assignment) do
    course.assignments.create!(submission_types: "online_text_entry", points_possible: 42)
  end
  # stuff that needs to run before the "broken import"
  let(:pre_import_setup) { -> {} }

  before do
    other_lti_assignment
    copied = [assignment, other_copied_assignment]
    pre_import_setup.call
    copied.each do |a|
      a.destroy
      a.reload
      a.update! workflow_state: "unpublished"
    end
  end

  describe ".run" do
    subject { DataFixup::Lti::RestoreMigratedLineItems.run }

    before do
      allow(DataFixup::Lti::RestoreMigratedLineItems).to receive(:process_batch).and_return(true)
    end

    it "only finds affected assignment" do
      subject
      expect(DataFixup::Lti::RestoreMigratedLineItems).to have_received(:process_batch).with([assignment.id])
    end
  end

  describe ".process_batch" do
    subject { DataFixup::Lti::RestoreMigratedLineItems.process_batch(assignment_ids) }

    let(:assignment_ids) { [assignment.id] }

    it "undeletes line items" do
      expect(Lti::LineItem.find_by(assignment:)).to be_deleted
      subject
      expect(Lti::LineItem.find_by(assignment:)).to be_active
    end

    it "undeletes resource links" do
      expect(Lti::ResourceLink.find_by(context: assignment)).to be_deleted
      subject
      expect(Lti::ResourceLink.find_by(context: assignment)).to be_active
    end

    it "undeletes content tags" do
      expect(ContentTag.find_by(context: assignment)).to be_deleted
      subject
      expect(ContentTag.find_by(context: assignment)).to be_active
    end

    context "when tool has scored assignment via AGS" do
      let(:user) { student_in_course(course:, active_all: true).user }
      let(:line_item) { Lti::LineItem.find_by(assignment:) }
      let(:result) do
        Lti::Result.create!(
          result_score: 10,
          result_maximum: 10,
          activity_progress: "Completed",
          grading_progress: "FullyGraded",
          line_item:,
          submission: assignment.submissions.find_by(user:),
          user:,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        )
      end
      let(:pre_import_setup) { -> { result } }

      it "undeletes results" do
        expect(result.reload).to be_deleted
        subject
        expect(result.reload).to be_active
      end
    end

    context "when assignment was created via Line Item API" do
      let(:pre_import_setup) do
        lambda do
          Timecop.travel(20.seconds.ago) do
            assignment.line_items.first.update! coupled: false
          end
        end
      end

      it "undeletes line items" do
        expect(Lti::LineItem.find_by(assignment:)).to be_deleted
        subject
        expect(Lti::LineItem.find_by(assignment:)).to be_active
      end
    end

    context "when assignment has deleted extra line item" do
      let(:resource_link) { Lti::ResourceLink.find_by(context: assignment) }
      let(:primary) { assignment.line_items.first }
      let(:extra_deleted) { Lti::LineItem.create!(assignment:, resource_link:, score_maximum: 42, label: "extra deleted", client_id: tool.developer_key.global_id, coupled: false) }
      let(:extra_active) { Lti::LineItem.create!(assignment:, resource_link:, score_maximum: 42, label: "extra active", client_id: tool.developer_key.global_id, coupled: false) }
      let(:pre_import_setup) do
        lambda do
          # simulate real world time passing between AGS delete
          # and assignment delete/re-import
          Timecop.travel(20.seconds.ago) do
            primary.update! created_at: Time.zone.now
          end
          Timecop.travel(10.seconds.ago) do
            # create extra line items and delete one,
            # acting as a tool would via AGS
            extra_active
            extra_deleted.destroy
          end
        end
      end

      it "only undeletes affected line items" do
        subject
        expect(primary.reload).to be_active
        expect(extra_active.reload).to be_active
        expect(extra_deleted.reload).to be_deleted
      end

      context "when primary line item is not marked coupled" do
        let(:pre_import_setup) do
          lambda do
            # simulate real world time passing between AGS delete
            # and assignment delete/re-import
            Timecop.travel(20.seconds.ago) do
              primary.update! created_at: Time.zone.now, coupled: false
            end
            Timecop.travel(10.seconds.ago) do
              # create extra line items and delete one,
              # acting as a tool would via AGS
              extra_active
              extra_deleted.destroy
            end
          end
        end

        it "undeletes affected line items" do
          subject
          expect(primary.reload).to be_active
          expect(extra_active.reload).to be_active
          expect(extra_deleted.reload).to be_deleted
        end
      end
    end
  end
end
