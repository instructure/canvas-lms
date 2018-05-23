#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::CourseType do
  let_once(:course) { course_with_student(active_all: true); @course }
  let(:course_type) { GraphQLTypeTester.new(Types::CourseType, course) }

  it "works" do
    expect(course_type._id).to eq course.id
    expect(course_type.name).to eq course.name
  end

  describe "assignmentsConnection" do
    let_once(:assignment) {
      course.assignments.create! name: "asdf", workflow_state: "unpublished"
    }

    it "only returns visible assignments" do
      expect(course_type.assignmentsConnection(current_user: @teacher).size).to eq 1
      expect(course_type.assignmentsConnection(current_user: @student).size).to eq 0
    end

    context "grading periods" do
      before(:once) do
        gpg = GradingPeriodGroup.create! title: "asdf",
          root_account: course.root_account
        course.enrollment_term.update_attributes grading_period_group: gpg
        @term1 = gpg.grading_periods.create! title: "past grading period",
        start_date: 2.weeks.ago,
          end_date: 1.weeks.ago
        @term2 = gpg.grading_periods.create! title: "current grading period",
        start_date: 2.days.ago,
          end_date: 2.days.from_now
        @term1_assignment1 = course.assignments.create! name: "asdf",
          due_at: (1.5).weeks.ago
        @term2_assignment1 = course.assignments.create! name: ";lkj",
          due_at: Date.today
      end

      it "only returns assignments for the current grading period" do
        expect(
          course_type.assignmentsConnection(current_user: @student)
        ).to eq [@term2_assignment1]
      end

      it "returns no assignments when outside of a grading period" do
        @term2.destroy
        expect(
          course_type.assignmentsConnection(current_user: @student)
        ).to eq []
      end

      it "returns assignments for the requested grading period" do
        expect(
          course_type.assignmentsConnection(
            current_user: @student,
            args: {filter: {gradingPeriodId: @term1.id.to_s}}
          )
        ).to eq [@term1_assignment1]
      end

      it "can still return assignments for all grading periods" do
        expect(
          course_type.assignmentsConnection(
            current_user: @student,
            args: {filter: {gradingPeriodId: nil}}
          )
        ).to eq course.assignments.published
      end
    end
  end

  describe "sectionsConnection" do
    it "only includes active sections" do
      section1 = course.course_sections.create!(name: "Delete Me")
      expect(course_type.sectionsConnection.size).to eq 2

      section1.destroy
      expect(course_type.sectionsConnection.size).to eq 1
    end
  end

  context "submissionsConnection" do
    before(:once) do
      a1 = course.assignments.create! name: "one", points_possible: 10
      a2 = course.assignments.create! name: "two", points_possible: 10

      @student1 = @student
      student_in_course(active_all: true)
      @student2 = @student

      @student1a1_submission, _ = a1.grade_student(@student1, grade: 1, grader: @teacher)
      @student1a2_submission, _ = a2.grade_student(@student1, grade: 9, grader: @teacher)
      @student2a1_submission, _ = a1.grade_student(@student2, grade: 5, grader: @teacher)

      @student1a1_submission.update_attribute :graded_at, 4.days.ago
      @student1a2_submission.update_attribute :graded_at, 2.days.ago
      @student2a1_submission.update_attribute :graded_at, 3.days.ago
    end

    it "returns submissions for specified students" do
      expect(
        course_type.submissionsConnection(
          current_user: @teacher,
          args: {
            studentIds: [@student1.id.to_s, @student2.id.to_s],
            orderBy: [{field: "id", direction: "asc"}],
          }
        )
      ).to eq [
        @student1a1_submission,
        @student1a2_submission,
        @student2a1_submission
      ].sort_by(&:id)
    end

    it "doesn't let students see other student's submissions" do
      expect(
        course_type.submissionsConnection(
          current_user: @student2,
          args: {
            studentIds: [@student1.id.to_s, @student2.id.to_s],
          }
        )
      ).to eq [@student2a1_submission]
    end

    context "sorting criteria" do
      it "takes sorting criteria" do
        expect(
          course_type.submissionsConnection(
            current_user: @teacher,
            args: {
              studentIds: [@student1.id.to_s, @student2.id.to_s],
              orderBy: [{field: "graded_at", direction: "desc"}],
            }
          )
        ).to eq [
          @student1a2_submission,
          @student2a1_submission,
          @student1a1_submission,
        ]
      end

      it "sorts null last" do
        @student2a1_submission.update_attribute :graded_at, nil

        # the code that turns enums->values runs at the schema- (not type-)
        # level doing it by hand here
        direction = Types::SubmissionOrderInputType.arguments["direction"].
          type.values["descending"].value

        expect(
          course_type.submissionsConnection(
            current_user: @teacher,
            args: {
              studentIds: [@student1.id.to_s, @student2.id.to_s],
              orderBy: [{field: "graded_at", direction: direction}],
            }
          )
        ).to eq [
          @student1a2_submission,
          @student1a1_submission,
          @student2a1_submission,
        ]
      end
    end

    context "filtering" do
      it "allows filtering submissions by their state" do
        expect(
          course_type.submissionsConnection(
            current_user: @teacher,
            args: {
              studentIds: [@student1.id.to_s],
              filter: {states: %[unsubmitted]}
            }
          )
        ).to eq [ ]
      end
    end
  end

  describe "usersConnection" do
    before(:once) do
      @student1 = @student
      @student2 = student_in_course(active_all: true).user
      @inactive_user = student_in_course.tap { |enrollment|
        enrollment.invite
      }.user
      @concluded_user = student_in_course.tap { |enrollment|
        enrollment.complete
      }.user
    end

    it "returns all visible users" do
      expect(
        course_type.usersConnection(current_user: @teacher)
      ).to eq [@teacher, @student1, @student2, @inactive_user]
    end

    it "returns only the specified users" do
      # deprecated method
      expect(
        course_type.usersConnection(
          current_user: @teacher,
          args: {userIds: @student1}
        )
      ).to eq [@student1]

      # current method
      expect(
        course_type.usersConnection(
          current_user: @teacher,
          args: {filter: {userIds: @student1}}
        )
      ).to eq [@student1]
    end

    it "doesn't return users that aren't visible to you" do
      other_teacher = teacher_in_course(active_all: true,
                                        course: Course.create!).user
      expect(
        course_type.usersConnection(current_user: other_teacher)
      ).to be_nil
    end

    it "allows filtering by enrollment state" do
      expect(
        course_type.usersConnection(
          current_user: @teacher,
          args: {filter: {enrollmentStates: ["active", "completed"]}}
        )
      ).to eq [@teacher, @student1, @student2, @concluded_user]
    end
  end

  describe "AssignmentGroupConnection" do
    it "returns assignment groups" do
      c = Course.find(course.id)
      c.assignment_groups.create!(name: 'a group')
      expect(c.assignment_groups.size).to be 1
      expect(course_type.assignmentGroupsConnection.length).to be 1
    end
  end

  describe "GroupsConnection" do
    before(:once) do
      course.groups.create! name: "A Group"
    end

    it "returns student groups" do
      expect(course_type.groupsConnection(current_user: @teacher)).to eq course.groups
    end

    it "returns nil for users with no permission" do
      other_course = course_with_teacher(active_all: true)
      other_teacher = @teacher
      expect(course_type.groupsConnection(current_user: other_teacher)).to be_nil
    end
  end
end
