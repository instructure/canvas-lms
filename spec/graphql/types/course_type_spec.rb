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
require_relative "../graphql_spec_helper"

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

  context "top-level permissions" do
    it "needs read permission" do
      course_with_student
      @course2, @student2 = @course, @student

      # node / legacy node
      expect(course_type.resolve("_id", current_user: @student2)).to be_nil

      # course
      expect(
        CanvasSchema.execute(<<~GQL, context: {current_user: @student2}).dig("data", "course")
          query { course(id: "#{course.id.to_s}") { id } }
        GQL
      ).to be_nil
    end
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
        course.enrollment_term.update grading_period_group: gpg
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
        ).to eq [
          other_ag_assignment,
          @term2_assignment1,
          @term1_assignment1,
        ].map { |a| a.id.to_s }
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
        ).to eq [ ]
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
        ).to eq [ @student1a2_submission.id.to_s ]
      end

      it "graded_since" do
        @student2a1_submission.update_attribute(:graded_at, 1.week.from_now)
        expect(
          course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              filter: { gradedSince: "#{1.day.from_now.iso8601}" }
            ) { nodes { _id } }
          GQL
        ).to eq [ @student2a1_submission.id.to_s ]
      end
    end
  end

  context "users and enrollments" do
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

    describe "usersConnection" do
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

    describe "enrollmentsConnection" do
      it "works" do
        expect(
          course_type.resolve(
            "enrollmentsConnection { nodes { _id } }",
            current_user: @teacher,
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
        expect(resolver.resolve("postPolicy { _id }")).to be nil
      end
    end

    context "when user does not have manage_grades permission" do
      let(:context) { { current_user: student } }

      it "returns null in place of the PostPolicy" do
        course.default_post_policy.update!(post_manually: true)
        resolver = GraphQLTypeTester.new(course, context)
        expect(resolver.resolve("postPolicy { _id }")).to be nil
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
        expect(resolver.resolve("assignmentPostPolicies { nodes { _id } }")).to be nil
      end
    end
  end

  describe 'Account' do
    it 'works' do
      expect(course_type.resolve("account { _id }")).to eq course.account.id.to_s
    end
  end

  describe 'imageUrl' do
    before(:once) {
      course.enable_feature! 'course_card_images'
    }

    it 'returns nil when the feature flag is disabled' do
      course.disable_feature! 'course_card_images'
      expect(course_type.resolve("imageUrl")).to be_nil
    end

    it 'returns a url from an uploaded image' do
      course.image_id = attachment_model(context: @course).id
      course.save!
      expect(course_type.resolve("imageUrl")).to_not be_nil
    end

    it 'returns a url from settings' do
      course.image_url = "http://some.cool/gif.gif"
      course.save!
      expect(course_type.resolve("imageUrl")).to eq "http://some.cool/gif.gif"
    end
  end

  describe 'notificationPreferences' do
    it 'returns the students notification preferences' do
      Notification.delete_all
      communication_channel = @student.communication_channels.create!(path: 'test@test.com')
      notification = notification_model(:name => 'test', :category => 'Announcement')

      expect(
        course_type.resolve('notificationPreferences { channels { notificationPolicies(contextType: Course) { notification { name } } } }')[0][0]
      ).to eq 'test'
    end
  end
end
