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

  let(:assignment_visibility) do
    AssignmentVisibility::AssignmentVisibilityService.assignments_with_user_visibilities(
      course, [assignment]
    )[assignment.id].map(&:to_s)
  end

  it "works" do
    expect(assignment_type.resolve("_id")).to eq assignment.id.to_s
    expect(assignment_type.resolve("name")).to eq assignment.name
    expect(assignment_type.resolve("state")).to eq assignment.workflow_state
    expect(assignment_type.resolve("onlyVisibleToOverrides")).to eq assignment.only_visible_to_overrides
    expect(assignment_type.resolve("assignmentGroup { _id }")).to eq assignment.assignment_group.id.to_s
    expect(assignment_type.resolve("allowedExtensions")).to eq assignment.allowed_extensions
    expect(Time.iso8601(assignment_type.resolve("createdAt")).to_i).to eq assignment.created_at.to_i
    expect(Time.iso8601(assignment_type.resolve("updatedAt")).to_i).to eq assignment.updated_at.to_i
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
    expect(assignment_type.resolve("isNewQuiz")).to eq assignment.quiz_lti?
    expect(assignment_type.resolve("muted")).to eq assignment.muted?
    expect(assignment_type.resolve("hasRubric")).to eq assignment.active_rubric_association?
  end

  describe "graded_submissions_exist" do
    it "returns true when graded submissions exist" do
      assignment.grade_student(student, grade: 5, grader: teacher)
      expect(assignment_type.resolve("gradedSubmissionsExist")).to be true
    end

    it "returns false when no graded submissions exist" do
      expect(assignment_type.resolve("gradedSubmissionsExist")).to be false
    end
  end

  it_behaves_like "types with enumerable workflow states" do
    let(:enum_class) { Types::AssignmentType::AssignmentStateType }
    let(:model_class) { Assignment }
  end

  describe "hasGroupCategory" do
    it "returns true for group assignments" do
      assignment.update!(group_category: course.group_categories.create!(name: "My Category"))
      expect(assignment_type.resolve("hasGroupCategory")).to be true
    end

    it "returns false for non-group assignments" do
      expect(assignment_type.resolve("hasGroupCategory")).to be false
    end
  end

  describe "hasPlagiarismTool" do
    it "returns true when assignment has a plagiarism tool configured" do
      tool = course.context_external_tools.create!(
        name: "Plagiarism Tool",
        url: "http://example.com",
        consumer_key: "key",
        shared_secret: "secret"
      )
      assignment.assignment_configuration_tool_lookups.create!(
        tool:,
        tool_type: "ContextExternalTool"
      )
      expect(assignment_type.resolve("hasPlagiarismTool")).to be true
    end

    it "returns false when assignment has no plagiarism tool configured" do
      expect(assignment_type.resolve("hasPlagiarismTool")).to be false
    end
  end

  describe "gradeAsGroup" do
    it "returns true for group assignments being graded as group" do
      assignment.update!(group_category: course.group_categories.create!(name: "My Category"))
      expect(assignment_type.resolve("gradeAsGroup")).to be true
    end

    it "returns false for group assignments being graded individually" do
      assignment.update!(
        group_category: course.group_categories.create!(name: "My Category"),
        grade_group_students_individually: true
      )
      expect(assignment_type.resolve("gradeAsGroup")).to be false
    end

    it "returns false for non-group assignments" do
      expect(assignment_type.resolve("gradeAsGroup")).to be false
    end
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
      expect(assignment_type.resolve("rubric { _id }")).to be_nil
      expect(assignment_type.resolve("rubricAssociation { _id }")).to be_nil
    end
  end

  describe "rubric self assessments" do
    before do
      rubric_for_course
      rubric_association_model(context: course, rubric: @rubric, association_object: assignment, purpose: "grading")
      course.enable_feature!(:enhanced_rubrics)
      course.enable_feature!(:platform_service_speedgrader)
      course.root_account.enable_feature!(:rubric_self_assessment)
      assignment.update(rubric_self_assessment_enabled: true)
    end

    it "returns rubric self assessment enabled" do
      expect(assignment_type.resolve("rubricSelfAssessmentEnabled")).to be true
    end

    it "returns can_update_rubric_self_assessment" do
      expect(assignment_type.resolve("canUpdateRubricSelfAssessment")).to be true
    end

    it "returns can_update_rubric_self_assessment false if the due dates have passed" do
      assignment.update(due_at: 1.day.ago)
      expect(assignment_type.resolve("canUpdateRubricSelfAssessment")).to be false
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
    expect(Time.iso8601(assignment_type.resolve("peerReviews { dueAt }")).to_i).to eq assignment.peer_reviews_due_at.to_i
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

  describe "assessmentRequestsForUser" do
    let(:student2) { student_in_course(course:, name: "Matthew Lemon", active_all: true).user }
    let(:student3) { student_in_course(course:, name: "Rob Orton", active_all: true).user }

    before do
      assignment.assign_peer_review(student, student2)
      assignment.assign_peer_review(student2, student3)
      assignment.assign_peer_review(student, student3)
    end

    context "when current user has grade permission" do
      it "returns assessment requests for specified user" do
        result = teacher_assignment_type.resolve("assessmentRequestsForUser(userId: \"#{student.id}\") { user { name } }")
        expect(result.count).to eq 2
        expect(result).to contain_exactly(student2.name, student3.name)
      end

      it "returns empty array when user has no assessment requests" do
        result = teacher_assignment_type.resolve("assessmentRequestsForUser(userId: \"#{student3.id}\") { user { name } }")
        expect(result).to eq([])
      end

      it "accepts relay-style user IDs" do
        relay_id = GraphQL::Schema::UniqueWithinType.encode("User", student.id)
        result = teacher_assignment_type.resolve("assessmentRequestsForUser(userId: \"#{relay_id}\") { user { name } }")
        expect(result.count).to eq 2
      end

      it "accepts legacy user IDs" do
        result = teacher_assignment_type.resolve("assessmentRequestsForUser(userId: \"#{student.id}\") { user { name } }")
        expect(result.count).to eq 2
      end

      it "returns nil for non-existent user" do
        result = teacher_assignment_type.resolve("assessmentRequestsForUser(userId: \"999999\") { user { name } }")
        expect(result).to be_nil
      end
    end

    context "when current user lacks grade permission" do
      it "returns nil" do
        result = assignment_type.resolve("assessmentRequestsForUser(userId: \"#{student2.id}\") { user { name } }")
        expect(result).to be_nil
      end
    end

    context "with non-participating students" do
      it "filters out assessment requests for deleted enrollments" do
        student2.enrollments.where(course:).destroy_all
        result = teacher_assignment_type.resolve("assessmentRequestsForUser(userId: \"#{student.id}\") { user { name } }")
        expect(result).not_to include(student2.name)
      end
    end

    context "with concluded enrollments" do
      it "filters out assessment requests for concluded enrollments" do
        enrollment = student2.enrollments.where(course:).first
        enrollment.conclude
        result = teacher_assignment_type.resolve("assessmentRequestsForUser(userId: \"#{student.id}\") { user { name } }")
        expect(result).to be_an(Array)
        expect(result).not_to include(student2.name)
      end
    end
  end

  describe "peerReviewSubAssignment" do
    context "when current user has grade permission" do
      context "when peer_review_allocation_and_grading feature is enabled" do
        before do
          course.enable_feature!(:peer_review_allocation_and_grading)
          assignment.update!(peer_reviews: true)
        end

        it "returns the peer review sub assignment" do
          peer_review_sub_assignment = peer_review_model(parent_assignment: assignment)
          result = teacher_assignment_type.resolve("peerReviewSubAssignment { _id }")
          expect(result).to eq peer_review_sub_assignment.id.to_s
        end

        it "returns nil when no peer review sub assignment exists" do
          result = teacher_assignment_type.resolve("peerReviewSubAssignment { _id }")
          expect(result).to be_nil
        end
      end

      context "when peer_review_allocation_and_grading feature is disabled" do
        it "returns nil" do
          peer_review_model(parent_assignment: assignment)
          course.disable_feature!(:peer_review_allocation_and_grading)
          result = teacher_assignment_type.resolve("peerReviewSubAssignment { _id }")
          expect(result).to be_nil
        end
      end
    end

    context "when current user lacks grade permission" do
      before do
        course.enable_feature!(:peer_review_allocation_and_grading)
      end

      it "returns nil for students" do
        peer_review_model(parent_assignment: assignment)
        result = assignment_type.resolve("peerReviewSubAssignment { _id }")
        expect(result).to be_nil
      end
    end
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
      assignment.update(description: %(Hi <img src="/courses/#{course.id}/files/12/download"<h1>Content</h1>), saving_user: teacher)
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
      course.update!(is_public: true, saving_user: teacher)
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

    it "tags attachments with location when file_association_access is enabled" do
      assignment_type =  GraphQLTypeTester.new(assignment, current_user: teacher, domain_root_account: course.root_account)
      course.root_account.enable_feature!(:file_association_access)
      attachment = attachment_model(context: course)
      assignment.update(description: "<img src='/courses/#{course.id}/files/#{attachment.id}/download'>", saving_user: teacher)
      expect(
        assignment_type.resolve("description", request: ActionDispatch::TestRequest.create)
      ).to include "http://test.host/courses/#{course.id}/files/#{attachment.id}/download?location=#{assignment.asset_string}"
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
    context "is set" do
      before do
        @grading_standard = course.grading_standards.create!(title: "Win/Lose", data: [["Winner", 0.94], ["Loser", 0]])
        assignment.update(grading_type: "letter_grade", grading_standard_id: @grading_standard.id)
        assignment.save!
      end

      it "returns the grading standard id" do
        expect(assignment_type.resolve("gradingStandardId")).to eq @grading_standard.id.to_s
      end

      it "returns the grading standard" do
        expect(assignment_type.resolve("gradingStandard { title }")).to eq @grading_standard.title
      end
    end

    context "is not set" do
      it "returns null if no grading standard is set" do
        expect(assignment_type.resolve("gradingStandardId")).to be_nil
        expect(assignment_type.resolve("gradingStandard { title }")).to be_nil
      end
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
        gql = "submissionsConnection(filter: {sectionIds: [#{section1.id}]}) {
            edges { node { _id } }
          }"
        section1_submission_ids = assignment_type.resolve(gql, current_user: teacher)
        expect(section1_submission_ids.map(&:to_i)).to contain_exactly(@section1_student_submission.id)
      end

      it "respects visibility for limited teachers" do
        teacher.enrollments.first.update! course_section: section2,
                                          limit_privileges_to_course_section: true
        submissions = assignment_type.resolve("submissionsConnection { nodes { _id } }", current_user: teacher)

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

    before do
      post_policy = assignment.post_policy
      post_policy.update!(post_manually: true)
      @scheduled_post = ScheduledPost.new(
        assignment:,
        post_policy:,
        root_account_id: assignment.root_account_id,
        post_comments_at: 2.days.from_now,
        post_grades_at: 2.days.from_now
      )
      @scheduled_post.save!
    end

    context "when user has manage_grades permission" do
      let(:context) { { current_user: teacher } }

      it "returns the PostPolicy related to the assignment" do
        resolver = GraphQLTypeTester.new(assignment, context)
        expect(resolver.resolve("postPolicy {_id}").to_i).to eql assignment.post_policy.id
      end

      it "returns the ScheduledPost when it exists" do
        resolver = GraphQLTypeTester.new(assignment, context)
        expect(resolver.resolve("scheduledPost { _id }")).to eq @scheduled_post.id.to_s
      end
    end

    context "when user does not have manage_grades permission" do
      let(:context) { { current_user: student } }

      it "returns null in place of the PostPolicy" do
        resolver = GraphQLTypeTester.new(assignment, context)
        expect(resolver.resolve("postPolicy {_id}")).to be_nil
      end

      it "returns null in place of the ScheduledPost" do
        resolver = GraphQLTypeTester.new(assignment, context)
        expect(resolver.resolve("scheduledPost { _id }")).to be_nil
      end
    end
  end

  describe "lti_asset_processors_connection" do
    let(:assignment) { course.assignments.create! }
    let(:course) { Course.create!(workflow_state: "available") }
    let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
    let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }
    let(:observer) { course.enroll_user(User.create!, "ObserverEnrollment", enrollment_state: "active", associated_user_id: student.id).user }

    context "when lti_asset_processor feature flag is disabled" do
      before { course.root_account.disable_feature!(:lti_asset_processor) }

      it "returns null" do
        resolver = GraphQLTypeTester.new(assignment, current_user: teacher)
        expect(resolver.resolve("ltiAssetProcessorsConnection { edges { node { _id } } }")).to be_nil
      end
    end

    context "when user has manage_grades permission" do
      let(:context) { { current_user: teacher } }

      it "returns lti asset processors" do
        asset_processor = lti_asset_processor_model(assignment:)
        resolver = GraphQLTypeTester.new(assignment, context)
        result = resolver.resolve("ltiAssetProcessorsConnection { edges { node { _id } } }")
        expect(result).to eq([asset_processor.id.to_s])
      end

      it "returns empty collection when no asset processors exist" do
        resolver = GraphQLTypeTester.new(assignment, context)
        result = resolver.resolve("ltiAssetProcessorsConnection { edges { node { _id } } }")
        expect(result).to eq([])
      end
    end

    context "when user is an observer" do
      let(:context) { { current_user: observer } }

      it "returns lti asset processors" do
        asset_processor = lti_asset_processor_model(assignment:)
        resolver = GraphQLTypeTester.new(assignment, context)
        result = resolver.resolve("ltiAssetProcessorsConnection { edges { node { _id } } }")
        expect(result).to eq([asset_processor.id.to_s])
      end

      it "returns empty collection when no asset processors exist" do
        resolver = GraphQLTypeTester.new(assignment, context)
        result = resolver.resolve("ltiAssetProcessorsConnection { edges { node { _id } } }")
        expect(result).to eq([])
      end
    end
  end

  describe "provisional_grading_locked" do
    let(:moderated_assignment) do
      course.assignments.create!(
        title: "moderated assignment",
        moderated_grading: true,
        grader_count: 2,
        final_grader: teacher
      )
    end

    let(:moderated_assignment_type) { GraphQLTypeTester.new(moderated_assignment, current_user: teacher) }

    context "when user is a student" do
      it "returns false" do
        student_type = GraphQLTypeTester.new(moderated_assignment, current_user: student)
        expect(student_type.resolve("provisionalGradingLocked")).to be false
      end
    end

    context "when user is the final grader" do
      it "returns false" do
        expect(moderated_assignment_type.resolve("provisionalGradingLocked")).to be false
      end
    end

    context "when grades are published" do
      it "returns false" do
        other_teacher = teacher_in_course(course:, active_all: true).user
        other_teacher_type = GraphQLTypeTester.new(moderated_assignment, current_user: other_teacher)

        moderated_assignment.update!(grades_published_at: Time.now.utc)

        expect(other_teacher_type.resolve("provisionalGradingLocked")).to be false
      end
    end

    context "when user is already a provisional grader" do
      it "returns false" do
        other_teacher = teacher_in_course(course:, active_all: true).user
        other_teacher_type = GraphQLTypeTester.new(moderated_assignment, current_user: other_teacher)

        moderated_assignment.moderation_graders.create!(user: other_teacher, anonymous_id: "abcde")

        expect(other_teacher_type.resolve("provisionalGradingLocked")).to be false
      end
    end

    context "when grader limit is not reached" do
      it "returns false" do
        other_teacher = teacher_in_course(course:, active_all: true).user
        other_teacher_type = GraphQLTypeTester.new(moderated_assignment, current_user: other_teacher)

        expect(other_teacher_type.resolve("provisionalGradingLocked")).to be false
      end
    end

    context "when grader limit is reached" do
      it "returns true for a teacher who is not already a grader" do
        grader1 = teacher_in_course(course:, active_all: true).user
        grader2 = teacher_in_course(course:, active_all: true).user
        extra_teacher = teacher_in_course(course:, active_all: true).user

        moderated_assignment.moderation_graders.create!(user: grader1, anonymous_id: "abcde")
        moderated_assignment.moderation_graders.create!(user: grader2, anonymous_id: "fghij")

        extra_teacher_type = GraphQLTypeTester.new(moderated_assignment, current_user: extra_teacher)
        expect(extra_teacher_type.resolve("provisionalGradingLocked")).to be true
      end
    end
  end

  describe "grading_role" do
    context "when user does not have grading permissions" do
      it "returns nil" do
        expect(assignment_type.resolve("gradingRole")).to be_nil
      end
    end

    context "when user has grading permissions" do
      let(:moderated_assignment) do
        course.assignments.create!(
          title: "moderated assignment",
          moderated_grading: true,
          grader_count: 2,
          final_grader: teacher
        )
      end

      let(:moderated_assignment_type) { GraphQLTypeTester.new(moderated_assignment, current_user: teacher) }

      it "returns 'moderator' when user is the final grader and grades are not published" do
        expect(moderated_assignment_type.resolve("gradingRole")).to eq "moderator"
      end

      it "returns 'provisional_grader' when user is not the final grader and grades are not published" do
        other_teacher = teacher_in_course(course:, active_all: true).user
        other_teacher_assignment_type = GraphQLTypeTester.new(moderated_assignment, current_user: other_teacher)

        expect(other_teacher_assignment_type.resolve("gradingRole")).to eq "provisional_grader"
      end

      it "returns 'grader' when grades are published" do
        moderated_assignment.update!(grades_published_at: Time.now.utc)

        expect(moderated_assignment_type.resolve("gradingRole")).to eq "grader"
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
        @course.account.disable_feature!(:discussion_checkpoints)
        expect(assignment_type.resolve("checkpoints {tag}")).to be_nil
        expect(assignment_type.resolve("hasSubAssignments")).to be_falsey
      end
    end

    describe "when feature flag is enabled" do
      before do
        course.account.enable_feature!(:discussion_checkpoints)
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
          expect(assignment_type.resolve("checkpoints {pointsPossible}")).to eq [@c1.points_possible, @c2.points_possible]
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
          expect(query.resolve("checkpoints {dueAt}")).to eq [@section_due_at.iso8601]
          expect(query.resolve("checkpoints {assignmentOverrides {nodes {dueAt}}}")).to eq [[@section_due_at.iso8601]]
        end
      end
    end
  end

  describe "mySubAssignmentSubmissionsConnection" do
    context "when feature flag is enabled" do
      before do
        course.account.enable_feature!(:discussion_checkpoints)
        @topic = DiscussionTopic.create_graded_topic!(course:, title: "Checkpointed Discussion")
        @topic.reply_to_entry_required_count = 2
        @topic.save!
        @assignment = @topic.assignment
        @assignment.update!(has_sub_assignments: true)
        @assignment.sub_assignments.create!(context: course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, points_possible: 5, due_at: 3.days.from_now)
        @assignment.sub_assignments.create!(context: course, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, points_possible: 10, due_at: 5.days.from_now)
        @other_student = student_in_course(course:, active_all: true).user
      end

      it "returns the correct sub assignment submissions" do
        root_entry = @topic.discussion_entries.create!(user: student, message: "my reply to topic")
        2.times { |i| @topic.discussion_entries.create!(user: student, message: "my child reply #{i}", parent_entry: root_entry) }
        @topic.discussion_entries.create!(user: @other_student, message: "other student reply to topic")

        query = GraphQLTypeTester.new(@assignment, current_user: student)

        expect(query.resolve("mySubAssignmentSubmissionsConnection {nodes {userId}}")).to match_array [student.id.to_s, student.id.to_s]
        expect(query.resolve("mySubAssignmentSubmissionsConnection {nodes {subAssignmentTag}}")).to match_array [CheckpointLabels::REPLY_TO_TOPIC, CheckpointLabels::REPLY_TO_ENTRY]
        expect(query.resolve("mySubAssignmentSubmissionsConnection {nodes {submissionStatus}}")).to match_array ["submitted", "submitted"]
      end

      it "does not mark REPLY_TO_ENTRY as submitted if user has not met minimum count" do
        root_entry = @topic.discussion_entries.create!(user: student, message: "my reply to topic")
        @topic.discussion_entries.create!(user: student, message: "my child reply", parent_entry: root_entry)

        query = GraphQLTypeTester.new(@assignment, current_user: student)
        expect(query.resolve("mySubAssignmentSubmissionsConnection {nodes {userId}}")).to match_array [student.id.to_s, student.id.to_s]
        expect(query.resolve("mySubAssignmentSubmissionsConnection {nodes {subAssignmentTag}}")).to match_array [CheckpointLabels::REPLY_TO_TOPIC, CheckpointLabels::REPLY_TO_ENTRY]
        expect(query.resolve("mySubAssignmentSubmissionsConnection {nodes {submissionStatus}}")).to match_array ["submitted", "unsubmitted"]
      end

      it "does not mark REPLY_TO_TOPIC as submitted if user has only replied to entries (but not enough)" do
        root_entry = @topic.discussion_entries.create!(user: @other_student, message: "my reply to topic")
        @topic.discussion_entries.create!(user: student, message: "my child reply", parent_entry: root_entry)
        query = GraphQLTypeTester.new(@assignment, current_user: student)
        expect(query.resolve("mySubAssignmentSubmissionsConnection {nodes {userId}}")).to match_array [student.id.to_s, student.id.to_s]
        expect(query.resolve("mySubAssignmentSubmissionsConnection {nodes {subAssignmentTag}}")).to match_array [CheckpointLabels::REPLY_TO_TOPIC, CheckpointLabels::REPLY_TO_ENTRY]
        expect(query.resolve("mySubAssignmentSubmissionsConnection {nodes {submissionStatus}}")).to match_array ["unsubmitted", "unsubmitted"]
      end
    end
  end

  describe "sub_assignment_submissions" do
    context "when feature flag is enabled" do
      before do
        course.account.enable_feature!(:discussion_checkpoints)
        @topic = DiscussionTopic.create_graded_topic!(course:, title: "Checkpointed Discussion")
        @topic.reply_to_entry_required_count = 2
        @topic.save!
        @assignment = @topic.assignment
        @assignment.update!(has_sub_assignments: true)
        @c1 = @assignment.sub_assignments.create!(context: course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, points_possible: 5, due_at: 3.days.from_now)
        @c2 = @assignment.sub_assignments.create!(context: course, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, points_possible: 10, due_at: 5.days.from_now)
        @other_student = student_in_course(course:, active_all: true).user
      end

      it "sub_submissions return correct submissions corresponding to the sub assignments" do
        root_entry = @topic.discussion_entries.create!(user: student, message: "my reply to topic")
        2.times { |i| @topic.discussion_entries.create!(user: student, message: "my child reply #{i}", parent_entry: root_entry) }
        @topic.discussion_entries.create!(user: @other_student, message: "other student reply to topic")

        query = GraphQLTypeTester.new(@assignment, current_user: teacher)

        expect(query.resolve("submissionsConnection {nodes {subAssignmentSubmissions {assignmentId}}}")).to match_array [[@c1.id.to_s, @c2.id.to_s]]
      end
    end
  end

  describe "supportsGradeByQuestion" do
    it "returns false when the assignment does not support grade by question" do
      expect(assignment_type.resolve("supportsGradeByQuestion")).to be false
    end

    it "returns true when the assignment supports grade by question" do
      assignment.update!(submission_types: "online_quiz")
      expect(assignment_type.resolve("supportsGradeByQuestion")).to be true
    end
  end

  describe "gradeByQuestionEnabled" do
    context "when the assignment does not support grade by question" do
      it "returns false, even if the user's preference is set to true" do
        teacher.update!(preferences: { enable_speedgrader_grade_by_question: true })
        expect(teacher_assignment_type.resolve("gradeByQuestionEnabled")).to be false
      end

      it "returns false when the user's preference is set to false" do
        expect(teacher_assignment_type.resolve("gradeByQuestionEnabled")).to be false
      end
    end

    context "when the assignment supports grade by question" do
      before do
        assignment.update!(submission_types: "online_quiz")
      end

      it "returns true when the user's preference is set to true" do
        teacher.update!(preferences: { enable_speedgrader_grade_by_question: true })
        expect(teacher_assignment_type.resolve("gradeByQuestionEnabled")).to be true
      end

      it "returns false when the user's preference is set to false" do
        expect(teacher_assignment_type.resolve("gradeByQuestionEnabled")).to be false
      end
    end
  end

  describe "submission stats" do
    let_once(:student2) { student_in_course(course:, active_all: true).user }
    let(:assignment2) do
      course.assignments.create(title: "another assignment",
                                points_possible: 10,
                                submission_types: ["online_text_entry"],
                                workflow_state: "published")
    end
    let(:teacher_assignment2_type) { GraphQLTypeTester.new(assignment2, current_user: teacher) }

    before do
      assignment.submit_homework(student, { body: "submission 1", submission_type: "online_text_entry" })
      assignment.submit_homework(student2, { body: "submission 2", submission_type: "online_text_entry" })
    end

    context "total_submissions" do
      context "when user has permissions to manage assignments" do
        it "returns the total submissions for an assignment" do
          expect(teacher_assignment_type.resolve("totalSubmissions")).to eq 2
        end

        it "calculates properly the total submissions for an assignment" do
          assignment2.submit_homework(student, { body: "submission 1, assignment 2", submission_type: "online_text_entry" })
          expect(teacher_assignment2_type.resolve("totalSubmissions")).to eq 1
        end
      end

      context "when user does not have permissions to manage assignments" do
        it "returns nil" do
          expect(assignment_type.resolve("totalSubmissions")).to be_nil
        end
      end
    end

    context "total_graded_submissions" do
      before do
        assignment.grade_student(student, grade: 5, grader: teacher)
      end

      context "when user has permissions to manage assignments" do
        it "returns the total graded submissions for an assignment" do
          expect(teacher_assignment_type.resolve("totalGradedSubmissions")).to eq 1
        end

        it "calculates properly the total graded submissions for an assignment" do
          assignment2.submit_homework(student, { body: "submission 1, assignment 2", submission_type: "online_text_entry" })
          assignment2.grade_student(student, grade: 5, grader: teacher)
          expect(teacher_assignment2_type.resolve("totalGradedSubmissions")).to eq 1
        end
      end

      context "when user does not have permissions to manage assignments" do
        it "returns nil" do
          expect(assignment_type.resolve("totalGradedSubmissions")).to be_nil
        end
      end
    end
  end

  describe "assignmentTargetConnection" do
    before(:once) do
      @overridden_assignment = course.assignments.create!(title: "assignment with overrides",
                                                          workflow_state: "published",
                                                          due_at: 5.weeks.from_now)

      @override1 = assignment_override_model(assignment: @overridden_assignment,
                                             title: "First override",
                                             due_at: 2.weeks.from_now,
                                             unlock_at: 1.week.from_now,
                                             lock_at: 3.weeks.from_now)
      @override1.assignment_override_students.build(user: student)
      @override1.save!

      @override2 = assignment_override_model(assignment: @overridden_assignment,
                                             title: "Second override",
                                             due_at: 3.weeks.from_now,
                                             unlock_at: 2.weeks.from_now,
                                             lock_at: 4.weeks.from_now)

      @override2.assignment_override_students.build(user: student2)
      @override2.save!
    end

    let_once(:student2) { student_in_course(course:, active_all: true).user }
    let(:overridden_assignment_type) { GraphQLTypeTester.new(@overridden_assignment, current_user: teacher) }
    let(:student_overridden_assignment_type) { GraphQLTypeTester.new(@overridden_assignment, current_user: student) }

    def create_context_module_and_override_adhoc(context: @course, assignment: @overridden_assignment, name: "Module 1", student: student2)
      context_module = context.context_modules.create!(name:)
      assignment.context_module_tags.create! context_module:, context:, tag_type: "context_module"
      module_override = context_module.assignment_overrides.create! title: "1 Student"
      override_student = module_override.assignment_override_students.build
      override_student.user = student
      override_student.save!
      module_override
    end

    def format_timestamps(timestamp)
      timestamp.map { |t| t&.strftime("%Y-%m-%dT%H:%M:%SZ") }
    end

    def sorted_results(field, sort_by, direction = "ascending")
      overridden_assignment_type.resolve(
        "assignmentTargetConnection (orderBy: { field: #{sort_by}, direction: #{direction} }) { edges { node { #{field} } } }"
      )
    end

    def paginated_results(field, first = 1)
      overridden_assignment_type.resolve(
        "assignmentTargetConnection (first: #{first}) { edges { node { #{field} } } }"
      )
    end

    def paginated_results_next_page(first = 1)
      overridden_assignment_type.resolve(
        "assignmentTargetConnection (first: #{first}) { pageInfo { hasNextPage } }"
      )
    end

    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "assignmentTargetConnection", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(message)
    end

    context "when user has permissions to manage assignments" do
      it "returns assignment overrides for the assignment" do
        expect(overridden_assignment_type.resolve(
                 "assignmentTargetConnection { edges { node { title } } }"
               )).to match_array([@override1.title, @override2.title])
      end

      it "returns module overrides for the assignment" do
        module_override = create_context_module_and_override_adhoc
        expect(overridden_assignment_type.resolve(
                 "assignmentTargetConnection { edges { node { title } } }"
               )).to match_array([@override1.title, @override2.title, module_override.title])
      end

      it "returns only active overrides for the assignment" do
        @override2.assignment_override_students.first.delete
        @override2.delete
        expect(overridden_assignment_type.resolve(
                 "assignmentTargetConnection { edges { node { title } } }"
               )).to match_array([@override1.title])
      end

      context "sorting" do
        it "sorts by title in ascending order" do
          expect(sorted_results("title", "title")).to eq([@override1.title, @override2.title])
        end

        it "sorts by title in descending order" do
          expect(sorted_results("title", "title", "descending")).to eq([@override2.title, @override1.title])
        end

        it "sorts by due_at in ascending order" do
          expect(sorted_results("dueAt", "due_at")).to eq(format_timestamps([@override1.due_at, @override2.due_at]))
        end

        it "sorts by due_at in descending order" do
          expect(sorted_results("dueAt", "due_at", "descending")).to eq(format_timestamps([@override2.due_at, @override1.due_at]))
        end

        it "sorts by unlock_at in ascending order" do
          expect(sorted_results("unlockAt", "unlock_at")).to eq(format_timestamps([@override1.unlock_at, @override2.unlock_at]))
        end

        it "sorts by unlock_at in descending order" do
          expect(sorted_results("unlockAt", "unlock_at", "descending")).to eq(format_timestamps([@override2.unlock_at, @override1.unlock_at]))
        end

        it "sorts by lock_at in ascending order" do
          expect(sorted_results("lockAt", "lock_at")).to eq(format_timestamps([@override1.lock_at, @override2.lock_at]))
        end

        it "sorts by lock_at in descending order" do
          expect(sorted_results("lockAt", "lock_at", "descending")).to eq(format_timestamps([@override2.lock_at, @override1.lock_at]))
        end

        it "orders NULL values at the end if descending order" do
          expect(sorted_results("lockAt", "lock_at", "descending")).to eq(format_timestamps([@override2.lock_at, @override1.lock_at]))
          @override2.lock_at = nil
          @override2.save!
          expect(sorted_results("lockAt", "lock_at", "descending")).to eq(format_timestamps([@override1.lock_at, @override2.lock_at]))
        end

        context "argument validation" do
          it "raises graphql error if sort field is invalid" do
            expect { sorted_results("title", "invalid_sort_field") }.to raise_error(GraphQLTypeTester::Error)
          end

          it "raises graphql error if sort direction is invalid" do
            expect { sorted_results("title", "title", "invalid_sort_direction") }.to raise_error(GraphQLTypeTester::Error)
          end
        end
      end

      context "pagination" do
        it "paginates results" do
          expect(paginated_results("title", 1).length).to eq 1
          expect(paginated_results_next_page(1)).to be true
          expect(paginated_results("title", 2).length).to eq 2
          expect(paginated_results_next_page(2)).to be false
        end
      end
    end

    context "when user does not have permissions to manage assignments" do
      it "returns nil" do
        expect(student_overridden_assignment_type.resolve(
                 "assignmentTargetConnection { edges { node { title } } }"
               )).to be_nil
      end
    end

    context "anonymous_student_identities" do
      context "when user does not have manage_grades permission" do
        let(:context) { { current_user: student } }

        it "returns null in place of the PostPolicy" do
          resolver = GraphQLTypeTester.new(assignment, context)
          expect(resolver.resolve("anonymousStudentIdentities {anonymousId}")).to be_nil
        end
      end

      context "when user has manage_grades permission" do
        let(:context) { { current_user: teacher } }
        let(:resolver) { GraphQLTypeTester.new(assignment, context) }

        it "returns the anonymous student identities for the assignment" do
          assignment.anonymous_grading = true
          assignment.save!
          result = resolver.resolve("anonymousStudentIdentities {anonymousId}")
          expect(result).to match_array(assignment.submissions.pluck(:anonymous_id))
        end
      end
    end
  end

  describe "assignmentVisibility" do
    it "returns assignment visiblity for teachers" do
      expect(teacher_assignment_type.resolve("assignmentVisibility")).to eq assignment_visibility
    end

    it "returns nil as assignment visiblity for non-authorized users" do
      expect(assignment_type.resolve("assignmentVisibility")).to be_nil
    end
  end

  describe "module_items" do
    let_once(:module_1) { course.context_modules.create!(name: "module 1") }
    let_once(:module_2) { course.context_modules.create!(name: "module 2") }

    let(:regular_assignment) do
      assignment = course.assignments.create!(
        title: "regular assignment",
        submission_types: "online_text_entry"
      )
      module_1.add_item(type: "assignment", id: assignment.id)
      assignment
    end

    let(:multi_module_assignment) do
      assignment = course.assignments.create!(
        title: "multi module assignment",
        submission_types: "online_text_entry,online_upload"
      )
      module_1.add_item(type: "assignment", id: assignment.id)
      module_2.add_item(type: "assignment", id: assignment.id)
      assignment
    end

    let(:quiz_assignment) do
      quiz = course.quizzes.create!(title: "test quiz")
      quiz.publish!
      module_1.add_item(type: "quiz", id: quiz.id)
      quiz.assignment
    end

    let(:discussion_assignment) do
      discussion = course.discussion_topics.create!(
        title: "test discussion",
        assignment: course.assignments.create!
      )
      module_1.add_item(type: "discussion_topic", id: discussion.id)
      discussion.assignment
    end

    let(:orphaned_assignment) do
      course.assignments.create!(title: "orphaned assignment")
    end

    it "returns module items for regular assignment" do
      resolver = GraphQLTypeTester.new(regular_assignment, current_user: teacher)
      expect(resolver.resolve("moduleItems { _id }")).to eq(regular_assignment.context_module_tags.map { |tag| tag.id.to_s })
      expect(resolver.resolve("moduleItems { position }")).to eq(regular_assignment.context_module_tags.map(&:position))
      expect(resolver.resolve("moduleItems { content { type } }")).to eq ["Assignment"]
      expect(resolver.resolve("moduleItems { module { _id } }")).to eq [module_1.id.to_s]
    end

    it "returns module items for quiz assignment" do
      resolver = GraphQLTypeTester.new(quiz_assignment, current_user: teacher)
      expect(resolver.resolve("moduleItems { _id }")).to eq(quiz_assignment.quiz.context_module_tags.map { |tag| tag.id.to_s })
      expect(resolver.resolve("moduleItems { position }")).to eq(quiz_assignment.quiz.context_module_tags.map(&:position))
      expect(resolver.resolve("moduleItems { content { type } }")).to eq ["Quizzes::Quiz"]
      expect(resolver.resolve("moduleItems { module { _id } }")).to eq [module_1.id.to_s]
    end

    it "returns module items for discussion assignment" do
      resolver = GraphQLTypeTester.new(discussion_assignment, current_user: teacher)
      expect(resolver.resolve("moduleItems { _id }")).to eq(discussion_assignment.discussion_topic.context_module_tags.map { |tag| tag.id.to_s })
      expect(resolver.resolve("moduleItems { position }")).to eq(discussion_assignment.discussion_topic.context_module_tags.map(&:position))
      expect(resolver.resolve("moduleItems { content { type } }")).to eq ["DiscussionTopic"]
      expect(resolver.resolve("moduleItems { module { _id } }")).to eq [module_1.id.to_s]
    end

    it "returns empty array when assignment is not in any module" do
      resolver = GraphQLTypeTester.new(orphaned_assignment, current_user: teacher)
      module_items = resolver.resolve("moduleItems { id }")

      expect(module_items).to eq []
    end

    it "returns multiple module items for an assignment in multiple modules" do
      resolver = GraphQLTypeTester.new(multi_module_assignment, current_user: teacher)

      expect(resolver.resolve("moduleItems { _id }")).to eq(multi_module_assignment.context_module_tags.map { |tag| tag.id.to_s })
      expect(resolver.resolve("moduleItems { position }")).to eq(multi_module_assignment.context_module_tags.map(&:position))
      expect(resolver.resolve("moduleItems { content { type } }")).to eq ["Assignment", "Assignment"]
      expect(resolver.resolve("moduleItems { module { _id } }")).to eq [module_1.id.to_s, module_2.id.to_s]
    end

    it "returns nil for module_items when quiz is nil (CNVS-15477)" do
      orphaned_quiz = course.assignments.create!(title: "orphaned quiz")
      orphaned_quiz.update_column(:submission_types, "online_quiz")

      expect(orphaned_quiz.submission_types).to eq "online_quiz"
      expect(orphaned_quiz.quiz).to be_nil

      resolver = GraphQLTypeTester.new(orphaned_quiz, current_user: teacher)
      expect(resolver.resolve("moduleItems { id }")).to be_nil
    end

    it "returns nil for module_items when discussion_topic is nil" do
      orphaned_discussion = course.assignments.create!(title: "orphaned discussion")
      orphaned_discussion.update_column(:submission_types, "discussion_topic")

      expect(orphaned_discussion.submission_types).to eq "discussion_topic"
      expect(orphaned_discussion.discussion_topic).to be_nil

      resolver = GraphQLTypeTester.new(orphaned_discussion, current_user: teacher)
      expect(resolver.resolve("moduleItems { id }")).to be_nil
    end
  end

  describe "assigned_students" do
    let(:regular_assignment) do
      course.assignments.create!(
        title: "regular assignment",
        submission_types: "online_text_entry"
      )
    end

    let_once(:student2) do
      user = user_factory(name: "First Last", account: @account)
      student_in_course(course:, user:, active_all: true).user
    end

    let_once(:fake_student) { course.student_view_student }

    it "returns students with assignment visibility when user has :manage_grades permission" do
      resolver = GraphQLTypeTester.new(regular_assignment, current_user: teacher)
      expect(resolver.resolve("assignedStudents { nodes { _id } }")).to match_array [student.id.to_s, student2.id.to_s]
    end

    it "returns nil when user doesn't have :manage_grades permission" do
      resolver = GraphQLTypeTester.new(regular_assignment, current_user: student)
      expect(resolver.resolve("assignedStudents { nodes { _id } }")).to be_nil
    end

    it "doesn't include fake students" do
      resolver = GraphQLTypeTester.new(regular_assignment, current_user: teacher)
      expect(resolver.resolve("assignedStudents { nodes { _id } }")).not_to include(fake_student.id.to_s)
    end

    it "filters by search term" do
      resolver = GraphQLTypeTester.new(regular_assignment, current_user: teacher)
      expect(resolver.resolve("assignedStudents (filter: { searchTerm: \"First\" }) { edges { node { name } } }")).to include(student2.name)
    end

    it "raises an error if search term is too short" do
      resolver = GraphQLTypeTester.new(regular_assignment, current_user: teacher)
      expect_error = "search term must be at least"
      expect do
        resolver.resolve("assignedStudents (filter: { searchTerm: \"a\" }) { edges { node { name } } }")
      end.to raise_error(GraphQLTypeTester::Error, /#{Regexp.escape(expect_error)}/)
    end

    it "only returns students who have visibility for the assignment" do
      create_adhoc_override_for_assignment(regular_assignment, student2)
      regular_assignment.update!(only_visible_to_overrides: true)
      resolver = GraphQLTypeTester.new(regular_assignment, current_user: teacher)
      result = resolver.resolve("assignedStudents { nodes { _id } }")
      expect(result).to eq [student2.id.to_s]
      expect(result).not_to include(student.id.to_s)
    end

    describe "assigned_students with peer review status" do
      before(:once) do
        @peer_review_course = course_factory(active_all: true)
        @peer_review_teacher = teacher_in_course(active_all: true, course: @peer_review_course).user
        @peer_review_assignment = @peer_review_course.assignments.create!(
          title: "Peer Review Assignment",
          points_possible: 10,
          peer_reviews: true,
          peer_review_count: 2
        )
        @student1 = student_in_course(course: @peer_review_course, name: "Student One", active_all: true).user
        @student2 = student_in_course(course: @peer_review_course, name: "Student Two", active_all: true).user

        @peer_review_course.enable_feature!(:peer_review_allocation_and_grading)

        AllocationRule.create!(
          assignment: @peer_review_assignment,
          course: @peer_review_course,
          assessor: @student1,
          assessee: @student2,
          must_review: true
        )

        submission1 = @peer_review_assignment.submit_homework(@student1, {
                                                                submission_type: "online_text_entry",
                                                                body: "Student 1 submission"
                                                              })
        submission2 = @peer_review_assignment.submit_homework(@student2, {
                                                                submission_type: "online_text_entry",
                                                                body: "Student 2 submission"
                                                              })
        AssessmentRequest.create!(
          asset: submission2,
          assessor_asset: submission1,
          user: @student2,
          assessor: @student1,
          workflow_state: "completed"
        )
      end

      let(:peer_review_assignment_type) { GraphQLTypeTester.new(@peer_review_assignment, current_user: @peer_review_teacher) }

      it "includes peer review status for assigned students" do
        must_review_count = peer_review_assignment_type.resolve("assignedStudents { nodes { peerReviewStatus { mustReviewCount } } }")
        expect(must_review_count.length).to eq(2)
        expect(must_review_count.sort).to eq([0, 1])

        completed_reviews_count = peer_review_assignment_type.resolve("assignedStudents { nodes { peerReviewStatus { completedReviewsCount } } }")
        expect(completed_reviews_count.sort).to eq([0, 1])
      end

      it "returns nil for peer review status when user lacks grade permission" do
        student_assignment_type = GraphQLTypeTester.new(@peer_review_assignment, current_user: @student1)

        result = student_assignment_type.resolve("assignedStudents { nodes { peerReviewStatus { mustReviewCount } } }")
        expect(result).to be_nil
      end

      it "returns nil for peer review status when feature is disabled" do
        @peer_review_course.disable_feature!(:peer_review_allocation_and_grading)

        result = peer_review_assignment_type.resolve("assignedStudents { nodes { peerReviewStatus { mustReviewCount } } }")

        # Should still return students but with nil peer review status
        expect(result.length).to eq(2)
        expect(result).to all(be_nil)
      end

      it "returns nil for peer review status when peer reviews are disabled" do
        @peer_review_assignment.update!(peer_reviews: false)

        result = peer_review_assignment_type.resolve("assignedStudents { nodes { peerReviewStatus { mustReviewCount } } }")

        # Should still return students but with nil peer review status
        expect(result.length).to eq(2)
        expect(result).to all(be_nil)
      end

      it "filters students with search term and maintains peer review status" do
        result = peer_review_assignment_type.resolve("assignedStudents (filter: { searchTerm: \"Student One\" }) { edges { node { peerReviewStatus { mustReviewCount } } } }")

        expect(result.length).to eq(1)
        expect(result.first).to eq(1)
      end
    end

    describe "section-limited visibility" do
      before(:once) do
        @section1 = course.course_sections.create!(name: "Section 1")
        @section2 = course.course_sections.create!(name: "Section 2")

        @student_section1 = user_factory(name: "Student Section 1", account: @account)
        student_in_course(course:, user: @student_section1, section: @section1, active_all: true)

        @student_section2 = user_factory(name: "Student Section 2", account: @account)
        student_in_course(course:, user: @student_section2, section: @section2, active_all: true)

        @section_limited_teacher = user_factory(name: "Section Limited Teacher", account: @account)
        teacher_in_course(
          course:,
          user: @section_limited_teacher,
          section: @section1,
          active_all: true,
          limit_privileges_to_course_section: true
        )
      end

      it "returns only students from teacher's section when teacher has limited section privileges" do
        resolver = GraphQLTypeTester.new(regular_assignment, current_user: @section_limited_teacher)
        result = resolver.resolve("assignedStudents { nodes { _id } }")
        expect(result).to include(@student_section1.id.to_s)
        expect(result).not_to include(@student_section2.id.to_s)
      end

      it "returns all students when teacher has no section limits" do
        resolver = GraphQLTypeTester.new(regular_assignment, current_user: teacher)
        result = resolver.resolve("assignedStudents { nodes { _id } }")
        expect(result).to include(@student_section1.id.to_s)
        expect(result).to include(@student_section2.id.to_s)
      end

      it "respects both section visibility and differentiated assignments" do
        create_adhoc_override_for_assignment(regular_assignment, @student_section1)
        regular_assignment.update!(only_visible_to_overrides: true)

        resolver = GraphQLTypeTester.new(regular_assignment, current_user: @section_limited_teacher)
        result = resolver.resolve("assignedStudents { nodes { _id } }")
        expect(result).to eq([@student_section1.id.to_s])
        expect(result).not_to include(@student_section2.id.to_s)
      end

      it "filters by search term within section-limited scope" do
        resolver = GraphQLTypeTester.new(regular_assignment, current_user: @section_limited_teacher)
        result = resolver.resolve("assignedStudents (filter: { searchTerm: \"Section 1\" }) { nodes { name } }")
        expect(result).to eq([@student_section1.name])
        expect(result).not_to include(@student_section2.name)
      end

      it "returns empty when section-limited teacher has no students in their section assigned to the assignment" do
        create_adhoc_override_for_assignment(regular_assignment, @student_section2)
        regular_assignment.update!(only_visible_to_overrides: true)

        resolver = GraphQLTypeTester.new(regular_assignment, current_user: @section_limited_teacher)
        result = resolver.resolve("assignedStudents { nodes { _id } }")
        expect(result).to be_empty
      end

      it "excludes students with enrollments that are not active by date" do
        course.update!(
          conclude_at: 1.day.ago,
          restrict_enrollments_to_course_dates: true
        )
        course.reload

        @student_concluded = user_factory(name: "Student Concluded", account: @account)
        student_in_course(course:, user: @student_concluded, active_all: true)

        resolver = GraphQLTypeTester.new(regular_assignment, current_user: teacher)
        result = resolver.resolve("assignedStudents { nodes { _id } }")

        expect(result).not_to include(@student_concluded.id.to_s)
        expect(result).not_to include(student.id.to_s)
      end
    end
  end

  describe "graderIdentitiesConnection" do
    before(:once) do
      @admin = account_admin_user(account: @account, name: "Admin")
      @grader_teacher = user_factory(active_all: true, name: "Grader Teacher")
      @student = user_factory(active_all: true, name: "Student")
      @moderator = user_factory(active_all: true, name: "Moderator")
      @course = course_factory(active_all: true)
      @course.enroll_teacher(@grader_teacher, enrollment_state: "active")
      @course.enroll_student(@student, enrollment_state: "active")
      @course.enroll_teacher(@moderator, enrollment_state: "active")

      @assignment = @course.assignments.create!(name: "assignment")

      @moderated_assignment = @course.assignments.create!(
        name: "moderated assignment",
        moderated_grading: true,
        grader_count: 2,
        final_grader: @moderator
      )
      @moderated_assignment.grade_student(@student, grader: @grader_teacher, provisional: true, score: 10)
      @moderated_assignment.grade_student(@student, grader: @moderator, provisional: true, score: 20)
    end

    def type(assignment, current_user)
      GraphQLTypeTester.new(assignment, current_user:)
    end

    it "returns nil for non-moderated assignments" do
      res = type(@assignment, @moderator).resolve("graderIdentitiesConnection { nodes { name } }")
      expect(res).to be_nil
    end

    it "returns nil for non-authorized users" do
      res = type(@moderated_assignment, @student).resolve("graderIdentitiesConnection { nodes { name } }")
      expect(res).to be_nil
    end

    %w[admin moderator grader_teacher].each do |user_type|
      it "returns all provisional grades for #{user_type}s" do
        user = instance_variable_get("@#{user_type}")
        res = type(@moderated_assignment, user).resolve("graderIdentitiesConnection { nodes { name } }")
        expect(res).to match_array(["Moderator", "Grader Teacher"])
      end
    end

    context "when grader names are anonymous to final grader" do
      before(:once) do
        @moderated_assignment.update!(grader_names_visible_to_final_grader: false)
      end

      it "final grader sees anonymous names" do
        res = type(@moderated_assignment, @moderator).resolve("graderIdentitiesConnection { nodes { name } }")
        expect(res).to eq ["Grader 1", "Grader 2"]
      end

      it "provisional grader sees non-anonymous names" do
        res = type(@moderated_assignment, @grader_teacher).resolve("graderIdentitiesConnection { nodes { name } }")
        expect(res).not_to eq ["Grader 1", "Grader 2"]
        expect(res).to match_array(["Moderator", "Grader Teacher"])
      end
    end

    shared_examples "grader name visibility" do
      it "final grader sees non-anonymous names" do
        res = type(@moderated_assignment, @moderator).resolve("graderIdentitiesConnection { nodes { name } }")

        expect(res).not_to eq ["Grader 1", "Grader 2"]
        expect(res).to match_array(["Moderator", "Grader Teacher"])
      end

      it "provisional grader sees anonymous names" do
        res = type(@moderated_assignment, @grader_teacher).resolve("graderIdentitiesConnection { nodes { name } }")
        expect(res).to eq ["Grader 1", "Grader 2"]
      end
    end

    context "when grader comments are anonymous to graders" do
      before(:once) do
        @moderated_assignment.update!(grader_comments_visible_to_graders: false)
      end

      it_behaves_like "grader name visibility"
    end

    context "when grader names are anonymous to graders" do
      before(:once) do
        @moderated_assignment.update!(graders_anonymous_to_graders: true)
      end

      it_behaves_like "grader name visibility"
    end
  end

  describe "assignedToDates field" do
    it "includes assignment overrides when present" do
      override = assignment_override_model(assignment:, due_at: 2.weeks.from_now)
      override.assignment_override_students.build(user: student)
      override.save!

      result = assignment_type.resolve("assignedToDates { id dueAt title base }")
      expect(result).to be_an(Array)
      expect(result.length).to eq(1)
    end

    describe "peerReviewDates" do
      let(:peer_review_assignment) do
        course.assignments.create!(
          title: "Peer Review Assignment",
          points_possible: 10,
          peer_reviews: true,
          peer_review_count: 2
        )
      end
      let(:peer_review_assignment_type) { GraphQLTypeTester.new(peer_review_assignment, current_user: student) }
      let(:teacher_peer_review_assignment_type) { GraphQLTypeTester.new(peer_review_assignment, current_user: teacher) }

      before do
        course.enable_feature!(:peer_review_allocation_and_grading)
      end

      it "returns nil when peer_review_sub_assignment does not exist" do
        peer_review_assignment_type.extract_result = false
        result = peer_review_assignment_type.resolve("assignedToDates { dueAt peerReviewDates { dueAt unlockAt lockAt } }")
        assigned_to_dates = result["assignedToDates"]

        expect(assigned_to_dates).to be_an(Array)
        expect(assigned_to_dates).not_to be_empty
        expect(assigned_to_dates.first["peerReviewDates"]).to be_nil
      end

      context "with peer_review_sub_assignment" do
        let!(:peer_review_sub) do
          service = PeerReview::PeerReviewCreatorService.new(
            parent_assignment: peer_review_assignment,
            points_possible: 5
          )
          service.call

          peer_review_assignment.reload.peer_review_sub_assignment.tap do |sub|
            sub.update!(
              due_at: 2.weeks.from_now,
              unlock_at: 1.week.from_now,
              lock_at: 3.weeks.from_now
            )
          end
        end

        it "includes peerReviewDates for student" do
          peer_review_assignment_type.extract_result = false
          result = peer_review_assignment_type.resolve("assignedToDates { dueAt peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates = result["assignedToDates"]

          expect(assigned_to_dates).to be_an(Array)
          expect(assigned_to_dates).not_to be_empty

          peer_review_dates = assigned_to_dates.first["peerReviewDates"]
          expect(peer_review_dates).not_to be_nil
          expect(Time.iso8601(peer_review_dates["dueAt"]).to_i).to eq(peer_review_sub.due_at.to_i)
          expect(Time.iso8601(peer_review_dates["unlockAt"]).to_i).to eq(peer_review_sub.unlock_at.to_i)
          expect(Time.iso8601(peer_review_dates["lockAt"]).to_i).to eq(peer_review_sub.lock_at.to_i)
        end

        it "includes peerReviewDates for teacher" do
          teacher_peer_review_assignment_type.extract_result = false
          result = teacher_peer_review_assignment_type.resolve("assignedToDates { dueAt peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates = result["assignedToDates"]

          expect(assigned_to_dates).to be_an(Array)
          expect(assigned_to_dates).not_to be_empty

          peer_review_dates = assigned_to_dates.first["peerReviewDates"]
          expect(peer_review_dates).not_to be_nil
          expect(Time.iso8601(peer_review_dates["dueAt"]).to_i).to eq(peer_review_sub.due_at.to_i)
          expect(Time.iso8601(peer_review_dates["unlockAt"]).to_i).to eq(peer_review_sub.unlock_at.to_i)
          expect(Time.iso8601(peer_review_dates["lockAt"]).to_i).to eq(peer_review_sub.lock_at.to_i)
        end

        it "returns null values when peer review dates are not set" do
          peer_review_sub.update!(due_at: nil, unlock_at: nil, lock_at: nil)

          peer_review_assignment_type.extract_result = false
          result = peer_review_assignment_type.resolve("assignedToDates { dueAt peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates = result["assignedToDates"]

          expect(assigned_to_dates).to be_an(Array)
          expect(assigned_to_dates).not_to be_empty

          peer_review_dates = assigned_to_dates.first["peerReviewDates"]
          expect(peer_review_dates).not_to be_nil
          expect(peer_review_dates["dueAt"]).to be_nil
          expect(peer_review_dates["unlockAt"]).to be_nil
          expect(peer_review_dates["lockAt"]).to be_nil
        end

        it "includes override-specific peerReviewDates using parent_override relationship" do
          section1 = course.course_sections.create!(name: "Section 1")
          section2 = course.course_sections.create!(name: "Section 2")

          section1_pr_due = 2.weeks.from_now
          section1_pr_unlock = 1.5.weeks.from_now
          section1_pr_lock = 2.5.weeks.from_now
          section2_pr_due = 12.days.from_now
          section2_pr_unlock = 11.days.from_now
          section2_pr_lock = 13.days.from_now

          parent_override1 = peer_review_assignment.assignment_overrides.create!(
            set: section1,
            due_at: 1.week.from_now
          )
          parent_override2 = peer_review_assignment.assignment_overrides.create!(
            set: section2,
            due_at: 10.days.from_now
          )

          peer_review_sub.assignment_overrides.create!(
            parent_override: parent_override1,
            set: section1,
            due_at: section1_pr_due,
            unlock_at: section1_pr_unlock,
            lock_at: section1_pr_lock
          )
          peer_review_sub.assignment_overrides.create!(
            parent_override: parent_override2,
            set: section2,
            due_at: section2_pr_due,
            unlock_at: section2_pr_unlock,
            lock_at: section2_pr_lock
          )

          teacher_peer_review_assignment_type.extract_result = false
          result = teacher_peer_review_assignment_type.resolve("assignedToDates { id dueAt title peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates = result["assignedToDates"]

          expect(assigned_to_dates).to be_an(Array)
          expect(assigned_to_dates.length).to be >= 2

          section1_entry = assigned_to_dates.find { |e| e["id"] == parent_override1.id.to_s }
          expect(section1_entry).not_to be_nil
          section1_peer_review_dates = section1_entry["peerReviewDates"]
          expect(section1_peer_review_dates).not_to be_nil
          expect(Time.iso8601(section1_peer_review_dates["dueAt"]).to_i).to eq(section1_pr_due.to_i)
          expect(Time.iso8601(section1_peer_review_dates["unlockAt"]).to_i).to eq(section1_pr_unlock.to_i)
          expect(Time.iso8601(section1_peer_review_dates["lockAt"]).to_i).to eq(section1_pr_lock.to_i)

          section2_entry = assigned_to_dates.find { |e| e["id"] == parent_override2.id.to_s }
          expect(section2_entry).not_to be_nil
          section2_peer_review_dates = section2_entry["peerReviewDates"]
          expect(section2_peer_review_dates).not_to be_nil
          expect(Time.iso8601(section2_peer_review_dates["dueAt"]).to_i).to eq(section2_pr_due.to_i)
          expect(Time.iso8601(section2_peer_review_dates["unlockAt"]).to_i).to eq(section2_pr_unlock.to_i)
          expect(Time.iso8601(section2_peer_review_dates["lockAt"]).to_i).to eq(section2_pr_lock.to_i)
        end

        it "falls back to base peer review dates when override has no matching peer review override" do
          section1 = course.course_sections.create!(name: "Section 1")

          parent_override = peer_review_assignment.assignment_overrides.create!(
            set: section1,
            due_at: 1.week.from_now
          )

          teacher_peer_review_assignment_type.extract_result = false
          result = teacher_peer_review_assignment_type.resolve("assignedToDates { id dueAt title peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates = result["assignedToDates"]

          expect(assigned_to_dates).to be_an(Array)
          section1_entry = assigned_to_dates.find { |e| e["id"] == parent_override.id.to_s }
          expect(section1_entry).not_to be_nil

          peer_review_dates = section1_entry["peerReviewDates"]
          expect(peer_review_dates).not_to be_nil
          expect(Time.iso8601(peer_review_dates["dueAt"]).to_i).to eq(peer_review_sub.due_at.to_i)
          expect(Time.iso8601(peer_review_dates["unlockAt"]).to_i).to eq(peer_review_sub.unlock_at.to_i)
          expect(Time.iso8601(peer_review_dates["lockAt"]).to_i).to eq(peer_review_sub.lock_at.to_i)
        end

        it "includes base peer review dates for base entries" do
          teacher_peer_review_assignment_type.extract_result = false
          result = teacher_peer_review_assignment_type.resolve("assignedToDates { dueAt title base peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates = result["assignedToDates"]

          expect(assigned_to_dates).to be_an(Array)
          base_entry = assigned_to_dates.find { |e| e["base"] == true }
          expect(base_entry).not_to be_nil

          peer_review_dates = base_entry["peerReviewDates"]
          expect(peer_review_dates).not_to be_nil
          expect(Time.iso8601(peer_review_dates["dueAt"]).to_i).to eq(peer_review_sub.due_at.to_i)
          expect(Time.iso8601(peer_review_dates["unlockAt"]).to_i).to eq(peer_review_sub.unlock_at.to_i)
          expect(Time.iso8601(peer_review_dates["lockAt"]).to_i).to eq(peer_review_sub.lock_at.to_i)
        end

        it "students only see their assigned peer review dates" do
          section1 = course.course_sections.create!(name: "Section 1")
          section2 = course.course_sections.create!(name: "Section 2")

          student1 = user_factory(active_all: true)
          student2 = user_factory(active_all: true)
          course.enroll_student(student1, section: section1, enrollment_state: "active")
          course.enroll_student(student2, section: section2, enrollment_state: "active")

          section1_pr_due = 2.weeks.from_now
          section1_pr_unlock = 1.5.weeks.from_now
          section1_pr_lock = 2.5.weeks.from_now
          section2_pr_due = 3.weeks.from_now
          section2_pr_unlock = 2.5.weeks.from_now
          section2_pr_lock = 3.5.weeks.from_now

          parent_override1 = peer_review_assignment.assignment_overrides.create!(
            set: section1,
            due_at: 1.week.from_now
          )
          parent_override2 = peer_review_assignment.assignment_overrides.create!(
            set: section2,
            due_at: 10.days.from_now
          )

          peer_review_sub.assignment_overrides.create!(
            parent_override: parent_override1,
            set: section1,
            due_at: section1_pr_due,
            unlock_at: section1_pr_unlock,
            lock_at: section1_pr_lock
          )
          peer_review_sub.assignment_overrides.create!(
            parent_override: parent_override2,
            set: section2,
            due_at: section2_pr_due,
            unlock_at: section2_pr_unlock,
            lock_at: section2_pr_lock
          )

          student1_type = GraphQLTypeTester.new(peer_review_assignment, current_user: student1)
          student1_type.extract_result = false
          result1 = student1_type.resolve("assignedToDates { id dueAt title peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates1 = result1["assignedToDates"]

          expect(assigned_to_dates1).to be_an(Array)
          expect(assigned_to_dates1.length).to eq(1)
          student1_entry = assigned_to_dates1.first
          student1_peer_review_dates = student1_entry["peerReviewDates"]
          expect(student1_peer_review_dates).not_to be_nil
          expect(Time.iso8601(student1_peer_review_dates["dueAt"]).to_i).to eq(section1_pr_due.to_i)
          expect(Time.iso8601(student1_peer_review_dates["unlockAt"]).to_i).to eq(section1_pr_unlock.to_i)
          expect(Time.iso8601(student1_peer_review_dates["lockAt"]).to_i).to eq(section1_pr_lock.to_i)

          student2_type = GraphQLTypeTester.new(peer_review_assignment, current_user: student2)
          student2_type.extract_result = false
          result2 = student2_type.resolve("assignedToDates { id dueAt title peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates2 = result2["assignedToDates"]

          expect(assigned_to_dates2).to be_an(Array)
          expect(assigned_to_dates2.length).to eq(1)
          student2_entry = assigned_to_dates2.first
          student2_peer_review_dates = student2_entry["peerReviewDates"]
          expect(student2_peer_review_dates).not_to be_nil
          expect(Time.iso8601(student2_peer_review_dates["dueAt"]).to_i).to eq(section2_pr_due.to_i)
          expect(Time.iso8601(student2_peer_review_dates["unlockAt"]).to_i).to eq(section2_pr_unlock.to_i)
          expect(Time.iso8601(student2_peer_review_dates["lockAt"]).to_i).to eq(section2_pr_lock.to_i)
        end

        it "returns distinct peer review dates for both section and ADHOC overrides when student has both" do
          section1 = course.course_sections.create!(name: "Section 1")
          student1 = user_factory(active_all: true)
          course.enroll_student(student1, section: section1, enrollment_state: "active")

          section1_pr_due = 2.weeks.from_now
          section1_pr_unlock = 1.5.weeks.from_now
          section1_pr_lock = 2.5.weeks.from_now
          adhoc_pr_due = 3.weeks.from_now
          adhoc_pr_unlock = 2.5.weeks.from_now
          adhoc_pr_lock = 3.5.weeks.from_now

          parent_section_override = peer_review_assignment.assignment_overrides.create!(
            set: section1,
            due_at: 1.week.from_now
          )

          parent_adhoc_override = peer_review_assignment.assignment_overrides.create!(
            due_at: 10.days.from_now
          )
          parent_adhoc_override.assignment_override_students.create!(user: student1)

          peer_review_sub.assignment_overrides.create!(
            parent_override: parent_section_override,
            set: section1,
            due_at: section1_pr_due,
            unlock_at: section1_pr_unlock,
            lock_at: section1_pr_lock
          )
          peer_review_sub.assignment_overrides.create!(
            parent_override: parent_adhoc_override,
            due_at: adhoc_pr_due,
            unlock_at: adhoc_pr_unlock,
            lock_at: adhoc_pr_lock
          )

          student1_type = GraphQLTypeTester.new(peer_review_assignment, current_user: student1)
          student1_type.extract_result = false
          result = student1_type.resolve("assignedToDates { id dueAt title peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates = result["assignedToDates"]

          expect(assigned_to_dates).to be_an(Array)
          expect(assigned_to_dates.length).to eq(2)

          # Verify section override and its peer review dates
          section_entry = assigned_to_dates.find { |e| e["id"] == parent_section_override.id.to_s }
          expect(section_entry).not_to be_nil
          section_peer_review_dates = section_entry["peerReviewDates"]
          expect(section_peer_review_dates).not_to be_nil
          expect(Time.iso8601(section_peer_review_dates["dueAt"]).to_i).to eq(section1_pr_due.to_i)

          # Verify ADHOC override and its peer review dates
          adhoc_entry = assigned_to_dates.find { |e| e["id"] == parent_adhoc_override.id.to_s }
          expect(adhoc_entry).not_to be_nil
          adhoc_peer_review_dates = adhoc_entry["peerReviewDates"]
          expect(adhoc_peer_review_dates).not_to be_nil
          expect(Time.iso8601(adhoc_peer_review_dates["dueAt"]).to_i).to eq(adhoc_pr_due.to_i)
          expect(Time.iso8601(adhoc_peer_review_dates["unlockAt"]).to_i).to eq(adhoc_pr_unlock.to_i)
          expect(Time.iso8601(adhoc_peer_review_dates["lockAt"]).to_i).to eq(adhoc_pr_lock.to_i)

          # Verify both overrides maintain their own distinct peer review dates
          expect(adhoc_peer_review_dates["dueAt"]).not_to eq(section_peer_review_dates["dueAt"])
        end

        it "returns nil when feature flag is disabled" do
          course.disable_feature!(:peer_review_allocation_and_grading)

          peer_review_assignment_type.extract_result = false
          result = peer_review_assignment_type.resolve("assignedToDates { dueAt peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates = result["assignedToDates"]

          expect(assigned_to_dates).to be_an(Array)
          expect(assigned_to_dates).not_to be_empty
          expect(assigned_to_dates.first["peerReviewDates"]).to be_nil
        end

        it "returns nil when peer_review_sub_assignment is deleted" do
          peer_review_sub.update!(workflow_state: "deleted")

          peer_review_assignment_type.extract_result = false
          result = peer_review_assignment_type.resolve("assignedToDates { dueAt peerReviewDates { dueAt unlockAt lockAt } }")
          assigned_to_dates = result["assignedToDates"]

          expect(assigned_to_dates).to be_an(Array)
          expect(assigned_to_dates).not_to be_empty
          expect(assigned_to_dates.first["peerReviewDates"]).to be_nil
        end
      end
    end
  end

  describe "N+1 query prevention" do
    it "prevents N+1 queries when accessing assignment overrides and dates" do
      # Create assignments with context modules
      module1 = course.context_modules.create!(name: "Module 1")
      assignments = []
      5.times do |i|
        assignment = course.assignments.create!(title: "Assignment #{i}")
        assignment.context_module_tags.create!(context_module: module1, context: course, tag_type: "context_module")
        assignments << assignment
      end

      # Create some overrides
      module1.assignment_overrides.create!

      # Build GraphQL query that accesses fields that could cause N+1 queries
      query = <<~GQL
        query {
          course(id: "#{course.id}") {
            assignmentsConnection {
              nodes {
                id
                visibleToEveryone
                assignmentOverrides {
                  nodes {
                    id
                  }
                }
              }
            }
          }
        }
      GQL

      # Track N+1 queries to module_ids/assignment_context_modules
      module_query_count = 0
      override_query_count = 0

      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
        # Check for module_ids N+1 queries
        if /FROM\s+["`]?context_modules["`]?\s+WHERE.*context_modules\.workflow_state.*context_modules\.id.*IN.*SELECT.*context_module_id/i.match?(payload[:sql])
          module_query_count += 1
        end
        # Check for assignment override N+1 queries
        if /FROM\s+["`]?assignment_overrides["`]?\s+WHERE.*assignment_overrides\.assignment_id.*LIMIT\s+1/i.match?(payload[:sql])
          override_query_count += 1
        end
      end

      # Execute the GraphQL query
      result = CanvasSchema.execute(query, context: { current_user: teacher, request: ActionDispatch::TestRequest.create })

      # Should be bulk loading, not N+1 queries
      expect(module_query_count).to be <= 1
      expect(override_query_count).to be <= 1

      # Verify the query succeeded
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "course", "assignmentsConnection", "nodes")).to be_present

      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it "prevents N+1 queries when accessing overridden date fields (OverrideAssignmentLoader)" do
      # Create multiple assignments with different due dates
      assignments = []
      5.times do |i|
        assignment = course.assignments.create!(
          title: "Assignment #{i}",
          due_at: (i + 1).days.from_now,
          lock_at: (i + 2).days.from_now,
          unlock_at: i.days.from_now
        )
        assignments << assignment
      end

      # Create some overrides that would trigger the loader logic
      assignments.first.assignment_overrides.create!(
        due_at: 1.week.from_now,
        set_type: "CourseSection",
        set_id: course.course_sections.first.id
      )

      # Build GraphQL query that accesses overridden date fields
      query = <<~GQL
        query {
          course(id: "#{course.id}") {
            assignmentsConnection {
              nodes {
                _id
                dueAt
                lockAt
                unlockAt
              }
            }
          }
        }
      GQL

      # Track queries that would indicate N+1 issues in override calculations
      override_query_count = 0
      student_query_count = 0

      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
        sql = payload[:sql]

        # Check for individual assignment override queries (N+1 pattern)
        if /assignment_overrides.*WHERE.*assignment_id.*= \?.*LIMIT/i.match?(sql) ||
           /assignment_overrides.*WHERE.*assignment_overrides\.assignment_id IN \(\?\)/i.match?(sql)
          override_query_count += 1
        end

        # Check for individual assignment override student queries (N+1 pattern)
        if /assignment_override_students.*assignment_override_id.*= \?/i.match?(sql)
          student_query_count += 1
        end
      end

      # Execute the GraphQL query
      result = CanvasSchema.execute(query, context: { current_user: teacher, request: ActionDispatch::TestRequest.create })

      # Should use bulk loading from OverrideAssignmentLoader, not individual queries per assignment
      expect(override_query_count).to be <= 2, "Expected ≤2 bulk override queries, got #{override_query_count} (indicates N+1)"
      expect(student_query_count).to be <= 2, "Expected ≤2 bulk student queries, got #{student_query_count} (indicates N+1)"

      # Verify the query succeeded and returned data
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "course", "assignmentsConnection", "nodes")).to be_present
      expect(result.dig("data", "course", "assignmentsConnection", "nodes").length).to eq 5

      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end

  describe "allocation_rules" do
    let(:assignment_with_peer_reviews) do
      course.assignments.create!(
        title: "Peer Review Assignment",
        points_possible: 10,
        submission_types: ["online_text_entry"],
        peer_reviews: true,
        peer_review_count: 2
      )
    end

    let(:student1) { student_in_course(course:, active_all: true).user }
    let(:student2) { student_in_course(course:, active_all: true).user }
    let(:student3) { student_in_course(course:, active_all: true).user }
    let(:ta) { ta_in_course(course:, active_all: true).user }
    let(:observer) { observer_in_course(course:, active_all: true).user }

    before do
      course.enable_feature!(:peer_review_allocation_and_grading)

      @allocation_rule_1 = AllocationRule.create!(
        course:,
        assignment: assignment_with_peer_reviews,
        assessor: student1,
        assessee: student2,
        must_review: true,
        review_permitted: true,
        applies_to_assessor: true
      )

      @allocation_rule_2 = AllocationRule.create!(
        course:,
        assignment: assignment_with_peer_reviews,
        assessor: student2,
        assessee: student3,
        must_review: true,
        review_permitted: true,
        applies_to_assessor: true
      )

      @teacher_assignment_type = GraphQLTypeTester.new(assignment_with_peer_reviews, current_user: teacher)
      @ta_assignment_type = GraphQLTypeTester.new(assignment_with_peer_reviews, current_user: ta)
      @student_assignment_type = GraphQLTypeTester.new(assignment_with_peer_reviews, current_user: student1)
      @observer_assignment_type = GraphQLTypeTester.new(assignment_with_peer_reviews, current_user: observer)
    end

    context "when user has grading permissions" do
      it "returns allocation rules for teachers" do
        result = @teacher_assignment_type.resolve("allocationRules { rulesConnection { nodes { _id } } }")
        expect(result).to eq([@allocation_rule_1.id.to_s, @allocation_rule_2.id.to_s])
      end

      it "returns allocation rules count for teachers" do
        result = @teacher_assignment_type.resolve("allocationRules { count }")
        expect(result).to eq 2
      end

      it "allows access to nested assessor and assessee information" do
        assessors = @teacher_assignment_type.resolve("allocationRules { rulesConnection { nodes { assessor { _id } } } }")
        assessees = @teacher_assignment_type.resolve("allocationRules { rulesConnection { nodes { assessee { _id } } } }")

        expect(assessors).to eq([@allocation_rule_1.assessor.id.to_s, @allocation_rule_2.assessor.id.to_s])
        expect(assessees).to eq([@allocation_rule_1.assessee.id.to_s, @allocation_rule_2.assessee.id.to_s])
      end

      it "allows TAs with grading permissions to access allocation rules" do
        result = @ta_assignment_type.resolve("allocationRules { rulesConnection { nodes { _id } } }")
        expect(result).to eq([@allocation_rule_1.id.to_s, @allocation_rule_2.id.to_s])
      end

      it "returns 0 when there are no allocation rules" do
        AllocationRule.destroy_all
        result = @teacher_assignment_type.resolve("allocationRules { count }")
        expect(result).to eq 0
      end

      it "only counts active allocation rules" do
        @allocation_rule_1.destroy
        result = @teacher_assignment_type.resolve("allocationRules { count }")
        expect(result).to eq 1
      end

      it "paginates rules connection results" do
        expect(@teacher_assignment_type.resolve("allocationRules { rulesConnection(first: 1) { edges { node { _id } } } }").length).to eq 1
        expect(@teacher_assignment_type.resolve("allocationRules { rulesConnection(first: 1) { pageInfo { hasNextPage } } }")).to be true
        expect(@teacher_assignment_type.resolve("allocationRules { rulesConnection(first: 2) { edges { node { _id } } } }").length).to eq 2
        expect(@teacher_assignment_type.resolve("allocationRules { rulesConnection(first: 2) { pageInfo { hasNextPage } } }")).to be false
      end
    end

    context "when user lacks grading permissions" do
      it "returns nil for students" do
        result = @student_assignment_type.resolve("allocationRules { rulesConnection { nodes { _id } } }")
        expect(result).to be_nil
      end

      it "returns nil for observers" do
        result = @observer_assignment_type.resolve("allocationRules { rulesConnection { nodes { _id } } }")
        expect(result).to be_nil
      end
    end

    context "when feature flag is disabled" do
      before do
        course.disable_feature!(:peer_review_allocation_and_grading)
      end

      it "returns nil even for teachers" do
        result = @teacher_assignment_type.resolve("allocationRules { rulesConnection { nodes { _id } } }")
        expect(result).to be_nil
      end
    end

    context "when peer reviews are disabled" do
      let(:assignment_without_peer_reviews) do
        course.assignments.create!(
          title: "Regular Assignment",
          points_possible: 10,
          submission_types: ["online_text_entry"],
          peer_reviews: false
        )
      end

      it "returns nil even for teachers" do
        peer_reviews_disabled_type = GraphQLTypeTester.new(assignment_without_peer_reviews, current_user: teacher)
        result = peer_reviews_disabled_type.resolve("allocationRules { rulesConnection { nodes { _id } } }")
        expect(result).to be_nil
      end
    end

    context "when assignment has no allocation rules" do
      let(:empty_assignment) do
        course.assignments.create!(
          title: "Empty Peer Review Assignment",
          points_possible: 10,
          submission_types: ["online_text_entry"],
          peer_reviews: true
        )
      end

      it "returns empty connection but valid count" do
        empty_type = GraphQLTypeTester.new(empty_assignment, current_user: teacher)
        result = empty_type.resolve("allocationRules { rulesConnection { nodes { _id } } }")
        count_result = empty_type.resolve("allocationRules { count }")

        expect(result).to be_empty
        expect(count_result).to eq 0
      end
    end

    context "with deleted allocation rules" do
      it "only returns active allocation rules" do
        AllocationRule.first.destroy
        result = @teacher_assignment_type.resolve("allocationRules { rulesConnection { nodes { workflowState } } }")
        count_result = @teacher_assignment_type.resolve("allocationRules { count }")

        expect(result.size).to eq 1
        expect(result.first).to eq "active"
        expect(count_result).to eq 1
      end
    end

    context "search functionality" do
      before do
        @search_assignment = course.assignments.create!(
          title: "Search Test Assignment",
          points_possible: 10,
          submission_types: ["online_text_entry"],
          peer_reviews: true,
          peer_review_count: 2
        )

        @frodo = student_in_course(course:, name: "Frodo Baggins", active_all: true).user
        @legolas = student_in_course(course:, name: "Legolas Greenleaf", active_all: true).user
        @bilbo = student_in_course(course:, name: "Bilbo Baggins", active_all: true).user
        @sam = student_in_course(course:, name: "Samwise Gamgee", active_all: true).user

        @rule_frodo_legolas = AllocationRule.create!(
          course:,
          assignment: @search_assignment,
          assessor: @frodo,
          assessee: @legolas,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )

        @rule_legolas_bilbo = AllocationRule.create!(
          course:,
          assignment: @search_assignment,
          assessor: @legolas,
          assessee: @bilbo,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )

        @rule_bilbo_sam = AllocationRule.create!(
          course:,
          assignment: @search_assignment,
          assessor: @bilbo,
          assessee: @sam,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )

        @search_teacher_assignment_type = GraphQLTypeTester.new(@search_assignment, current_user: teacher)
        @search_student_assignment_type = GraphQLTypeTester.new(@search_assignment, current_user: student1)
      end

      it "returns rules for specific assessor name" do
        result = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "Frodo" }) { nodes { _id } } }'
        )
        expect(result).to contain_exactly(@rule_frodo_legolas.id.to_s)
      end

      it "returns rules for specific assessee name" do
        result = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "Bilbo" }) { nodes { _id } } }'
        )
        expect(result).to contain_exactly(@rule_legolas_bilbo.id.to_s, @rule_bilbo_sam.id.to_s)
      end

      it "returns rules matching full name" do
        result = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "Legolas Greenleaf" }) { nodes { _id } } }'
        )
        expect(result).to contain_exactly(@rule_frodo_legolas.id.to_s, @rule_legolas_bilbo.id.to_s)
      end

      it "is case insensitive" do
        result_lower = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "frodo" }) { nodes { _id } } }'
        )
        result_upper = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "FRODO" }) { nodes { _id } } }'
        )
        result_mixed = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "FrOdo" }) { nodes { _id } } }'
        )

        expect(result_lower).to eq([@rule_frodo_legolas.id.to_s])
        expect(result_upper).to eq([@rule_frodo_legolas.id.to_s])
        expect(result_mixed).to eq([@rule_frodo_legolas.id.to_s])
      end

      it "returns empty result for no matches" do
        result = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "NonExistentName" }) { nodes { _id } } }'
        )
        expect(result).to be_empty
      end

      it "returns partial matches in names" do
        result = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "Baggins" }) { nodes { _id } } }'
        )
        expect(result).to contain_exactly(@rule_frodo_legolas.id.to_s, @rule_legolas_bilbo.id.to_s, @rule_bilbo_sam.id.to_s)
      end

      it "works with common prefixes" do
        result = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "Bag" }) { nodes { _id } } }'
        )
        expect(result).to contain_exactly(@rule_frodo_legolas.id.to_s, @rule_legolas_bilbo.id.to_s, @rule_bilbo_sam.id.to_s)
      end

      it "raises error for search term too short" do
        expect do
          @search_teacher_assignment_type.resolve(
            'allocationRules { rulesConnection(filter: { searchTerm: "a" }) { nodes { _id } } }'
          )
        end.to raise_error(GraphQLTypeTester::Error, /search term must be at least/)
      end

      it "works with minimum valid search term length" do
        min_length_term = "a" * SearchTermHelper::MIN_SEARCH_TERM_LENGTH
        expect do
          @search_teacher_assignment_type.resolve(
            "allocationRules { rulesConnection(filter: { searchTerm: \"#{min_length_term}\" }) { nodes { _id } } }"
          )
        end.not_to raise_error
      end

      it "combines search with pagination" do
        result = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "Bilbo" }, first: 1) { nodes { _id } } }'
        )
        expect(result.length).to eq 1
        expect([@rule_legolas_bilbo.id.to_s, @rule_bilbo_sam.id.to_s]).to include(result.first)

        has_next_page = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "Bilbo" }, first: 1) { pageInfo { hasNextPage } } }'
        )
        expect(has_next_page).to be true
      end

      it "excludes deleted rules from search results" do
        @rule_frodo_legolas.destroy

        result = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "Frodo" }) { nodes { _id } } }'
        )
        expect(result).to be_empty

        result_legolas = @search_teacher_assignment_type.resolve(
          'allocationRules { rulesConnection(filter: { searchTerm: "Legolas" }) { nodes { _id } } }'
        )
        expect(result_legolas).to contain_exactly(@rule_legolas_bilbo.id.to_s)
      end

      it "returns all results when no search term provided" do
        result_with_filter = @search_teacher_assignment_type.resolve(
          "allocationRules { rulesConnection(filter: {}) { nodes { _id } } }"
        )
        result_without_filter = @search_teacher_assignment_type.resolve(
          "allocationRules { rulesConnection { nodes { _id } } }"
        )

        expect(result_with_filter).to match_array([
                                                    @rule_frodo_legolas.id.to_s,
                                                    @rule_legolas_bilbo.id.to_s,
                                                    @rule_bilbo_sam.id.to_s
                                                  ])
        expect(result_without_filter).to eq(result_with_filter)
      end
    end
  end

  describe "auto_grade_assignment_issues" do
    before do
      allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_assignment)
        .with(assignment:)
        .and_return({ level: "error", message: "Test error" })
    end

    it "returns nil when project_lhotse feature flag is disabled" do
      course.disable_feature!(:project_lhotse)
      expect(GraphQLHelpers::AutoGradeEligibilityHelper).not_to receive(:validate_assignment)
      expect(assignment_type.resolve("autoGradeAssignmentIssues { level message }")).to be_nil
    end

    it "returns issues when project_lhotse feature flag is enabled" do
      course.enable_feature!(:project_lhotse)
      expect(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_assignment)
      level = assignment_type.resolve("autoGradeAssignmentIssues { level }")
      message = assignment_type.resolve("autoGradeAssignmentIssues { message }")
      expect(level).to eq "error"
      expect(message).to eq "Test error"
    end
  end

  describe "auto_grade_assignment_errors" do
    before do
      allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_assignment)
        .with(assignment:)
        .and_return({ level: "error", message: "Test error" })
    end

    it "returns empty array when project_lhotse feature flag is disabled" do
      course.disable_feature!(:project_lhotse)
      expect(GraphQLHelpers::AutoGradeEligibilityHelper).not_to receive(:validate_assignment)
      expect(assignment_type.resolve("autoGradeAssignmentErrors")).to eq([])
    end

    it "returns error messages when project_lhotse feature flag is enabled" do
      course.enable_feature!(:project_lhotse)
      expect(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_assignment)
      expect(assignment_type.resolve("autoGradeAssignmentErrors")).to eq(["Test error"])
    end
  end

  describe "allowProvisionalGrading" do
    before(:once) do
      @moderated_assignment = course.assignments.create!(
        name: "moderated assignment",
        moderated_grading: true,
        grader_count: 2,
        final_grader: teacher
      )
      @moderated_assignment.create_moderation_grader(teacher, occupy_slot: true)
    end

    let(:moderated_assignment_type) { GraphQLTypeTester.new(@moderated_assignment, current_user: teacher) }
    let(:moderated_assignment_type_for_student) { GraphQLTypeTester.new(@moderated_assignment, current_user: student) }

    it "returns 'allowed' for allowProvisionalGrading when user can be a moderated grader" do
      expect(moderated_assignment_type.resolve("allowProvisionalGrading")).to eq "allowed"
    end

    it "returns 'not_allowed' for allowProvisionalGrading when user cannot be a moderated grader" do
      expect(moderated_assignment_type_for_student.resolve("allowProvisionalGrading")).to eq "not_allowed"
    end

    it "returns 'not_applicable' for allowProvisionalGrading on non-moderated assignments" do
      expect(teacher_assignment_type.resolve("allowProvisionalGrading")).to eq "not_applicable"
    end

    it "returns 'not_applicable' for allowProvisionalGrading after grades are published" do
      @moderated_assignment.update!(grades_published_at: Time.zone.now)
      expect(moderated_assignment_type.resolve("allowProvisionalGrading")).to eq "not_applicable"
    end

    it "returns 'not_applicable' for allowProvisionalGrading after grades are published (non-provisional grader)" do
      @moderated_assignment.update!(grades_published_at: Time.zone.now)
      expect(moderated_assignment_type_for_student.resolve("allowProvisionalGrading")).to eq "not_applicable"
    end
  end

  describe "postable submission counts" do
    let(:manually_posted_assignment) do
      assignment = course.assignments.create!(
        title: "Test Assignment",
        points_possible: 10,
        submission_types: ["online_text_entry"],
        workflow_state: "published"
      )
      assignment.ensure_post_policy(post_manually: true)
      assignment
    end

    let(:manually_posted_assignment_type) { GraphQLTypeTester.new(manually_posted_assignment, current_user: teacher) }

    let_once(:student2) { student_in_course(course:, active_all: true).user }

    def postable_count_query(assignment_type = manually_posted_assignment_type)
      query = <<~GQL
        submissionsConnection(filter: { postingStatus: postable, includeUnsubmitted: true }) {
          pageInfo {
            totalCount
          }
        }
      GQL
      assignment_type.resolve(query)
    end

    it "excludes submissions without any activity on them" do
      expect(postable_count_query).to eq 0
    end

    it "excludes already posted submissions with feedback" do
      submission = manually_posted_assignment.grade_student(student, grade: 8, grader: teacher).first

      expect do
        manually_posted_assignment.post_submissions(submission_ids: [submission.id])
      end.to change { postable_count_query }.from(1).to(0)
    end

    it "excludes submissions where the student has turned in work but there's no feedback" do
      expect do
        manually_posted_assignment.submit_homework(student, body: "my submission", submission_type: "online_text_entry")
      end.not_to change { postable_count_query }.from(0)
    end

    it "includes unposted graded submissions" do
      expect do
        manually_posted_assignment.grade_student(student, grade: 8, grader: teacher)
      end.to change { postable_count_query }.from(0).to(1)
    end

    it "excludes unposted graded submissions for deactivated students" do
      manually_posted_assignment.grade_student(student, grade: 8, grader: teacher)
      expect do
        course.enrollments.find_by(user: student).deactivate
      end.to change { postable_count_query }.from(1).to(0)
    end

    it "excludes unposted graded submissions for concluded students" do
      manually_posted_assignment.grade_student(student, grade: 8, grader: teacher)
      expect do
        course.enrollments.find_by(user: student).conclude
      end.to change { postable_count_query }.from(1).to(0)
    end

    it "includes unposted excused submissions" do
      expect do
        manually_posted_assignment.grade_student(student, excused: true, grader: teacher)
      end.to change { postable_count_query }.from(0).to(1)
    end

    it "includes unposted submissions with a sticker" do
      submission = manually_posted_assignment.submissions.find_by(user: student)

      expect do
        submission.update!(sticker: "star")
      end.to change { postable_count_query }.from(0).to(1)
    end

    it "includes submissions with unposted non-draft comments" do
      submission = manually_posted_assignment.submissions.find_by(user: student)

      expect do
        submission.submission_comments.create!(
          author: teacher,
          comment: "hidden comment",
          hidden: true
        )
      end.to change { postable_count_query }.from(0).to(1)
    end

    it "excludes submissions with unposted draft comments" do
      submission = manually_posted_assignment.submissions.find_by(user: student)
      expect do
        submission.submission_comments.create!(
          author: teacher,
          comment: "draft comment",
          hidden: true,
          draft: true
        )
      end.not_to change { postable_count_query }.from(0)
    end

    context "section-limited teachers" do
      before do
        @original_teacher = teacher
        @original_student = student
        @limited_section = course.course_sections.create!(name: "Limited Access Section")
        @limited_teacher = teacher_in_course(course:, section: @limited_section, active_all: true).user
        @limited_student = student_in_course(course:, section: @limited_section, active_all: true).user
        Enrollment.limit_privileges_to_course_section!(@course, @limited_teacher, true)
      end

      let(:limited_teacher_assignment_type) { GraphQLTypeTester.new(manually_posted_assignment, current_user: @limited_teacher) }

      it "includes submissions for students in a visible section" do
        expect do
          manually_posted_assignment.grade_student(@limited_student, grade: 8, grader: @original_teacher)
        end.to change { postable_count_query }.from(0).to(1)
      end

      it "excludes submissions for students in a non-visible section" do
        expect do
          manually_posted_assignment.grade_student(@original_student, grade: 8, grader: @original_teacher)
        end.not_to change { postable_count_query(limited_teacher_assignment_type) }.from(0)
      end
    end

    it "treats test (fake) students just like regular students. No special treatment" do
      fake_student = course.student_view_student
      expect do
        manually_posted_assignment.grade_student(fake_student, score: 10, grader: teacher)
      end.to change { postable_count_query }.from(0).to(1)
    end

    it "includes submissions graded with 0" do
      expect do
        manually_posted_assignment.grade_student(student, score: 0, grader: teacher)
      end.to change { postable_count_query }.from(0).to(1)
    end

    it "excludes submissions when their original grade is removed" do
      manually_posted_assignment.grade_student(student, score: 5, grader: teacher)

      expect do
        manually_posted_assignment.grade_student(student, score: nil, grader: teacher)
      end.to change { postable_count_query }.from(1).to(0)
    end

    it "returns 0 when an assignment is assigned to no students" do
      empty_course = course_factory(active_all: true)
      empty_teacher = teacher_in_course(active_all: true, course: empty_course).user
      empty_assignment = empty_course.assignments.create!(
        title: "Empty Assignment",
        points_possible: 10,
        workflow_state: "published"
      )
      empty_type = GraphQLTypeTester.new(empty_assignment, current_user: empty_teacher)

      expect(postable_count_query(empty_type)).to eq 0
    end

    it "excludes students with feedback that were originally assigned and then got unassigned" do
      manually_posted_assignment.grade_student(student, grade: 8, grader: teacher).first

      expect do
        manually_posted_assignment.update!(only_visible_to_overrides: true)
        adhoc_override = manually_posted_assignment.assignment_overrides.create!(set_type: "ADHOC")
        adhoc_override.assignment_override_students.create!(user: student2)
        run_jobs
      end.to change { postable_count_query }.from(1).to(0)
    end
  end

  describe "hideable submission counts" do
    let(:manually_posted_assignment) do
      assignment = course.assignments.create!(
        title: "Test Assignment",
        points_possible: 10,
        submission_types: ["online_text_entry"],
        workflow_state: "published"
      )
      assignment.ensure_post_policy(post_manually: true)
      assignment
    end

    let(:manually_posted_assignment_type) { GraphQLTypeTester.new(manually_posted_assignment, current_user: teacher) }

    let_once(:student2) { student_in_course(course:, active_all: true).user }

    def hideable_count_query(assignment_type = manually_posted_assignment_type)
      query = <<~GQL
        submissionsConnection(filter: { postingStatus: hideable, includeUnsubmitted: true }) {
          pageInfo {
            totalCount
          }
        }
      GQL
      assignment_type.resolve(query)
    end

    it "includes posted submissions" do
      submission = manually_posted_assignment.grade_student(student, grade: 8, grader: teacher).first

      expect do
        manually_posted_assignment.post_submissions(submission_ids: [submission.id])
      end.to change { hideable_count_query }.from(0).to(1)
    end

    it "excludes unposted submissions" do
      manually_posted_assignment.grade_student(student, grade: 8, grader: teacher)

      expect(hideable_count_query).to eq 0
    end

    it "excludes posted submissions for deactivated students" do
      submission = manually_posted_assignment.grade_student(student, grade: 8, grader: teacher).first
      manually_posted_assignment.post_submissions(submission_ids: [submission.id])

      expect do
        course.enrollments.find_by(user: student).deactivate
      end.to change { hideable_count_query }.from(1).to(0)
    end

    it "excludes posted submissions for concluded students" do
      submission = manually_posted_assignment.grade_student(student, grade: 8, grader: teacher).first
      manually_posted_assignment.post_submissions(submission_ids: [submission.id])

      expect do
        course.enrollments.find_by(user: student).conclude
      end.to change { hideable_count_query }.from(1).to(0)
    end

    context "section-limited teachers" do
      before do
        @original_teacher = teacher
        @original_student = student
        @limited_section = course.course_sections.create!(name: "Limited Access Section")
        @limited_teacher = teacher_in_course(course:, section: @limited_section, active_all: true).user
        @limited_student = student_in_course(course:, section: @limited_section, active_all: true).user
        Enrollment.limit_privileges_to_course_section!(@course, @limited_teacher, true)
      end

      let(:limited_teacher_assignment_type) { GraphQLTypeTester.new(manually_posted_assignment, current_user: @limited_teacher) }

      it "includes posted submissions for students in a visible section" do
        submission = manually_posted_assignment.grade_student(@limited_student, grade: 8, grader: @original_teacher).first

        expect do
          manually_posted_assignment.post_submissions(submission_ids: [submission.id])
        end.to change { hideable_count_query }.from(0).to(1)
      end

      it "excludes posted submissions for students in a non-visible section" do
        submission = manually_posted_assignment.grade_student(@original_student, grade: 8, grader: @original_teacher).first
        manually_posted_assignment.post_submissions(submission_ids: [submission.id])

        expect(hideable_count_query(limited_teacher_assignment_type)).to eq 0
      end
    end

    it "treats test (fake) students just like regular students. No special treatment" do
      fake_student = course.student_view_student
      submission = manually_posted_assignment.grade_student(fake_student, score: 10, grader: teacher).first

      expect do
        manually_posted_assignment.post_submissions(submission_ids: [submission.id])
      end.to change { hideable_count_query }.from(0).to(1)
    end

    it "includes posted submissions even when their grade is removed" do
      submission = manually_posted_assignment.grade_student(student, score: 5, grader: teacher).first
      manually_posted_assignment.post_submissions(submission_ids: [submission.id])

      expect do
        manually_posted_assignment.grade_student(student, score: nil, grader: teacher)
      end.not_to change { hideable_count_query }.from(1)
    end

    it "returns 0 when an assignment is assigned to no students" do
      empty_course = course_factory(active_all: true)
      empty_teacher = teacher_in_course(active_all: true, course: empty_course).user
      empty_assignment = empty_course.assignments.create!(
        title: "Empty Assignment",
        points_possible: 10,
        workflow_state: "published"
      )
      empty_type = GraphQLTypeTester.new(empty_assignment, current_user: empty_teacher)

      expect(hideable_count_query(empty_type)).to eq 0
    end

    it "excludes posted students that were originally assigned and then got unassigned" do
      submission = manually_posted_assignment.grade_student(student, grade: 8, grader: teacher).first
      manually_posted_assignment.post_submissions(submission_ids: [submission.id])

      expect do
        manually_posted_assignment.update!(only_visible_to_overrides: true)
        adhoc_override = manually_posted_assignment.assignment_overrides.create!(set_type: "ADHOC")
        adhoc_override.assignment_override_students.create!(user: student2)
        run_jobs
      end.to change { hideable_count_query }.from(1).to(0)
    end
  end
end
