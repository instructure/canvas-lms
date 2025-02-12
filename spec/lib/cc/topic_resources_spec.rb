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
require_relative "cc_spec_helper"

class TopicResourceTestClass
  include CC::TopicResources

  delegate :add_exported_asset, to: :@manifest

  def initialize(user, manifest, course)
    @user = user
    @manifest = manifest
    @course = course
  end

  def create_key(entity)
    "unique_" + entity.id.to_s
  end
end

describe CC::TopicResources do
  subject do
    test_class = TopicResourceTestClass.new(mock_user, manifest, mock_course)
    doc.instruct!
    doc.topicMeta("identifier" => "id123",
                  "xmlns" => CC::CCHelper::CANVAS_NAMESPACE,
                  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                  "xsi:schemaLocation" => "#{CC::CCHelper::CANVAS_NAMESPACE} #{CC::CCHelper::XSD_URI}") do |parent_doc|
      test_class.create_canvas_topic(parent_doc, topic)
    end
    Nokogiri::XML(doc.target!)
  end

  let(:ccc_schema) { get_ccc_schema }
  let(:mock_course) { course_model }
  let(:mock_user) { user_model }
  let(:exporter) { CC::CCExporter.new(nil, course: mock_course, user: mock_user) }
  let(:manifest) { CC::Manifest.new(exporter) }
  let(:doc) { Builder::XmlMarkup.new }
  let(:reply_to_entry_required_count) { "5" }
  let(:parent_assignment) { mock_course.assignments.create! }
  let(:discussion_type) { DiscussionTopic::DiscussionTypes::THREADED }
  let(:topic) { mock_course.discussion_topics.create!(message: "hi", title: "discussion title", discussion_type:) }
  let(:discussion_checkpoints_enabled) do
    allow(mock_course.root_account).to receive(:feature_enabled?).with(:discussion_checkpoints)
  end

  before do
    allow(mock_course).to receive_messages(root_account: Account.create!)
    allow(mock_course.root_account).to receive(:feature_enabled?).with(:horizon_course_setting)
  end

  describe "#create_canvas_topic" do
    before do
      allow(mock_course.account).to receive(:feature_enabled?).with(:assign_to_differentiation_tags).and_return(false)
    end

    context "reply_to_entry_required_count" do
      context "when discussion_checkpoints is enabled" do
        before do
          discussion_checkpoints_enabled.and_return(true)
        end

        context "when reply_to_entry_required_count is present" do
          before do
            topic.update!(reply_to_entry_required_count:, assignment: parent_assignment)
            topic.assignment.update!(has_sub_assignments: true)
          end

          it "should add reply_to_entry_required_count attribute with value to xml" do
            expect(subject.css("reply_to_entry_required_count").text).to eq reply_to_entry_required_count
          end

          it("should validate the xml output by xsd") { expect(ccc_schema.validate(subject)).to be_empty }
        end

        context "when parent assignment is not present for discussion" do
          before do
            topic.update!(assignment: nil)
          end

          it "should skip reply_to_entry_required_count attribute from xml" do
            expect(subject.css("reply_to_entry_required_count").count).to eq 0
          end

          it("should validate the xml output by xsd") { expect(ccc_schema.validate(subject)).to be_empty }
        end

        context "when discussion is not checkpoint discussion" do
          before do
            topic.update!(assignment: parent_assignment)
            topic.assignment.update!(has_sub_assignments: false)
          end

          it "should skip reply_to_entry_required_count attribute from xml" do
            expect(subject.css("reply_to_entry_required_count").count).to eq 0
          end

          it("should validate the xml output by xsd") { expect(ccc_schema.validate(subject)).to be_empty }
        end
      end

      context "when discussion_checkpoints is disabled" do
        before do
          discussion_checkpoints_enabled.and_return(false)
        end

        it "should skip reply_to_entry_required_count attribute from xml" do
          expect(subject.css("reply_to_entry_required_count").count).to eq 0
        end

        it("should validate the xml output by xsd") { expect(ccc_schema.validate(subject)).to be_empty }
      end
    end

    context "sub_assignments" do
      context "when discussion_checkpoints is enabled" do
        before do
          discussion_checkpoints_enabled.and_return(true)
        end

        context "when parent assignment is not present for discussion" do
          before do
            topic.update!(reply_to_entry_required_count:, assignment: nil)
          end

          it "should skip sub_assignments attribute from xml" do
            expect(subject.css("sub_assignments").count).to eq 0
            expect(subject.css("sub_assignment").count).to eq 0
          end

          it("should validate the xml output by xsd") { expect(ccc_schema.validate(subject)).to be_empty }
        end

        context "when sub_assignment is present" do
          before do
            topic.update!(reply_to_entry_required_count:, assignment: parent_assignment)
            topic.assignment.update!(has_sub_assignments: true)

            common_attributes = {
              name: "SubAssignment Name",
              points_possible: 1,
              due_at: 3.days.from_now,
              only_visible_to_overrides: false,
              context: mock_course,
              parent_assignment:
            }

            SubAssignment.create!(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, **common_attributes)
            SubAssignment.create!(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, **common_attributes)
          end

          it "should add 1 sub_assignments attribute with 2 sub_assignment to xml" do
            sub_assignments = subject.css("sub_assignments")
            expect(sub_assignments.count).to eq 1
            expect(sub_assignments.css("sub_assignment").count).to eq 2
          end

          it "should add 1 sub_assignment with CheckpointLabels::REPLY_TO_TOPIC to xml" do
            expect(subject.css("sub_assignment[tag=#{CheckpointLabels::REPLY_TO_TOPIC}]").count).to eq 1
          end

          it "should add 1 sub_assignment with CheckpointLabels::REPLY_TO_ENTRY to xml" do
            expect(subject.css("sub_assignment[tag=#{CheckpointLabels::REPLY_TO_ENTRY}]").count).to eq 1
          end

          it("should validate the xml output by xsd") { expect(ccc_schema.validate(subject)).to be_empty }

          context "when discussion is not checkpoint discussion" do
            before do
              topic.assignment.update!(has_sub_assignments: false)
            end

            it "should skip sub_assignments attribute from xml" do
              expect(subject.css("sub_assignments").count).to eq 0
              expect(subject.css("sub_assignment").count).to eq 0
            end

            it("should validate the xml output by xsd") { expect(ccc_schema.validate(subject)).to be_empty }
          end
        end

        context "when sub_assignment is not present" do
          before do
            topic.update!(reply_to_entry_required_count:, assignment: parent_assignment)
            topic.assignment.update!(has_sub_assignments: true)
          end

          it "should skip sub_assignments attribute from xml" do
            expect(subject.css("sub_assignments").count).to eq 0
            expect(subject.css("sub_assignment").count).to eq 0
          end

          it("should validate the xml output by xsd") { expect(ccc_schema.validate(subject)).to be_empty }
        end
      end

      context "when discussion_checkpoints is disabled" do
        before do
          discussion_checkpoints_enabled.and_return(false)
        end

        it "should skip sub_assignments attribute from xml" do
          expect(subject.css("sub_assignments").count).to eq 0
          expect(subject.css("sub_assignment").count).to eq 0
        end

        it("should validate the xml output by xsd") { expect(ccc_schema.validate(subject)).to be_empty }
      end
    end
  end
end
