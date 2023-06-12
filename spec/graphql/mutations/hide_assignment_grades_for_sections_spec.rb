# frozen_string_literal: true

#
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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::HideAssignmentGradesForSections do
  let(:assignment) { course.assignments.create! }
  let(:course) { Course.create!(workflow_state: "available") }
  let(:section1) { course.course_sections.create! }
  let(:section2) { course.course_sections.create! }
  let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

  def mutation_str(assignment_id: nil, section_ids: nil)
    input_string = assignment_id ? "assignmentId: #{assignment_id}" : ""
    input_string += " sectionIds: #{section_ids}" unless section_ids.nil?

    <<~GQL
      mutation {
        hideAssignmentGradesForSections(input: {
          #{input_string}
        }) {
          assignment {
            _id
          }
          progress {
            _id
          }
          sections {
            _id
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def execute_query(mutation_str, context)
    CanvasSchema.execute(mutation_str, context:)
  end

  before do
    @section1_student = section1.enroll_user(User.create!, "StudentEnrollment", "active").user
    @section2_student = section2.enroll_user(User.create!, "StudentEnrollment", "active").user
  end

  context "when user has grade permission" do
    let(:context) { { current_user: teacher } }

    it "requires that assignmentId be passed in the query" do
      result = execute_query(mutation_str(section_ids: [section1.id]), context)
      expected_error = "'assignmentId' on InputObject 'HideAssignmentGradesForSectionsInput' is required"
      expect(result.dig("errors", 0, "message")).to include expected_error
    end

    it "requires that sectionIds be passed in the query" do
      result = execute_query(mutation_str(assignment_id: assignment.id), context)
      expected_error = "'sectionIds' on InputObject 'HideAssignmentGradesForSectionsInput' is required"
      expect(result.dig("errors", 0, "message")).to include expected_error
    end

    it "returns an error when the assignment does not exist" do
      bad_id = (Assignment.last&.id || 0) + 1
      result = execute_query(mutation_str(assignment_id: bad_id, section_ids: [section1.id]), context)
      expect(result.dig("errors", 0, "message")).to eql "not found"
    end

    it "returns an error when not passed any section ids" do
      result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: []), context)
      expected_error = "Invalid section ids"
      expect(result.dig("errors", 0, "message")).to eql expected_error
    end

    it "returns an error when a section is not part of the course" do
      unrelated_section = Course.create!.course_sections.create!
      section_ids = [unrelated_section.id, section1.id]
      result = execute_query(mutation_str(assignment_id: assignment.id, section_ids:), context)
      expected_error = "Invalid section ids"
      expect(result.dig("errors", 0, "message")).to eql expected_error
    end

    it "does not allow hiding by section for anonymous assignments" do
      assignment.update!(anonymous_grading: true)
      result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section1.id]), context)
      expected_error = "Anonymous assignments cannot be hidden by section"
      expect(result.dig("errors", 0, "message")).to eql expected_error
    end

    it "allows hiding by section for assignments that are no longer anonymized" do
      assignment.update!(anonymous_grading: true)
      assignment.post_submissions
      result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section1.id]), context)
      expect(result["errors"]).to be_nil
    end

    it "does not allow hiding by section for moderated assignments that have not had grades published yet" do
      assignment.update!(moderated_grading: true, grader_count: 2, final_grader: teacher)
      result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section1.id]), context)
      expected_error = "Assignments under moderation cannot be hidden by section before grades are published"
      expect(result.dig("errors", 0, "message")).to eql expected_error
    end

    it "allows hiding by section for moderated assignments that have had grades published" do
      now = Time.zone.now
      assignment.update!(moderated_grading: true, grader_count: 2, final_grader: teacher, grades_published_at: now)
      result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section1.id]), context)
      expect(result["errors"]).to be_nil
    end

    describe "hiding the grades" do
      let(:hide_submissions_job) { Delayed::Job.where(tag: "Assignment#hide_submissions").order(:id).last }
      let(:section1_student_submission) { assignment.submissions.find_by(user: @section1_student) }
      let(:section2_student_submission) { assignment.submissions.find_by(user: @section2_student) }

      before do
        now = Time.zone.now
        section1_student_submission.update!(posted_at: now)
        section2_student_submission.update!(posted_at: now)
      end

      it "hides the assignment grades for the specified section" do
        execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section2.id]), context)
        hide_submissions_job.invoke_job
        expect(section2_student_submission.reload).not_to be_posted
      end

      it "returns the assignment" do
        result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section2.id]), context)
        expect(result.dig("data", "hideAssignmentGradesForSections", "assignment", "_id").to_i).to be assignment.id
      end

      it "returns the progress" do
        result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section2.id]), context)
        progress = Progress.find(result.dig("data", "hideAssignmentGradesForSections", "progress", "_id"))
        expect(result.dig("data", "hideAssignmentGradesForSections", "progress", "_id").to_i).to be progress.id
      end

      it "stores the assignment id of submissions hidden on the Progress object" do
        result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section1.id]), context)
        hide_submissions_job.invoke_job
        progress = Progress.find(result.dig("data", "hideAssignmentGradesForSections", "progress", "_id"))
        expect(progress.results[:assignment_id]).to eq assignment.id
      end

      it "stores the posted_at of submissions hidden on the Progress object" do
        result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section1.id]), context)
        hide_submissions_job.invoke_job
        progress = Progress.find(result.dig("data", "hideAssignmentGradesForSections", "progress", "_id"))
        expect(progress.results[:posted_at]).to eq section1_student_submission.reload.posted_at
      end

      it "stores the user ids of submissions hidden on the Progress object" do
        result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section1.id]), context)
        hide_submissions_job.invoke_job
        progress = Progress.find(result.dig("data", "hideAssignmentGradesForSections", "progress", "_id"))
        expect(progress.results[:user_ids]).to match_array [@section1_student.id]
      end

      it "returns the sections" do
        result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section2.id]), context)
        sections = result.dig("data", "hideAssignmentGradesForSections", "sections")
        section_ids = sections.map { |section| section["_id"].to_i }
        expect(section_ids).to contain_exactly(section2.id)
      end

      it "does not hide the assignment grades for the sections not specified" do
        execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section2.id]), context)
        expect(section1_student_submission).to be_posted
      end

      context "when the hider has limited visibility" do
        let(:ta) { User.create! }

        before do
          course.enroll_ta(ta, enrollment_state: "active", section: section1, limit_privileges_to_course_section: true)
        end

        it "does not hide grades for the requested sections if the user cannot see them" do
          execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section1.id, section2.id]), { current_user: ta })
          hide_submissions_job.invoke_job
          expect(assignment.submission_for_student(@section2_student).posted_at).not_to be_nil
        end

        it "stores only the user ids of affected students on the Progress object" do
          result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section1.id, section2.id]), { current_user: ta })
          hide_submissions_job.invoke_job
          progress = Progress.find(result.dig("data", "hideAssignmentGradesForSections", "progress", "_id"))
          expect(progress.results[:user_ids]).to match_array [@section1_student.id]
        end
      end
    end
  end

  context "when user does not have grade permission" do
    let(:context) { { current_user: @section1_student } }

    it "returns an error" do
      result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section2.id]), context)
      expect(result.dig("errors", 0, "message")).to eql "not found"
    end

    it "does not return data for the related submissions" do
      result = execute_query(mutation_str(assignment_id: assignment.id, section_ids: [section2.id]), context)
      expect(result.dig("data", "hideAssignmentGradesForSections")).to be_nil
    end
  end
end
