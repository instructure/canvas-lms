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

require_relative "../../spec_helper"

describe Assignments::GraderIdentities do
  before :once do
    course_with_teacher(active_all: true)
  end

  # Test direct module methods
  describe ".anonymize_grader_identity" do
    it "returns an anonymized grader identity with the correct structure" do
      grader = { name: "John Doe", anonymous_id: "abc123", position: 2, user_id: 42 }
      anonymized = Assignments::GraderIdentities.anonymize_grader_identity(grader)

      expect(anonymized).to match({
                                    name: "Grader 2",
                                    anonymous_id: "abc123",
                                    position: 2
                                  })
      expect(anonymized).not_to have_key(:user_id)
    end
  end

  # Test instance methods through Assignment model
  describe "#grader_identities" do
    let(:teacher1) { @teacher }
    let(:teacher2) { User.create!(name: "Another Teacher") }
    let(:assignment) do
      assignment = @course.assignments.create!(
        title: "Moderated Assignment",
        moderated_grading: true,
        grader_count: 2
      )
      assignment.update_attribute(:grader_count, 2)
      assignment
    end

    before do
      assignment.moderation_graders.create!(user: teacher1, anonymous_id: "anon1")
      assignment.moderation_graders.create!(user: teacher2, anonymous_id: "anon2")
    end

    it "returns an empty array when moderated_grading? is false" do
      assignment.update_attribute(:moderated_grading, false)
      expect(assignment.grader_identities).to eq []
    end

    it "returns grader identities with names" do
      identities = assignment.grader_identities

      expect(identities.length).to eq 2

      expect(identities[0]).to match({
                                       name: teacher1.name,
                                       user_id: teacher1.id,
                                       anonymous_id: "anon1",
                                       position: 1
                                     })

      expect(identities[1]).to match({
                                       name: teacher2.name,
                                       user_id: teacher2.id,
                                       anonymous_id: "anon2",
                                       position: 2
                                     })
    end

    context "with filtering and ordering" do
      let(:assignment_with_slots) do
        assignment = @course.assignments.create!(
          title: "Assignment with slots",
          moderated_grading: true,
          grader_count: 2,
          final_grader: @teacher
        )
        assignment
      end

      it "includes users that have taken a grader slot" do
        assignment_with_slots.moderation_graders.create!(user: teacher1, anonymous_id: "anon1", slot_taken: true)
        identities = assignment_with_slots.grader_identities

        expect(identities.length).to eq 1
        expect(identities[0][:user_id]).to eq teacher1.id
      end

      it "assigns positions based on the ordered anonymous IDs" do
        assignment_with_slots.moderation_graders.create!(user: teacher1, anonymous_id: "bbbbb", slot_taken: true)
        assignment_with_slots.moderation_graders.create!(user: teacher2, anonymous_id: "aaaaa", slot_taken: true)

        identities = assignment_with_slots.grader_identities

        # Teacher2 has "aaaaa" which should come first alphabetically
        expect(identities[0][:user_id]).to eq teacher2.id
        expect(identities[0][:position]).to eq 1

        # Teacher1 has "bbbbb" which should come second alphabetically
        expect(identities[1][:user_id]).to eq teacher1.id
        expect(identities[1][:position]).to eq 2
      end

      it "excludes users that have not taken a grader slot" do
        assignment_with_slots.moderation_graders.create!(user: teacher1, anonymous_id: "anon1", slot_taken: false)
        identities = assignment_with_slots.grader_identities

        expect(identities).to be_empty
      end

      it "excludes users that do not have a moderation grader record for the assignment" do
        teacher3 = User.create!(name: "Third Teacher")
        @course.enroll_teacher(teacher3, enrollment_state: :active)

        identities = assignment_with_slots.grader_identities
        user_ids = identities.pluck(:user_id)

        expect(user_ids).not_to include(teacher3.id)
      end
    end
  end

  describe "#anonymous_grader_identities_by_user_id" do
    let(:teacher1) { @teacher }
    let(:teacher2) { User.create!(name: "Another Teacher") }
    let(:assignment) do
      assignment = @course.assignments.create!(
        title: "Moderated Assignment",
        moderated_grading: true,
        grader_count: 2
      )
      assignment.moderation_graders.create!(user: teacher1, anonymous_id: "anon1")
      assignment.moderation_graders.create!(user: teacher2, anonymous_id: "anon2")
      assignment
    end

    it "returns a hash indexed by user_id" do
      identities = assignment.anonymous_grader_identities_by_user_id

      expect(identities).to match({
                                    teacher1.id => { id: "anon1", name: "Grader 1" },
                                    teacher2.id => { id: "anon2", name: "Grader 2" }
                                  })
    end

    it "memoizes the result" do
      # Call once to establish memoization
      first_call = assignment.anonymous_grader_identities_by_user_id

      # Change the underlying data
      assignment.moderation_graders.first.update!(anonymous_id: "anon3")

      # Result should be memoized and not reflect the change
      second_call = assignment.anonymous_grader_identities_by_user_id
      expect(second_call).to eq first_call
      expect(second_call[teacher1.id][:id]).to eq "anon1"
    end
  end

  describe "#anonymous_grader_identities_by_anonymous_id" do
    let(:teacher1) { @teacher }
    let(:teacher2) { User.create!(name: "Another Teacher") }
    let(:assignment) do
      assignment = @course.assignments.create!(
        title: "Moderated Assignment",
        moderated_grading: true,
        grader_count: 2
      )
      assignment.moderation_graders.create!(user: teacher1, anonymous_id: "anon1")
      assignment.moderation_graders.create!(user: teacher2, anonymous_id: "anon2")
      assignment
    end

    it "returns a hash indexed by anonymous_id" do
      identities = assignment.anonymous_grader_identities_by_anonymous_id

      expect(identities).to match({
                                    "anon1" => { id: "anon1", name: "Grader 1" },
                                    "anon2" => { id: "anon2", name: "Grader 2" }
                                  })
    end

    it "memoizes the result" do
      # Call once to establish memoization
      first_call = assignment.anonymous_grader_identities_by_anonymous_id

      # Change the underlying data by removing a moderation grader
      assignment.moderation_graders.first.destroy

      # Result should be memoized and not reflect the change
      second_call = assignment.anonymous_grader_identities_by_anonymous_id
      expect(second_call).to eq first_call
      expect(second_call.keys).to include "anon1"
    end
  end

  describe "#anonymous_grader_identities_by" do
    let(:teacher) { @teacher }
    let(:assignment) do
      assignment = @course.assignments.create!(
        title: "Moderated Assignment",
        moderated_grading: true,
        grader_count: 1
      )
      assignment.moderation_graders.create!(user: teacher, anonymous_id: "anon1")
      assignment
    end

    it "raises an ArgumentError if index_by is not :user_id or :anonymous_id" do
      expect { assignment.anonymous_grader_identities_by(index_by: :invalid) }
        .to raise_error(ArgumentError, "index_by must be either :user_id or :anonymous_id")
    end
  end

  # Test class methods
  describe ".build_grader_identities" do
    let(:teacher1) { @teacher }
    let(:teacher2) { User.create!(name: "Another Teacher") }
    let(:assignment) do
      assignment = @course.assignments.create!(
        title: "Moderated Assignment",
        moderated_grading: true,
        grader_count: 2
      )
      assignment
    end

    let(:moderation_grader1) { assignment.moderation_graders.create!(user: teacher1, anonymous_id: "anon1") }
    let(:moderation_grader2) { assignment.moderation_graders.create!(user: teacher2, anonymous_id: "anon2") }
    let(:graders) { [moderation_grader1, moderation_grader2] }

    it "builds grader identities with names when anonymize is false" do
      identities = Assignment.build_grader_identities(graders)

      expect(identities.length).to eq 2

      expect(identities[0]).to match({
                                       name: teacher1.name,
                                       user_id: teacher1.id,
                                       anonymous_id: "anon1",
                                       position: 1
                                     })

      expect(identities[1]).to match({
                                       name: teacher2.name,
                                       user_id: teacher2.id,
                                       anonymous_id: "anon2",
                                       position: 2
                                     })
    end

    it "builds anonymized grader identities when anonymize is true" do
      identities = Assignment.build_grader_identities(graders, anonymize: true)

      expect(identities.length).to eq 2

      expect(identities[0]).to match({
                                       name: "Grader 1",
                                       anonymous_id: "anon1",
                                       position: 1
                                     })
      expect(identities[0]).not_to have_key(:user_id)

      expect(identities[1]).to match({
                                       name: "Grader 2",
                                       anonymous_id: "anon2",
                                       position: 2
                                     })
      expect(identities[1]).not_to have_key(:user_id)
    end
  end
end
