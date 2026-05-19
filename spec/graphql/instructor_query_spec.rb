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

require_relative "../spec_helper"

describe InstructorQuery do
  before(:once) do
    @course = Course.create!(name: "Test Course", workflow_state: "available")
    @student = User.create!(name: "Test Student", sortable_name: "Student, Test")
    @course.enroll_student(@student, enrollment_state: "active")

    @teacher1 = User.create!(name: "Alice Teacher", sortable_name: "Alice Teacher")
    @teacher2 = User.create!(name: "Bob TA", sortable_name: "Bob TA")
    @teacher3 = User.create!(name: "Charlie Teacher", sortable_name: "Charlie Teacher")

    @teacher_enrollment1 = @course.enroll_teacher(@teacher1, enrollment_state: "active")
    @ta_enrollment = @course.enroll_ta(@teacher2, enrollment_state: "active")
    @teacher_enrollment3 = @course.enroll_teacher(@teacher3, enrollment_state: "active")
  end

  def build_subquery(course_ids)
    Enrollment.joins(:enrollment_state)
              .where(workflow_state: "active")
              .joins(:course)
              .where(course_id: course_ids)
              .where(type: %w[TeacherEnrollment TaEnrollment])
              .where(enrollment_states: { restricted_access: false, state: "active" })
              .where(courses: { workflow_state: "available" })
              .where("courses.conclude_at IS NULL OR courses.conclude_at > ?", Time.now.utc)
              .select("DISTINCT ON (enrollments.course_id, enrollments.user_id) enrollments.id")
              .order(Arel.sql("enrollments.course_id"), Arel.sql("enrollments.user_id"), Enrollment.state_by_date_rank_sql, Arel.sql("enrollments.id"))
  end

  let(:subquery) { build_subquery([@course.id]) }
  let(:query) { InstructorQuery.new(subquery) }

  describe "#total_count" do
    it "returns the count of distinct users from the subquery" do
      expect(query.total_count).to eq 3
    end

    it "excludes student enrollments from the count" do
      expect(query.total_count).to eq 3
      student_ids = [@student.id]
      user_ids = query.fetch_page(10, 0).map { |i| i.user.id }
      expect(user_ids).not_to include(*student_ids)
    end

    it "is memoized" do
      query.total_count
      expect(Enrollment).not_to receive(:where)
      query.total_count
    end
  end

  describe "#count" do
    it "aliases to total_count" do
      expect(query.count).to eq query.total_count
    end
  end

  describe "#fetch_page" do
    it "returns the correct number of results with limit" do
      results = query.fetch_page(2, 0)
      expect(results.length).to eq 2
    end

    it "applies offset correctly" do
      all_results = query.fetch_page(10, 0)
      offset_results = query.fetch_page(10, 1)

      expect(offset_results.length).to eq(all_results.length - 1)
      expect(offset_results.first.user).to eq all_results.second.user
    end

    it "returns an empty array when no results match" do
      empty_subquery = build_subquery([0])
      empty_query = InstructorQuery.new(empty_subquery)

      expect(empty_query.fetch_page(10, 0)).to eq []
    end

    it "returns InstructorWithEnrollments structs" do
      results = query.fetch_page(10, 0)

      results.each do |result|
        expect(result).to be_a InstructorWithEnrollments
        expect(result.user).to be_a User
        expect(result.enrollments).to all(be_a(InstructorEnrollmentInfo))
      end
    end

    it "populates enrollment info with correct course, type, role, and state" do
      results = query.fetch_page(10, 0)
      teacher_result = results.find { |r| r.user == @teacher1 }

      expect(teacher_result).to be_present
      enrollment = teacher_result.enrollments.first
      expect(enrollment.course).to eq @course
      expect(enrollment.type).to eq "TeacherEnrollment"
      expect(enrollment.role).to eq teacher_role
      expect(enrollment.state).to eq "active"
    end

    it "sorts results by sortable_name in ascending order" do
      results = query.fetch_page(10, 0)
      names = results.map { |r| r.user.sortable_name }

      expect(names).to eq names.sort
    end

    context "with multiple courses" do
      before(:once) do
        @course2 = Course.create!(name: "Second Course", workflow_state: "available")
        @course2.enroll_teacher(@teacher1, enrollment_state: "active")
      end

      it "includes enrollments from all matching courses" do
        multi_subquery = build_subquery([@course.id, @course2.id])
        multi_query = InstructorQuery.new(multi_subquery)
        results = multi_query.fetch_page(10, 0)

        teacher_result = results.find { |r| r.user == @teacher1 }
        expect(teacher_result.enrollments.length).to eq 2
        courses = teacher_result.enrollments.map(&:course)
        expect(courses).to contain_exactly(@course, @course2)
      end
    end
  end
end
