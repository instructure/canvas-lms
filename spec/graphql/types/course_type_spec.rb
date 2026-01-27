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
require "lti_1_3_tool_configuration_spec_helper"

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

  context "connection types" do
    describe "foldersConnection" do
      before(:once) do
        @folder1 = folder_model(context: course, name: "Folder 1")
        @folder2 = folder_model(context: course, name: "Folder 2")
        @folder3 = folder_model(context: course, name: "Folder 3")
        @folder3.destroy
      end

      it "returns course folders" do
        expect(
          course_type.resolve("foldersConnection { edges { node { _id } } }", current_user: @teacher)
        ).to match_array [@folder1.id.to_s, @folder2.id.to_s, Folder.root_folders(course).first.id.to_s]
      end

      it "doesn't return deleted folders" do
        expect(
          course_type.resolve("foldersConnection { edges { node { _id name } } }", current_user: @teacher)
        ).not_to include("node" => { "_id" => @folder3.id.to_s, "name" => @folder3.name })
      end

      it "requires read permission" do
        other_course_student = student_in_course(course: course_factory).user
        resolver = GraphQLTypeTester.new(course, current_user: other_course_student)
        expect(resolver.resolve("foldersConnection { edges { node { _id } } }")).to be_nil
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

      context "hide_in_gradebook filter" do
        before(:once) do
          @regular_assignment = course.assignments.create!(
            name: "Regular Assignment",
            points_possible: 10,
            workflow_state: "published"
          )
          @hidden_assignment = course.assignments.create!(
            name: "Hidden Assignment",
            points_possible: 0,
            workflow_state: "published",
            hide_in_gradebook: true,
            omit_from_final_grade: true
          )
        end

        it "filters out assignments with hide_in_gradebook when feature flag is enabled" do
          Account.site_admin.enable_feature!(:hide_zero_point_quizzes_option)
          result = course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: @student)
          assignment_ids = result.map(&:to_i)
          expect(assignment_ids).to include(@regular_assignment.id)
          expect(assignment_ids).not_to include(@hidden_assignment.id)
        end

        it "includes all assignments when feature flag is disabled" do
          Account.site_admin.disable_feature!(:hide_zero_point_quizzes_option)
          result = course_type.resolve("assignmentsConnection { edges { node { _id } } }", current_user: @student)
          assignment_ids = result.map(&:to_i)
          expect(assignment_ids).to include(@regular_assignment.id)
          expect(assignment_ids).to include(@hidden_assignment.id)
        end
      end

      context "submission types" do
        before(:once) do
          @assignment1 = course.assignments.create!(
            name: "Online Upload Assignment",
            submission_types: "online_upload",
            workflow_state: "published"
          )
          @assignment2 = course.assignments.create!(
            name: "Online Quiz Assignment",
            submission_types: "online_quiz",
            workflow_state: "published"
          )
          @assignment3 = course.assignments.create!(
            name: "No Submission Assignment",
            submission_types: "none",
            workflow_state: "published"
          )
          @assignment4 = course.assignments.create!(
            name: "Multiple Submission Types Assignment",
            submission_types: "online_upload,online_quiz",
            workflow_state: "published"
          )
          @assignment5 = course.assignments.create!(
            name: "No Submission Assignment 2",
            submission_types: "",
            workflow_state: "published"
          )
        end

        it "only returns assignments with `online_upload` submission type" do
          result = course_type.resolve("assignmentsConnection(filter: { submissionTypes: [online_upload] }) { edges { node { _id } } }", current_user: @student)
          expect(result).to eq [@assignment1.id.to_s, @assignment4.id.to_s]
        end

        it "only returns assignments with `online_upload, online_quiz` submission type" do
          result = course_type.resolve("assignmentsConnection(filter: { submissionTypes: [online_upload, online_quiz] }) { edges { node { _id } } }", current_user: @student)
          expect(result).to eq [@assignment1.id.to_s, @assignment2.id.to_s, @assignment4.id.to_s]
        end

        it "only returns assignments with `no submission` submission type" do
          result = course_type.resolve("assignmentsConnection(filter: { submissionTypes: [none] }) { edges { node { _id } } }", current_user: @student)
          expect(result).to eq [@assignment3.id.to_s, @assignment5.id.to_s]
        end
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
                                                          due_at: Time.zone.today
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

      context "searchTerm" do
        before do
          @discussion_1 = course.discussion_topics.create!(title: "asdf", message: "asdf")
          @discussion_2 = course.discussion_topics.create!(title: "asdf2", message: "asdf2")
          @discussion_3 = course.discussion_topics.create!(title: "asdf3", message: "asdf3")
        end

        it "returns discussions with general search term" do
          expect(
            course_type.resolve("discussionsConnection(filter: { searchTerm: \"asdf\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@discussion_1.id.to_s, @discussion_2.id.to_s, @discussion_3.id.to_s]
        end

        it "returns discussions with specific search term" do
          expect(
            course_type.resolve("discussionsConnection(filter: { searchTerm: \"asdf2\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@discussion_2.id.to_s]
        end
      end
    end

    context "discussionsConnection" do
      before do
        @discussion_1 = course.discussion_topics.create!(title: "asdf", message: "asdf")
        @discussion_2 = course.discussion_topics.create!(title: "asdf2", message: "asdf2")
        @discussion_3 = course.discussion_topics.create!(title: "asdf3", message: "asdf3")
      end

      it "returns discussions" do
        expect(
          course_type.resolve("discussionsConnection { edges { node { _id } } }", current_user: @teacher)
        ).to eq [@discussion_1.id.to_s, @discussion_2.id.to_s, @discussion_3.id.to_s]
      end

      context "searchTerm" do
        it "returns discussions with general search term" do
          expect(
            course_type.resolve("discussionsConnection(filter: { searchTerm: \"asdf\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@discussion_1.id.to_s, @discussion_2.id.to_s, @discussion_3.id.to_s]
        end

        it "returns discussions with specific search term" do
          expect(
            course_type.resolve("discussionsConnection(filter: { searchTerm: \"asdf2\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@discussion_2.id.to_s]
        end
      end

      context "as a student" do
        it "returns discussions" do
          expect(
            course_type.resolve("discussionsConnection { edges { node { _id } } }", current_user: @student)
          ).to eq [@discussion_1.id.to_s, @discussion_2.id.to_s, @discussion_3.id.to_s]
        end

        it "returns only discussions assigned to the student" do
          new_section = course.course_sections.create!(name: "new section")
          @discussion_1.assignment_overrides.create!(course_section: new_section)
          @discussion_1.update!(only_visible_to_overrides: true)
          expect(
            course_type.resolve("discussionsConnection { edges { node { _id } } }", current_user: @student)
          ).to eq [@discussion_2.id.to_s, @discussion_3.id.to_s]
        end
      end

      context "userId filter" do
        it "returns unauthorized code when user is not allowed to act as another user" do
          new_section = course.course_sections.create!(name: "new section")
          @discussion_1.assignment_overrides.create!(course_section: new_section)
          @discussion_1.update!(only_visible_to_overrides: true)
          expect_error = "You do not have permission to view this course."
          expect do
            course_type.resolve("discussionsConnection(filter: { userId: \"#{@teacher.id}\" }) { edges { node { _id } } }", current_user: @student)
          end.to raise_error(GraphQLTypeTester::Error, /#{Regexp.escape(expect_error)}/)
        end

        it "returns discussions assigned to the user_id when allowed to act as that user" do
          new_section = course.course_sections.create!(name: "new section")
          @discussion_1.assignment_overrides.create!(course_section: new_section)
          @discussion_1.update!(only_visible_to_overrides: true)
          expect(
            course_type.resolve("discussionsConnection(filter: { userId: \"#{@student.id}\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@discussion_2.id.to_s, @discussion_3.id.to_s]
        end
      end
    end

    context "pagesConnection" do
      before do
        @page_1 = course.wiki_pages.create!(title: "asdf", body: "asdf")
        @page_2 = course.wiki_pages.create!(title: "asdf2", body: "asdf2")
        @page_3 = course.wiki_pages.create!(title: "asdf3", body: "asdf3")
      end

      it "returns pages" do
        expect(
          course_type.resolve("pagesConnection { edges { node { _id } } }", current_user: @teacher)
        ).to eq [@page_1.id.to_s, @page_2.id.to_s, @page_3.id.to_s]
      end

      context "search" do
        it "returns pages with general search term" do
          expect(
            course_type.resolve("pagesConnection(filter: { searchTerm: \"asdf\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@page_1.id.to_s, @page_2.id.to_s, @page_3.id.to_s]
        end

        it "returns pages with specific search term" do
          expect(
            course_type.resolve("pagesConnection(filter: { searchTerm: \"asdf2\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@page_2.id.to_s]
        end
      end

      context "as a student" do
        it "returns pages" do
          expect(
            course_type.resolve("pagesConnection { edges { node { _id } } }", current_user: @student)
          ).to eq [@page_1.id.to_s, @page_2.id.to_s, @page_3.id.to_s]
        end

        it "returns only wiki pages assigned to the student" do
          new_section = course.course_sections.create!(name: "new section")
          @page_1.assignment_overrides.create!(course_section: new_section)
          @page_1.update!(only_visible_to_overrides: true)
          expect(
            course_type.resolve("pagesConnection { edges { node { _id } } }", current_user: @student)
          ).to eq [@page_2.id.to_s, @page_3.id.to_s]
        end
      end

      context "userId filter" do
        it "returns unauthorized code when user is not allowed to act as another user" do
          expect_error = "You do not have permission to view this course."
          expect do
            course_type.resolve("pagesConnection(filter: { userId: \"#{@teacher.id}\" }) { edges { node { _id } } }", current_user: @student)
          end.to raise_error(GraphQLTypeTester::Error, /#{Regexp.escape(expect_error)}/)
        end

        it "returns pages for the given user" do
          expect(
            course_type.resolve("pagesConnection(filter: { userId: \"#{@teacher.id}\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@page_1.id.to_s, @page_2.id.to_s, @page_3.id.to_s]
        end
      end
    end

    context "quizzesConnection" do
      before do
        @quiz_1 = course.quizzes.create!(title: "asdf", quiz_type: "assignment")
        @quiz_2 = course.quizzes.create!(title: "asdf2", quiz_type: "assignment")
        @quiz_3 = course.quizzes.create!(title: "asdf3", quiz_type: "assignment")
        @quiz_lti_1 = new_quizzes_assignment(course:, title: "quiz_lti_1")

        @quiz_lti_1.quiz_lti!
        @quiz_lti_1.save!
      end

      shared_examples "userId filter tests" do
        context "userId filter" do
          it "returns unauthorized code when user is not allowed to act as another user" do
            expect_error = "You do not have permission to view this course."
            expect do
              course_type.resolve("quizzesConnection(filter: { userId: \"#{@teacher.id}\" }) { edges { node { _id } } }", current_user: @student)
            end.to raise_error(GraphQLTypeTester::Error, /#{Regexp.escape(expect_error)}/)
          end

          it "returns quizzes for the given user" do
            expect(
              course_type.resolve("quizzesConnection(filter: { userId: \"#{@teacher.id}\" }) { edges { node { _id } } }", current_user: @teacher)
            ).to match_array expected_quiz_ids_for_teacher
          end
        end
      end

      context "without new quizzes enabled" do
        let(:expected_quiz_ids_for_teacher) { [@quiz_1.id.to_s, @quiz_2.id.to_s, @quiz_3.id.to_s] }

        it "returns quizzes" do
          expect(
            course_type.resolve("quizzesConnection { edges { node { _id } } }", current_user: @teacher)
          ).to match_array [@quiz_1.id.to_s, @quiz_2.id.to_s, @quiz_3.id.to_s]
        end

        context "searchTerm" do
          it "returns quizzes with general search term" do
            expect(
              course_type.resolve("quizzesConnection(filter: { searchTerm: \"asdf\" }) { edges { node { _id } } }", current_user: @teacher)
            ).to match_array [@quiz_1.id.to_s, @quiz_2.id.to_s, @quiz_3.id.to_s]
          end

          it "returns quizzes with specific search term" do
            expect(
              course_type.resolve("quizzesConnection(filter: { searchTerm: \"asdf2\" }) { edges { node { _id } } }", current_user: @teacher)
            ).to match_array [@quiz_2.id.to_s]
          end

          it "returns empty array for LTI quiz search term" do
            expect(
              course_type.resolve("quizzesConnection(filter: { searchTerm: \"quiz_lti_1\" }) { edges { node { _id } } }", current_user: @teacher)
            ).to be_empty
          end
        end

        context "as a student" do
          it "returns quizzes" do
            expect(
              course_type.resolve("quizzesConnection { edges { node { _id } } }", current_user: @student)
            ).to match_array [@quiz_1.id.to_s, @quiz_2.id.to_s, @quiz_3.id.to_s]
          end

          it "returns only quizzes assigned to the student" do
            new_section = course.course_sections.create!(name: "new section")
            @quiz_1.assignment_overrides.create!(course_section: new_section)
            @quiz_1.update!(only_visible_to_overrides: true)
            expect(
              course_type.resolve("quizzesConnection { edges { node { _id } } }", current_user: @student)
            ).to match_array [@quiz_2.id.to_s, @quiz_3.id.to_s]
          end
        end

        it_behaves_like "userId filter tests"
      end

      context "with new quizzes enabled" do
        let(:expected_quiz_ids_for_teacher) { [@quiz_1.id.to_s, @quiz_2.id.to_s, @quiz_3.id.to_s, @quiz_lti_1.id.to_s] }

        before do
          course.context_external_tools.create!(
            name: "Quizzes.Next",
            consumer_key: "test_key",
            shared_secret: "test_secret",
            tool_id: "Quizzes 2",
            url: "http://example.com/launch"
          )
          course.root_account.settings[:provision] = { "lti" => "lti url" }
          course.root_account.save!
          course.root_account.enable_feature! :quizzes_next
          course.enable_feature! :quizzes_next
        end

        it "returns quizzes" do
          expect(
            course_type.resolve("quizzesConnection { edges { node { _id } } }", current_user: @teacher)
          ).to match_array [@quiz_1.id.to_s, @quiz_2.id.to_s, @quiz_3.id.to_s, @quiz_lti_1.id.to_s]
        end

        context "searchTerm" do
          it "returns quizzes with general search term" do
            expect(
              course_type.resolve("quizzesConnection(filter: { searchTerm: \"asdf\" }) { edges { node { _id } } }", current_user: @teacher)
            ).to match_array [@quiz_1.id.to_s, @quiz_2.id.to_s, @quiz_3.id.to_s]
          end

          it "returns quizzes with specific search term" do
            expect(
              course_type.resolve("quizzesConnection(filter: { searchTerm: \"asdf2\" }) { edges { node { _id } } }", current_user: @teacher)
            ).to match_array [@quiz_2.id.to_s]
          end

          it "returns quiz with new engine" do
            expect(
              course_type.resolve("quizzesConnection(filter: { searchTerm: \"quiz_lti_1\" }) { edges { node { quizType } } }", current_user: @teacher)
            ).to match_array ["assignment"]
          end
        end

        context "as a student" do
          it "returns quizzes" do
            expect(
              course_type.resolve("quizzesConnection { edges { node { _id } } }", current_user: @student)
            ).to match_array [@quiz_1.id.to_s, @quiz_2.id.to_s, @quiz_3.id.to_s, @quiz_lti_1.id.to_s]
          end

          it "returns only quizzes assigned to the student" do
            new_section = course.course_sections.create!(name: "new section")
            @quiz_1.assignment_overrides.create!(course_section: new_section)
            @quiz_1.update!(only_visible_to_overrides: true)
            expect(
              course_type.resolve("quizzesConnection { edges { node { _id } } }", current_user: @student)
            ).to match_array [@quiz_2.id.to_s, @quiz_3.id.to_s, @quiz_lti_1.id.to_s]
          end
        end

        it_behaves_like "userId filter tests"
      end
    end

    context "filesConnection" do
      before do
        @file_1 = course.attachments.create!(filename: "asdf", uploaded_data: default_uploaded_data)
        @file_2 = course.attachments.create!(filename: "asdf2", uploaded_data: default_uploaded_data)
        @file_3 = course.attachments.create!(filename: "asdf3", uploaded_data: default_uploaded_data)
      end

      it "returns files" do
        expect(
          course_type.resolve("filesConnection { edges { node { _id } } }", current_user: @teacher)
        ).to eq [@file_1.id.to_s, @file_2.id.to_s, @file_3.id.to_s]
      end

      context "search" do
        it "returns files with general search term" do
          expect(
            course_type.resolve("filesConnection(filter: { searchTerm: \"asdf\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@file_1.id.to_s, @file_2.id.to_s, @file_3.id.to_s]
        end

        it "returns files with specific search term" do
          expect(
            course_type.resolve("filesConnection(filter: { searchTerm: \"asdf2\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@file_2.id.to_s]
        end
      end

      context "userId filter" do
        it "returns unauthorized code when user is not allowed to act as another user" do
          expect_error = "You do not have permission to view this course."
          expect do
            course_type.resolve("filesConnection(filter: { userId: \"#{@teacher.id}\" }) { edges { node { _id } } }", current_user: @student)
          end.to raise_error(GraphQLTypeTester::Error, /#{Regexp.escape(expect_error)}/)
        end

        it "returns files for the given user" do
          expect(
            course_type.resolve("filesConnection(filter: { userId: \"#{@teacher.id}\" }) { edges { node { _id } } }", current_user: @teacher)
          ).to eq [@file_1.id.to_s, @file_2.id.to_s, @file_3.id.to_s]
        end
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

    it "returns the custom grade statuses used by the course" do
      expect(
        course_type.resolve("customGradeStatusesConnection { edges { node { name } } }", current_user: @teacher)
      ).to match_array ["My Status"]
    end

    it "returns the custom grade statuses used by the course for a student" do
      expect(
        course_type.resolve("customGradeStatusesConnection { edges { node { name } } }", current_user: @student)
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

      context "with peer review sub assignments" do
        before do
          course.enable_feature!(:peer_review_allocation_and_grading)
          @section1 = course.course_sections.create!(name: "Section 1")
          @section2 = course.course_sections.create!(name: "Section 2")
          @parent_assignment = course.assignments.create!(
            title: "Parent Assignment",
            peer_reviews: true,
            peer_review_count: 2
          )
          @peer_review_sub_assignment = peer_review_model(parent_assignment: @parent_assignment)
        end

        let(:peer_review_query) { "sectionsConnection(filter: { assignmentId: #{@peer_review_sub_assignment.id} }) { edges { node { _id } } }" }

        it "returns course sections for peer review sub assignment" do
          result = course_type.resolve(peer_review_query)
          expect(result).to be_an(Array)
          expect(result).not_to be_empty
        end

        it "returns all course sections including multiple sections" do
          result = course_type.resolve(peer_review_query)
          expect(result).to include(@section1.id.to_s, @section2.id.to_s)
        end

        context "with visibility overrides" do
          before do
            @section3 = course.course_sections.create!(name: "Section 3")
            student_in_section(@section1)
            student_in_section(@section2)
            @peer_review_sub_assignment.update!(only_visible_to_overrides: true)
            parent_override1 = @parent_assignment.assignment_overrides.create!(set: @section1)
            parent_override2 = @parent_assignment.assignment_overrides.create!(set: @section2)
            @peer_review_sub_assignment.assignment_overrides.create!(set: @section1, parent_override: parent_override1)
            @peer_review_sub_assignment.assignment_overrides.create!(set: @section2, parent_override: parent_override2)
          end

          it "returns only sections with overrides when only_visible_to_overrides is true" do
            result = course_type.resolve(peer_review_query)
            expect(result).to contain_exactly(@section1.id.to_s, @section2.id.to_s)
            expect(result).not_to include(@section3.id.to_s)
          end
        end

        context "with regular assignment visibility overrides" do
          before do
            @regular_assignment = course.assignments.create!(
              title: "Regular Assignment",
              only_visible_to_overrides: true
            )
            @section3 = course.course_sections.create!(name: "Section 3")
            student_in_section(@section1)
            @regular_assignment.assignment_overrides.create!(set: @section1)
          end

          let(:regular_query) { "sectionsConnection(filter: { assignmentId: #{@regular_assignment.id} }) { edges { node { _id } } }" }

          it "still works correctly for regular assignments" do
            result = course_type.resolve(regular_query)
            expect(result).to contain_exactly(@section1.id.to_s)
            expect(result).not_to include(@section3.id.to_s)
          end
        end

        context "when feature flag is disabled" do
          before do
            course.disable_feature!(:peer_review_allocation_and_grading)
          end

          it "raises an error for peer review sub assignment" do
            expect { course_type.resolve(peer_review_query) }.to raise_error(/assignment not found/)
          end
        end
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

      @student1a1_submission = a1.grade_student(@student1, grade: 1, grader: @teacher).first
      @student1a2_submission = a2.grade_student(@student1, grade: 9, grader: @teacher).first
      @student2a1_submission = a1.grade_student(@student2, grade: 5, grader: @teacher).first

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

      describe "due_between" do
        it "accepts a full range" do
          @student2a1_submission.assignment.update(due_at: 3.days.ago)

          expect(
            course_type.resolve(<<~GQL, current_user: @teacher)
              submissionsConnection(
                filter: {
                  dueBetween: {
                    start: "#{1.week.ago.iso8601}",
                    end: "#{1.day.ago.iso8601}"
                  }
                }
              ) { nodes { _id } }
            GQL
          ).to include @student2a1_submission.id.to_s
        end

        it "does not include submissions out of the range" do
          @student2a1_submission.assignment.update(due_at: 8.days.ago)

          expect(
            course_type.resolve(<<~GQL, current_user: @teacher)
              submissionsConnection(
                filter: {
                  dueBetween: {
                    start: "#{1.week.ago.iso8601}",
                    end: "#{1.day.ago.iso8601}"
                  }
                }
              ) { nodes { _id } }
            GQL
          ).to_not include @student2a1_submission.id.to_s
        end

        it "accepts a start-open range" do
          @student2a1_submission.assignment.update(due_at: 3.days.ago)

          expect(
            course_type.resolve(<<~GQL, current_user: @teacher)
              submissionsConnection(
                filter: {
                  dueBetween: {
                    end: "#{1.day.ago.iso8601}"
                  }
                }
              ) { nodes { _id } }
            GQL
          ).to include @student2a1_submission.id.to_s
        end

        it "accepts a end-open range" do
          @student2a1_submission.assignment.update(due_at: 3.days.ago)

          expect(
            course_type.resolve(<<~GQL, current_user: @teacher)
              submissionsConnection(
                filter: {
                  dueBetween: {
                    start: "#{1.week.ago.iso8601}",
                  }
                }
              ) { nodes { _id } }
            GQL
          ).to include @student2a1_submission.id.to_s
        end
      end
    end

    context "with peer review sub assignments" do
      before(:once) do
        course.enable_feature!(:peer_review_allocation_and_grading)
        @parent_assignment = course.assignments.create!(
          title: "Parent Assignment",
          submission_types: "online_text_entry",
          points_possible: 100
        )
        @peer_review_sub_assignment = PeerReviewSubAssignment.create!(
          parent_assignment: @parent_assignment,
          title: "Peer Review",
          points_possible: 50
        )
        @parent_assignment.submit_homework(@student1, body: "Student 1 submission")
        @peer_review_submission = @peer_review_sub_assignment.grade_student(@student1, grade: 40, grader: @teacher).first
      end

      it "includes peer review sub assignment submissions when feature enabled and filter is true" do
        result = course_type.resolve(<<~GQL, current_user: @teacher)
          submissionsConnection(
            studentIds: ["#{@student1.id}"],
            filter: { includePeerReviewSubmissions: true },
            orderBy: [{field: _id, direction: ascending}]
          ) { edges { node { _id } } }
        GQL

        expect(result).to include(@peer_review_submission.id.to_s)
      end

      it "excludes peer review submissions when feature disabled" do
        course.disable_feature!(:peer_review_allocation_and_grading)

        result = course_type.resolve(<<~GQL, current_user: @teacher)
          submissionsConnection(
            studentIds: ["#{@student1.id}"],
            orderBy: [{field: _id, direction: ascending}]
          ) { edges { node { _id } } }
        GQL

        expect(result).not_to include(@peer_review_submission.id.to_s)
      end

      context "with include_peer_review_submissions filter" do
        it "excludes peer review submissions when filter is false" do
          result = course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              studentIds: ["#{@student1.id}"],
              filter: { includePeerReviewSubmissions: false }
            ) { edges { node { _id } } }
          GQL

          expect(result).not_to include(@peer_review_submission.id.to_s)
        end

        it "excludes peer review submissions when filter is not provided" do
          result = course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              studentIds: ["#{@student1.id}"]
            ) { edges { node { _id } } }
          GQL

          expect(result).not_to include(@peer_review_submission.id.to_s)
        end

        it "includes peer review submissions when filter is true and feature enabled" do
          result = course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              studentIds: ["#{@student1.id}"],
              filter: { includePeerReviewSubmissions: true }
            ) { edges { node { _id } } }
          GQL

          expect(result).to include(@peer_review_submission.id.to_s)
        end

        it "excludes peer review submissions when filter is true but feature disabled" do
          course.disable_feature!(:peer_review_allocation_and_grading)

          result = course_type.resolve(<<~GQL, current_user: @teacher)
            submissionsConnection(
              studentIds: ["#{@student1.id}"],
              filter: { includePeerReviewSubmissions: true }
            ) { edges { node { _id } } }
          GQL

          expect(result).not_to include(@peer_review_submission.id.to_s)
        end
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

      context "permissions" do
        it "returns nil for student without permissions" do
          @course.account.role_overrides.create!(permission: :read_roster, role: student_role, enabled: false)

          expect(
            course_type.resolve(
              "usersConnection { edges { node { _id } } }",
              current_user: @student1
            )
          ).to be_nil
        end

        it "returns nil for teacher without permissions" do
          @course.account.role_overrides.create!(permission: :read_roster, role: teacher_role, enabled: false)
          @course.account.role_overrides.create!(permission: :view_all_grades, role: teacher_role, enabled: false)
          @course.account.role_overrides.create!(permission: :manage_grades, role: teacher_role, enabled: false)

          expect(
            course_type.resolve(
              "usersConnection { edges { node { _id } } }",
              current_user: @teacher
            )
          ).to be_nil
        end

        it "returns user even without read_roster permission if only self is requested" do
          @course.account.role_overrides.create!(permission: :read_roster, role: student_role, enabled: false)

          student1_id_variations = [@student1.id, @student1.global_id]
          student1_id_variations.each do |id|
            expect(
              course_type.resolve(<<~GQL, current_user: @student1)
                usersConnection(filter: {userIds: ["#{id}"]}) { edges { node { _id } } }
              GQL
            ).to eq [@student1.to_param]
          end
        end

        it "returns nil for for user without read_roster permission if they request other users" do
          @course.account.role_overrides.create!(permission: :read_roster, role: student_role, enabled: false)

          expect(
            course_type.resolve(<<~GQL, current_user: @student1)
              usersConnection(filter: {userIds: ["#{@student1.id}", "#{@student2.id}"]}) { edges { node { _id } } }
            GQL
          ).to be_nil
        end
      end

      context "filtering" do
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

        context "enrollment role ids" do
          before(:once) do
            root_account_id = @course.root_account.id
            @student_role = Role.get_built_in_role("StudentEnrollment", root_account_id:)
            @ta_role = Role.get_built_in_role("TaEnrollment", root_account_id:)
            @teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id:)
            @ta = course_with_ta(course: @course, active_all: true).user
          end

          it "returns only users with the specified enrollment role ids" do
            result = course_type.resolve(<<~GQL, current_user: @teacher)
              usersConnection(filter: {enrollmentRoleIds: ["#{@student_role.id}"]}) { edges { node { _id } } }
            GQL
            expect(result).to match_array([@student1.id, @student2.id, @inactive_user.id].map(&:to_s))

            result = course_type.resolve(<<~GQL, current_user: @teacher)
              usersConnection(filter: {enrollmentRoleIds: ["#{@ta_role.id}"]}) { edges { node { _id } } }
            GQL
            expect(result).to match_array([@ta.id.to_s])
          end

          it "does not return users when enrollment role ids are invalid" do
            fake_role_id = (@teacher_role.id + 99_999).to_s
            result = course_type.resolve(<<~GQL, current_user: @teacher)
              usersConnection(filter: {enrollmentRoleIds: ["#{fake_role_id}"]}) { edges { node { _id } } }
            GQL
            expect(result).to be_empty
          end
        end

        context "test students" do
          before(:once) do
            @test_student = course.student_view_student
            @regular_student = student_in_course(active_all: true).user
          end

          it "includes test students by default" do
            result = course_type.resolve("usersConnection { edges { node { _id } } }", current_user: @teacher)
            expect(result).to include(@test_student.to_param, @regular_student.to_param)
          end

          it "excludes test students when exclude_test_students is true" do
            result = course_type.resolve(<<~GQL, current_user: @teacher)
              usersConnection(filter: {excludeTestStudents: true}) { edges { node { _id } } }
            GQL
            expect(result).not_to include(@test_student.to_param)
            expect(result).to include(@regular_student.to_param)
          end
        end
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

      context "search and sort" do
        before(:once) do
          @domain_root_account = Account.default
          @student_with_name = student_in_course(active_all: true).user
          @student_with_name.update!(name: "John Doe", sortable_name: "Doe, John")
          @student_with_email = student_in_course(active_all: true).user
          @student_with_email.update!(name: "Mary Smith", sortable_name: "Smith, Mary")
          @student_with_email.email = "a123@example.com"
          @student_with_email.save!
          @student_with_sis = student_in_course(active_all: true).user
          @student_with_sis.update(email: "b456@email.com", name: "Claire Anne", sortable_name: "Anne, Claire")
          @student_with_sis.pseudonyms.create!(
            account: Account.default,
            sis_user_id: "sis_123",
            unique_id: "uid_123"
          )
          @student_with_login = student_in_course(active_all: true).user
          @student_with_login.update(email: "c789@example.com", name: "Newman Bradley", sortable_name: "Bradley, Newman")
          @student_with_login.pseudonyms.create!(
            account: Account.default,
            sis_user_id: "sis_456",
            unique_id: "uid_456"
          )
          @student_with_email.pseudonyms.create!(
            account: Account.default,
            sis_user_id: "sis_789",
            unique_id: "uid_789"
          )
          @student_with_email.enrollments.first.update!(total_activity_time: 100)
          @student_with_sis.enrollments.first.update!(total_activity_time: 200)
          @student_with_login.enrollments.first.update!(total_activity_time: 300)
        end

        context "search" do
          it "filters users by search term matching name" do
            expect(
              course_type.resolve(<<~GQL, current_user: @teacher)
                usersConnection(filter: {searchTerm: "john"}) { edges { node { _id } } }
              GQL
            ).to eq [@student_with_name.to_param]
          end

          it "filters users by search term matching email when user has permissions" do
            expect(
              course_type.resolve(<<~GQL, current_user: @teacher)
                usersConnection(filter: {searchTerm: "a123@example.com"}) { edges { node { _id } } }
              GQL
            ).to eq [@student_with_email.to_param]
          end

          it "does not match email when user lacks permissions" do
            expect(
              course_type.resolve(<<~GQL, current_user: @student1)
                usersConnection(filter: {searchTerm: "a123@example.com"}) { edges { node { _id } } }
              GQL
            ).to be_empty
          end

          it "filters users by search term matching SIS ID when user has permissions" do
            expect(
              course_type.resolve(<<~GQL, current_user: @teacher)
                usersConnection(filter: {searchTerm: "sis_123"}) { edges { node { _id } } }
              GQL
            ).to eq [@student_with_sis.to_param]
          end

          it "does not match SIS ID when user lacks permissions" do
            expect(
              course_type.resolve(<<~GQL, current_user: @student1)
                usersConnection(filter: {searchTerm: "sis_123"}) { edges { node { _id } } }
              GQL
            ).to be_empty
          end

          it "filters users by search term matching login ID when user has permissions" do
            expect(
              course_type.resolve(<<~GQL, current_user: @teacher)
                usersConnection(filter: {searchTerm: "uid_456"}) { edges { node { _id } } }
              GQL
            ).to eq [@student_with_login.to_param]
          end

          it "does not match login ID when user lacks permissions" do
            expect(
              course_type.resolve(<<~GQL, current_user: @student1)
                usersConnection(filter: {searchTerm: "uid_456"}) { edges { node { _id } } }
              GQL
            ).to be_empty
          end

          it "returns empty when search term does not match users" do
            expect(
              course_type.resolve(<<~GQL, current_user: @teacher)
                usersConnection(filter: {searchTerm: "nonexistent"}) { edges { node { _id } } }
              GQL
            ).to be_empty
          end

          it "throws error if search term is too short" do
            result = CanvasSchema.execute(<<~GQL, context: { current_user: @teacher })
              query {
                course(id: "#{course.id}") {
                  usersConnection(filter: {searchTerm: "a"}) {
                    edges { node { _id } }
                  }
                }
              }
            GQL

            expect(result["errors"]).to be_present
            expect(result["errors"][0]["message"]).to match(/at least 2 characters/)
          end

          it "ignores search term if empty string" do
            expect(
              course_type.resolve(<<~GQL, current_user: @teacher)
                usersConnection(filter: {searchTerm: ""}) { edges { node { _id } } }
              GQL
            ).to match_array([
              @teacher,
              @student1,
              other_teacher,
              @student2,
              @inactive_user,
              @student_with_name,
              @student_with_email,
              @student_with_sis,
              @student_with_login
            ].map(&:to_param))
          end
        end

        context "sort" do
          before :once do
            @sorted_by_name_asc = [@student_with_sis, @student_with_name, @student_with_email].map(&:name)
            @sorted_by_sis_id_asc = [@student_with_sis, @student_with_login, @student_with_email].map { |u| u.pseudonyms.first.sis_user_id }
            @sorted_by_login_id_asc = [@student_with_sis, @student_with_login, @student_with_email].map { |u| u.pseudonyms.first.unique_id }
            @sorted_by_total_activity_time_asc = [@student_with_email, @student_with_sis, @student_with_login].map { |u| u.enrollments.first.total_activity_time }
          end

          def get_sorted_results(field, direction, result = "_id")
            course_type.resolve(
              "usersConnection(sort: {field: #{field}, direction: #{direction}}) { edges { node { #{result} } } }",
              current_user: @teacher,
              domain_root_account: @domain_root_account
            )
          end

          context "name" do
            it "sorts by name ascending" do
              expect(get_sorted_results(:name, :asc, "name")[0..2]).to eq @sorted_by_name_asc
            end

            it "sorts by name descending" do
              expect(get_sorted_results(:name, :desc, "name")[-3..]).to eq @sorted_by_name_asc.reverse
            end
          end

          context "sis_id" do
            it "sorts by SIS ID ascending" do
              expect(get_sorted_results(:sis_id, :asc, "sisId")[0..2]).to eq @sorted_by_sis_id_asc
            end

            it "sorts by SIS ID descending" do
              expect(get_sorted_results(:sis_id, :desc, "sisId")[0..2]).to eq @sorted_by_sis_id_asc.reverse
            end
          end

          context "login_id" do
            it "sorts by login_id ascending" do
              expect(get_sorted_results(:login_id, :asc, "loginId")[0..2]).to eq @sorted_by_login_id_asc
            end

            it "sorts by login_id descending" do
              expect(get_sorted_results(:login_id, :desc, "loginId")[0..2]).to eq @sorted_by_login_id_asc.reverse
            end
          end

          context "total_activity_time" do
            it "sorts by total_activity_time ascending" do
              expect(get_sorted_results(:total_activity_time, :asc, "enrollments { totalActivityTime }")[0..2].flatten).to eq @sorted_by_total_activity_time_asc
            end

            it "sorts by total_activity_time descending" do
              expect(get_sorted_results(:total_activity_time, :desc, "enrollments { totalActivityTime }")[0..2].flatten).to eq @sorted_by_total_activity_time_asc.reverse
            end
          end
        end
      end

      describe "users_connection_count" do
        before(:once) do
          @course = course_factory
          @teacher = @course.enroll_teacher(user_factory, enrollment_state: "active").user
          @student1 = @course.enroll_student(user_factory, enrollment_state: "active").user
          @student2 = @course.enroll_student(user_factory, enrollment_state: "active").user
          @student3 = @course.enroll_student(user_factory(name: "Searchable Student"), enrollment_state: "active").user
          @inactive_student = @course.enroll_student(user_factory, enrollment_state: "inactive").user
          @test_student = @course.student_view_student
        end

        let(:course_type) { GraphQLTypeTester.new(@course, current_user: @teacher) }

        it "counts all course users" do
          users = course_type.resolve("usersConnection { edges { node { _id } } }")
          count = course_type.resolve("usersConnectionCount")
          expect(users.size).to eq count
          # All active students + teacher + test student + inactive student
          expect(count).to eq 6
        end

        it "counts users filtered by user_ids with legacy parameter" do
          users = course_type.resolve("usersConnection(userIds: [#{@student1.id}, #{@student2.id}]) { edges { node { _id } } }")
          count = course_type.resolve("usersConnectionCount(userIds: [#{@student1.id}, #{@student2.id}])")
          expect(users.size).to eq count
          expect(count).to eq 2
        end

        it "counts users filtered by user_ids with filter parameter" do
          users = course_type.resolve("usersConnection(filter: {userIds: [#{@student1.id}, #{@student2.id}]}) { edges { node { _id } } }")
          count = course_type.resolve("usersConnectionCount(filter: {userIds: [#{@student1.id}, #{@student2.id}]})")
          expect(users.size).to eq count
          expect(count).to eq 2
        end

        it "counts users filtered by search_term" do
          users = course_type.resolve('usersConnection(filter: {searchTerm: "Searchable"}) { edges { node { _id } } }')
          count = course_type.resolve('usersConnectionCount(filter: {searchTerm: "Searchable"})')
          expect(users.size).to eq count
          expect(count).to eq 1
        end

        it "counts users filtered by enrollment_states" do
          users = course_type.resolve("usersConnection(filter: {enrollmentStates: [inactive]}) { edges { node { _id } } }")
          count = course_type.resolve("usersConnectionCount(filter: {enrollmentStates: [inactive]})")
          expect(users.size).to eq count
          expect(count).to eq 1
        end

        it "counts users filtered by enrollment_types" do
          users = course_type.resolve("usersConnection(filter: {enrollmentTypes: [TeacherEnrollment]}) { edges { node { _id } } }")
          count = course_type.resolve("usersConnectionCount(filter: {enrollmentTypes: [TeacherEnrollment]})")
          expect(users.size).to eq count
          expect(count).to eq 1
        end

        it "excludes from count test students when requested" do
          users = course_type.resolve("usersConnection(filter: {excludeTestStudents: true}) { edges { node { _id } } }")
          count = course_type.resolve("usersConnectionCount(filter: {excludeTestStudents: true})")
          expect(users.size).to eq count
          expect(count).to eq 5 # All users except test student
        end

        it "requires appropriate permissions to return count" do
          other_user = user_factory
          resolver = GraphQLTypeTester.new(@course, current_user: other_user)
          users = resolver.resolve("usersConnection { edges { node { _id } } }")
          count = resolver.resolve("usersConnectionCount")
          expect(users).to be_nil
          expect(count).to be_nil
        end

        it "counts users filtered by multiple filters" do
          users_with_multiple_filters = <<~GQL
            usersConnection(
              filter: {
                enrollmentTypes: [StudentEnrollment]
                enrollmentStates: [active]
                excludeTestStudents: true
              }
            ){ edges { node { _id } } }
          GQL
          count_with_multiple_filters = <<~GQL
            usersConnectionCount(
              filter: {
                enrollmentTypes: [StudentEnrollment]
                enrollmentStates: [active]
                excludeTestStudents: true
              }
            )
          GQL
          users = course_type.resolve(users_with_multiple_filters)
          count = course_type.resolve(count_with_multiple_filters)
          expect(users.size).to eq count
          expect(count).to eq 3 # Three active students
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
        expect(Time.iso8601(student_last_activity.first)).to be_within(1.second)
          .of(@student1.enrollments.first.last_activity_at)
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
        expected_total_activity_time = [nil, 0, nil, nil, nil, nil]

        result_total_activity_time = course_type.resolve(
          "enrollmentsConnection { nodes { totalActivityTime } }",
          current_user: @student1
        )

        expect(result_total_activity_time).to match_array(expected_total_activity_time)
      end

      it "returns the sisRole of each user" do
        expected_sis_roles = %w[teacher student teacher student student student]

        result_sis_roles = course_type.resolve(
          "enrollmentsConnection { nodes { sisRole } }",
          current_user: @teacher
        )

        expect(result_sis_roles).to match_array(expected_sis_roles)
      end

      it "returns an htmlUrl for each enrollment" do
        expected_urls = [@teacher, @student1, other_teacher, @student2, @inactive_user, @concluded_user]
                        .map { |user| "http://test.host/courses/#{@course.id}/users/#{user.id}" }

        result_urls = course_type.resolve(
          "enrollmentsConnection { nodes { htmlUrl } }",
          current_user: @teacher,
          request: ActionDispatch::TestRequest.create
        )

        expect(result_urls).to match_array(expected_urls)
      end

      it "returns canBeRemoved boolean value for each enrollment" do
        expected_can_be_removed = [false, true, true, true, true, true]

        result_can_be_removed = course_type.resolve(
          "enrollmentsConnection { nodes { canBeRemoved } }",
          current_user: @teacher
        )

        expect(result_can_be_removed).to match_array(expected_can_be_removed)
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

        it "returns only enrollments with the specified user_ids if included" do
          student_1 = course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user
          student_2 = course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user
          course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user

          expect(
            course_type.resolve(
              "enrollmentsConnection(filter: {userIds: [#{student_1.id}, #{student_2.id}]}) { nodes { _id } }",
              current_user: @teacher
            )
          ).to eq [student_1.enrollments.first.id.to_s, student_2.enrollments.first.id.to_s]
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
      ag2 = course.assignment_groups.create!(name: "another group")
      ag2.destroy
      expect(
        course_type.resolve("assignmentGroupsConnection { edges { node { _id } } }")
      ).to eq [ag.to_param]
    end
  end

  describe "GroupsConnection" do
    before(:once) do
      @cg = course.groups.create! name: "A Group"
      ncc = course.group_categories.create! name: "Non-Collaborative Category", non_collaborative: true
      @ncg = course.groups.create! name: "Non-Collaborative Group", non_collaborative: true, group_category: ncc
    end

    it "returns student groups" do
      expect(
        course_type.resolve("groupsConnection { edges { node { _id } } }")
      ).to eq [@cg.to_param]
    end

    context "differentiation_tags" do
      before :once do
        Account.default.settings[:allow_assign_to_differentiation_tags] = { value: true }
        Account.default.save!
        Account.default.reload
        @teacher = course.enroll_teacher(user_factory, section: other_section, limit_privileges_to_course_section: false).user
      end

      it "returns combined student groups and non-collaborative groups for users with sufficient permission" do
        RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS.each do |permission|
          course.account.role_overrides.create!(
            permission:,
            role: teacher_role,
            enabled: true
          )
        end

        tester = GraphQLTypeTester.new(course, current_user: @teacher)
        res = tester.resolve("groupsConnection(includeNonCollaborative: true) { edges { node { _id } } }")
        expect(res).to match_array([@cg.id.to_param, @ncg.id.to_param])
      end

      it "returns only collaborative groups if includeNonCollaborative is not provided" do
        RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS.each do |permission|
          course.account.role_overrides.create!(
            permission:,
            role: teacher_role,
            enabled: true
          )
        end

        tester = GraphQLTypeTester.new(course, current_user: @teacher)
        res = tester.resolve("groupsConnection { edges { node { _id } } }")
        expect(res).to match_array([@cg.id.to_param])
      end

      it "returns only collaborative groups if the user does not have sufficient permissions" do
        # course_type is student, keep in mind, the setting differentiation_tags is enabled
        expect(
          course_type.resolve("groupsConnection(includeNonCollaborative: true) { edges { node { _id } } }")
        ).to eq [@cg.to_param]
      end
    end
  end

  describe "groupSetsConnection" do
    before(:once) do
      @teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
      @project_groups = course.group_categories.create! name: "Project Groups"
      @student_groups = GroupCategory.student_organized_for(course)
      @non_collaborative_groups = course.group_categories.create! name: "NC Groups", non_collaborative: true
    end

    it "returns project group sets (not student_organized, not non_collaborative) when not asked for" do
      expect(
        course_type.resolve("groupSetsConnection { edges { node { _id } } }",
                            current_user: @teacher)
      ).to eq [@project_groups.id.to_s]
    end

    it "includes non_collaborative group sets when asked for by someone with permissions" do
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload
      RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS.each do |permission|
        @course.account.role_overrides.create!(
          permission:,
          role: @teacher_role,
          enabled: true
        )
      end

      expect(
        course_type.resolve("groupSetsConnection(includeNonCollaborative: true) { edges { node { _id } } }",
                            current_user: @teacher)
      ).to match_array [@project_groups.id.to_s, @non_collaborative_groups.id.to_s]
    end

    it "does not include non_collaborative group sets when asked for by someone without permissions" do
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload
      RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS.each do |permission|
        @course.account.role_overrides.create!(
          permission:,
          role: @teacher_role,
          enabled: false
        )
      end
      expect(
        course_type.resolve("groupSetsConnection { edges { node { _id } } }",
                            current_user: @teacher)
      ).to eq [@project_groups.id.to_s]
    end
  end

  describe "groupSets" do
    before(:once) do
      @teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
      @project_groups = course.group_categories.create! name: "Project Groups"
      @student_groups = GroupCategory.student_organized_for(course)
      @non_collaborative_groups = course.group_categories.create! name: "NC Groups", non_collaborative: true
    end

    it "returns project group sets (not student_organized, not non_collaborative) when not asked for" do
      expect(
        course_type.resolve("groupSets { _id}",
                            current_user: @teacher)
      ).to eq [@project_groups.id.to_s]
    end

    it "includes non_collaborative group sets when asked for by someone with permissions" do
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload
      RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS.each do |permission|
        @course.account.role_overrides.create!(
          permission:,
          role: @teacher_role,
          enabled: true
        )
      end

      expect(
        course_type.resolve("groupSets(includeNonCollaborative: true) { _id }",
                            current_user: @teacher)
      ).to match_array [@project_groups.id.to_s, @non_collaborative_groups.id.to_s]
    end

    it "excludes non_collaborative group sets when asked for by someone without permissions" do
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
      @course.account.reload
      RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS.each do |permission|
        @course.account.role_overrides.create!(
          permission:,
          role: @teacher_role,
          enabled: false
        )
      end

      expect(
        course_type.resolve("groupSets(includeNonCollaborative: true) { _id }",
                            current_user: @teacher)
      ).to match_array [@project_groups.id.to_s]
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
      deleted_rubric_for_course
      rubric_association_model(context: course, rubric: @rubric, association_object: course, purpose: "bookmark")
      rubric_association_model(context: course, rubric: @deleted_rubric, association_object: course, purpose: "bookmark")
    end

    it "returns rubrics" do
      expect(
        course_type.resolve("rubricsConnection { edges { node { _id } } }")
      ).to eq [course.rubrics.first.to_param]
    end

    it "returns only active rubrics, excluding those with workflow_state 'deleted'" do
      rubrics = course_type.resolve("rubricsConnection { edges { node { _id workflowState } } }")

      expect(rubrics).to match_array(["active"])
    end
  end

  describe "ActivityStream" do
    it "return activity stream summaries" do
      cur_course = Course.create!
      new_teacher = User.create!
      cur_course.enroll_teacher(new_teacher).accept
      cur_course.announcements.create! title: "hear ye!", message: "wat"
      cur_course.discussion_topics.create!
      cur_resolver = GraphQLTypeTester.new(cur_course, current_user: new_teacher)
      expect(cur_resolver.resolve("activityStream { summary { type } } ")).to match_array ["DiscussionTopic", "Announcement"]
      expect(cur_resolver.resolve("activityStream { summary { count } } ")).to match_array [1, 1]
      expect(cur_resolver.resolve("activityStream { summary { unreadCount } } ")).to match_array [1, 1]
      expect(cur_resolver.resolve("activityStream { summary { notificationCategory } } ")).to match_array [nil, nil]
    end
  end

  describe "submissionStatistics" do
    let(:now) { Time.zone.now }

    context "when user doesn't have read permission" do
      it "returns null" do
        other_student = user_factory
        expect(course_type.resolve("submissionStatistics { submissionsDueThisWeekCount }", current_user: other_student)).to be_nil
      end
    end

    context "when user has read permission" do
      describe "submissionsDueThisWeekCount" do
        it "counts submissions with due dates within the next 7 days" do
          Timecop.freeze(now) do
            # Set up a submission due within this week
            assignment = course.assignments.create!(
              title: "Assignment due this week",
              workflow_state: "published",
              submission_types: "online_text_entry"
            )
            submission = assignment.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now + 2.days)

            expect(course_type.resolve("submissionStatistics { submissionsDueThisWeekCount }")).to eq 1
          end
        end

        it "excludes submissions due beyond this week" do
          Timecop.freeze(now) do
            # Set up a submission due far in the future
            assignment = course.assignments.create!(
              title: "Future assignment",
              workflow_state: "published",
              submission_types: "online_text_entry"
            )
            submission = assignment.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now + 10.days)

            expect(course_type.resolve("submissionStatistics { submissionsDueThisWeekCount }")).to eq 0
          end
        end

        it "excludes submissions from unpublished assignments" do
          Timecop.freeze(now) do
            # Set up a submission for an unpublished assignment
            assignment = course.assignments.create!(
              title: "Unpublished assignment",
              workflow_state: "unpublished",
              submission_types: "online_text_entry"
            )
            submission = assignment.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now + 2.days)

            expect(course_type.resolve("submissionStatistics { submissionsDueThisWeekCount }")).to eq 0
          end
        end

        context "when the submission is coming from graded discussion assignment" do
          let(:assignment_for_graded_discussion) do
            course.assignments.create!(title: "Assignment for graded discussion", workflow_state: "published", submission_types: ["online_text_entry"])
          end

          let(:graded_discussion) do
            course.discussion_topics.create!(message: "hi", title: "title", assignment: assignment_for_graded_discussion)
          end

          it "should use it in the calculation" do
            Timecop.freeze(now) do
              submission = graded_discussion.assignment.submissions.find_by(user_id: @student.id)
              submission.update!(cached_due_date: now + 2.days)

              expect(course_type.resolve("submissionStatistics { submissionsDueThisWeekCount }")).to eq 1
            end
          end
        end

        context "when the submission is coming from checkpoint discussion assignment" do
          let(:assignment_for_checkpoint_discussion) do
            parent_assignment = course.assignments.create!(has_sub_assignments: true, title: "Parent Assignment", workflow_state: "published")
            parent_assignment.sub_assignments.create!(
              context: course,
              sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
              title: "Sub Assignment 1",
              workflow_state: "published",
              submission_types: "discussion_topic"
            )
            parent_assignment
          end

          let(:checkpoint_discussion) do
            course.discussion_topics.create!(message: "hi", title: "discussion title", assignment: assignment_for_checkpoint_discussion)
          end

          it "should use it in the calculation" do
            Timecop.freeze(now) do
              sub_assignments = assignment_for_checkpoint_discussion.sub_assignments
              submission = sub_assignments.first.submissions.find_by(user_id: @student.id)
              submission.update!(cached_due_date: now + 2.days)

              expect(course_type.resolve("submissionStatistics { submissionsDueThisWeekCount }")).to eq 1
            end
          end
        end

        context "when the submission is coming from classic quiz assignment" do
          let(:assignment_for_classic_quiz) do
            course.assignments.create!(title: "Assignment for classic quiz", workflow_state: "published", submission_types: ["online_text_entry"])
          end

          let(:classic_quiz_with_assignment) do
            course.quizzes.create!(title: "classic_quiz_with_assignment", assignment: assignment_for_classic_quiz)
          end

          it "should use it in the calculation" do
            Timecop.freeze(now) do
              submission = classic_quiz_with_assignment.assignment.submissions.find_by(user_id: @student.id)
              submission.update!(cached_due_date: now + 2.days)

              expect(course_type.resolve("submissionStatistics { submissionsDueThisWeekCount }")).to eq 1
            end
          end
        end
      end

      describe "missingSubmissionsCount" do
        # Create a fresh course and enrollment for each test to ensure isolation
        let(:isolated_course_with_student) do
          course_with_student(active_all: true)
          @course
        end

        let(:isolated_course_type) do
          GraphQLTypeTester.new(isolated_course_with_student, current_user: @student)
        end

        it "counts past-due submissions that aren't submitted" do
          course = isolated_course_with_student
          Timecop.freeze(now) do
            # Set up a past-due submission
            assignment = course.assignments.create!(
              title: "Past due assignment",
              workflow_state: "published",
              submission_types: "online_text_entry"
            )
            submission = assignment.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now - 2.days)

            expect(isolated_course_type.resolve("submissionStatistics { missingSubmissionsCount }")).to eq 1
          end
        end

        it "excludes submissions due in the future" do
          course = isolated_course_with_student
          Timecop.freeze(now) do
            # Set up a submission due far in the future
            assignment = course.assignments.create!(
              title: "Future assignment",
              workflow_state: "published",
              submission_types: "online_text_entry"
            )
            submission = assignment.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now + 10.days)

            expect(isolated_course_type.resolve("submissionStatistics { missingSubmissionsCount }")).to eq 0
          end
        end

        it "counts submissions explicitly marked as missing" do
          course = isolated_course_with_student
          Timecop.freeze(now) do
            # Set up a submission marked as missing
            assignment = course.assignments.create!(
              title: "Assignment marked missing",
              workflow_state: "published",
              submission_types: "online_text_entry"
            )
            submission = assignment.submissions.find_by(user_id: @student.id)
            submission.update!(late_policy_status: "missing")

            expect(isolated_course_type.resolve("submissionStatistics { missingSubmissionsCount }")).to eq 1
          end
        end

        it "excludes submitted submissions" do
          Timecop.freeze(now) do
            # Set up a past-due but submitted submission
            assignment = course.assignments.create!(
              title: "Submitted assignment",
              workflow_state: "published",
              submission_types: "online_text_entry"
            )
            submission = assignment.submissions.find_by(user_id: @student.id)
            submission.update!(
              cached_due_date: now - 2.days,
              submission_type: "online_text_entry",
              workflow_state: "submitted"
            )

            expect(course_type.resolve("submissionStatistics { missingSubmissionsCount }")).to eq 0
          end
        end

        context "when the submission is coming from graded discussion assignment" do
          let(:assignment_for_graded_discussion) do
            course.assignments.create!(title: "Assignment for graded discussion", workflow_state: "published", submission_types: ["online_text_entry"])
          end

          let(:graded_discussion) do
            course.discussion_topics.create!(message: "hi", title: "title", assignment: assignment_for_graded_discussion)
          end

          it "should use it in the calculation" do
            Timecop.freeze(now) do
              submission = graded_discussion.assignment.submissions.find_by(user_id: @student.id)
              submission.update!(cached_due_date: now - 1.day)

              expect(course_type.resolve("submissionStatistics { missingSubmissionsCount }")).to eq 1
            end
          end
        end

        context "when the submission is coming from checkpoint discussion assignment" do
          let(:assignment_for_checkpoint_discussion) do
            parent_assignment = course.assignments.create!(has_sub_assignments: true, title: "Parent Assignment", workflow_state: "published")
            parent_assignment.sub_assignments.create!(
              context: course,
              sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
              title: "Sub Assignment 1",
              workflow_state: "published",
              submission_types: "discussion_topic"
            )
            parent_assignment
          end

          let(:checkpoint_discussion) do
            course.discussion_topics.create!(message: "hi", title: "discussion title", assignment: assignment_for_checkpoint_discussion)
          end

          it "should use it in the calculation" do
            Timecop.freeze(now) do
              sub_assignments = assignment_for_checkpoint_discussion.sub_assignments
              submission = sub_assignments.first.submissions.find_by(user_id: @student.id)
              submission.update!(cached_due_date: now - 1.day)

              expect(course_type.resolve("submissionStatistics { missingSubmissionsCount }")).to eq 1
            end
          end
        end

        context "when the submission is coming from classic quiz assignment" do
          let(:assignment_for_classic_quiz) do
            course.assignments.create!(title: "Assignment for classic quiz", workflow_state: "published", submission_types: ["online_text_entry"])
          end

          let(:classic_quiz_with_assignment) do
            course.quizzes.create!(title: "classic_quiz_with_assignment", assignment: assignment_for_classic_quiz)
          end

          it "should use it in the calculation" do
            Timecop.freeze(now) do
              submission = classic_quiz_with_assignment.assignment.submissions.find_by(user_id: @student.id)
              submission.update!(cached_due_date: now - 1.day)

              expect(course_type.resolve("submissionStatistics { missingSubmissionsCount }")).to eq 1
            end
          end
        end
      end
    end
  end

  describe "moderators" do
    def execute_query(pagination_options: {}, user: @teacher)
      options_string = pagination_options.empty? ? "" : "(#{pagination_options.map { |key, value| "#{key}: #{value.inspect}" }.join(", ")})"
      CanvasSchema.execute(<<~GQL, context: { current_user: user }).dig("data", "course")
        query {
          course(id: #{course.id}) {
            availableModerators#{options_string} {
              edges {
                node {
                  _id
                  name
                }
              }
              pageInfo {
                hasNextPage
                endCursor
              }
            }
            availableModeratorsCount
          }
        }
      GQL
    end

    before(:once) do
      @ta = User.create!
      course.enroll_ta(@ta, enrollment_state: :active)
    end

    context "when user has permissions to manage assignments" do
      it "returns availableModerators and availableModeratorsCount" do
        result = execute_query

        expect(result["availableModerators"]["edges"]).to match_array [
          { "node" => { "_id" => @teacher.id.to_s, "name" => @teacher.name } },
          { "node" => { "_id" => @ta.id.to_s, "name" => @ta.name } },
        ]

        expect(result["availableModeratorsCount"]).to eq 2
      end

      it "paginate available moderators" do
        result = execute_query(pagination_options: { first: 1 })
        expect(result["availableModerators"]["edges"].length).to eq 1
        expect(result["availableModerators"]["pageInfo"]["hasNextPage"]).to be true

        end_cursor = result["availableModerators"]["pageInfo"]["endCursor"]
        result = execute_query(pagination_options: { first: 1, after: end_cursor })
        expect(result["availableModerators"]["edges"].length).to eq 1
        expect(result["availableModerators"]["pageInfo"]["hasNextPage"]).to be false
      end
    end

    context "when user does not have permissions to manage assignments" do
      it "returns nil" do
        result = execute_query(user: @student)
        expect(result["availableModerators"]).to be_nil
        expect(result["availableModeratorsCount"]).to be_nil
      end
    end
  end

  describe "modules_connection with filters" do
    let(:course) { @course }
    let(:student) { @student }
    let(:teacher) { @teacher }

    def execute_with_context(query, user)
      CanvasSchema.execute(query, context: { current_user: user })
    end

    before :once do
      # Create modules with different completion states
      @completed_module = @course.context_modules.create!(name: "Completed Module")
      @started_module = @course.context_modules.create!(name: "Started Module")
      @unlocked_module = @course.context_modules.create!(name: "Unlocked Module")
      @no_progression_module = @course.context_modules.create!(name: "No Progression Module")

      # Create progressions for student and ensure they're persisted
      completed_progression = @completed_module.context_module_progressions.create!(
        user: @student,
        workflow_state: "completed"
      )
      started_progression = @started_module.context_module_progressions.create!(
        user: @student,
        workflow_state: "started"
      )
      unlocked_progression = @unlocked_module.context_module_progressions.create!(
        user: @student,
        workflow_state: "unlocked"
      )

      # Ensure all progressions are committed to the database before tests run
      [completed_progression, started_progression, unlocked_progression].each(&:reload)
    end

    context "filtering by completion status" do
      def modules_query(completion_status, user_id = nil)
        <<~GQL
          query {
            course(id: "#{@course.id}") {
              modulesConnection(filter: {
                completionStatus: #{completion_status}
                #{", userId: \"#{user_id}\"" if user_id}
              }) {
                nodes {
                  _id
                  name
                  progression {
                    workflowState
                  }
                }
              }
            }
          }
        GQL
      end

      def fetch_modules_from_result(result)
        result.dig("data", "course", "modulesConnection", "nodes")
      end

      context "as a student" do
        it "returns completed modules" do
          result = execute_with_context(modules_query("COMPLETED"), student)
          modules = fetch_modules_from_result(result)

          expect(modules.length).to eq(1)
          expect(modules[0]["name"]).to eq("Completed Module")
        end

        it "returns incomplete modules" do
          result = execute_with_context(modules_query("INCOMPLETE"), student)
          modules = fetch_modules_from_result(result)

          expect(modules.length).to eq(3)
          module_names = modules.pluck("name")
          expect(module_names).to contain_exactly("Started Module", "Unlocked Module", "No Progression Module")
        end

        it "returns in progress modules" do
          result = execute_with_context(modules_query("IN_PROGRESS"), student)
          modules = fetch_modules_from_result(result)

          expect(modules.length).to eq(1)
          expect(modules[0]["name"]).to eq("Started Module")
        end

        it "returns not started modules" do
          result = execute_with_context(modules_query("NOT_STARTED"), student)
          modules = fetch_modules_from_result(result)

          expect(modules.length).to eq(2)
          module_names = modules.pluck("name")
          expect(module_names).to contain_exactly("Unlocked Module", "No Progression Module")
        end

        it "returns error when trying to view another user's progress" do
          other_student = user_factory(active_all: true)
          @course.enroll_student(other_student, enrollment_state: "active")

          # Ensure they're different users
          expect(student.id).not_to eq(other_student.id)

          result = execute_with_context(modules_query("COMPLETED", other_student.id), student)

          expect(result["errors"]).to be_present
          expect(result["errors"][0]["message"]).to eq("Not authorized to view this user's module progress")
        end
      end

      context "as a teacher" do
        it "can view student's completed modules" do
          result = execute_with_context(modules_query("COMPLETED", student.id), teacher)
          modules = fetch_modules_from_result(result)

          expect(modules.length).to eq(1)
          expect(modules[0]["name"]).to eq("Completed Module")
        end

        it "defaults to teacher's own progress when no user_id specified" do
          # Teacher has no progressions, so should return no completed modules
          result = execute_with_context(modules_query("COMPLETED"), teacher)
          modules = fetch_modules_from_result(result)

          expect(modules).to be_empty
        end
      end

      context "filtering performance" do
        it "uses efficient filtering at database level for completion status" do
          # Create many modules and ensure progressions are persisted
          progressions = []
          10.times do |i|
            mod = @course.context_modules.create!(name: "Module #{i}")
            progressions << mod.context_module_progressions.create!(
              user: student,
              workflow_state: i.even? ? "completed" : "started"
            )
          end

          # Ensure all progressions are committed to the database before testing
          progressions.each(&:reload)

          # The filter uses a JOIN which is expected for database-level filtering
          result = execute_with_context(modules_query("COMPLETED"), student)
          modules = fetch_modules_from_result(result)

          # Should return only completed modules
          expect(modules.length).to eq(6) # 1 original + 5 even-numbered new ones
          expect(modules.all? { |m| m.dig("progression", "workflowState") == "completed" }).to be true
        end
      end

      context "as an unauthenticated user (public course)" do
        before do
          @course.update!(is_public: true)
        end

        it "returns all modules for incomplete filter" do
          result = execute_with_context(modules_query("INCOMPLETE"), nil)
          modules = fetch_modules_from_result(result)

          expect(modules.length).to eq(4)
          module_names = modules.pluck("name")
          expect(module_names).to contain_exactly(
            "Completed Module",
            "Started Module",
            "Unlocked Module",
            "No Progression Module"
          )
        end

        it "returns no modules for completed filter" do
          result = execute_with_context(modules_query("COMPLETED"), nil)
          modules = fetch_modules_from_result(result)

          expect(modules).to be_empty
        end

        it "returns no modules for in_progress filter" do
          result = execute_with_context(modules_query("IN_PROGRESS"), nil)
          modules = fetch_modules_from_result(result)

          expect(modules).to be_empty
        end

        it "returns no modules for not_started filter" do
          result = execute_with_context(modules_query("NOT_STARTED"), nil)
          modules = fetch_modules_from_result(result)

          expect(modules).to be_empty
        end

        it "cannot specify a user_id when unauthenticated" do
          result = execute_with_context(modules_query("COMPLETED", student.id), nil)

          expect(result["errors"]).to be_present
          expect(result["errors"][0]["message"]).to eq("Authentication required to view other users' module progress")
        end
      end
    end
  end

  describe "submission_statistics with observed_user_id" do
    before do
      course_with_teacher(active_all: true)

      @observer = user_factory(name: "Observer")
      @observed_student = user_factory(name: "Observed Student")

      @course.enroll_student(@observed_student, active_all: true)
      @course.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @observed_student.id, active_all: true)

      @assignment = @course.assignments.create!(
        title: "Test Assignment",
        points_possible: 10,
        workflow_state: "published",
        submission_types: "online_text_entry",
        due_at: 1.day.from_now
      )

      # Create unsubmitted submission for observed student
      @observed_submission = @assignment.submissions.find_by(user: @observed_student)
      @observed_submission.update!(cached_due_date: 1.day.from_now)
    end

    context "as observer with observed_user_id" do
      let(:observer_type) { GraphQLTypeTester.new(@course, current_user: @observer) }

      it "returns statistics for the specified observed user" do
        due_count = observer_type.resolve(<<~GQL)
          submissionStatistics(observedUserId: "#{@observed_student.id}") {
            submissionsDueCount(startDate: "#{1.week.ago.iso8601}", endDate: "#{1.week.from_now.iso8601}")
          }
        GQL

        submitted_count = observer_type.resolve(<<~GQL)
          submissionStatistics(observedUserId: "#{@observed_student.id}") {
            submissionsSubmittedCount
          }
        GQL

        expect(due_count).to eq(1)
        expect(submitted_count).to eq(0)
      end

      it "returns nil when observed_user_id is provided but user is not an observer in this course" do
        # Enroll observer as student in another course
        other_course = course_factory
        other_course.enroll_student(@observer, enrollment_state: "active")
        other_course_type = GraphQLTypeTester.new(other_course, current_user: @observer)

        result = other_course_type.resolve(<<~GQL)
          submissionStatistics(observedUserId: "#{@observed_student.id}") {
            submissionsDueCount(startDate: "#{1.week.ago.iso8601}", endDate: "#{1.week.from_now.iso8601}")
          }
        GQL

        expect(result).to be_nil
      end
    end
  end

  describe "External Tools Connection" do
    include_context "lti_1_3_tool_configuration_spec_helper"

    let_once(:developer_key) do
      dk = lti_developer_key_model(account: course.root_account)
      dk.developer_key_account_bindings.first.update! workflow_state: "on"
      dk
    end

    let_once(:tool_json_definitions) do
      [
        {
          name: "Tool 1",
          url: "https://example.com/tool1",
          workflow_state: "public",
          lti_version: "1.3",
          not_selectable: false,
          placement_type: "link_selection"
        },
        {
          name: "Tool 2",
          url: "https://example.com/tool2",
          workflow_state: "public",
          lti_version: "1.3",
          not_selectable: false,
          placement_type: "homework_submission"
        },
        {
          name: "Tool 3",
          url: "https://example.com/tool2",
          workflow_state: "email_only",
          lti_version: "1.3",
          not_selectable: false,
          placement_type: "resource_selection"
        },
        {
          name: "Tool 4",
          url: "https://example.com/tool4",
          workflow_state: "email_only",
          lti_version: "1.1",
          not_selectable: false,
          placement_type: "homework_submission"
        },
        {
          name: "Tool 5",
          url: "https://example.com/tool5",
          workflow_state: "email_only",
          lti_version: "1.1",
          not_selectable: true,
          placement_type: "homework_submission"
        }
      ]
    end

    def create_tool(tool_json_definition)
      tool = course.context_external_tools.create!(
        name: tool_json_definition[:name],
        shared_secret: "test_secret",
        developer_key:,
        consumer_key: "test_key",
        domain: "example.com",
        not_selectable: tool_json_definition[:not_selectable],
        url: tool_json_definition[:url],
        workflow_state: tool_json_definition[:workflow_state],
        lti_version: tool_json_definition[:lti_version]
      )
      tool.context_external_tool_placements.create(placement_type: tool_json_definition[:placement_type])

      control = tool.context_controls.new(registration: tool.developer_key.lti_registration, available: true)
      control.course = course
      control.save!
      tool
    end

    before(:once) do
      @teacher = course.enroll_teacher(user_factory).user

      tool_json_definitions.each do |tool_json_definition|
        create_tool(tool_json_definition)
      end
    end

    before do
      user_session(@teacher)
    end

    it "no placement filter for external tools" do
      result_array = tool_json_definitions.pluck(:name)

      expect(
        course_type.resolve(<<~GQL, current_user: @teacher)
          externalToolsConnection { edges { node { name } } }
        GQL
      ).to match_array result_array
    end

    it "placement filter for external tools" do
      result_array = tool_json_definitions.select { |tool| tool[:placement_type] == "homework_submission" }.pluck(:name)

      expect(
        course_type.resolve(<<~GQL, current_user: @teacher)
          externalToolsConnection(filter: { placement: homework_submission }) { edges { node { name } } }
        GQL
      ).to match_array result_array
    end

    it "placement list filter includes LTI 1.1 tools with not_selectable false when legacy placements requested" do
      result_array = tool_json_definitions.select { |tool| ["link_selection", "resource_selection"].include?(tool[:placement_type]) || (tool[:lti_version] == "1.1" && tool[:not_selectable] == false) }.pluck(:name)

      expect(
        course_type.resolve(<<~GQL, current_user: @teacher)
          externalToolsConnection(filter: { placementList: [link_selection, resource_selection] }) { edges { node { name } } }
        GQL
      ).to match_array result_array
    end

    it "verifies LTI version filtering behavior with legacy placements" do
      result = course_type.resolve(<<~GQL, current_user: @teacher)
        externalToolsConnection(filter: { placementList: [link_selection, resource_selection] }) { edges { node { name } } }
      GQL

      expect(result).to include("Tool 1")
      expect(result).to include("Tool 3")
      expect(result).to include("Tool 4")
      expect(result).not_to include("Tool 2")
      expect(result).not_to include("Tool 5")
    end

    it "includes all tools with explicit non-legacy placement regardless of not_selectable" do
      result = course_type.resolve(<<~GQL, current_user: @teacher)
        externalToolsConnection(filter: { placement: homework_submission }) { edges { node { name } } }
      GQL

      expect(result).to include("Tool 2")
      expect(result).to include("Tool 4")
      expect(result).to include("Tool 5")
      expect(result).not_to include("Tool 1")
      expect(result).not_to include("Tool 3")
    end

    it "state filter for external tools" do
      result_array = tool_json_definitions.select { |tool| tool[:workflow_state] == "email_only" }.pluck(:name)
      expect(
        course_type.resolve(<<~GQL, current_user: @teacher)
          externalToolsConnection(filter: { state: email_only }) { edges { node { name } } }
        GQL
      ).to match_array result_array
    end
  end
end
