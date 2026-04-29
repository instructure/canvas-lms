# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

RSpec.describe Loaders::AssignmentNeedsGradingCountLoader do
  before :once do
    course_with_teacher(active_all: true)
    @student1 = course_with_user("StudentEnrollment", course: @course, active_all: true).user
    @student2 = course_with_user("StudentEnrollment", course: @course, active_all: true).user

    @a1 = @course.assignments.create!(title: "Assignment 1", submission_types: ["online_text_entry"])
    @a2 = @course.assignments.create!(title: "Assignment 2", submission_types: ["online_text_entry"])
    @a3 = @course.assignments.create!(title: "Assignment 3", submission_types: ["online_text_entry"])
  end

  def loader_for(user)
    Loaders::AssignmentNeedsGradingCountLoader.for(user)
  end

  describe "#perform" do
    it "returns 0 when no submissions need grading" do
      GraphQL::Batch.batch do
        loader_for(@teacher).load(@a1).then do |count|
          expect(count).to eq(0)
        end
      end
    end

    it "returns the correct count for a single assignment with ungraded submissions" do
      @a1.submit_homework(@student1, submission_type: "online_text_entry", body: "hi")
      @a1.submit_homework(@student2, submission_type: "online_text_entry", body: "hello")

      GraphQL::Batch.batch do
        loader_for(@teacher).load(@a1).then do |count|
          expect(count).to eq(2)
        end
      end
    end

    it "decrements count after a submission is graded" do
      @a1.submit_homework(@student1, submission_type: "online_text_entry", body: "hi")
      @a1.submit_homework(@student2, submission_type: "online_text_entry", body: "hello")
      @a1.grade_student(@student1, grade: "10", grader: @teacher)

      GraphQL::Batch.batch do
        loader_for(@teacher).load(@a1).then do |count|
          expect(count).to eq(1)
        end
      end
    end

    it "returns correct counts for multiple assignments in one batch" do
      @a1.submit_homework(@student1, submission_type: "online_text_entry", body: "a1 s1")
      @a1.submit_homework(@student2, submission_type: "online_text_entry", body: "a1 s2")
      @a2.submit_homework(@student1, submission_type: "online_text_entry", body: "a2 s1")

      GraphQL::Batch.batch do
        p1 = loader_for(@teacher).load(@a1)
        p2 = loader_for(@teacher).load(@a2)
        p3 = loader_for(@teacher).load(@a3)

        Promise.all([p1, p2, p3]).then do |counts|
          expect(counts[0]).to eq(2) # a1: 2 submissions
          expect(counts[1]).to eq(1) # a2: 1 submission
          expect(counts[2]).to eq(0) # a3: no submissions
        end
      end
    end

    it "delegates all assignments to a single NeedsGradingCountQuery call" do
      query_double = instance_double(Assignments::NeedsGradingCountQuery, count: {})
      allow(query_double).to receive(:count).and_return(
        @a1.global_id => 0,
        @a2.global_id => 0
      )

      expect(Assignments::NeedsGradingCountQuery)
        .to receive(:new)
        .once
        .with(contain_exactly(@a1, @a2), @teacher)
        .and_return(query_double)

      GraphQL::Batch.batch do
        loader_for(@teacher).load(@a1)
        loader_for(@teacher).load(@a2)
      end
    end

    context "with section-limited teacher" do
      before :once do
        @section2 = @course.course_sections.create!(name: "Section 2")
        @student_s2 = course_with_user("StudentEnrollment",
                                       course: @course,
                                       section: @section2,
                                       active_all: true).user

        @ta = user_with_pseudonym(active_all: true)
        ta_enrollment = @course.enroll_ta(@ta)
        ta_enrollment.limit_privileges_to_course_section = true
        ta_enrollment.workflow_state = "active"
        ta_enrollment.save!

        @a1.submit_homework(@student1, submission_type: "online_text_entry", body: "default section")
        @a1.submit_homework(@student_s2, submission_type: "online_text_entry", body: "section 2")
      end

      it "returns count for all sections to full-visibility teacher" do
        GraphQL::Batch.batch do
          loader_for(@teacher).load(@a1).then do |count|
            expect(count).to eq(2)
          end
        end
      end

      it "returns only the visible section count to a section-limited TA" do
        GraphQL::Batch.batch do
          loader_for(@ta).load(@a1).then do |count|
            expect(count).to eq(1)
          end
        end
      end
    end
  end
end
