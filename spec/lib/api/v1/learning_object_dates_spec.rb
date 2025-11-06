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

require_relative "../../../spec_helper"

class LearningObjectDatesApiHarness
  include Api::V1::LearningObjectDates

  def initialize(current_user = nil)
    @current_user = current_user
  end

  def session
    {}
  end
end

describe Api::V1::LearningObjectDates do
  let(:harness) { LearningObjectDatesApiHarness.new(user_model) }
  let(:course) { course_model }
  let(:assignment) { assignment_model(course:) }

  describe "#peer_review_overrides_supported?" do
    context "when overridable is not an Assignment" do
      let(:quiz) { quiz_model(course:) }

      it "returns false for non-Assignment objects" do
        expect(harness.send(:peer_review_overrides_supported?, quiz)).to be false
      end
    end

    context "when overridable is an Assignment" do
      context "when assignment does not have peer reviews enabled" do
        it "returns false" do
          assignment.update!(peer_reviews: false)
          expect(harness.send(:peer_review_overrides_supported?, assignment)).to be false
        end
      end

      context "when assignment has peer reviews but no peer_review_sub_assignment" do
        it "returns false" do
          assignment.update!(peer_reviews: true)
          expect(harness.send(:peer_review_overrides_supported?, assignment)).to be false
        end
      end

      context "when assignment is a discussion topic" do
        let(:discussion_assignment) { graded_discussion_topic(context: course).assignment }

        it "returns false for discussion topics" do
          discussion_assignment.update!(peer_reviews: true)
          course.enable_feature!(:peer_review_grading)

          expect(harness.send(:peer_review_overrides_supported?, discussion_assignment)).to be false
        end
      end

      context "when assignment has peer reviews and peer_review_sub_assignment" do
        before do
          assignment.update!(peer_reviews: true)
          course.enable_feature!(:peer_review_grading)
          PeerReview::PeerReviewCreatorService.new(parent_assignment: assignment).call
          assignment.reload
        end

        it "returns true when feature is enabled" do
          expect(harness.send(:peer_review_overrides_supported?, assignment)).to be true
        end

        it "returns false when feature is disabled" do
          course.disable_feature!(:peer_review_grading)
          expect(harness.send(:peer_review_overrides_supported?, assignment)).to be false
        end
      end
    end
  end

  describe "#add_peer_review_info" do
    let(:hash) { {} }

    context "when peer review overrides are not supported" do
      it "does not modify the hash" do
        assignment.update!(peer_reviews: false)
        harness.send(:add_peer_review_info, hash, assignment)
        expect(hash).to eq({})
      end
    end

    context "when peer review overrides are supported" do
      let(:user) { user_model }
      let(:section) { course.course_sections.create!(name: "Test Section") }

      before do
        assignment.update!(peer_reviews: true)
        course.enable_feature!(:peer_review_grading)
        PeerReview::PeerReviewCreatorService.new(
          parent_assignment: assignment,
          due_at: "2025-09-10T18:00:00Z",
          unlock_at: "2025-09-05T08:00:00Z",
          lock_at: "2025-09-15T18:00:00Z"
        ).call
        assignment.reload
      end

      context "without overrides" do
        it "adds peer_review_sub_assignment data to hash" do
          peer_review_sub = assignment.peer_review_sub_assignment
          harness.send(:add_peer_review_info, hash, assignment)

          expect(hash).to have_key("peer_review_sub_assignment")
          peer_review_data = hash["peer_review_sub_assignment"]
          expect(peer_review_data[:id]).to eq(peer_review_sub.id)
          expect(peer_review_data[:due_at]).to eq("2025-09-10T18:00:00Z")
          expect(peer_review_data[:unlock_at]).to eq("2025-09-05T08:00:00Z")
          expect(peer_review_data[:lock_at]).to eq("2025-09-15T18:00:00Z")
          expect(peer_review_data[:only_visible_to_overrides]).to eq(peer_review_sub.only_visible_to_overrides)
          expect(peer_review_data[:visible_to_everyone]).to eq(peer_review_sub.visible_to_everyone)
          expect(peer_review_data[:overrides]).to eq([])
        end
      end

      context "with overrides" do
        before do
          @peer_review_override = assignment.peer_review_sub_assignment.assignment_overrides.create!(
            course_section: section,
            due_at: "2025-09-12T18:00:00Z",
            unlock_at: "2025-09-07T08:00:00Z",
            lock_at: "2025-09-17T18:00:00Z",
            due_at_overridden: true,
            unlock_at_overridden: true,
            lock_at_overridden: true
          )
        end

        it "includes overrides data in the response" do
          harness.send(:add_peer_review_info, hash, assignment)

          expect(hash).to have_key("peer_review_sub_assignment")
          peer_review_data = hash["peer_review_sub_assignment"]
          expect(peer_review_data[:overrides]).to have(1).item

          override_data = peer_review_data[:overrides].first
          expect(override_data["id"]).to eq(@peer_review_override.id)
          expect(override_data["assignment_id"]).to eq(assignment.peer_review_sub_assignment.id)
          expect(override_data["course_section_id"]).to eq(section.id)
          expect(override_data["title"]).to eq(section.name)
          expect(override_data["due_at"]).to eq("2025-09-12T18:00:00Z")
          expect(override_data["unlock_at"]).to eq("2025-09-07T08:00:00Z")
          expect(override_data["lock_at"]).to eq("2025-09-17T18:00:00Z")
        end
      end

      context "when assignment has inactive overrides" do
        before do
          assignment.peer_review_sub_assignment.assignment_overrides.create!(
            course_section: section,
            due_at: "2025-09-15T18:00:00Z",
            workflow_state: "deleted"
          )
        end

        it "excludes inactive overrides" do
          harness.send(:add_peer_review_info, hash, assignment)

          peer_review_data = hash["peer_review_sub_assignment"]
          expect(peer_review_data[:overrides]).to eq([])
        end
      end
    end
  end
end
