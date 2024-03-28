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
require_relative "shared_examples/types_with_enumerable_workflow_states"

describe Types::AssignmentType do
  let_once(:course) { course_factory(active_all: true) }

  let_once(:teacher) { teacher_in_course(active_all: true, course:).user }
  let_once(:student) { student_in_course(course:, active_all: true).user }
  let_once(:admin_user) { account_admin_user_with_role_changes }

  let(:assignment) do
    course.assignments.create(title: "some assignment",
                              points_possible: 10,
                              submission_types: ["online_text_entry"],
                              workflow_state: "published",
                              allowed_extensions: %w[doc xlt foo])
  end

  let(:assignment_type) { GraphQLTypeTester.new(assignment, current_user: student) }
  let(:teacher_assignment_type) { GraphQLTypeTester.new(assignment, current_user: teacher) }
  let(:admin_user_assignment_type) { GraphQLTypeTester.new(assignment, current_user: admin_user) }

  it "works" do
    expect(assignment_type.resolve("_id")).to eq assignment.id.to_s
    expect(assignment_type.resolve("name")).to eq assignment.name
    expect(assignment_type.resolve("state")).to eq assignment.workflow_state
    expect(assignment_type.resolve("onlyVisibleToOverrides")).to eq assignment.only_visible_to_overrides
    expect(assignment_type.resolve("assignmentGroup { _id }")).to eq assignment.assignment_group.id.to_s
    expect(assignment_type.resolve("allowedExtensions")).to eq assignment.allowed_extensions
    expect(assignment_type.resolve("createdAt").to_datetime).to eq assignment.created_at.to_s.to_datetime
    expect(assignment_type.resolve("updatedAt").to_datetime).to eq assignment.updated_at.to_s.to_datetime
    expect(assignment_type.resolve("gradeGroupStudentsIndividually")).to eq assignment.grade_group_students_individually
    expect(assignment_type.resolve("originalityReportVisibility")).to eq assignment.turnitin_settings[:originality_report_visibility]
    expect(assignment_type.resolve("anonymousGrading")).to eq assignment.anonymous_grading
    expect(assignment_type.resolve("omitFromFinalGrade")).to eq assignment.omit_from_final_grade
    expect(assignment_type.resolve("anonymousInstructorAnnotations")).to eq assignment.anonymous_instructor_annotations
    expect(assignment_type.resolve("postToSis")).to eq assignment.post_to_sis
    expect(assignment_type.resolve("canUnpublish")).to eq assignment.can_unpublish?
    expect(assignment_type.resolve("courseId")).to eq assignment.context_id.to_s
    expect(assignment_type.resolve("gradesPublished")).to eq assignment.grades_published?
    expect(assignment_type.resolve("moderatedGradingEnabled")).to eq assignment.moderated_grading?
    expect(assignment_type.resolve("postManually")).to eq assignment.post_manually?
    expect(assignment_type.resolve("published")).to eq assignment.published?
    expect(assignment_type.resolve("importantDates")).to eq assignment.important_dates
  end

  it_behaves_like "types with enumerable workflow states" do
    let(:enum_class) { Types::AssignmentType::AssignmentStateType }
    let(:model_class) { Assignment }
  end

  context "top-level permissions" do
    it "requires read permission" do
      assignment.unpublish

      # node / legacy node
      expect(assignment_type.resolve("_id")).to be_nil

      # assignment
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: student }).dig("data", "assignment")
          query { assignment(id: "#{assignment.id}") { id } }
        GQL
      ).to be_nil
    end
  end

  context "sis field" do
    let_once(:sis_assignment) do
      assignment.update!(sis_source_id: "sisAssignment")
      assignment
    end

    let(:admin) { account_admin_user_with_role_changes(role_changes: { read_sis: false }) }

    it "returns sis_id if you have read_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: teacher }).dig("data", "assignment", "sisId")
          query { assignment(id: "#{sis_assignment.id}") { sisId } }
        GQL
      ).to eq("sisAssignment")
    end

    it "returns sis_id if you have manage_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: admin }).dig("data", "assignment", "sisId")
          query { assignment(id: "#{sis_assignment.id}") { sisId } }
        GQL
      ).to eq("sisAssignment")
    end

    it "doesn't return sis_id if you don't have read_sis or management_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: student }).dig("data", "assignment", "sisId")
          query { assignment(id: "#{sis_assignment.id}") { sisId } }
        GQL
      ).to be_nil
    end
  end

  it "works with rubric" do
    rubric_for_course
    rubric_association_model(context: course, rubric: @rubric, association_object: assignment, purpose: "grading")
    expect(assignment_type.resolve("rubric { _id }")).to eq @rubric.id.to_s
  end

  describe "rubric association" do
    before do
      rubric_for_course
      rubric_association_model(context: course, rubric: @rubric, association_object: assignment, purpose: "grading")
    end

    it "is returned if an association exists and is active" do
      expect(assignment_type.resolve("rubricAssociation { _id }")).to eq @rubric_association.id.to_s
    end

    it "is not returned if the association is soft-deleted" do
      @rubric_association.destroy!
      expect(assignment_type.resolve("rubricAssociation { _id }")).to be_nil
    end
  end

  it "works with moderated grading" do
    assignment.moderated_grading = true
    assignment.grader_count = 1
    assignment.final_grader_id = teacher.id
    assignment.save!
    assignment.update final_grader_id: teacher.id
    expect(assignment_type.resolve("moderatedGrading { enabled }")).to eq assignment.moderated_grading
    expect(assignment_type.resolve("moderatedGrading { finalGrader { _id } }")).to eq teacher.id.to_s
    expect(assignment_type.resolve("moderatedGrading { gradersAnonymousToGraders }")).to eq assignment.graders_anonymous_to_graders
    expect(assignment_type.resolve("moderatedGrading { graderCount }")).to eq assignment.grader_count
    expect(assignment_type.resolve("moderatedGrading { graderCommentsVisibleToGraders }")).to eq assignment.grader_comments_visible_to_graders
    expect(assignment_type.resolve("moderatedGrading { graderNamesVisibleToFinalGrader }")).to eq assignment.grader_names_visible_to_final_grader
  end

  it "works with peer review info" do
    assignment.peer_reviews_due_at = Time.zone.now
    assignment.save!
    expect(assignment_type.resolve("peerReviews { enabled }")).to eq assignment.peer_reviews
    expect(assignment_type.resolve("peerReviews { count }")).to eq assignment.peer_review_count
    expect(assignment_type.resolve("peerReviews { dueAt }").to_datetime).to eq assignment.peer_reviews_due_at.to_s.to_datetime
    expect(assignment_type.resolve("peerReviews { intraReviews }")).to eq assignment.intra_group_peer_reviews
    expect(assignment_type.resolve("peerReviews { anonymousReviews }")).to eq assignment.anonymous_peer_reviews
    expect(assignment_type.resolve("peerReviews { automaticReviews }")).to eq assignment.automatic_peer_reviews
  end

  it "returns assessment requests for the current user" do
    student2 = student_in_course(course:, name: "Matthew Lemon", active_all: true).user
    student3 = student_in_course(course:, name: "Rob Orton", active_all: true).user

    assignment.assign_peer_review(student, student2)
    assignment.assign_peer_review(student2, student3)
    assignment.assign_peer_review(student3, student)

    result = assignment_type.resolve("assessmentRequestsForCurrentUser { user { name } }")
    expect(result.count).to eq 1
    expect(result[0]).to eq student2.name

    result = GraphQLTypeTester.new(assignment, current_user: student2).resolve("assessmentRequestsForCurrentUser { user { name } }")
    expect(result.count).to eq 1
    expect(result[0]).to eq student3.name

    result = GraphQLTypeTester.new(assignment, current_user: student3).resolve("assessmentRequestsForCurrentUser { user { name } }")
    expect(result.count).to eq 1
    expect(result[0]).to eq student.name
  end

  it "works with timezone stuffs" do
    assignment.time_zone_edited = "Mountain Time (US & Canada)"
    assignment.save!
    expect(assignment_type.resolve("timeZoneEdited")).to eq assignment.time_zone_edited
  end

  it "returns needsGradingCount" do
    assignment.submit_homework(student, { body: "so cool", submission_type: "online_text_entry" })
    expect(assignment_type.resolve("needsGradingCount", current_user: teacher)).to eq 1
  end

  it "can return a url for the assignment" do
    expect(
      assignment_type.resolve("htmlUrl", request: ActionDispatch::TestRequest.create)
    ).to eq "http://test.host/courses/#{assignment.context_id}/assignments/#{assignment.id}"
  end

  context "scoreStatistic" do
    it "returns null when there are no scores" do
      assignment.submissions.destroy_all
      expect(assignment_type.resolve("scoreStatistic { mean }")).to be_nil
    end

    context "when there are scores" do
      before do
        assignment.update!(grading_type: "points")
        assignment.grade_student(student, grade: 5, grader: teacher)
        student_2 = student_in_course(course:, active_all: true).user
        assignment.grade_student(student_2, grade: 10, grader: teacher)
        student_3 = student_in_course(course:, active_all: true).user
        assignment.grade_student(student_3, grade: 15, grader: teacher)
      end

      it "returns the scoreStatistic always for teachers" do
        expect(teacher_assignment_type.resolve("scoreStatistic { mean }")).to be 10.0
        expect(teacher_assignment_type.resolve("scoreStatistic { maximum }")).to be 15.0
        expect(teacher_assignment_type.resolve("scoreStatistic { minimum }")).to be 5.0
        expect(teacher_assignment_type.resolve("scoreStatistic { count }")).to be 3

        assignment.mute!

        expect(teacher_assignment_type.resolve("scoreStatistic { mean }")).to be 10.0
      end

      it "returns null for students when there are fewer than 5 submissions" do
        expect(assignment_type.resolve("scoreStatistic { mean }")).to be_nil
      end

      it "returns the scoreStatistic for students when there are 5 or more submissions" do
        student_4 = student_in_course(course:, active_all: true).user
        assignment.grade_student(student_4, grade: 10, grader: teacher)
        student_5 = student_in_course(course:, active_all: true).user
        assignment.grade_student(student_5, grade: 10, grader: teacher)

        # students should see statistics if there are 5 or more submissions
        expect(assignment_type.resolve("scoreStatistic { mean }")).to be 10.0
      end

      it "returns null for students when the assignment is muted" do
        assignment.mute!
        expect(assignment_type.resolve("scoreStatistic { mean }")).to be_nil
      end

      it "returns stats for admins" do
        expect(admin_user_assignment_type.resolve("scoreStatistic { mean }")).to be 10.0
      end
    end
  end

  context "description" do
    before do
      assignment.update description: %(Hi <img src="/courses/#{course.id}/files/12/download"<h1>Content</h1>)
    end

    it "includes description when lock settings allow" do
      expect_any_instance_of(Assignment)
        .to receive(:low_level_locked_for?)
        .and_return(can_view: true)
      expect(assignment_type.resolve("description", request: ActionDispatch::TestRequest.create)).to include "Content"
    end

    it "returns null when not allowed" do
      expect_any_instance_of(Assignment)
        .to receive(:low_level_locked_for?)
        .and_return(can_view: false)
      expect(assignment_type.resolve("description", request: ActionDispatch::TestRequest.create)).to be_nil
    end

    it "works for assignments in public courses" do
      course.update! is_public: true
      expect(
        assignment_type.resolve(
          "description",
          request: ActionDispatch::TestRequest.create,
          current_user: nil
        )
      ).to include "Content"
    end

    it "uses api_user_content for the description" do
      expect(
        assignment_type.resolve("description", request: ActionDispatch::TestRequest.create)
      ).to include "http://test.host/courses/#{course.id}/files/12/download"
    end
  end

  it "returns nil when allowed_attempts is unset" do
    expect(assignment_type.resolve("allowedAttempts")).to be_nil
  end

  it "returns nil when allowed_attempts is an invalid non-positive value" do
    assignment.update allowed_attempts: 0
    expect(assignment_type.resolve("allowedAttempts")).to be_nil
    assignment.update allowed_attempts: -1
    expect(assignment_type.resolve("allowedAttempts")).to be_nil
  end

  it "returns allowed_attempts value set on the assignment" do
    assignment.update allowed_attempts: 7
    expect(assignment_type.resolve("allowedAttempts")).to eq 7
  end

  describe "gradingStandard" do
    it "returns the grading standard" do
      grading_standard = course.grading_standards.create!(title: "Win/Lose", data: [["Winner", 0.94], ["Loser", 0]])
      assignment.update(grading_type: "letter_grade", grading_standard_id: grading_standard.id)
      assignment.save!
      expect(assignment_type.resolve("gradingStandard { title }")).to eq grading_standard.title
    end

    it "returns null if no grading standard is set" do
      expect(assignment_type.resolve("gradingStandard { title }")).to be_nil
    end
  end

  describe "submissionsConnection" do
    let_once(:other_student) { student_in_course(course:, active_all: true).user }

    # This is kind of a catch-all test the assignment.submissionsConnection
    # graphql plumbing. The submission search specs handle testing the
    # implementation. This makes sure the graphql inputs are hooked up right.
    # Other tests below were already here to test specific cases, and I think
    # they still have value as a sanity check.
    it "plumbs through filter options to SubmissionSearch" do
      allow(SubmissionSearch).to receive(:new).and_call_original
      assignment_type.resolve(<<~GQL, current_user: teacher)
        submissionsConnection(
          filter: {
            states: submitted,
            sectionIds: 42,
            enrollmentTypes: StudentEnrollment,
            userSearch: "foo",
            scoredLessThan: 3
            scoredMoreThan: 1
            gradingStatus: needs_grading
          }
          orderBy: {field: username, direction: descending}
        ) { nodes { _id } }
      GQL
      expect(SubmissionSearch).to have_received(:new).with(assignment, teacher, nil, {
                                                             states: ["submitted"],
                                                             section_ids: ["42"],
                                                             enrollment_types: ["StudentEnrollment"],
                                                             user_search: "foo",
                                                             scored_less_than: 3.0,
                                                             scored_more_than: 1.0,
                                                             grading_status: :needs_grading,
                                                             order_by: [{
                                                               field: "username",
                                                               direction: "descending"
                                                             }]
                                                           })
    end

    context "include_unsubmitted" do
      it "returns unsubmitted submission when include_unsubmitted is true" do
        assignment_unsubmitted = course.assignments.create!
        assignment_unsubmitted.update!(submission_types: "online_text_entry")
        assignment_type_2 = GraphQLTypeTester.new(assignment_unsubmitted, current_user: student)

        result = assignment_type_2.resolve(<<~GQL, current_user: student)
          submissionsConnection(
            filter: {
              includeUnsubmitted: true
            }
          ) { nodes { state } }
        GQL

        expect(result.count).to eq 1
        expect(result[0]).to eq "unsubmitted"
      end

      it "does not return unsubmitted submission when include_unsubmitted is false" do
        assignment_unsubmitted = course.assignments.create!
        assignment_unsubmitted.update!(submission_types: "online_text_entry")
        assignment_type_2 = GraphQLTypeTester.new(assignment_unsubmitted, current_user: student)

        result = assignment_type_2.resolve(<<~GQL, current_user: student)
          submissionsConnection(
            filter: {
              includeUnsubmitted: false
            }
          ) { nodes { state } }
        GQL

        expect(result.count).to eq 0
      end
    end

    it "returns 'real' submissions from with permissions" do
      submission1 = assignment.submit_homework(student, { body: "sub1", submission_type: "online_text_entry" })
      submission2 = assignment.submit_homework(other_student, { body: "sub1", submission_type: "online_text_entry" })

      expect(
        assignment_type.resolve(
          "submissionsConnection { edges { node { _id } } }",
          current_user: teacher
        )
      ).to match_array [submission1.id.to_s, submission2.id.to_s]

      expect(
        assignment_type.resolve(
          "submissionsConnection { edges { node { _id } } }",
          current_user: student
        )
      ).to eq [submission1.id.to_s]
    end

    it "returns nil when not logged in" do
      course.update(is_public: true)

      expect(
        assignment_type.resolve("_id", current_user: nil)
      ).to eq assignment.id.to_s

      expect(
        assignment_type.resolve(
          "submissionsConnection { nodes { _id } }",
          current_user: nil
        )
      ).to be_nil
    end

    it "can filter submissions according to workflow state" do
      expect(
        assignment_type.resolve(
          "submissionsConnection { edges { node { _id } } }",
          current_user: teacher
        )
      ).to eq []

      expect(
        assignment_type.resolve(<<~GQL, current_user: teacher)
          submissionsConnection(filter: {states: [unsubmitted]}) {
            edges { node { _id } }
          }
        GQL
      ).to match_array assignment.submissions.pluck(:id).map(&:to_s)
    end

    context "filtering by section" do
      let(:assignment) { course.assignments.create! }
      let(:course) { Course.create! }
      let(:section1) { course.course_sections.create! }
      let(:section2) { course.course_sections.create! }
      let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

      before do
        section1_student = section1.enroll_user(User.create!, "StudentEnrollment", "active").user
        section2_student = section2.enroll_user(User.create!, "StudentEnrollment", "active").user
        @section1_student_submission = assignment.submit_homework(section1_student, body: "hello world")
        @section2_student_submission = assignment.submit_homework(section2_student, body: "hello universe")
      end

      it "returns submissions only for the given section" do
        section1_submission_ids = assignment_type.resolve(<<~GQL, current_user: teacher)
          submissionsConnection(filter: {sectionIds: [#{section1.id}]}) {
            edges { node { _id } }
          }
        GQL
        expect(section1_submission_ids.map(&:to_i)).to contain_exactly(@section1_student_submission.id)
      end

      it "respects visibility for limited teachers" do
        teacher.enrollments.first.update! course_section: section2,
                                          limit_privileges_to_course_section: true

        submissions = assignment_type.resolve(<<~GQL, current_user: teacher)
          submissionsConnection { nodes { _id } }
        GQL

        expect(submissions).not_to include @section1_student_submission.id.to_s
        expect(submissions).to include @section2_student_submission.id.to_s
      end
    end
  end

  describe "groupSubmissionConnection" do
    before(:once) do
      course_with_teacher
      assignment_model(group_category: "GROUPS!")
      @group_category.create_groups(2)
      2.times do
        student_in_course
        @group_category.groups.first.add_user(@user)
      end
      2.times do
        student_in_course
        @group_category.groups.last.add_user(@user)
      end
      @assignment.submit_homework(@group_category.groups.first.users.first, body: "Submit!")
      @assignment.submit_homework(@group_category.groups.last.users.first, body: "Submit!")

      @assignment_type = GraphQLTypeTester.new(@assignment, current_user: @teacher)
    end

    it "plumbs through filter options to SubmissionSearch" do
      allow(SubmissionSearch).to receive(:new).and_call_original
      @assignment_type.resolve(<<~GQL, current_user: @teacher)
        groupSubmissionsConnection(
          filter: {
            states: submitted,
            sectionIds: 42,
            enrollmentTypes: StudentEnrollment,
            userSearch: "foo",
            scoredLessThan: 3
            scoredMoreThan: 1
            gradingStatus: needs_grading
          }
        ) { nodes { _id } }
      GQL
      expect(SubmissionSearch).to have_received(:new).with(@assignment, @teacher, nil, {
                                                             states: ["submitted"],
                                                             section_ids: ["42"],
                                                             enrollment_types: ["StudentEnrollment"],
                                                             user_search: "foo",
                                                             scored_less_than: 3.0,
                                                             scored_more_than: 1.0,
                                                             grading_status: :needs_grading,
                                                             order_by: []
                                                           })
    end

    it "returns nil if not a group assignment" do
      assignment = @course.assignments.create!
      type = GraphQLTypeTester.new(assignment, current_user: @teacher)
      result = type.resolve(<<~GQL, current_user: @teacher)
        groupSubmissionsConnection {
          edges { node { _id } }
        }
      GQL
      expect(result).to be_nil
    end

    it "returns submissions grouped up" do
      result = @assignment_type.resolve(<<~GQL, current_user: @teacher)
        groupSubmissionsConnection(
          filter: {
            states: submitted
          }
        ) {
          edges { node { _id } }
        }
      GQL
      expect(result.count).to eq 2
    end
  end

  xit "validate assignment 404 return correctly with override instrumenter (ADMIN-2407)" do
    result = CanvasSchema.execute(<<~GQL, context: { current_user: @teacher })
      query {
        assignment(id: "987654321") {
          _id dueAt lockAt unlockAt
        }
      }
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "assignment")).to be_nil
  end

  it "can access it's parent course" do
    expect(assignment_type.resolve("course { _id }")).to eq course.to_param
  end

  it "has an assignmentGroup" do
    expect(assignment_type.resolve("assignmentGroup { _id }")).to eq assignment.assignment_group.to_param
  end

  it "has an assignmentGroupID" do
    expect(assignment_type.resolve("assignmentGroupId")).to eq assignment.assignment_group.id.to_s
  end

  it "has modules" do
    module1 = assignment.course.context_modules.create!(name: "Module 1")
    module2 = assignment.course.context_modules.create!(name: "Module 2")
    assignment.context_module_tags.create!(context_module: module1, context: assignment.course, tag_type: "context_module")
    assignment.context_module_tags.create!(context_module: module2, context: assignment.course, tag_type: "context_module")
    expect(assignment_type.resolve("modules { _id }").to_set).to eq [module1.id.to_s, module2.id.to_s].to_set
  end

  it "only returns valid submission types" do
    assignment.update_attribute :submission_types, "none,foodfight"
    expect(assignment_type.resolve("submissionTypes")).to eq ["none"]
  end

  it "can return multiple submission types" do
    assignment.update_attribute :submission_types, "discussion_topic,wiki_page"
    expect(assignment_type.resolve("submissionTypes")).to eq ["discussion_topic", "wiki_page"]
  end

  it "returns (valid) grading types" do
    expect(assignment_type.resolve("gradingType")).to eq assignment.grading_type

    assignment.update_attribute :grading_type, "fakefakefake"
    expect(assignment_type.resolve("gradingType")).to be_nil
  end

  it "returns grading period id" do
    grading_period_group = GradingPeriodGroup.create!(title: "foo", course_id: @course.id)
    grading_period = GradingPeriod.create!(title: "foo", start_date: 1.day.ago, end_date: 1.day.from_now, grading_period_group_id: grading_period_group.id)
    gp_assignment = @course.assignments.create! name: "asdf", points_possible: 10

    grading_period_assignment_type = GraphQLTypeTester.new(gp_assignment, current_user: student)

    expect(grading_period_assignment_type.resolve("gradingPeriodId")).to eq grading_period.id.to_s
  end

  context "overridden assignments" do
    before(:once) do
      @assignment_due_at = 1.month.from_now

      @overridden_due_at = 2.weeks.from_now
      @overridden_unlock_at = 1.week.from_now
      @overridden_lock_at = 3.weeks.from_now

      @overridden_assignment = course.assignments.create!(title: "asdf",
                                                          workflow_state: "published",
                                                          due_at: @assignment_due_at)

      override = assignment_override_model(assignment: @overridden_assignment,
                                           due_at: @overridden_due_at,
                                           unlock_at: @overridden_unlock_at,
                                           lock_at: @overridden_lock_at)

      override.assignment_override_students.build(user: student)
      override.save!
    end

    let(:overridden_assignment_type) { GraphQLTypeTester.new(@overridden_assignment) }

    it "returns overridden assignment dates" do
      expect(overridden_assignment_type.resolve("dueAt", current_user: teacher)).to eq @assignment_due_at.iso8601
      expect(overridden_assignment_type.resolve("dueAt", current_user: student)).to eq @overridden_due_at.iso8601

      expect(overridden_assignment_type.resolve("lockAt", current_user: student)).to eq @overridden_lock_at.iso8601
      expect(overridden_assignment_type.resolve("unlockAt", current_user: student)).to eq @overridden_unlock_at.iso8601
    end

    it "allows opting out of overrides" do
      # need to make the assignment due sooner so we can tell that the teacher
      # is getting the un-overridden date (not the most lenient date)
      @overridden_assignment.update(due_at: 1.hour.from_now)
      expect(
        overridden_assignment_type.resolve("dueAt(applyOverrides: false)", current_user: @teacher)
      ).to eq @overridden_assignment.without_overrides.due_at.iso8601

      # students still get overrides
      expect(
        overridden_assignment_type.resolve("dueAt(applyOverrides: false)", current_user: @student)
      ).to eq @overridden_due_at.iso8601
      expect(
        overridden_assignment_type.resolve("lockAt(applyOverrides: false)", current_user: @student)
      ).to eq @overridden_lock_at.iso8601
      expect(
        overridden_assignment_type.resolve("unlockAt(applyOverrides: false)", current_user: @student)
      ).to eq @overridden_unlock_at.iso8601
    end
  end

  describe Types::AssignmentOverrideType do
    it "works for groups" do
      gc = assignment.group_category = GroupCategory.create! name: "asdf", context: course
      group = gc.groups.create! name: "group", context: course
      assignment.update group_category: gc
      assignment.assignment_overrides.create!(set: group)
      expect(
        assignment_type.resolve(<<~GQL, current_user: teacher)
          assignmentOverrides { edges { node { set {
            ... on Group {
              _id
            }
          } } } }
        GQL
      ).to eq [group.id.to_s]
    end

    it "works for sections" do
      section = course.course_sections.create! name: "section"
      assignment.assignment_overrides.create!(set: section)
      expect(
        assignment_type.resolve(<<~GQL, current_user: teacher)
          assignmentOverrides { edges { node { set {
            ... on Section {
              _id
            }
          } } } }
        GQL
      ).to eq [section.id.to_s]
    end

    it "works for adhoc students" do
      adhoc_override = assignment.assignment_overrides.new(set_type: "ADHOC")
      adhoc_override.assignment_override_students.build(
        assignment:,
        user: student,
        assignment_override: adhoc_override
      )
      adhoc_override.save!

      expect(
        assignment_type.resolve(<<~GQL, current_user: teacher)
          assignmentOverrides { edges { node { set {
            ... on AdhocStudents {
              students {
                _id
              }
            }
          } } } }
        GQL
      ).to eq [[student.id.to_s]]
    end

    it "works for Noop tags" do
      account = course.account
      account.settings[:conditional_release] = { value: true }
      account.save!
      assignment.assignment_overrides.create!(set_type: "Noop", set_id: 555)
      expect(
        assignment_type.resolve(<<~GQL, current_user: teacher)
          assignmentOverrides { edges { node { set {
            ... on Noop {
              _id
            }
          } } } }
        GQL
      ).to eq ["555"]
    end

    it "works for Course tags" do
      Account.site_admin.enable_feature!(:differentiated_modules)
      assignment.assignment_overrides.create!(set: course)

      expect(
        assignment_type.resolve(<<~GQL, current_user: teacher)
          assignmentOverrides { edges { node { set {
            ... on Course {
              _id
            }
          } } } }
        GQL
      ).to eq [course.id.to_s]
    end
  end

  describe Types::LockInfoType do
    it "works when lock_info is false" do
      expect(
        assignment_type.resolve("lockInfo { isLocked }")
      ).to be false

      %i[lockAt unlockAt canView].each do |field|
        expect(
          assignment_type.resolve("lockInfo { #{field} }")
        ).to be_nil
      end
    end

    it "works when lock_info is a hash" do
      assignment.update! unlock_at: 1.month.from_now
      expect(assignment_type.resolve("lockInfo { isLocked }")).to be true
    end
  end

  describe "PostPolicy" do
    let(:assignment) { course.assignments.create! }
    let(:course) { Course.create!(workflow_state: "available") }
    let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
    let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

    context "when user has manage_grades permission" do
      let(:context) { { current_user: teacher } }

      it "returns the PostPolicy related to the assignment" do
        resolver = GraphQLTypeTester.new(assignment, context)
        expect(resolver.resolve("postPolicy {_id}").to_i).to eql assignment.post_policy.id
      end
    end

    context "when user does not have manage_grades permission" do
      let(:context) { { current_user: student } }

      it "returns null in place of the PostPolicy" do
        resolver = GraphQLTypeTester.new(assignment, context)
        expect(resolver.resolve("postPolicy {_id}")).to be_nil
      end
    end
  end

  describe "restrictQuantitativeData" do
    it "returns false when restrictQuantitativeData is off" do
      expect(
        assignment_type.resolve("restrictQuantitativeData")
      ).to be false
    end

    context "when RQD is enabled" do
      before :once do
        # truthy feature flag
        Account.default.enable_feature! :restrict_quantitative_data

        # truthy setting
        Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
        Account.default.save!
        course.restrict_quantitative_data = true
        course.save!
      end

      context "default RQD state" do
        it "returns true for student" do
          expect(
            assignment_type.resolve("restrictQuantitativeData")
          ).to be true
        end

        it "returns true for teacher" do
          expect(
            teacher_assignment_type.resolve("restrictQuantitativeData")
          ).to be true
        end
      end

      context "checkExtraPermissions RQD state" do
        it "returns true for student" do
          expect(
            assignment_type.resolve("restrictQuantitativeData(checkExtraPermissions: true)")
          ).to be true
        end

        it "returns false for teacher" do
          expect(
            teacher_assignment_type.resolve("restrictQuantitativeData(checkExtraPermissions: true)")
          ).to be false
        end
      end
    end
  end

  describe "checkpoints" do
    describe "when feature flag is disabled" do
      it "checkpoints is nil and hasSubAssignments is false" do
        expect(assignment_type.resolve("checkpoints {tag}")).to be_nil
        expect(assignment_type.resolve("hasSubAssignments")).to be_falsey
      end
    end

    describe "when feature flag is enabled" do
      before do
        course.root_account.enable_feature!(:discussion_checkpoints)
      end

      it "checkpoints is [] and hasSubAssignments is false" do
        expect(assignment_type.resolve("checkpoints {tag}")).to eq []
        expect(assignment_type.resolve("hasSubAssignments")).to be_falsey
      end

      describe "when assignment has checkpoint assignments" do
        before do
          assignment.update!(has_sub_assignments: true)
          @c1 = assignment.sub_assignments.create!(context: course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, points_possible: 5, due_at: 3.days.from_now)
          @c2 = assignment.sub_assignments.create!(context: course, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, points_possible: 10, due_at: 5.days.from_now)
        end

        it "checkpoints returns the correct tags" do
          expect(assignment_type.resolve("checkpoints {tag}")).to match_array [CheckpointLabels::REPLY_TO_TOPIC, CheckpointLabels::REPLY_TO_ENTRY]
        end

        it "hasSubAssignments is true" do
          expect(assignment_type.resolve("hasSubAssignments")).to be_truthy
        end

        it "checkpoints returns the points possible" do
          expect(assignment_type.resolve("checkpoints {pointsPossible}")).to match_array [@c1.points_possible, @c2.points_possible]
        end

        it "checkpoints returns the due at" do
          expect(assignment_type.resolve("checkpoints {dueAt}")).to match_array [@c1.due_at.iso8601, @c2.due_at.iso8601]
        end

        it "checkpoints returns the onlyVisibleToOverrides as false" do
          expect(assignment_type.resolve("checkpoints {onlyVisibleToOverrides}")).to match_array [@c1.only_visible_to_overrides, @c2.only_visible_to_overrides]
        end
      end

      describe "when assignment has checkpoints with overrides" do
        before do
          @everyone_due_at = 2.days.from_now
          @section_due_at = 3.days.from_now

          @topic = DiscussionTopic.create_graded_topic!(course:, title: "Checkpointed Discussion")
          @c1 = Checkpoints::DiscussionCheckpointCreatorService.call(
            discussion_topic: @topic,
            checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
            dates: [
              { type: "everyone", due_at: @everyone_due_at },
              { type: "override", set_type: "CourseSection", set_id: @topic.course.default_section.id, due_at: @section_due_at }
            ],
            points_possible: 10
          )
        end

        it "returns assignment overrides for checkpoints" do
          query = GraphQLTypeTester.new(@topic.assignment, current_user: student)

          expect(query.resolve("checkpoints {pointsPossible}")).to eq [10]
          expect(query.resolve("checkpoints {dueAt}")).to eq [@everyone_due_at.iso8601]
          expect(query.resolve("checkpoints {assignmentOverrides {nodes {dueAt}}}")).to eq [[@section_due_at.iso8601]]
        end
      end
    end
  end
end
