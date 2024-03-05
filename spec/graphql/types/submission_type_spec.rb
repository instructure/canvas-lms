# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require_relative "../graphql_spec_helper"

describe Types::SubmissionType do
  before(:once) do
    student_in_course(active_all: true)
    @assignment = @course.assignments.create! name: "asdf", points_possible: 10
    @submission = @assignment.grade_student(@student, score: 8, grader: @teacher, student_entered_score: 13).first
  end

  let(:submission_type) { GraphQLTypeTester.new(@submission, current_user: @teacher, request: ActionDispatch::TestRequest.create) }
  let(:submission_type_for_student) { GraphQLTypeTester.new(@submission, current_user: @student, request: ActionDispatch::TestRequest.create) }

  it "works" do
    expect(submission_type.resolve("user { _id }")).to eq @student.id.to_s
    expect(submission_type.resolve("userId")).to eq @student.id.to_s
    expect(submission_type.resolve("excused")).to be false
    expect(submission_type.resolve("assignment { _id }")).to eq @assignment.id.to_s
    expect(submission_type.resolve("assignmentId")).to eq @assignment.id.to_s
    expect(submission_type.resolve("redoRequest")).to eq @submission.redo_request?
    expect(submission_type.resolve("cachedDueDate")).to eq @submission.cached_due_date
    expect(submission_type.resolve("studentEnteredScore")).to eq @submission.student_entered_score
  end

  it "requires read permission" do
    other_student = student_in_course(active_all: true).user
    expect(submission_type.resolve("_id", current_user: other_student)).to be_nil
  end

  describe "posted" do
    it "returns the posted status of the submission" do
      @submission.update!(posted_at: nil)
      expect(submission_type.resolve("posted")).to be false
      @submission.update!(posted_at: Time.zone.now)
      expect(submission_type.resolve("posted")).to be true
    end
  end

  describe "read state" do
    it "returns unread when user has not read the submission" do
      @submission.change_read_state("unread", @teacher)
      expect(submission_type.resolve("readState")).to eq "unread"
    end

    it "returns read when user has read the submission" do
      @submission.change_read_state("read", @teacher)
      expect(submission_type.resolve("readState")).to eq "read"
    end
  end

  describe "posted_at" do
    it "returns the posted_at of the submission" do
      now = Time.zone.now.change(usec: 0)
      @submission.update!(posted_at: now)
      posted_at = Time.zone.parse(submission_type.resolve("postedAt"))
      expect(posted_at).to eq now
    end
  end

  describe "sticker" do
    let(:sticker) { type.resolve("sticker") }

    before { @submission.update!(sticker: "trophy") }

    context "as a student" do
      let(:type) { submission_type_for_student }

      it "returns the sticker for posted submissions" do
        expect(sticker).to eq "trophy"
      end

      it "does not return the sticker for unposted submissions" do
        @assignment.hide_submissions
        expect(sticker).to be_nil
      end
    end

    context "as a teacher" do
      let(:type) { submission_type }

      it "returns the sticker for posted submissions" do
        expect(sticker).to eq "trophy"
      end

      it "returns the sticker for unposted submissions" do
        @assignment.hide_submissions
        expect(sticker).to eq "trophy"
      end
    end
  end

  describe "hide_grade_from_student" do
    it "returns true for hide_grade_from_student" do
      @assignment.mute!
      expect(submission_type.resolve("hideGradeFromStudent")).to be true
    end

    it "returns false for hide_grade_from_student" do
      expect(submission_type.resolve("hideGradeFromStudent")).to be false
    end
  end

  describe "custom_grade_status" do
    before do
      custom_grade_status = CustomGradeStatus.create!(name: "foo", color: "#FFE8E5", root_account_id: Account.default.id, created_by_id: @teacher.id)
      @submission.update!(custom_grade_status_id: custom_grade_status.id)
    end

    it "returns the custom grade status" do
      expect(submission_type.resolve("customGradeStatus")).to eq "foo"
    end
  end

  describe "grading period id" do
    it "returns the grading period id" do
      grading_period_group = GradingPeriodGroup.create!(title: "foo", course_id: @course.id)
      grading_period = GradingPeriod.create!(title: "foo", start_date: 1.day.ago, end_date: 1.day.from_now, grading_period_group_id: grading_period_group.id)
      assignment = @course.assignments.create! name: "asdf", points_possible: 10
      submission = assignment.grade_student(@student, score: 8, grader: @teacher).first
      submission.update!(grading_period_id: grading_period.id)
      submission_type = GraphQLTypeTester.new(submission, current_user: @teacher)

      expect(submission_type.resolve("gradingPeriodId")).to eq grading_period.id.to_s
    end
  end

  describe "unread_comment_count" do
    let(:valid_submission_comment_attributes) { { comment: "some comment" } }

    it "returns 0 if the submission is read" do
      @submission.mark_read(@teacher)
      submission_unread_count = submission_type.resolve("unreadCommentCount")
      expect(submission_unread_count).to eq 0
    end

    it "returns unread count if the submission is unread" do
      @submission.mark_unread(@teacher)
      @submission.submission_comments.create!(valid_submission_comment_attributes)
      @submission.submission_comments.create!(valid_submission_comment_attributes)
      @submission.submission_comments.create!(valid_submission_comment_attributes)
      submission_unread_count = submission_type.resolve("unreadCommentCount")
      expect(submission_unread_count).to eq 3
    end

    it "returns 0 if the submission is unread and all comments are read" do
      comment = @submission.submission_comments.create!(valid_submission_comment_attributes)
      comment.mark_read!(@teacher)
      @submission.mark_unread(@teacher)
      submission_unread_count = submission_type.resolve("unreadCommentCount")
      expect(submission_unread_count).to eq 0
    end

    it "treats submission comments for attempt nil, 0, and 1 as the same" do
      @submission.submission_comments.create!(comment: "foo", attempt: nil)
      @submission.submission_comments.create!(comment: "foo", attempt: 0)
      @submission.submission_comments.create!(comment: "foo", attempt: 1)
      submission_unread_count = submission_type.resolve("unreadCommentCount")
      expect(submission_unread_count).to eq 3
    end

    it "only displays unread count for the given submission attempt" do
      @submission.attempt = 2
      @submission.save!
      @submission.submission_comments.create!(comment: "foo", attempt: nil)
      @submission.submission_comments.create!(comment: "foo", attempt: 0)
      @submission.submission_comments.create!(comment: "foo", attempt: 1)
      @submission.submission_comments.create!(comment: "foo", attempt: 2)
      submission_unread_count = submission_type.resolve("unreadCommentCount")
      expect(submission_unread_count).to eq 1
    end
  end

  describe "score and grade" do
    context "muted assignment" do
      before { @assignment.mute! }

      it "returns score/grade for teachers when assignment is muted" do
        expect(submission_type.resolve("score", current_user: @teacher)).to eq @submission.score
        expect(submission_type.resolve("grade", current_user: @teacher)).to eq @submission.grade
        expect(submission_type.resolve("enteredScore", current_user: @teacher)).to eq @submission.entered_score
        expect(submission_type.resolve("enteredGrade", current_user: @teacher)).to eq @submission.entered_grade
        expect(submission_type.resolve("deductedPoints", current_user: @teacher)).to eq @submission.points_deducted
      end

      it "doesn't return score/grade for students when assignment is muted" do
        expect(submission_type.resolve("score", current_user: @student)).to be_nil
        expect(submission_type.resolve("grade", current_user: @student)).to be_nil
        expect(submission_type.resolve("enteredScore", current_user: @student)).to be_nil
        expect(submission_type.resolve("enteredGrade", current_user: @student)).to be_nil
        expect(submission_type.resolve("deductedPoints", current_user: @student)).to be_nil
      end
    end

    context "regular assignment" do
      it "returns the score and grade for authorized users" do
        expect(submission_type.resolve("score", current_user: @student)).to eq @submission.score
        expect(submission_type.resolve("grade", current_user: @student)).to eq @submission.grade
        expect(submission_type.resolve("enteredScore", current_user: @student)).to eq @submission.entered_score
        expect(submission_type.resolve("enteredGrade", current_user: @student)).to eq @submission.entered_grade
        expect(submission_type.resolve("deductedPoints", current_user: @student)).to eq @submission.points_deducted
      end

      it "returns nil for unauthorized users" do
        @student2 = student_in_course(active_all: true).user
        expect(submission_type.resolve("score", current_user: @student2)).to be_nil
        expect(submission_type.resolve("grade", current_user: @student2)).to be_nil
        expect(submission_type.resolve("enteredScore", current_user: @student)).to be_nil
        expect(submission_type.resolve("enteredGrade", current_user: @student)).to be_nil
        expect(submission_type.resolve("deductedPoints", current_user: @student)).to be_nil
      end
    end
  end

  describe "body" do
    before do
      allow(GraphQLHelpers::UserContent).to receive(:process).and_return("bad")
    end

    context "for a quiz" do
      let(:quiz) do
        quiz_with_submission
        @quiz
      end
      let(:assignment) { quiz.assignment }
      let(:submission) { assignment.submission_for_student(@student) }

      let(:submission_type_for_student) { GraphQLTypeTester.new(submission, current_user: @student) }
      let(:submission_type_for_teacher) { GraphQLTypeTester.new(submission, current_user: @teacher) }

      before do
        assignment.hide_submissions
      end

      context "when the quiz is not posted" do
        it "returns nil for users who cannot read the grade" do
          expect(submission_type_for_student.resolve("body")).to be_nil
        end

        it "returns a value for users who can read the grade" do
          expect(submission_type_for_teacher.resolve("body")).to eq "bad"
        end
      end

      it "returns the value of the body for a posted quiz" do
        assignment.post_submissions
        expect(submission_type_for_student.resolve("body")).to eq "bad"
      end
    end

    it "returns the value of the body for a non-quiz assignment" do
      @submission.update!(body: "bad")
      submission_type = GraphQLTypeTester.new(@submission, current_user: @student)
      expect(submission_type.resolve("body")).to eq "bad"
    end
  end

  describe "submissionStatus" do
    before do
      quiz_with_submission
      @quiz_assignment = @quiz.assignment
      @quiz_submission = @quiz_assignment.submission_for_student(@student)
    end

    let(:submission_type_quiz) { GraphQLTypeTester.new(@quiz_submission, current_user: @teacher) }

    it "contains submissionStatus field" do
      expect(submission_type.resolve("submissionStatus")).to eq "unsubmitted"
    end

    it "preloads quiz type assignments" do
      expect(submission_type_quiz.resolve("submissionStatus")).to eq "submitted"
    end
  end

  describe "late policy" do
    it "shows late policy" do
      @submission.update!(late_policy_status: :missing)
      expect(submission_type.resolve("latePolicyStatus")).to eq "missing"
    end
  end

  describe "#attempt" do
    it "shows the attempt" do
      @submission.update_column(:attempt, 1) # bypass infer_values callback
      expect(submission_type.resolve("attempt")).to eq 1
    end

    it "translates nil in the database to 0 in graphql" do
      @submission.update_column(:attempt, nil) # bypass infer_values callback
      expect(submission_type.resolve("attempt")).to eq 0
    end
  end

  describe "submission comments" do
    before(:once) do
      @submission.update_column(:attempt, 2) # bypass infer_values callback
      @comment1 = @submission.add_comment(author: @teacher, comment: "test1", attempt: 1)
      @comment2 = @submission.add_comment(author: @teacher, comment: "test2", attempt: 2)
    end

    it "will allow comments to be sorted in ascending order" do
      @comment3 = @submission.add_comment(author: @teacher, comment: "test3", attempt: 2)
      expect(
        submission_type.resolve("commentsConnection(sortOrder: asc) { nodes { _id }}")
      ).to eq [@comment2.id.to_s, @comment3.id.to_s]
    end

    it "will allow comments to be sorted in descending order" do
      @comment3 = @submission.add_comment(author: @teacher, comment: "test3", attempt: 2)
      expect(
        submission_type.resolve("commentsConnection(sortOrder: desc) { nodes { _id }}")
      ).to eq [@comment3.id.to_s, @comment2.id.to_s]
    end

    it "will only be shown for the current submission attempt by default" do
      expect(
        submission_type.resolve("commentsConnection { nodes { _id }}")
      ).to eq [@comment2.id.to_s]
    end

    it "will show comments for a given attempt using the target_attempt argument" do
      expect(
        submission_type.resolve("commentsConnection(filter: {forAttempt: 1}) { nodes { _id }}")
      ).to eq [@comment1.id.to_s]
    end

    it "will show all comments for all attempts if all_comments is true" do
      expect(
        submission_type.resolve("commentsConnection(filter: {allComments: true}) { nodes { _id }}")
      ).to eq [@comment1.id.to_s, @comment2.id.to_s]
    end

    it "will only show comments written by the reviewer if peerReview is true" do
      comment3 = @submission.add_comment(author: @student, comment: "test3", attempt: 2)
      expect(
        submission_type_for_student.resolve("commentsConnection(filter: {peerReview: true}) { nodes { _id }}")
      ).to eq [comment3.id.to_s]
    end

    it "will combine comments for attempt nil, 0, and 1" do
      @comment0 = @submission.add_comment(author: @teacher, comment: "test1", attempt: 0)
      @commentNil = @submission.add_comment(author: @teacher, comment: "test1", attempt: nil)

      2.times do |i|
        expect(
          submission_type.resolve("commentsConnection(filter: {forAttempt: #{i}}) { nodes { _id }}")
        ).to eq [@comment1.id.to_s, @comment0.id.to_s, @commentNil.id.to_s]
      end
    end

    it "will only return published drafts" do
      @submission.add_comment(author: @teacher, comment: "test3", attempt: 2, draft_comment: true)
      expect(
        submission_type.resolve("commentsConnection { nodes { _id }}")
      ).to eq [@comment2.id.to_s]
    end

    it "requires permission" do
      other_course_student = student_in_course(course: course_factory).user
      expect(
        submission_type.resolve("commentsConnection { nodes { _id }}", current_user: other_course_student)
      ).to be_nil
    end

    context "grants_rights check" do
      before(:once) do
        @assignment.update_attribute(:peer_reviews, true)
        @student2 = User.create!
        @student3 = User.create!
        @course.enroll_user(@student2, "StudentEnrollment", enrollment_state: "active")
        @course.enroll_user(@student3, "StudentEnrollment", enrollment_state: "active")
        @peer_review_submission = @assignment.submit_homework(@student, body: "Attempt 1", submitted_at: 2.hours.ago)
        @assignment.submit_homework(@student2, body: "test", submitted_at: 1.hour.ago)
        @assignment.submit_homework(@student3, body: "test", submitted_at: 1.hour.ago)
        @assignment.assign_peer_review(@student2, @student)
        @assignment.assign_peer_review(@student3, @student)
        @peer_review_submission.add_comment(author: @student3, comment: "this comment shouldnt be seen")
      end

      let(:resolver) { GraphQLTypeTester.new(@peer_review_submission, current_user: @student2) }

      it "returns no comments when student2 has no comments" do
        expect(
          resolver.resolve("commentsConnection(filter: {allComments: true}) { nodes { _id }}", current_user: @student2)
        ).to eq []
      end

      it "only returns comments for student2" do
        student_2_comment = @peer_review_submission.add_comment(author: @student2, comment: "this is a student comment")
        expect(
          resolver.resolve("commentsConnection(filter: {allComments: true}) { nodes { _id }}", current_user: @student2)
        ).to eq [student_2_comment.id.to_s]
      end
    end
  end

  describe "submission_drafts" do
    it "returns the draft for attempt 0 when the submission attempt is nil" do
      @submission.update_columns(attempt: nil) # bypass #infer_details for test
      SubmissionDraft.create!(submission: @submission, submission_attempt: 1)
      expect(
        submission_type.resolve("submissionDraft { submissionAttempt }", current_user: @student)
      ).to eq 1
    end

    it "returns nil for a non current submission history that has a draft" do
      assignment = @course.assignments.create! name: "asdf", points_possible: 10
      @submission1 = assignment.submit_homework(@student, body: "Attempt 1", submitted_at: 2.hours.ago)
      @submission2 = assignment.submit_homework(@student, body: "Attempt 2", submitted_at: 1.hour.ago)
      SubmissionDraft.create!(submission: @submission1, submission_attempt: @submission1.attempt + 1)
      SubmissionDraft.create!(submission: @submission2, submission_attempt: @submission2.attempt + 1)
      resolver = GraphQLTypeTester.new(@submission2, current_user: @student)
      expect(
        resolver.resolve(
          "submissionHistoriesConnection { nodes { submissionDraft { submissionAttempt }}}"
        )
      ).to eq [nil, @submission2.attempt + 1]
    end

    it "returns nil for a submission draft not belonging to current user" do
      observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
      @submission.submission_drafts.create!(submission_attempt: 1)
      resolver = GraphQLTypeTester.new(@submission, current_user: observer)
      expect(
        resolver.resolve(
          "submissionHistoriesConnection { nodes { submissionDraft { _id }}}"
        )
      ).to eq [nil]
    end
  end

  describe "attachments" do
    before(:once) do
      assignment = @course.assignments.create! name: "asdf", points_possible: 10
      @attachment1 = attachment_model
      @attachment2 = attachment_model
      @submission1 = assignment.submit_homework(@student, body: "Attempt 1", submitted_at: 2.hours.ago)
      @submission1.attachments = [@attachment1]
      @submission1.save!
      @submission2 = assignment.submit_homework(@student, body: "Attempt 2", submitted_at: 1.hour.ago)
      @submission2.attachments = [@attachment2]
      @submission2.save!
    end

    let(:submission_type) { GraphQLTypeTester.new(@submission2, current_user: @teacher) }

    it "works for a submission" do
      expect(submission_type.resolve("attachments { _id }")).to eq [@attachment2.id.to_s]
    end

    it "works for a submission history" do
      expect(
        submission_type.resolve(
          "submissionHistoriesConnection(first: 1) { nodes { attachments { _id }}}"
        )
      ).to eq [[@attachment1.id.to_s]]
    end
  end

  describe "submission histories connection" do
    before(:once) do
      assignment = @course.assignments.create! name: "asdf2", points_possible: 10
      @submission1 = assignment.submit_homework(@student, body: "Attempt 1", submitted_at: 2.hours.ago)
      @submission2 = assignment.submit_homework(@student, body: "Attempt 2", submitted_at: 1.hour.ago)
      @submission3 = assignment.submit_homework(@student, body: "Attempt 3")
    end

    let(:submission_history_type) { GraphQLTypeTester.new(@submission3, current_user: @teacher) }

    it "returns the submission histories" do
      expect(
        submission_history_type.resolve("submissionHistoriesConnection { nodes { attempt }}")
      ).to eq [1, 2, 3]
    end

    it "properly handles cursors for submission histories" do
      expect(
        submission_history_type.resolve("submissionHistoriesConnection { edges { cursor }}")
      ).to eq %w[MQ Mg Mw]
    end

    context "filter" do
      describe "states" do
        before(:once) do
          # Cannot use .first here, because versionable changes .first to .last :knife:
          history_version = @submission3.versions[0]
          history = YAML.load(history_version.yaml)
          history["workflow_state"] = "unsubmitted"
          history_version.update!(yaml: history.to_yaml)
        end

        it "does not filter by states by default" do
          expect(
            submission_history_type.resolve("submissionHistoriesConnection { nodes { attempt }}")
          ).to eq [1, 2, 3]
        end

        it "can be used to filter by workflow state" do
          expect(
            submission_history_type.resolve(
              "submissionHistoriesConnection(filter: {states: [submitted]}) { nodes { attempt }}"
            )
          ).to eq [1, 2]
        end
      end

      describe "include_current_submission" do
        it "includes the current submission history by default" do
          expect(
            submission_history_type.resolve("submissionHistoriesConnection { nodes { attempt }}")
          ).to eq [1, 2, 3]
        end

        it "includes the current submission history when true" do
          expect(
            submission_history_type.resolve(
              "submissionHistoriesConnection(filter: {includeCurrentSubmission: true}) { nodes { attempt }}"
            )
          ).to eq [1, 2, 3]
        end

        it "does not includes the current submission history when false" do
          expect(
            submission_history_type.resolve(
              "submissionHistoriesConnection(filter: {includeCurrentSubmission: false}) { nodes { attempt }}"
            )
          ).to eq [1, 2]
        end
      end
    end
  end

  describe "late" do
    before(:once) do
      assignment = @course.assignments.create!(name: "late assignment", points_possible: 10, due_at: 2.hours.ago)
      @submission1 = assignment.submit_homework(@student, body: "late", submitted_at: 1.hour.ago)
    end

    let(:submission_type) { GraphQLTypeTester.new(@submission1, current_user: @teacher) }

    it "returns late" do
      expect(submission_type.resolve("late")).to be true
    end
  end

  describe "missing" do
    before(:once) do
      assignment = @course.assignments.create!(
        name: "missing assignment",
        points_possible: 10,
        due_at: 1.hour.ago,
        submission_types: ["online_text_entry"]
      )
      @submission1 = Submission.where(assignment_id: assignment.id, user_id: @student.id).first
    end

    let(:submission_type) { GraphQLTypeTester.new(@submission1, current_user: @teacher) }

    it "returns missing" do
      expect(submission_type.resolve("missing")).to be true
    end
  end

  describe "customGradeStatus" do
    before(:once) do
      Account.site_admin.enable_feature!(:custom_gradebook_statuses)
      assignment = @course.assignments.create!(
        name: "custom status assignment",
        points_possible: 10,
        due_at: 1.hour.ago,
        submission_types: ["online_text_entry"]
      )
      @submission1 = Submission.where(assignment_id: assignment.id, user_id: @student.id).first
      @custom_status = CustomGradeStatus.create(name: "Test Status", color: "#000000", root_account: @course.root_account, created_by: @teacher)
    end

    let(:submission_type) { GraphQLTypeTester.new(@submission1, current_user: @teacher) }

    it "returns customGradeStatus" do
      @submission1.update!(custom_grade_status: @custom_status)
      expect(submission_type.resolve("customGradeStatus")).to eq @custom_status.name
    end
  end

  describe "gradeMatchesCurrentSubmission" do
    before(:once) do
      assignment = @course.assignments.create!(name: "assignment", points_possible: 10)
      assignment.submit_homework(@student, body: "asdf")
      assignment.grade_student(@student, score: 8, grader: @teacher)
      @submission1 = assignment.submit_homework(@student, body: "asdf")
    end

    let(:submission_type) { GraphQLTypeTester.new(@submission1, current_user: @teacher) }

    it "returns gradeMatchesCurrentSubmission" do
      expect(submission_type.resolve("gradeMatchesCurrentSubmission")).to be false
    end
  end

  describe "rubric_Assessments_connection" do
    before(:once) do
      rubric_for_course
      rubric_association_model(
        context: @course,
        rubric: @rubric,
        association_object: @assignment,
        purpose: "grading"
      )

      @assignment.submit_homework(@student, body: "foo", submitted_at: 2.hours.ago)

      rubric_assessment_model(
        user: @student,
        assessor: @teacher,
        rubric_association: @rubric_association,
        assessment_type: "grading"
      )
    end

    it "works" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { _id } }")
      ).to eq [@rubric_assessment.id.to_s]
    end

    it "requires permission" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { _id } }", current_user: @student)
      ).to eq [@rubric_assessment.id.to_s]
    end

    it "grabs the assessment for the current submission attempt by default" do
      @submission2 = @assignment.submit_homework(@student, body: "Attempt 2", submitted_at: 1.hour.ago)
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { _id } }")
      ).to eq []
    end

    it "grabs the assessment for the given submission attempt when using the for_attempt filter" do
      @assignment.submit_homework(@student, body: "bar", submitted_at: 1.hour.since)
      expect(
        submission_type.resolve("rubricAssessmentsConnection(filter: {forAttempt: 2}) { nodes { _id } }")
      ).to eq [@rubric_assessment.id.to_s]
    end

    it "works with submission histories" do
      @assignment.submit_homework(@student, body: "bar", submitted_at: 1.hour.since)
      expect(
        submission_type.resolve(
          "submissionHistoriesConnection { nodes { rubricAssessmentsConnection { nodes { _id } } } }"
        )
      ).to eq [[], [@rubric_assessment.id.to_s], []]
    end
  end

  describe "turnitin_data" do
    before(:once) do
      @tii_data = {
        similarity_score: 10,
        state: "acceptable",
        report_url: "http://example.com",
        status: "scored"
      }

      @submission.turnitin_data[@submission.asset_string] = @tii_data
      @submission.turnitin_data[:last_processed_attempt] = 1
      @submission.turnitin_data[:status] = "pending"
      @submission.turnitin_data[:student_error] = "The product for this account has expired. Please contact your sales agent to renew the product"
      @submission.turnitin_data[:assignment_error] = "The product for this account has expired. Please contact your sales agent to renew the product"
      @submission.save!
    end

    it "returns turnitin_data" do
      expect(
        submission_type.resolve("turnitinData { target { ...on Submission { _id } } }")
      ).to eq [@submission.id.to_s]
      expect(
        submission_type.resolve("turnitinData { status }")
      ).to eq [@tii_data[:status]]
      expect(
        submission_type.resolve("turnitinData { score }")
      ).to eq [@tii_data[:similarity_score]]
      expect(
        submission_type.resolve("turnitinData { state }")
      ).to eq [@tii_data[:state]]
      expect(
        submission_type.resolve("turnitinData { reportUrl }")
      ).to eq [@tii_data[:report_url]]
    end
  end

  describe "submissionType" do
    before(:once) do
      @assignment.submit_homework(@student, body: "bar", submission_type: "online_text_entry")
    end

    it "returns the submissionType" do
      expect(
        submission_type.resolve("submissionType")
      ).to eq "online_text_entry"
    end
  end

  describe "assignedAssessments" do
    before(:once) do
      @assignment.update_attribute(:peer_reviews, true)
      reviewee = User.create!
      @course.enroll_user(reviewee, "StudentEnrollment", enrollment_state: "active")
      @assignment.assign_peer_review(@student, reviewee)
    end

    let(:submission_type) { GraphQLTypeTester.new(@submission, current_user: @student) }

    it "works" do
      result = submission_type.resolve("assignedAssessments { workflowState }")
      expect(result.count).to eq 1
    end
  end

  describe "previewUrl" do
    it "returns the preview URL" do
      expected_url = "http://test.host/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}?preview=1&version=1"
      expect(submission_type.resolve("previewUrl")).to eq expected_url
    end
  end

  describe "wordCount" do
    it "returns the word count" do
      @submission.update!(body: "word " * 100)
      expect(submission_type.resolve("wordCount")).to eq 100
    end
  end
end
