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

require_relative "../../spec_helper"

describe SupportHelpers::AssetProcessorDiscussionNoticeResubmission do
  let(:course) { course_model }
  let(:student) { user_model }
  let(:assignment) { assignment_model(course:, submission_types: "discussion_topic") }
  let(:discussion_topic) { assignment.discussion_topic }
  let(:submission) { assignment.submissions.find_by(user: student) }
  let(:tool) { external_tool_1_3_model(context: course, placements: ["ActivityAssetProcessorContribution"]) }
  let(:asset_processor) { lti_asset_processor_model(assignment:, tool:) }

  before do
    course.enroll_student(student, enrollment_state: "active")
    # Create a discussion entry with a version
    @discussion_entry = discussion_topic.discussion_entries.create!(
      user: student,
      message: "Test discussion entry"
    )
    @discussion_entry_version = @discussion_entry.discussion_entry_versions.first
  end

  describe "#fix" do
    it "notifies the asset processor of a resubmission for discussion topic context" do
      asset_processor # Ensure asset processor exists
      fixer = SupportHelpers::AssetProcessorDiscussionNoticeResubmission.new("email", nil, discussion_topic)
      expect(Lti::AssetProcessorDiscussionNotifier).to receive(:notify_asset_processors_of_discussion).with(
        hash_including(
          assignment:,
          submission:,
          discussion_entry_version: @discussion_entry_version,
          contribution_status: Lti::Pns::LtiAssetProcessorContributionNoticeBuilder::SUBMITTED,
          current_user: student,
          asset_processor: nil
        )
      )
      fixer.fix
    end

    it "notifies the asset processor of a resubmission for course context" do
      asset_processor # Ensure asset processor exists
      fixer = SupportHelpers::AssetProcessorDiscussionNoticeResubmission.new("email", nil, course)
      expect(Lti::AssetProcessorDiscussionNotifier).to receive(:notify_asset_processors_of_discussion).with(
        hash_including(
          assignment:,
          submission:,
          discussion_entry_version: @discussion_entry_version,
          contribution_status: Lti::Pns::LtiAssetProcessorContributionNoticeBuilder::SUBMITTED,
          current_user: student,
          asset_processor: nil
        )
      )
      fixer.fix
    end

    it "skips non-graded discussion topics when context is course" do
      asset_processor # Ensure asset processor exists
      # Create a non-graded discussion topic
      non_graded_topic = discussion_topic_model(context: course)
      # Create entry for the non-graded topic
      non_graded_topic.discussion_entries.create!(
        user: student,
        message: "Entry for non-graded topic"
      )

      fixer = SupportHelpers::AssetProcessorDiscussionNoticeResubmission.new("email", nil, course)

      # Should only notify for the graded topic (the one with assignment)
      expect(Lti::AssetProcessorDiscussionNotifier).to receive(:notify_asset_processors_of_discussion).once.with(
        hash_including(
          assignment:,
          discussion_entry_version: @discussion_entry_version
        )
      )

      fixer.fix
    end

    it "includes teacher comments (entries without submissions)" do
      asset_processor # Ensure asset processor exists

      # Create a teacher and enroll them
      teacher = user_model
      course.enroll_teacher(teacher, enrollment_state: "active")

      # Teacher creates a comment (no submission for teachers)
      teacher_entry = discussion_topic.discussion_entries.create!(
        user: teacher,
        message: "Teacher feedback"
      )
      teacher_entry.discussion_entry_versions.first

      fixer = SupportHelpers::AssetProcessorDiscussionNoticeResubmission.new("email", nil, discussion_topic)

      # Should notify for both student entry and teacher comment
      expect(Lti::AssetProcessorDiscussionNotifier).to receive(:notify_asset_processors_of_discussion).twice

      fixer.fix
    end

    it "raises ArgumentError for invalid context type" do
      expect do
        SupportHelpers::AssetProcessorDiscussionNoticeResubmission.new("email", nil, student)
      end.to raise_error(ArgumentError, "context must be a DiscussionTopic or Course")
    end
  end
end
