# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe OutcomeResultResolverHelper do
  include OutcomesServiceAuthoritativeResultsHelper

  let(:time) { Time.zone.now }

  before(:once) do
    names = %w[Keroppi HelloKitty BadtzMaru]

    course_factory
    course_with_teacher(course: @course)

    @students = create_users(names.map { |name| { name: "User #{name}", sortable_name: "#{name}, User" } }, return_type: :record)

    @students.each do |s|
      course_with_user("StudentEnrollment", course: @course, user: s)
    end
  end

  describe "removes the alignment result" do
    it "if there is a rubric result for that student, assignment, and outcome" do
      assignments = []
      outcome = create_outcome
      assignments.push(create_alignment)
      lor = create_learning_outcome_result @students[0], 1.0

      # We cannot have two LORs for the same student, assignment, and outcome in the db
      lor.workflow_state = "deleted"
      lor.save!

      assignments.push(create_alignment_with_rubric({ assignment: @assignment }))
      create_learning_outcome_result_from_rubric @students[0], 1.0

      expect(resolve_outcome_results(authoritative_results_from_db, @course, [outcome], [@students[0]], assignments).size).to eq 0
    end

    it "if a rubric result exists for multiple students for the same assignment and outcome" do
      assignments = []
      outcome = create_outcome
      assignments.push(create_alignment)
      lor1 = create_learning_outcome_result @students[0], 1.0
      lor2 = create_learning_outcome_result @students[1], 1.0

      # We cannot have two LORs for the same student, assignment, and outcome in the db
      lor1.workflow_state = "deleted"
      lor1.save!
      lor2.workflow_state = "deleted"
      lor2.save!

      assignments.push(create_alignment_with_rubric({ assignment: @assignment }))
      create_learning_outcome_result_from_rubric @students[0], 1.0
      create_learning_outcome_result_from_rubric @students[1], 1.0

      expect(resolve_outcome_results(authoritative_results_from_db, @course, [outcome], [@students[0], @students[1]], assignments).size).to eq 0
    end

    it "for just one student if a rubric result exists for their assignment and outcome" do
      assignments = []
      outcome = create_outcome
      assignments.push(create_alignment)
      lor = create_learning_outcome_result @students[0], 1.0
      create_learning_outcome_result @students[1], 1.0

      # We cannot have two LORs for the same student, assignment, and outcome in the db
      lor.workflow_state = "deleted"
      lor.save!

      assignments.push(create_alignment_with_rubric({ assignment: @assignment }))
      create_learning_outcome_result_from_rubric @students[0], 1.0

      expect(resolve_outcome_results(authoritative_results_from_db, @course, [outcome], [@students[0], @students[1]], assignments).size).to eq 1
    end

    it "for an assignment with multiple outcomes aligned, where one outcome has a rubric result for a student" do
      assignments = []
      outcomes = []
      outcomes.push(create_outcome)
      assignments.push(create_alignment)
      create_learning_outcome_result @students[0], 1.0

      outcomes.push(create_outcome)
      assignments.push(create_alignment)
      lor = create_learning_outcome_result @students[0], 1.0

      # We cannot have two LORs for the same student, assignment, and outcome in the db
      lor.workflow_state = "deleted"
      lor.save!

      assignments.push(create_alignment_with_rubric({ assignment: @assignment }))
      create_learning_outcome_result_from_rubric @students[0], 1.0

      expect(resolve_outcome_results(authoritative_results_from_db, @course, outcomes, [@students[0]], assignments).size).to eq 1
    end
  end

  describe "doesn't remove the alignment result" do
    it "if there is no rubric result for that student, assignment, and outcome" do
      outcome = create_outcome
      create_alignment
      create_learning_outcome_result @students[0], 1.0

      expect(resolve_outcome_results(authoritative_results_from_db, @course, [outcome], [@students[0]], [@assignment]).size).to eq 1
    end

    it "if there is no rubric result for that student" do
      assignments = []
      outcome = create_outcome
      assignments.push(create_alignment)
      create_learning_outcome_result @students[0], 1.0

      assignments.push(create_alignment_with_rubric({ assignment: @assignment }))
      create_learning_outcome_result_from_rubric @students[1], 1.0

      expect(resolve_outcome_results(authoritative_results_from_db, @course, [outcome], [@students[0], @students[1]], assignments).size).to eq 1
    end

    it "if there is no rubric result for that assignment" do
      assignments = []
      outcome = create_outcome
      assignments.push(create_alignment)
      create_learning_outcome_result @students[2], 1.0

      assignments.push(create_alignment_with_rubric)
      create_learning_outcome_result_from_rubric @students[2], 1.0

      expect(resolve_outcome_results(authoritative_results_from_db, @course, [outcome], [@students[2]], assignments).size).to eq 1
    end

    it "if there is no rubric result for that outcome" do
      assignments = []
      outcomes = []
      outcomes.push(create_outcome)
      assignments.push(create_alignment)
      create_learning_outcome_result @students[0], 1.0

      outcomes.push(create_outcome)
      assignments.push(create_alignment_with_rubric)
      create_learning_outcome_result_from_rubric @students[0], 1.0

      expect(resolve_outcome_results(authoritative_results_from_db, @course, outcomes, [@students[0]], assignments).size).to eq 1
    end
  end
end
