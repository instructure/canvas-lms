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

require "spec_helper"

RSpec.describe PeerReview::PeerReviewCommonService do
  let(:course) { course_model(name: "Course with Assignment") }
  let(:parent_assignment) do
    assignment_model(
      course:,
      title: "Parent Assignment",
      points_possible: 10,
      grading_type: "points",
      due_at: 1.week.from_now,
      unlock_at: 1.day.from_now,
      lock_at: 2.weeks.from_now,
      peer_review_count: 2,
      peer_reviews: true,
      automatic_peer_reviews: true,
      anonymous_peer_reviews: false,
      intra_group_peer_reviews: true,
      submission_types: "online_text_entry,online_upload"
    )
  end

  let(:peer_review_grading_type) { "points" }
  let(:peer_review_points_possible) { 10 }
  let(:custom_due_at) { 3.days.from_now }
  let(:custom_unlock_at) { 2.days.from_now }
  let(:custom_lock_at) { 1.week.from_now }

  let(:service) do
    described_class.new(
      parent_assignment:,
      points_possible: peer_review_points_possible,
      grading_type: peer_review_grading_type,
      due_at: custom_due_at,
      unlock_at: custom_unlock_at,
      lock_at: custom_lock_at
    )
  end

  before do
    course.enable_feature!(:peer_review_grading)
  end

  describe "#initialize" do
    it "sets the instance variables correctly" do
      expect(service.instance_variable_get(:@parent_assignment)).to eq(parent_assignment)
      expect(service.instance_variable_get(:@points_possible)).to eq(peer_review_points_possible)
      expect(service.instance_variable_get(:@grading_type)).to eq(peer_review_grading_type)
      expect(service.instance_variable_get(:@due_at)).to eq(custom_due_at)
      expect(service.instance_variable_get(:@unlock_at)).to eq(custom_unlock_at)
      expect(service.instance_variable_get(:@lock_at)).to eq(custom_lock_at)
    end

    it "allows nil values for optional parameters" do
      simple_service = described_class.new(parent_assignment:)
      expect(simple_service.instance_variable_get(:@points_possible)).to be_nil
      expect(simple_service.instance_variable_get(:@grading_type)).to be_nil
      expect(simple_service.instance_variable_get(:@due_at)).to be_nil
      expect(simple_service.instance_variable_get(:@unlock_at)).to be_nil
      expect(simple_service.instance_variable_get(:@lock_at)).to be_nil
    end
  end

  describe "#peer_review_attributes" do
    it "returns combined inherited and specific attributes" do
      attributes = service.send(:peer_review_attributes)

      expect(attributes[:assignment_group_id]).to eq(parent_assignment.assignment_group_id)
      expect(attributes[:context_id]).to eq(parent_assignment.context_id)
      expect(attributes[:context_type]).to eq(parent_assignment.context_type)
      expect(attributes[:description]).to eq(parent_assignment.description)
      expect(attributes[:peer_review_count]).to eq(parent_assignment.peer_review_count)
      expect(attributes[:peer_reviews]).to eq(parent_assignment.peer_reviews)
      expect(attributes[:peer_reviews_due_at]).to eq(parent_assignment.peer_reviews_due_at)
      expect(attributes[:anonymous_peer_reviews]).to eq(parent_assignment.anonymous_peer_reviews)
      expect(attributes[:automatic_peer_reviews]).to eq(parent_assignment.automatic_peer_reviews)
      expect(attributes[:intra_group_peer_reviews]).to eq(parent_assignment.intra_group_peer_reviews)
      expect(attributes[:workflow_state]).to eq(parent_assignment.workflow_state)

      expect(attributes[:has_sub_assignments]).to be(false)
      expect(attributes[:title]).to eq("#{parent_assignment.title} Peer Review")
      expect(attributes[:submission_types]).to eq("online_text_entry")
      expect(attributes[:parent_assignment_id]).to eq(parent_assignment.id)
      expect(attributes[:points_possible]).to eq(peer_review_points_possible)
      expect(attributes[:grading_type]).to eq(peer_review_grading_type)
      expect(attributes[:due_at]).to eq(custom_due_at)
      expect(attributes[:unlock_at]).to eq(custom_unlock_at)
      expect(attributes[:lock_at]).to eq(custom_lock_at)
    end
  end

  describe "#inherited_attributes" do
    it "includes all expected attributes from parent assignment" do
      inherited = service.send(:inherited_attributes)

      expected_keys = %i[
        assignment_group_id
        context_id
        context_type
        description
        peer_review_count
        peer_reviews
        peer_reviews_due_at
        peer_reviews_assigned
        anonymous_peer_reviews
        automatic_peer_reviews
        intra_group_peer_reviews
        workflow_state
        group_category_id
      ]

      expect(inherited.keys).to match_array(expected_keys)
    end
  end

  describe "#specific_attributes" do
    context "with all custom parameters" do
      it "returns specific attributes with custom values" do
        specific = service.send(:specific_attributes)

        expect(specific[:has_sub_assignments]).to be(false)
        expect(specific[:title]).to eq("#{parent_assignment.title} Peer Review")
        expect(specific[:submission_types]).to eq("online_text_entry")
        expect(specific[:parent_assignment_id]).to eq(parent_assignment.id)
        expect(specific[:points_possible]).to eq(peer_review_points_possible)
        expect(specific[:grading_type]).to eq(peer_review_grading_type)
        expect(specific[:due_at]).to eq(custom_due_at)
        expect(specific[:unlock_at]).to eq(custom_unlock_at)
        expect(specific[:lock_at]).to eq(custom_lock_at)
      end
    end

    context "with minimal parameters" do
      let(:minimal_service) { described_class.new(parent_assignment:) }

      it "returns specific attributes without optional values" do
        specific = minimal_service.send(:specific_attributes)

        expect(specific[:has_sub_assignments]).to be(false)
        expect(specific[:title]).to eq("#{parent_assignment.title} Peer Review")
        expect(specific[:submission_types]).to eq("online_text_entry")
        expect(specific[:parent_assignment_id]).to eq(parent_assignment.id)
        expect(specific).not_to have_key(:points_possible)
        expect(specific).not_to have_key(:grading_type)
        expect(specific).not_to have_key(:due_at)
        expect(specific).not_to have_key(:unlock_at)
        expect(specific).not_to have_key(:lock_at)
      end
    end

    it "creates peer review title from parent assignment title appended with Peer Review" do
      expected_title = I18n.t("%{title} Peer Review", title: parent_assignment.title)
      attributes = service.send(:specific_attributes)
      expect(attributes[:title]).to eq(expected_title)
    end

    context "submission types based on grading type" do
      it "sets submission_types to 'not_graded' when grading_type is 'not_graded'" do
        service_not_graded = described_class.new(
          parent_assignment:,
          grading_type: "not_graded"
        )
        attributes = service_not_graded.send(:specific_attributes)

        expect(attributes[:submission_types]).to eq("not_graded")
      end

      it "sets submission_types to 'online_text_entry' when grading_type is 'points'" do
        service_points = described_class.new(
          parent_assignment:,
          grading_type: "points"
        )
        attributes = service_points.send(:specific_attributes)

        expect(attributes[:submission_types]).to eq("online_text_entry")
      end

      it "sets submission_types to 'online_text_entry' when grading_type is 'pass_fail'" do
        service_pass_fail = described_class.new(
          parent_assignment:,
          grading_type: "pass_fail"
        )
        attributes = service_pass_fail.send(:specific_attributes)

        expect(attributes[:submission_types]).to eq("online_text_entry")
      end

      it "sets submission_types to 'online_text_entry' when grading_type is 'percent'" do
        service_percent = described_class.new(
          parent_assignment:,
          grading_type: "percent"
        )
        attributes = service_percent.send(:specific_attributes)

        expect(attributes[:submission_types]).to eq("online_text_entry")
      end

      it "sets submission_types to 'online_text_entry' when grading_type is 'letter_grade'" do
        service_letter = described_class.new(
          parent_assignment:,
          grading_type: "letter_grade"
        )
        attributes = service_letter.send(:specific_attributes)

        expect(attributes[:submission_types]).to eq("online_text_entry")
      end

      it "sets submission_types to 'online_text_entry' when grading_type is 'gpa_scale'" do
        service_gpa = described_class.new(
          parent_assignment:,
          grading_type: "gpa_scale"
        )
        attributes = service_gpa.send(:specific_attributes)

        expect(attributes[:submission_types]).to eq("online_text_entry")
      end

      it "defaults to 'online_text_entry' when no grading_type is specified" do
        service_default = described_class.new(parent_assignment:)
        attributes = service_default.send(:specific_attributes)

        expect(attributes[:submission_types]).to eq("online_text_entry")
      end
    end
  end

  describe "#attributes_to_inherit_from_parent" do
    it "returns the expected array of attribute names" do
      expected_attributes = %w[
        anonymous_peer_reviews
        assignment_group_id
        automatic_peer_reviews
        context_id
        context_type
        description
        group_category_id
        intra_group_peer_reviews
        peer_review_count
        peer_reviews
        peer_reviews_assigned
        peer_reviews_due_at
        workflow_state
      ]

      expect(service.send(:attributes_to_inherit_from_parent)).to eq(expected_attributes)
    end
  end

  describe "integration with ApplicationService" do
    it "inherits from ApplicationService" do
      expect(described_class.superclass).to eq(ApplicationService)
    end

    it "responds to the call class method" do
      expect(described_class).to respond_to(:call)
    end
  end

  describe "#peer_review_attributes_to_update" do
    let!(:peer_review_sub_assignment) do
      PeerReviewSubAssignment.create!(
        parent_assignment:,
        context: course,
        title: "Test Peer Review",
        points_possible: 5,
        grading_type: "pass_fail",
        due_at: 5.days.from_now,
        unlock_at: 3.days.from_now,
        lock_at: 3.weeks.from_now
      )
    end

    context "when peer review specific attributes have changed" do
      let(:new_points_possible) { 15 }
      let(:new_grading_type) { "points" }
      let(:new_due_at) { 1.day.from_now }
      let(:new_unlock_at) { Time.zone.now }
      let(:new_lock_at) { 4.weeks.from_now }

      let(:service) do
        described_class.new(
          parent_assignment:,
          points_possible: new_points_possible,
          grading_type: new_grading_type,
          due_at: new_due_at,
          unlock_at: new_unlock_at,
          lock_at: new_lock_at
        )
      end

      it "includes all changed peer review specific attributes" do
        attributes = service.send(:peer_review_attributes_to_update)

        expect(attributes[:points_possible]).to eq(new_points_possible)
        expect(attributes[:grading_type]).to eq(new_grading_type)
        expect(attributes[:due_at]).to eq(new_due_at)
        expect(attributes[:unlock_at]).to eq(new_unlock_at)
        expect(attributes[:lock_at]).to eq(new_lock_at)
      end

      it "does not include peer review attributes that match existing values" do
        service_with_same_points = described_class.new(
          parent_assignment:,
          points_possible: peer_review_sub_assignment.points_possible,
          grading_type: new_grading_type,
          due_at: new_due_at
        )

        attributes = service_with_same_points.send(:peer_review_attributes_to_update)

        expect(attributes).not_to have_key(:points_possible)
        expect(attributes[:grading_type]).to eq(new_grading_type)
        expect(attributes[:due_at]).to eq(new_due_at)
      end
    end

    context "when inherited attributes have changed on parent" do
      before do
        parent_assignment.update!(
          description: "Updated description",
          peer_review_count: 3
        )
      end

      it "includes inherited attributes that differ from the peer review sub assignment" do
        attributes = service.send(:peer_review_attributes_to_update)

        expect(attributes[:description]).to eq("Updated description")
        expect(attributes[:peer_review_count]).to eq(3)
      end
    end

    context "when both inherited and specific attributes have changed" do
      before do
        parent_assignment.update!(
          description: "New description",
          peer_review_count: 5
        )
      end

      let(:service) do
        described_class.new(
          parent_assignment:,
          points_possible: 20,
          grading_type: "points",
          due_at: 2.days.from_now
        )
      end

      it "includes both inherited and specific changed attributes" do
        attributes = service.send(:peer_review_attributes_to_update)

        expect(attributes[:description]).to eq("New description")
        expect(attributes[:peer_review_count]).to eq(5)
        expect(attributes[:points_possible]).to eq(20)
        expect(attributes[:grading_type]).to eq("points")
        expect(attributes[:due_at]).to be_within(1.second).of(2.days.from_now)
      end
    end

    context "handling of title changes" do
      context "when peer review sub assignment title differs from expected title" do
        before do
          peer_review_sub_assignment.update!(title: "Old Incorrect Title")
        end

        it "includes the correct title in the attributes to update" do
          attributes = service.send(:peer_review_attributes_to_update)
          expect(attributes[:title]).to eq("Parent Assignment Peer Review")
        end
      end

      context "when peer review sub assignment title matches expected title" do
        before do
          expected_title = I18n.t("%{title} Peer Review", title: parent_assignment.title)
          peer_review_sub_assignment.update!(title: expected_title)
        end

        it "does not include title in the attributes to update" do
          attributes = service.send(:peer_review_attributes_to_update)

          expect(attributes).not_to have_key(:title)
        end
      end

      context "when parent assignment title changes" do
        before do
          initial_title = I18n.t("%{title} Peer Review", title: parent_assignment.title)
          peer_review_sub_assignment.update!(title: initial_title)
          parent_assignment.update!(title: "Updated Parent Assignment")
        end

        it "includes the updated title based on new parent title" do
          attributes = service.send(:peer_review_attributes_to_update)
          expect(attributes[:title]).to eq("Updated Parent Assignment Peer Review")
        end
      end
    end

    context "handling of submission_types changes" do
      context "when peer review sub assignment submission_types differs from expected value" do
        before do
          peer_review_sub_assignment.update!(submission_types: "none")
        end

        it "includes submission_types set to online_text_entry in the attributes to update" do
          attributes = service.send(:peer_review_attributes_to_update)
          expect(attributes[:submission_types]).to eq("online_text_entry")
        end
      end

      context "when peer review sub assignment submission_types already matches expected value" do
        before do
          peer_review_sub_assignment.update!(submission_types: "online_text_entry")
        end

        it "does not include submission_types in the attributes to update" do
          attributes = service.send(:peer_review_attributes_to_update)
          expect(attributes).not_to have_key(:submission_types)
        end
      end

      context "when grading_type changes to 'not_graded'" do
        let(:service) do
          described_class.new(
            parent_assignment:,
            grading_type: "not_graded"
          )
        end

        before do
          peer_review_sub_assignment.update!(submission_types: "online_text_entry")
        end

        it "includes submission_types set to 'not_graded' in the attributes to update" do
          attributes = service.send(:peer_review_attributes_to_update)
          expect(attributes[:submission_types]).to eq("not_graded")
        end
      end

      context "when grading_type changes from 'not_graded' to graded type" do
        let(:service) do
          described_class.new(
            parent_assignment:,
            grading_type: "points"
          )
        end

        before do
          peer_review_sub_assignment.update!(submission_types: "not_graded")
        end

        it "includes submission_types set to 'online_text_entry' in the attributes to update" do
          attributes = service.send(:peer_review_attributes_to_update)
          expect(attributes[:submission_types]).to eq("online_text_entry")
        end
      end

      context "when grading_type stays the same" do
        let(:service) do
          described_class.new(
            parent_assignment:,
            grading_type: "points"
          )
        end

        before do
          peer_review_sub_assignment.update!(submission_types: "online_text_entry")
        end

        it "does not include submission_types in the attributes to update" do
          attributes = service.send(:peer_review_attributes_to_update)
          expect(attributes).not_to have_key(:submission_types)
        end
      end
    end
  end

  describe "#compute_due_dates_and_create_submissions" do
    let(:peer_review_sub_assignment) do
      PeerReviewSubAssignment.create!(
        parent_assignment:,
        context: course,
        title: "Test Peer Review"
      )
    end

    before do
      allow(PeerReviewSubAssignment).to receive(:clear_cache_keys)
      allow(SubmissionLifecycleManager).to receive(:recompute)
    end

    it "clears cache keys for the peer review sub assignment" do
      expect(PeerReviewSubAssignment).to receive(:clear_cache_keys)
        .with(peer_review_sub_assignment, :availability)

      service.send(:compute_due_dates_and_create_submissions, peer_review_sub_assignment)
    end

    it "calls SubmissionLifecycleManager.recompute with correct parameters" do
      expect(SubmissionLifecycleManager).to receive(:recompute)
        .with(peer_review_sub_assignment, update_grades: true, create_sub_assignment_submissions: false)

      service.send(:compute_due_dates_and_create_submissions, peer_review_sub_assignment)
    end

    it "handles the method being called with a nil peer review sub assignment" do
      expect(PeerReviewSubAssignment).to receive(:clear_cache_keys)
        .with(nil, :availability)
      expect(SubmissionLifecycleManager).to receive(:recompute)
        .with(nil, update_grades: true, create_sub_assignment_submissions: false)

      expect { service.send(:compute_due_dates_and_create_submissions, nil) }.not_to raise_error
    end
  end
end
