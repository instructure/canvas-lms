# frozen_string_literal: true

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

require_relative "../graphql_spec_helper"

describe Types::CourseType do
  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end
  let(:course_type) { GraphQLTypeTester.new(course, current_user: @student) }

  let_once(:other_section) { course.course_sections.create! name: "other section" }
  let_once(:other_teacher) do
    course.enroll_teacher(user_factory, section: other_section, limit_privileges_to_course_section: true).user
  end

  it "works" do
    expect(course_type.resolve("_id")).to eq course.id.to_s
    expect(course_type.resolve("name")).to eq course.name
    expect(course_type.resolve("courseNickname")).to be_nil
  end

  it "works for root_outcome_group" do
    expect(course_type.resolve("rootOutcomeGroup { _id }")).to eq course.root_outcome_group.id.to_s
  end

  context "top-level permissions" do
    it "needs read permission" do
      course_with_student
      @course2, @student2 = @course, @student

      # node / legacy node
      expect(course_type.resolve("_id", current_user: @student2)).to be_nil

      # course
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: @student2 }).dig("data", "course")
          query { course(id: "#{course.id}") { id } }
        GQL
      ).to be_nil
    end
  end

  context "sis fields" do
    let_once(:sis_course) do
      course.update!(sis_course_id: "SIScourseID")
      course
    end

    let(:admin) { account_admin_user_with_role_changes(role_changes: { read_sis: false }) }

    it "returns sis_id if you have read_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: @teacher }).dig("data", "course", "sisId")
          query { course(id: "#{sis_course.id}") { sisId } }
        GQL
      ).to eq("SIScourseID")
    end

    it "returns sis_id if you have manage_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: admin }).dig("data", "course", "sisId")
          query { course(id: "#{sis_course.id}") { sisId } }
        GQL
      ).to eq("SIScourseID")
    end

    it "doesn't return sis_id if you don't have read_sis or management_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: @student }).dig("data", "course", "sisId")
          query { course(id: "#{sis_course.id}") { sisId } }
        GQL
      ).to be_nil
    end
  end

  describe "relevantGradingPeriodGroup" do
    let!(:grading_period_group) { Account.default.grading_period_groups.create!(title: "a test group") }

    it "returns the grading period group for the course" do
      enrollment_term = course.enrollment_term
      enrollment_term.update(grading_period_group_id: grading_period_group.id)
      expect(course.relevant_grading_period_group).to eq grading_period_group
      expect(course_type.resolve("relevantGradingPeriodGroup { _id }")).to eq grading_period_group.id.to_s
    end
  end

  describe "assignmentsConnection" do
    let_once(:assignment) do
      course.assignments.create! name: "asdf", workflow_state: "unpublished"
    end

    context "user_id filter" do
      let_once(:other_student) do
        other_user = user_factory(active_all: true, active_state: "active")
        @course.enroll_student(other_user, enrollment_state: "active").user
      end

      # Create an observer in the course that observes the other_student
      let_once(:observer) do
        course_with_observer(course: @course, associated_user_id: other_student.id)
        @observer
      end

      # Create an assignment that is only visible to other_student
      before(:once) do
        # Set the assigment to active
        assignment.workflow_state = "active"
        assignment.save

        @overridden_assignment = course.assignments.create!(title: "asdf",
                                                            workflow_state: "published",
                                                            only_visible_to_overrides: true)

        override = assignment_override_model(assignment: @overridden_assignment)
        override.assignment_override_students.build(user: other_student)
        override.save!
      end

      it "filters assignments by userId correctly for students" do
        expect(
          course_type.resolve(<<~GQL, current_user: other_student)
            assignmentsConnection(filter: {userId: "#{other_student.id}"}) { edges { node { _id } } }
          GQL
        ).to eq [assignment.id.to_s, @overridden_assignment.id.to_s]

        # the other_student lacks permission to see @student's assignments
        expect(
          course_type.resolve(<<~GQL, current_user: other_student)
            assignmentsConnection(filter: {userId: "#{@student.id}"}) { edges { node { _id } } }
          GQL
        ).to eq []
      end

      it "filters assignments by userId correctly for observers" do
        expect(
          course_type.resolve(<<~GQL, current_user: observer)
            assignmentsConnection(filter: {userId: "#{other_student.id}"}) { edges { node { _id } } }
          GQL
        ).to eq [assignment.id.to_s, @overridden_assignment.id.to_s]

        # the observer doesn't observer @student, so it can not see their assignments
        expect(
          course_type.resolve(<<~GQL, current_user: observer)
            assignmentsConnection(filter: {userId: "#{@student.id}"}) { edges { node { _id } } }
          GQL
        ).to eq []
      end

      it "filters assignments by userId correctly for teachers" do
        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            assignmentsConnection(filter: {userId: "#{other_student.id}"}) { edges { node { _id } } }
          GQL
        ).to eq [assignment.id.to_s, @overridden_assignment.id.to_s]

        # A teacher has permission to see all assignments
        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            assignmentsConnection(filter: {userId: "#{@student.id}"}) { edges { node { _id } } }
          GQL
        ).to eq [assignment.id.to_s]
      end

      it "returns visible assignments to current user" do
        expect(course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: @teacher).size).to eq 2
        expect(course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: @student).size).to eq 1
        expect(course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: other_student).size).to eq 2
      end
    end

    it "only returns visible assignments" do
      expect(course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: @teacher).size).to eq 1
      expect(course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: @student).size).to eq 0
    end

    context "grading periods" do
      before(:once) do
        gpg = GradingPeriodGroup.create! title: "asdf",
                                         root_account: course.root_account
        course.enrollment_term.update grading_period_group: gpg
        @term1 = gpg.grading_periods.create! title: "past grading period",
                                             start_date: 2.weeks.ago,
                                             end_date: 1.week.ago
        @term2 = gpg.grading_periods.create! title: "current grading period",
                                             start_date: 2.days.ago,
                                             end_date: 2.days.from_now
        @term1_assignment1 = course.assignments.create! name: "asdf",
                                                        due_at: 1.5.weeks.ago
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
        result = course_type.resolve(<<~GQL, current_user: @student)
          assignmentsConnection(filter: {gradingPeriodId: null}) { edges { node { _id } } }
        GQL
        expect(result.sort).to match course.assignments.published.map(&:to_param).sort
      end

      it "returns assignments in order by position" do
        ag = @course.assignment_groups.create! name: "Other Assignments", position: 1
        other_ag_assignment = @course.assignments.create! assignment_group: ag, name: "other ag"

        @term1_assignment1.assignment_group.update!(position: 2)
        @term2_assignment1.update!(position: 1)
        @term1_assignment1.update!(position: 2)

        expect(
          course_type.resolve(<<~GQL, current_user: @student)
            assignmentsConnection(filter: {gradingPeriodId: null}) { edges { node { _id } } }
          GQL
        ).to eq([
          other_ag_assignment,
          @term2_assignment1,
          @term1_assignment1,
        ].map { |a| a.id.to_s })
      end
    end

    context "grading standards" do
      it "returns grading standard title" do
        expect(
          course_type.resolve("gradingStandard { title }", current_user: @student)
        ).to eq "Default Grading Scheme"
      end

      it "returns grading standard id" do
        expect(
          course_type.resolve("gradingStandard { _id }", current_user: @student)
        ).to eq course.grading_standard_or_default.id
      end

      it "returns grading standard data" do
        expect(
          course_type.resolve("gradingStandard { data { letterGrade } }", current_user: @student)
        ).to eq ["A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "D-", "F"]

        expect(
          course_type.resolve("gradingStandard { data { baseValue } }", current_user: @student)
        ).to eq [0.94, 0.9, 0.87, 0.84, 0.8, 0.77, 0.74, 0.7, 0.67, 0.64, 0.61, 0.0]
      end
    end

    context "apply assignment group weights" do
      it "returns false if not weighted" do
        expect(
          course_type.resolve("applyGroupWeights", current_user: @student)
        ).to be false
      end
    end
  end

  describe "customGradeStatusesConnection" do
    before do
      account_admin_user
      course.root_account.custom_grade_statuses.create!(
        color: "#BBB",
        created_by: @admin,
        name: "My Status"
      )
    end

    it "returns nil when the feature flag is disabled" do
      Account.site_admin.disable_feature!(:custom_gradebook_statuses)
      expect(
        course_type.resolve("customGradeStatusesConnection { edges { node { name } } }", current_user: @teacher)
      ).to be_nil
    end

    it "returns nil when the requesting user lacks needed permissions" do
      expect(
        course_type.resolve("customGradeStatusesConnection { edges { node { name } } }", current_user: @student)
      ).to be_nil
    end

    it "returns the custom grade statuses used by the course" do
      expect(
        course_type.resolve("customGradeStatusesConnection { edges { node { name } } }", current_user: @teacher)
      ).to match_array ["My Status"]
    end

    it "excludes custom statuses not used by the course" do
      new_account = Account.create!
      new_admin = account_admin_user(account: new_account)
      new_account.custom_grade_statuses.create!(color: "#AAA", created_by: new_admin, name: "Another Status")
      expect(
        course_type.resolve("customGradeStatusesConnection { edges { node { name } } }", current_user: @teacher)
      ).not_to include "Another Status"
    end
  end

  describe "gradeStatuses" do
    before do
      account_admin_user
    end

    it "always includes 'late', 'missing', 'none', and 'excused'" do
      expect(
        course_type.resolve("gradeStatuses", current_user: @teacher)
      ).to include("late", "missing", "none", "excused")
    end

    it "returns 'extended' only when the 'Extended Submission State' feature flag is enabled" do
      expect do
        course.root_account.disable_feature!(:extended_submission_state)
      end.to change {
        course_type.resolve("gradeStatuses", current_user: @teacher).include?("extended")
      }.from(true).to(false)
    end
  end

  describe "outcomeProficiency" do
    it "resolves to the account proficiency" do
      outcome_proficiency_model(course.account)
      expect(
        course_type.resolve("outcomeProficiency { _id }", current_user: @teacher)
      ).to eq course.account.outcome_proficiency.id.to_s
    end
  end

  describe "outcomeCalculationMethod" do
    it "resolves to the account calculation method" do
      outcome_calculation_method_model(course.account)
      expect(
        course_type.resolve("outcomeCalculationMethod { _id }", current_user: @teacher)
      ).to eq course.account.outcome_calculation_method.id.to_s
    end
  end

  context "outcomeAlignmentStats" do
    before do
      account_admin_user
      outcome_alignment_stats_model
      course_with_student(course: @course)
      @course.account.enable_feature!(:improved_outcomes_management)
    end

    context "for users with Admin role" do
      it "resolves outcome alignment stats" do
        course_type = GraphQLTypeTester.new(@course, { current_user: @admin })
        expect(course_type.resolve("outcomeAlignmentStats { totalOutcomes }")).to eq 2
        expect(course_type.resolve("outcomeAlignmentStats { alignedOutcomes }")).to eq 1
      end
    end

    context "for users with Teacher role" do
      it "resolves outcome alignment stats" do
        course_type = GraphQLTypeTester.new(@course, { current_user: @teacher })
        expect(course_type.resolve("outcomeAlignmentStats { totalOutcomes }")).to eq 2
        expect(course_type.resolve("outcomeAlignmentStats { alignedOutcomes }")).to eq 1
      end
    end

    context "for users with Student role" do
      it "does not resolve outcome alignment stats" do
        course_type = GraphQLTypeTester.new(@course, { current_user: @student })
        expect(course_type.resolve("outcomeAlignmentStats { totalOutcomes }")).to be_nil
      end
    end
  end

  describe "sectionsConnection" do
    it "only includes active sections" do
      section1 = course.course_sections.create!(name: "Delete Me")
      expect(
        course_type.resolve("sectionsConnection { edges { node { _id } } }")
      ).to match_array course.course_sections.map(&:to_param)

      section1.destroy
      expect(
        course_type.resolve("sectionsConnection { edges { node { _id } } }")
      ).to match_array course.course_sections.active.map(&:to_param)
    end

    describe "assignmentId filter" do
      before do
        other_section_student = course_with_student(active_all: true, course:, section: other_section).user
        @assignment = course.assignments.create!(only_visible_to_overrides: true)
        create_adhoc_override_for_assignment(@assignment, other_section_student)
      end

      let(:query) { "sectionsConnection(filter: { assignmentId: #{@assignment.id} }) { edges { node { _id } } }" }

      it "returns course sections associated with the assignment's assigned students" do
        expect(course_type.resolve(query)).to match_array [other_section.to_param]
      end

      it "raises an error if the provided assignment is soft-deleted" do
        @assignment.destroy
        expect { course_type.resolve(query) }.to raise_error(/assignment not found/)
      end
    end
  end

  describe "modulesConnection" do
    it "returns course modules" do
      modulea = course.context_modules.create! name: "module a"
      course.context_modules.create! name: "module b"
      expect(
        course_type.resolve("modulesConnection { edges {node { _id } } }")
      ).to match_array course.context_modules.map(&:to_param)

      modulea.destroy
      expect(
        course_type.resolve("modulesConnection { edges {node { _id } } }")
      ).to match_array course.modules_visible_to(@student).map(&:to_param)
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
        course_type.resolve(<<~GQL, current_user: @teacher)
          submissionsConnection(
            studentIds: ["#{@student1.id}", "#{@student2.id}"],
            orderBy: [{field: _id, direction: ascending}]
          ) { edges { node { _id } } }
        GQL
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

      expect(
        course_type.resolve(<<~GQL, current_user: @student2)
          submissionsConnection { nodes { _id } }
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
        ).to eq []
      end

      it "submitted_since" do
        @student1a1_submission.update_attribute(:submitted_at, 1.month.ago)
        @student1a2_submission.update_attribute(:submitted_at, 1.day.ago)

        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              filter: { submittedSince: "#{5.days.ago.iso8601}" }
            ) { nodes { _id } }
          GQL
        ).to eq [@student1a2_submission.id.to_s]
      end

      it "graded_since" do
        @student2a1_submission.update_attribute(:graded_at, 1.week.from_now)
        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              filter: { gradedSince: "#{1.day.from_now.iso8601}" }
            ) { nodes { _id } }
          GQL
        ).to eq [@student2a1_submission.id.to_s]
      end

      it "updated_since" do
        @student2a1_submission.update_attribute(:updated_at, 1.week.from_now)
        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              filter: { updatedSince: "#{1.day.from_now.iso8601}" }
            ) { nodes { _id } }
          GQL
        ).to eq [@student2a1_submission.id.to_s]
      end
    end
  end

  context "users and enrollments" do
    before(:once) do
      @student1 = @student
      @student2 = student_in_course(active_all: true).user
      @inactive_user = student_in_course.tap(&:invite).user
      @concluded_user = student_in_course.tap(&:complete).user
    end

    describe "usersConnection" do
      it "returns all visible users" do
        expect(
          course_type.resolve(
            "usersConnection { edges { node { _id } } }",
            current_user: @teacher
          )
        ).to eq [@teacher, @student1, other_teacher, @student2, @inactive_user].map(&:to_param)
      end

      it "returns all visible users in alphabetical order by the sortable_name" do
        expected_users = [@teacher, @student1, other_teacher, @student2, @inactive_user]
                         .sort_by(&:sortable_name)
                         .map(&:to_param)

        actual_user_response = course_type.resolve(
          "usersConnection { edges { node { _id } } }",
          current_user: @teacher
        )

        expect(actual_user_response).to eq(expected_users)
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

      it "allows filtering by enrollment type" do
        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            usersConnection(
              filter: {enrollmentTypes: [TeacherEnrollment]}
            ) { edges { node { _id } } }
          GQL
        ).to match_array [@teacher, other_teacher].map(&:to_param)
        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            usersConnection(
              filter: {enrollmentTypes: [StudentEnrollment]}
            ) { edges { node { _id } } }
          GQL
        ).to match_array [@student1, @student2, @inactive_user].map(&:to_param)
      end

      context "loginId" do
        def pseud_params(unique_id, account = Account.default)
          {
            account:,
            unique_id:,
          }
        end

        before do
          users = [@teacher, @student1, other_teacher, @student2, @inactive_user]
          @pseudonyms = users.map { |user| user.pseudonyms.create!(pseud_params("#{user.id}@example.com")).unique_id }
        end

        it "returns loginId for all users when requested by a teacher" do
          expect(
            course_type.resolve(
              "usersConnection { edges { node { loginId } } }",
              current_user: @teacher
            )
          ).to eq @pseudonyms
        end

        it "does not return loginId for any users when requested by a student" do
          expect(
            course_type.resolve(
              "usersConnection { edges { node { loginId } } }",
              current_user: @student1
            )
          ).to eq [nil, nil, nil, nil, nil]
        end
      end
    end

    describe "enrollmentsConnection" do
      it "works" do
        expect(
          course_type.resolve(
            "enrollmentsConnection { nodes { _id } }",
            current_user: @teacher
          )
        ).to match_array @course.all_enrollments.map(&:to_param)
      end

      it "doesn't return users not visible to current_user" do
        expect(
          course_type.resolve(
            "enrollmentsConnection { nodes { _id } }",
            current_user: other_teacher
          )
        ).to match_array [
          @teacher.enrollments.first.id.to_s,
          other_teacher.enrollments.first.id.to_s,
        ]
      end

      it "returns nil for each user's initial lastActivityAt" do
        expect(
          course_type.resolve(
            "enrollmentsConnection { nodes { lastActivityAt } }",
            current_user: @teacher
          )
        ).to eq [nil, nil, nil, nil, nil, nil]
      end

      it "returns a datetime for each user enrollment once its last activity has been updated" do
        last_activity = "2022-08-01T00:00:00Z"
        course.enrollments.each do |enrollment|
          enrollment.last_activity_at = last_activity
          enrollment.save
          last_activity = (Date.parse(last_activity) + 1.day).to_s
        end

        expect(
          course_type.resolve(
            "enrollmentsConnection { nodes { lastActivityAt } }",
            current_user: @teacher
          ).sort
        ).to eq [
          "2022-08-01T00:00:00Z",
          "2022-08-02T00:00:00Z",
          "2022-08-03T00:00:00Z",
          "2022-08-04T00:00:00Z",
          "2022-08-05T00:00:00Z",
          "2022-08-06T00:00:00Z"
        ]
      end

      it "returns nil for other users's initial lastActivityAt if current user does not have appropriate permissions" do
        last_activity = "2022-08-01T00:00:00Z"
        course.enrollments.each do |enrollment|
          enrollment.last_activity_at = last_activity
          enrollment.save
          last_activity = (Date.parse(last_activity) + 1.day).to_s
        end

        student_last_activity = course_type.resolve(
          "enrollmentsConnection { nodes { lastActivityAt } }",
          current_user: @student1
        ).compact

        expect(student_last_activity).to have(1).items
        expect(student_last_activity.first.to_datetime).to be_within(1.second)
          .of(@student1.enrollments.first.last_activity_at.to_datetime)
      end

      it "returns zero for each user's initial totalActivityTime" do
        expect(
          course_type.resolve(
            "enrollmentsConnection { nodes { totalActivityTime } }",
            current_user: @teacher
          )
        ).to eq [0, 0, 0, 0, 0, 0]
      end

      it "returns nil for other users's initial totalActivityTime if current user does not have appropriate permissions" do
        expect(
          course_type.resolve(
            "enrollmentsConnection { nodes { totalActivityTime } }",
            current_user: @student1
          )
        ).to eq [nil, 0, nil, nil, nil, nil]
      end

      it "returns the sisRole of each user" do
        expect(
          course_type.resolve(
            "enrollmentsConnection { nodes { sisRole } }",
            current_user: @teacher
          )
        ).to eq %w[teacher student teacher student student student]
      end

      it "returns an htmlUrl for each enrollment" do
        expect(
          course_type.resolve(
            "enrollmentsConnection { nodes { htmlUrl } }",
            current_user: @teacher,
            request: ActionDispatch::TestRequest.create
          )
        ).to eq([@teacher, @student1, other_teacher, @student2, @inactive_user, @concluded_user]
          .map { |user| "http://test.host/courses/#{@course.id}/users/#{user.id}" })
      end

      it "returns canBeRemoved boolean value for each enrollment" do
        expect(
          course_type.resolve(
            "enrollmentsConnection { nodes { canBeRemoved } }",
            current_user: @teacher
          )
        ).to eq [false, true, true, true, true, true]
      end

      describe "filtering" do
        it "returns only enrollments of the specified types if included" do
          ta_enrollment = course.enroll_ta(User.create!, enrollment_state: :active)

          expect(
            course_type.resolve(
              "enrollmentsConnection(filter: {types: [TeacherEnrollment, TaEnrollment]}) { nodes { _id } }",
              current_user: @teacher
            )
          ).to match_array([
                             @teacher.enrollments.first.id.to_s,
                             other_teacher.enrollments.first.id.to_s,
                             ta_enrollment.id.to_s
                           ])
        end

        it "returns only enrollments with the specified associated_user_ids if included" do
          observer = User.create!
          observer_enrollment = observer_in_course(course: @course, user: observer)
          observer_enrollment.update!(associated_user: @student1)

          other_observer_enrollment = observer_in_course(course: @course, user: observer)
          other_observer_enrollment.update!(associated_user: @student2)

          expect(
            course_type.resolve(
              "enrollmentsConnection(filter: {associatedUserIds: [#{@student1.id}]}) { nodes { _id } }",
              current_user: @teacher
            )
          ).to eq [observer_enrollment.id.to_s]
        end

        it "returns only enrollments with the specified states if included" do
          inactive_student = course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "inactive").user
          deleted_student = course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "deleted").user
          rejected_student = course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "rejected").user
          expect(
            course_type.resolve(
              "enrollmentsConnection(filter: {states: [inactive, deleted, rejected]}) { nodes { _id } }",
              current_user: @teacher
            )
          ).to eq [inactive_student.enrollments.first.id.to_s, deleted_student.enrollments.first.id.to_s, rejected_student.enrollments.first.id.to_s]
        end
      end
    end
  end

  describe "AssignmentGroupConnection" do
    it "returns assignment groups" do
      ag = course.assignment_groups.create!(name: "a group")
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

  describe "GroupSetsConnection" do
    before(:once) do
      @project_groups = course.group_categories.create! name: "Project Groups"
      @student_groups = GroupCategory.student_organized_for(course)
    end

    it "returns project groups" do
      expect(
        course_type.resolve("groupSetsConnection { edges { node { _id } } }",
                            current_user: @teacher)
      ).to eq [@project_groups.id.to_s]
    end
  end

  describe "term" do
    before(:once) do
      course.enrollment_term.update(start_at: 1.month.ago)
    end

    it "works" do
      expect(
        course_type.resolve("term { _id }")
      ).to eq course.enrollment_term.id.to_s
      expect(
        course_type.resolve("term { name }")
      ).to eq course.enrollment_term.name
      expect(
        course_type.resolve("term { startAt }")
      ).to eq course.enrollment_term.start_at.iso8601
    end
  end

  describe "PostPolicy" do
    let(:assignment) { course.assignments.create! }
    let(:course) { Course.create!(workflow_state: "available") }
    let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
    let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

    context "when user has manage_grades permission" do
      let(:context) { { current_user: teacher } }

      it "returns the PostPolicy for the course" do
        resolver = GraphQLTypeTester.new(course, context)
        expect(resolver.resolve("postPolicy { _id }").to_i).to eql course.default_post_policy.id
      end

      it "returns null if there is no course-specific PostPolicy" do
        course.default_post_policy.destroy
        resolver = GraphQLTypeTester.new(course, context)
        expect(resolver.resolve("postPolicy { _id }")).to be_nil
      end
    end

    context "when user does not have manage_grades permission" do
      let(:context) { { current_user: student } }

      it "returns null in place of the PostPolicy" do
        course.default_post_policy.update!(post_manually: true)
        resolver = GraphQLTypeTester.new(course, context)
        expect(resolver.resolve("postPolicy { _id }")).to be_nil
      end
    end
  end

  describe "AssignmentPostPoliciesConnection" do
    let(:course) { Course.create!(workflow_state: "available") }
    let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
    let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

    context "when user has manage_grades permission" do
      let(:context) { { current_user: teacher } }

      it "returns only the assignment PostPolicies for the course" do
        assignment1 = course.assignments.create!
        assignment2 = course.assignments.create!

        resolver = GraphQLTypeTester.new(course, context)
        ids = resolver.resolve("assignmentPostPolicies { nodes { _id } }").map(&:to_i)
        expect(ids).to contain_exactly(assignment1.post_policy.id, assignment2.post_policy.id)
      end

      it "returns null if there are no assignment PostPolicies" do
        course.post_policies.where.not(assignment: nil).destroy_all
        resolver = GraphQLTypeTester.new(course, context)
        expect(resolver.resolve("assignmentPostPolicies { nodes { _id } }")).to be_empty
      end
    end

    context "when user does not have manage_grades permission" do
      let(:context) { { current_user: student } }

      it "returns null in place of the PostPolicy" do
        resolver = GraphQLTypeTester.new(course, context)
        expect(resolver.resolve("assignmentPostPolicies { nodes { _id } }")).to be_nil
      end
    end
  end

  describe "Account" do
    it "works" do
      expect(course_type.resolve("account { _id }")).to eq course.account.id.to_s
    end
  end

  describe "imageUrl" do
    it "returns a url from an uploaded image" do
      course.image_id = attachment_model(context: @course).id
      course.save!
      expect(course_type.resolve("imageUrl")).to_not be_nil
    end

    it "returns a url from id when url is blank" do
      course.image_url = ""
      course.image_id = attachment_model(context: @course).id
      course.save!
      expect(course_type.resolve("imageUrl")).to_not be_nil
      expect(course_type.resolve("imageUrl")).to_not eq ""
    end

    it "returns a url from settings" do
      course.image_url = "http://some.cool/gif.gif"
      course.save!
      expect(course_type.resolve("imageUrl")).to eq "http://some.cool/gif.gif"
    end
  end

  describe "AssetString" do
    it "returns the asset string" do
      result = course_type.resolve("assetString")
      expect(result).to eq @course.asset_string
    end
  end

  describe "AllowFinalGradeOverride" do
    it "returns the final grade override policy" do
      result = course_type.resolve("allowFinalGradeOverride")
      expect(result).to eq @course.allow_final_grade_override
    end
  end

  describe "RubricsConnection" do
    before(:once) do
      rubric_for_course
      rubric_association_model(context: course, rubric: @rubric, association_object: course, purpose: "bookmark")
    end

    it "returns rubrics" do
      expect(
        course_type.resolve("rubricsConnection { edges { node { _id } } }")
      ).to eq [course.rubrics.first.to_param]

      expect(
        course_type.resolve("rubricsConnection { edges { node { criteriaCount } } }")
      ).to eq [1]

      expect(
        course_type.resolve("rubricsConnection { edges { node { workflowState } } }")
      ).to eq ["active"]
    end
  end
end
