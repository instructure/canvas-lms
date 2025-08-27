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

require "spec_helper"

RSpec.describe PeerReviewSubAssignment do
  describe "associations" do
    it "belongs to a parent assignment" do
      association = PeerReviewSubAssignment.reflect_on_association(:parent_assignment)
      expect(association.macro).to eq :belongs_to
      expect(association.class_name).to eq "Assignment"
      expect(association.inverse_of.name).to eq :peer_review_sub_assignment
    end

    it "has many assessment_requests" do
      association = PeerReviewSubAssignment.reflect_on_association(:assessment_requests)
      expect(association.macro).to eq :has_many
    end
  end

  describe "validations" do
    let(:course) { course_model(name: "Course with Assignment") }
    let(:parent_assignment) { assignment_model(course:, title: "Parent Assignment") }

    it "is not valid without a parent_assignment_id" do
      peer_review_sub_assignment = PeerReviewSubAssignment.new(context: course)
      expect(peer_review_sub_assignment).not_to be_valid
      expect(peer_review_sub_assignment.errors[:parent_assignment_id]).to include("can't be blank")
    end

    describe "parent_assignment_id uniqueness" do
      it "is not valid with a duplicate parent_assignment_id" do
        PeerReviewSubAssignment.create!(parent_assignment:, context: course)
        duplicate_peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, context: course)
        expect(duplicate_peer_review_sub_assignment).not_to be_valid
        expect(duplicate_peer_review_sub_assignment.errors[:parent_assignment_id]).to include("has already been taken")
      end

      it "allows duplicate parent_assignment_id for deleted records" do
        first = PeerReviewSubAssignment.create!(parent_assignment:, context: course)
        first.destroy
        duplicate_peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, context: course)
        expect(duplicate_peer_review_sub_assignment).to be_valid
      end
    end

    it "is not valid if has_sub_assignments is true" do
      peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, context: course, has_sub_assignments: true)
      expect(peer_review_sub_assignment).not_to be_valid
      expect(peer_review_sub_assignment.errors[:has_sub_assignments]).to include(I18n.t("cannot have sub assignments"))
    end

    it "is not valid with a sub_assignment_tag" do
      peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, context: course, sub_assignment_tag: "some_tag")
      expect(peer_review_sub_assignment).not_to be_valid
      expect(peer_review_sub_assignment.errors[:sub_assignment_tag]).to include(I18n.t("cannot have sub assignment tag"))
    end

    describe "#context_matches_parent_assignment" do
      let(:other_course) { Course.create! }

      it "is valid when context matches parent assignment context" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, context: course)
        expect(peer_review_sub_assignment).to be_valid
      end

      it "is invalid when context does not match parent assignment context" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, context: other_course)
        expect(peer_review_sub_assignment).not_to be_valid
        expect(peer_review_sub_assignment.errors[:context]).to include("must match parent assignment context")
      end
    end
  end

  describe "#checkpoint?" do
    it "returns false" do
      expect(subject.checkpoint?).to be(false)
    end
  end

  describe "#checkpoints_parent?" do
    it "returns false" do
      expect(subject.checkpoints_parent?).to be(false)
    end
  end

  describe "#governs_submittable?" do
    it "returns false" do
      expect(subject.governs_submittable?).to be(false)
    end
  end
end
