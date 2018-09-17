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
  let(:course_type) { GraphQLTypeTester.new(course, current_user: @student) }
  let_once(:other_section) { course.course_sections.create! name: "other section" }
  let_once(:other_teacher) {
    course.enroll_teacher(user_factory, section: other_section, limit_privileges_to_course_section: true).user
  }


  it "works" do
    expect(course_type.resolve("_id")).to eq course.id.to_s
    expect(course_type.resolve("name")).to eq course.name
  end

  it "needs read permission" do
    course_with_student
    @course2, @student2 = @course, @student

    expect(course_type.resolve("_id", current_user: @student2)).to be_nil
  end

  describe "assignmentsConnection" do
    let_once(:assignment) {
      course.assignments.create! name: "asdf", workflow_state: "unpublished"
    }

    it "only returns visible assignments" do
      expect(course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: @teacher).size).to eq 1
      expect(course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: @student).size).to eq 0
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
          course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: @student)
        ).to eq [@term2_assignment1.id.to_s]
      end

      it "returns no assignments when outside of a grading period" do
        @term2.destroy
        expect(
          course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: @student)
        ).to eq []
      end

      it "returns assignments for the requested grading period" do
        expect(
          course_type.resolve(<<~GQL, current_user: @student)
            assignmentsConnection(filter: {gradingPeriodId: "#{@term1.id}"}) { edges { node { _id } } }
          GQL
        ).to eq [@term1_assignment1.id.to_s]
      end

      it "can still return assignments for all grading periods" do
        expect(
          course_type.resolve(<<~GQL, current_user: @student)
            assignmentsConnection(filter: {gradingPeriodId: null}) { edges { node { _id } } }
          GQL
        ).to match course.assignments.published.map(&:to_param)
      end
    end
  end

  describe "sectionsConnection" do
    it "only includes active sections" do
      section1 = course.course_sections.create!(name: "Delete Me")
      expect(
        course_type.resolve("sectionsConnection { edges { node { _id } } }")
      ).to match course.course_sections.map(&:to_param)

      section1.destroy
      expect(
        course_type.resolve("sectionsConnection { edges { node { _id } } }")
      ).to eq course.course_sections.active.map(&:to_param)
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
        course_type.resolve(<<~GQL, current_user: @teacher
          submissionsConnection(
            studentIds: ["#{@student1.id}", "#{@student2.id}"],
            orderBy: [{field: _id, direction: ascending}]
          ) { edges { node { _id } } }
          GQL
        )
      ).to eq [
        @student1a1_submission.id.to_s,
        @student1a2_submission.id.to_s,
        @student2a1_submission.id.to_s,
      ].sort
    end


    it "doesn't let students see other student's submissions" do
      expect(
        course_type.resolve(<<~GQL, current_user: @student2)
          submissionsConnection(
            studentIds: ["#{@student1.id}", "#{@student2.id}"],
          ) { edges { node { _id } } }
        GQL
      ).to eq [@student2a1_submission.id.to_s]
    end

    context "sorting criteria" do
      it "takes sorting criteria" do
        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              studentIds: ["#{@student1.id}", "#{@student2.id}"],
              orderBy: [{field: gradedAt, direction: descending}]
            ) { edges { node { _id } } }
            GQL
        ).to eq [
          @student1a2_submission.id.to_s,
          @student2a1_submission.id.to_s,
          @student1a1_submission.id.to_s,
        ]
      end

      it "sorts null last" do
        @student2a1_submission.update_attribute :graded_at, nil

        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              studentIds: ["#{@student1.id}", "#{@student2.id}"],
              orderBy: [{field: gradedAt, direction: descending}]
            ) { edges { node { _id } } }
          GQL
        ).to eq [
          @student1a2_submission.id.to_s,
          @student1a1_submission.id.to_s,
          @student2a1_submission.id.to_s,
        ]
      end
    end

    context "filtering" do
      it "allows filtering submissions by their state" do
        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              studentIds: ["#{@student1.id}"],
              filter: {states: [unsubmitted]}
            ) { edges { node { _id } } }
          GQL
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
        course_type.resolve(
          "usersConnection { edges { node { _id } } }",
          current_user: @teacher
        )
      ).to eq [@teacher, @student1, other_teacher, @student2, @inactive_user].map(&:to_param)
    end

    it "returns only the specified users" do
      # deprecated method
      expect(
        course_type.resolve(<<~GQL, current_user: @teacher)
          usersConnection(userIds: ["#{@student1.id}"]) { edges { node { _id } } }
        GQL
      ).to eq [@student1.to_param]

      # current method
      expect(
        course_type.resolve(<<~GQL, current_user: @teacher)
          usersConnection(filter: {userIds: ["#{@student1.id}"]}) { edges { node { _id } } }
        GQL
      ).to eq [@student1.to_param]
    end

    it "doesn't return users that aren't visible to you" do
      expect(
        course_type.resolve(
          "usersConnection { edges { node { _id } } }",
          current_user: other_teacher
        )
      ).to eq [other_teacher.id.to_s]
    end

    it "allows filtering by enrollment state" do
      expect(
        course_type.resolve(<<~GQL, current_user: @teacher)
          usersConnection(
            filter: {enrollmentStates: [active completed]}
          ) { edges { node { _id } } }
        GQL
      ).to match_array [@teacher, @student1, @student2, @concluded_user].map(&:to_param)
    end
  end

  describe "AssignmentGroupConnection" do
    it "returns assignment groups" do
      ag = course.assignment_groups.create!(name: 'a group')
      expect(
        course_type.resolve("assignmentGroupsConnection { edges { node { _id } } }")
      ).to eq [ag.to_param]
    end
  end

  describe "GroupsConnection" do
    before(:once) do
      course.groups.create! name: "A Group"
    end

    it "returns student groups" do
      expect(
        course_type.resolve("groupsConnection { edges { node { _id } } }")
      ).to eq course.groups.map(&:to_param)
    end
  end
end
