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
    @assignment = @course.assignments.create!(name: "asdf", submission_types: "online_text_entry", points_possible: 10)
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
    expect(submission_type.resolve("secondsLate")).to eq @submission.seconds_late
    expect(submission_type.resolve("studentEnteredScore")).to eq @submission.student_entered_score
    expect(submission_type.resolve("submissionCommentDownloadUrl")).to eq "/submissions/#{@submission.id}/comments.pdf"
  end

  it "requires read permission" do
    other_student = student_in_course(active_all: true).user
    expect(submission_type.resolve("_id", current_user: other_student)).to be_nil
  end

  describe "last_commented_by_user_at" do
    it "returns the timestamp of the last comment by the current user" do
      now = Time.zone.now
      Timecop.freeze(3.hours.ago(now)) { @submission.submission_comments.create!(comment: "hi from teacher", author: @teacher) }
      Timecop.freeze(2.hours.ago(now)) { @submission.submission_comments.create!(comment: "hi sooner from teacher", author: @teacher) }
      Timecop.freeze(1.hour.ago(now)) { @submission.submission_comments.create!(comment: "hi soonest from student", author: @student) }

      expect(submission_type.resolve("lastCommentedByUserAt")).to eq 2.hours.ago(now).iso8601
    end

    it "returns null if the user has no comments" do
      expect(submission_type.resolve("lastCommentedByUserAt")).to be_nil
    end
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

  describe "external_tool_url" do
    it "returns the URL for an LTI submission" do
      @assignment.update!(submission_types: "external_tool")
      @submission.update!(url: "https://example.com", submission_type: "basic_lti_launch")
      expect(submission_type.resolve("externalToolUrl")).to eq "https://example.com"
    end

    it "returns nil if the submission has a URL but is not an LTI submission" do
      @submission.update!(url: "https://example.com")
      expect(submission_type.resolve("externalToolUrl")).to be_nil
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

  describe "status_tag" do
    let(:status_tag) { submission_type.resolve("statusTag") }

    it "returns 'custom' when the submission has a custom grade status" do
      custom_grade_status = @submission.root_account.custom_grade_statuses.create!(
        name: "Potato",
        color: "#FFE8E5",
        created_by: @teacher
      )

      @submission.update!(custom_grade_status:)
      expect(status_tag).to eq "custom"
    end

    it "returns 'excused' when the submission is excused" do
      @submission.update!(excused: true)
      expect(status_tag).to eq "excused"
    end

    it "returns 'late' when the submission is marked late" do
      @submission.update!(late_policy_status: :late)
      expect(status_tag).to eq "late"
    end

    it "returns 'late' when the submission is naturally late" do
      @assignment.update!(due_at: 1.day.ago)
      @assignment.submit_homework(@student, body: "foo")
      expect(status_tag).to eq "late"
    end

    it "returns 'extended' when the submission is extended" do
      @submission.update!(late_policy_status: :extended)
      expect(status_tag).to eq "extended"
    end

    it "returns 'missing' when the submission is marked missing" do
      @submission.update!(late_policy_status: :missing)
      expect(status_tag).to eq "missing"
    end

    it "returns 'missing' when the submission is naturally missing" do
      @assignment.update!(due_at: 1.day.ago)
      # graded submission's aren't considered missing, so we need to ungrade it
      @submission.update!(score: nil, grader: nil)
      expect(status_tag).to eq "missing"
    end

    it "returns 'none' when the submission is marked 'none'" do
      @assignment.update!(due_at: 1.day.ago)
      @assignment.submit_homework(@student, body: "foo")
      # the submission is naturally late, but marked as "none"
      @submission.update!(late_policy_status: :none)
      expect(status_tag).to eq "none"
    end

    it "returns 'none' when the submission has no special status" do
      expect(status_tag).to eq "none"
    end
  end

  describe "status" do
    let(:status) { submission_type.resolve("status") }

    it "returns the custom status name when the submission has a custom grade status" do
      custom_grade_status = @submission.root_account.custom_grade_statuses.create!(
        name: "Potato",
        color: "#FFE8E5",
        created_by: @teacher
      )

      @submission.update!(custom_grade_status:)
      expect(status).to eq "Potato"
    end

    it "returns 'Excused' when the submission is excused" do
      @submission.update!(excused: true)
      expect(status).to eq "Excused"
    end

    it "returns 'Late' when the submission is late" do
      @submission.update!(late_policy_status: :late)
      expect(status).to eq "Late"
    end

    it "returns 'Extended' when the submission is extended" do
      @submission.update!(late_policy_status: :extended)
      expect(status).to eq "Extended"
    end

    it "returns 'Missing' when the submission is missing" do
      @submission.update!(late_policy_status: :missing)
      expect(status).to eq "Missing"
    end

    it "returns 'None' when the submission has no special status" do
      expect(status).to eq "None"
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

    context "draft comments" do
      before(:once) do
        @draft_comment = @submission.add_comment(author: @teacher, comment: "draft", draft_comment: true)
      end

      it "returns draft comments for the current user" do
        expect(
          submission_type.resolve("commentsConnection(includeDraftComments: true) { nodes { _id }}")
        ).to eq [@comment2.id.to_s, @draft_comment.id.to_s]
      end

      it "does not return draft comments for other users" do
        other_teacher = teacher_in_course(course: @course).user
        expect(
          submission_type.resolve("commentsConnection { nodes { _id }}", current_user: other_teacher)
        ).to eq [@comment2.id.to_s]
      end

      it "does not return draft comments for other users when expecting drafts" do
        other_teacher = teacher_in_course(course: @course).user
        expect(
          submission_type.resolve("commentsConnection(includeDraftComments: true) { nodes { _id }}", current_user: other_teacher)
        ).to eq [@comment2.id.to_s]
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

    it "has a valid viewedAt" do
      now = Time.zone.now.change(usec: 0)
      @attachment1.update!(viewed_at: now)

      expect(Time.zone.parse(submission_type.resolve(
        "submissionHistoriesConnection(first: 1) { nodes { attachments { viewedAt }}}"
      )[0][0])).to eq now
    end
  end

  describe "submission histories connection" do
    before(:once) do
      assignment = @course.assignments.create! name: "asdf2", points_possible: 10
      @submission1 = assignment.submit_homework(@student, body: "Attempt 1", submitted_at: 2.hours.ago)
      @submission2 = assignment.submit_homework(@student, body: "Attempt 2", submitted_at: 1.hour.ago)
      @submission3 = assignment.submit_homework(@student, body: "Attempt 3")
    end

    let(:submission_history_type) { GraphQLTypeTester.new(@submission3, current_user: @teacher, request: ActionDispatch::TestRequest.create) }

    describe "orderBy" do
      it "allows ordering the histories by attempt, ascending" do
        expect(
          submission_history_type.resolve("submissionHistoriesConnection(orderBy: { field: attempt, direction: ascending }) { nodes { attempt }}")
        ).to eq [1, 2, 3]
      end

      it "allows ordering the histories by attempt, descending" do
        expect(
          submission_history_type.resolve("submissionHistoriesConnection(orderBy: { field: attempt, direction: descending }) { nodes { attempt }}")
        ).to eq [3, 2, 1]
      end

      it "falls back to comparing by version id if two histories have the same attempt" do
        v3 = @submission3.versions.find_by(number: 3)
        model = v3.model
        model.attempt = 1
        model.updated_at = @submission3.versions.find_by(number: 1).model.updated_at
        v3.update!(yaml: model.attributes.to_yaml)

        aggregate_failures do
          expect(
            submission_history_type.resolve("submissionHistoriesConnection(orderBy: { field: attempt, direction: ascending }) { nodes { body }}")
          ).to eq ["Attempt 1", "Attempt 3", "Attempt 2"]

          expect(
            submission_history_type.resolve("submissionHistoriesConnection(orderBy: { field: attempt, direction: descending }) { nodes { body }}")
          ).to eq ["Attempt 2", "Attempt 3", "Attempt 1"]
        end
      end

      it "does not allow ordering by unupported fields" do
        expect do
          submission_history_type.resolve("submissionHistoriesConnection(orderBy: { field: body, direction: ascending }) { nodes { attempt }}")
        end.to raise_error(GraphQLTypeTester::Error)
      end

      it "does not allow ordering by unsupported directions" do
        expect do
          submission_history_type.resolve("submissionHistoriesConnection(orderBy: { field: attempt, direction: asc }) { nodes { attempt }}")
        end.to raise_error(GraphQLTypeTester::Error)
      end

      it "requires field to be specified" do
        expect do
          submission_history_type.resolve("submissionHistoriesConnection(orderBy: { direction: ascending }) { nodes { attempt }}")
        end.to raise_error(GraphQLTypeTester::Error)
      end

      it "requires direction to be specified" do
        expect do
          submission_history_type.resolve("submissionHistoriesConnection(orderBy: { field: attempt }) { nodes { attempt }}")
        end.to raise_error(GraphQLTypeTester::Error)
      end
    end

    it "returns the submission histories" do
      expect(
        submission_history_type.resolve("submissionHistoriesConnection { nodes { attempt }}")
      ).to eq [1, 2, 3]
    end

    it "allows fetching anonymousId on histories" do
      anon_id = @submission3.anonymous_id
      expect(
        submission_history_type.resolve("submissionHistoriesConnection { nodes { anonymousId }}")
      ).to eq [anon_id, anon_id, anon_id]
    end

    it "properly handles cursors for submission histories" do
      expect(
        submission_history_type.resolve("submissionHistoriesConnection { edges { cursor }}")
      ).to eq %w[MQ Mg Mw]
    end

    it "can include up to 100 items" do
      assignment = @course.assignments.create! name: "pagination test", points_possible: 10
      100.times do |i|
        assignment.submit_homework(@student, body: "Attempt #{i + 1}", submitted_at: (100 - i).hours.ago)
      end

      submissions = @student.submissions.find_by(assignment:)
      submission_type = GraphQLTypeTester.new(submissions, current_user: @teacher, request: ActionDispatch::TestRequest.create)
      result = submission_type.resolve("submissionHistoriesConnection(first: 100) { nodes { attempt } }")
      expect(result.length).to eq(100)
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

    it "returns empty assessments if there is not a matching rubric assessment for the latest attempt" do
      @assignment.submit_homework(@student, body: "bar", submitted_at: 1.hour.since)
      @assignment.submit_homework(@student, body: "bar2", submitted_at: 1.hour.since)
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { _id } }")
      ).to eq []
    end

    it "returns all assessment if for_all_attempts is true" do
      @assignment.submit_homework(@student, body: "bar", submitted_at: 1.hour.since)
      @assignment.submit_homework(@student, body: "bar2", submitted_at: 1.hour.since)
      expect(
        submission_type.resolve("rubricAssessmentsConnection(filter: {forAllAttempts: true}) { nodes { _id } }")
      ).to eq [@rubric_assessment.id.to_s]
    end

    describe "with provisional assessments" do
      before(:once) do
        @final_grader = @teacher
        @moderated_assignment = @course.assignments.create!(
          due_at: 2.years.from_now,
          final_grader: @final_grader,
          grader_count: 2,
          moderated_grading: true,
          points_possible: 10,
          submission_types: :online_text_entry,
          title: "Moderated Assignment"
        )
        rubric_for_course
        rubric_association_model(
          context: @course,
          rubric: @rubric,
          association_object: @moderated_assignment,
          purpose: "grading"
        )
        @submission = @moderated_assignment.submit_homework(@student, body: "foo", submitted_at: 2.hours.ago)

        moderator_provisional_grade = @submission.find_or_create_provisional_grade!(@final_grader)
        @moderator_provisional_assessment = @rubric_association.assess({
                                                                         user: @student,
                                                                         assessor: @final_grader,
                                                                         artifact: moderator_provisional_grade,
                                                                         assessment: { assessment_type: "grading", criterion_crit1: { points: 5 } }
                                                                       })

        @provisional_grader = user_factory(active_all: true)
        @course.enroll_ta(@provisional_grader, enrollment_state: "active")

        provisional_grade = @submission.find_or_create_provisional_grade!(@provisional_grader)
        @provisional_assessment = @rubric_association.assess({
                                                               user: @student,
                                                               assessor: @provisional_grader,
                                                               artifact: provisional_grade,
                                                               assessment: { assessment_type: "grading", criterion_crit1: { points: 5 } }
                                                             })
      end

      it "excludes provisional assessments by default" do
        submission_type = GraphQLTypeTester.new(@submission, current_user: @provisional_grader)
        expect(
          submission_type.resolve("rubricAssessmentsConnection { nodes { _id } }")
        ).to eq []
      end

      it "includes provisional assessments when include_provisional_assessments is true" do
        submission_type = GraphQLTypeTester.new(@submission, current_user: @provisional_grader)
        expect(
          submission_type.resolve("rubricAssessmentsConnection(filter: {includeProvisionalAssessments: true}) { nodes { _id } }")
        ).to contain_exactly(@provisional_assessment.id.to_s)
      end

      it "allows moderators to see all provisional assessments" do
        submission_type = GraphQLTypeTester.new(@submission, current_user: @final_grader)
        expect(
          submission_type.resolve("rubricAssessmentsConnection(filter: {includeProvisionalAssessments: true}) { nodes { _id } }")
        ).to contain_exactly(@moderator_provisional_assessment.id.to_s, @provisional_assessment.id.to_s)
      end

      it "allows provisional graders to see only their own provisional assessments" do
        other_grader = user_factory(active_all: true)
        @course.enroll_ta(other_grader, enrollment_state: "active")

        other_provisional_grade = @submission.find_or_create_provisional_grade!(other_grader)
        other_assessment = @rubric_association.assess({
                                                        user: @student,
                                                        assessor: other_grader,
                                                        artifact: other_provisional_grade,
                                                        assessment: { assessment_type: "grading", criterion_crit1: { points: 5 } }
                                                      })

        submission_type = GraphQLTypeTester.new(@submission, current_user: other_grader)
        expect(
          submission_type.resolve("rubricAssessmentsConnection(filter: {includeProvisionalAssessments: true}) { nodes { _id } }")
        ).to contain_exactly(other_assessment.id.to_s)
      end
    end
  end

  describe "comments_connection" do
    describe "with includeProvisionalComments filter" do
      before(:once) do
        @course = Course.create!
        @teacher = course_with_teacher(course: @course, active_all: true).user
        @first_ta = course_with_ta(course: @course, active_all: true).user
        @student = course_with_student(course: @course, active_all: true).user

        @assignment = @course.assignments.create!(
          moderated_grading: true,
          grader_count: 2,
          final_grader: @teacher
        )
        @submission = @assignment.submit_homework(@student, body: "hello")

        @submission.add_comment(author: @teacher, comment: "Regular comment")
        ta_pg = @submission.find_or_create_provisional_grade!(@first_ta)

        @provisional_comment = @submission.add_comment(author: @first_ta, comment: "Provisional comment", provisional: true)
        @provisional_comment.update!(provisional_grade_id: ta_pg.id)
      end

      it "calls visible_provisional_comments when includeProvisionalComments is true" do
        expect_any_instance_of(Submission).to receive(:visible_provisional_comments).with(@teacher, provisional_comments: [@provisional_comment]).and_call_original

        submission_type = GraphQLTypeTester.new(@submission, current_user: @teacher)
        query = "commentsConnection(filter: {}, includeProvisionalComments: true) { nodes { _id } }"
        submission_type.resolve(query)
      end

      it "does not call visible_provisional_comments when includeProvisionalComments is false" do
        expect_any_instance_of(Submission).not_to receive(:visible_provisional_comments)

        submission_type = GraphQLTypeTester.new(@submission, current_user: @teacher)
        query = "commentsConnection(filter: {}, includeProvisionalComments: false) { nodes { _id } }"
        submission_type.resolve(query)
      end

      it "includes both regular and provisional comments when includeProvisionalComments is true for a moderator" do
        submission_type = GraphQLTypeTester.new(@submission, current_user: @teacher)
        query = "commentsConnection(filter: {}, includeProvisionalComments: true) { nodes { _id } }"
        result = submission_type.resolve(query)

        expect(result.length).to eq(2)
      end

      it "includes only regular comments when includeProvisionalComments is false" do
        submission_type = GraphQLTypeTester.new(@submission, current_user: @teacher)
        query = "commentsConnection(filter: {}, includeProvisionalComments: false) { nodes { _id } }"
        result = submission_type.resolve(query)

        expect(result.length).to eq(1)
      end
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

    it "returns submission _id" do
      expect(
        submission_type.resolve("turnitinData { target { ...on Submission { _id } } }")
      ).to eq [@submission.id.to_s]
    end

    it "returns status" do
      expect(
        submission_type.resolve("turnitinData { status }")
      ).to eq [@tii_data[:status]]
    end

    it "returns score" do
      expect(
        submission_type.resolve("turnitinData { score }")
      ).to eq [@tii_data[:similarity_score]]
    end

    it "returns state" do
      expect(
        submission_type.resolve("turnitinData { state }")
      ).to eq [@tii_data[:state]]
    end

    it "returns reportUrl" do
      expect(
        submission_type.resolve("turnitinData { reportUrl }")
      ).to eq [@tii_data[:report_url]]
    end

    it "returns assetString" do
      expect(submission_type.resolve("turnitinData { assetString }")).to eq [@submission.asset_string]
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

  describe "groupId" do
    before(:once) do
      @first_student = @student
      @second_student = student_in_course(course: @course, active_all: true).user
      group_category = @course.group_categories.create!(name: "My Category")
      @course.groups.create!(name: "Group A", group_category:)
      @group_b = @course.groups.create!(name: "Group B", group_category:)
      @group_b.add_user(@first_student)
      @group_b.save!
      @assignment.update!(group_category:)
    end

    it "returns the group id associated with the submission" do
      @assignment.submit_homework(@first_student, body: "help my legs are stuck under my desk!")
      aggregate_failures do
        expect(@assignment.submissions.find_by(user: @first_student).group_id).to eq @group_b.id
        expect(submission_type.resolve("groupId")).to eq @group_b.id.to_s
      end
    end

    it "works even when the submission's group_id is set to nil (which is the case before the group has submitted)" do
      aggregate_failures do
        expect(@assignment.submissions.find_by(user: @first_student).group_id).to be_nil
        expect(submission_type.resolve("groupId")).to eq @group_b.id.to_s
      end
    end

    it "returns nil for students not in groups" do
      expect(submission_type.resolve("groupId", current_user: @second_student)).to be_nil
    end

    it "returns nil for non-group assignments" do
      @assignment.update!(group_category: nil)
      expect(submission_type.resolve("groupId")).to be_nil
    end
  end

  describe "previewUrl" do
    let(:preview_url) { submission_type.resolve("previewUrl") }

    let(:quiz) do
      quiz_with_submission
      @quiz
    end

    it "returns the preview URL when a student has submitted" do
      @assignment.submit_homework(@student, body: "test")
      expected_url = "http://test.host/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}?preview=1&version=0"
      expect(preview_url).to eq expected_url
    end

    it "returns nil when the student has not submitted and has not been graded" do
      expect(preview_url).to be_nil
    end

    it "returns nil when the student has not submitted but has been graded" do
      @assignment.grade_student(@student, score: 8, grader: @teacher)
      expect(preview_url).to be_nil
    end

    context "external tool submissions" do
      before do
        @assignment.update!(submission_types: "external_tool")
      end

      let(:query_params) { Rack::Utils.parse_query(URI(preview_url).query).with_indifferent_access }

      it "returns the external tool URL" do
        @assignment.submit_homework(
          @student,
          submission_type: "basic_lti_launch",
          url: "http://anexternaltoolsubmission.com"
        )
        expect(preview_url).to include "/courses/#{@course.id}/external_tools/retrieve"
      end

      it "includes the grade_by_question_enabled query param when it's a new quiz" do
        tool = @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://somenewquiz.com/launch"
        )
        @assignment.update!(external_tool_tag_attributes: { content: tool })
        url = "http://anexternaltoolsubmission.com"
        @assignment.submit_homework(
          @student,
          submission_type: "basic_lti_launch",
          url:
        )
        expect(query_params[:url]).to eq "#{url}?grade_by_question_enabled=false"
      end

      it "excludes the grade_by_question_enabled query param when it's not a new quiz" do
        @assignment.submit_homework(
          @student,
          submission_type: "basic_lti_launch",
          url: "http://anexternaltoolsubmission.com"
        )
        expect(query_params[:url]).not_to include "grade_by_question_enabled"
      end
    end

    it "includes a 'version' query param that corresponds to the attempt number - 1 (and NOT the associated submission version number)" do
      @assignment.submit_homework(@student, body: "My first attempt")
      @assignment.update!(points_possible: 5) # this causes a new submission version to get created
      expected_url = "http://test.host/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}?preview=1&version=0"
      @submission.reload
      aggregate_failures do
        expect(@submission.attempt).to eq 1
        expect(@submission.versions.maximum(:number)).to eq 2
        expect(submission_type.resolve("previewUrl")).to eq expected_url
      end
    end

    it "includes a 'version' query param that corresponds to the submission version number when it's an old quiz" do
      @quiz_assignment = quiz.assignment
      @quiz_submission = @quiz_assignment.submission_for_student(@student)
      quiz_submission_type_for_teacher = GraphQLTypeTester.new(@quiz_submission, current_user: @teacher, request: ActionDispatch::TestRequest.create)
      expected_url = "http://test.host/courses/#{@course.id}/assignments/#{@quiz_assignment.id}/submissions/#{@student.id}?preview=1&version=1"
      aggregate_failures do
        expect(@quiz_submission.attempt).to eq 1
        expect(quiz_submission_type_for_teacher.resolve("previewUrl")).to eq expected_url
      end
    end

    context "when the assignment is a discussion topic" do
      before do
        @assignment.update!(submission_types: "discussion_topic")
        @discussion_topic = @assignment.discussion_topic
      end

      it "returns the preview URL for the discussion topic" do
        @discussion_topic.discussion_entries.create!(user: @student, message: "I have a lot to say about this topic")
        expect(preview_url).to eq "http://test.host/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}?preview=1&show_full_discussion_immediately=true&version=0"
      end
    end

    context "when the assignment is anonymous" do
      before do
        @assignment.update!(anonymous_grading: true)
      end

      it "returns the preview URL for the submission" do
        @assignment.submit_homework(@student, body: "test")
        @submission.update!(posted_at: nil)
        expect(preview_url).to eq "http://test.host/courses/#{@course.id}/assignments/#{@assignment.id}/anonymous_submissions/#{@submission.anonymous_id}?preview=1&version=0"
      end
    end
  end

  describe "wordCount" do
    it "returns the word count" do
      @submission.update!(body: "word " * 100)
      run_jobs
      expect(submission_type.resolve("wordCount")).to eq 100
    end
  end

  describe "anonymous grading" do
    before do
      @assignment.update!(anonymous_grading: true)
      @submission.update!(posted_at: nil)
    end

    it "returns the anonymous id" do
      expect(submission_type.resolve("anonymousId")).to eq @submission.anonymous_id
    end

    it "does not show the user to a grader when an assignment is actively anonymous" do
      expect(submission_type.resolve("userId")).to be_nil
    end
  end

  describe "enrollments" do
    let(:other_section) { @course.course_sections.create! name: "other section" }
    let(:other_teacher) do
      @course.enroll_teacher(user_factory, section: other_section, limit_privileges_to_course_section: true).user
    end

    it "works" do
      expect(
        submission_type.resolve(
          "enrollmentsConnection { nodes { _id } }",
          current_user: @teacher
        )
      ).to match_array @course.enrollments.where(user_id: @submission.user_id).map(&:to_param)
    end

    it "doesn't return users not visible to current_user" do
      expect(
        submission_type.resolve(
          "enrollmentsConnection { nodes { _id } }",
          current_user: other_teacher
        )
      ).to be_empty
    end

    it "filters out soft-deleted enrollments" do
      @course.enrollments.where(user: @submission.user).destroy_all
      expect(
        submission_type.resolve(
          "enrollmentsConnection { nodes { _id } }",
          current_user: @teacher
        )
      ).to be_empty
    end
  end

  describe "lti_asset_reports_connection" do
    let(:root_account) { @course.root_account }
    let(:assignment) { @assignment }
    let(:submission) { @submission }
    let(:submission_type) { GraphQLTypeTester.new(submission, current_user:) }
    let(:lti_asset) { lti_asset_model(submission:) }
    let(:lti_asset_processor) { lti_asset_processor_model(assignment:) }
    let(:lti_asset_report) do
      lti_asset_report_model(
        lti_asset_processor_id: lti_asset_processor.id,
        asset: lti_asset,
        visible_to_owner: true
      )
    end

    before { lti_asset_report }

    context "when the current user is a teacher" do
      let(:current_user) { submission.assignment.context.instructors.first }

      it "returns LTI asset reports" do
        result = submission_type.resolve("ltiAssetReportsConnection { nodes { _id } }")
        expect(result).to eq [lti_asset_report.id.to_s]
      end

      it "returns LTI asset reports when latest is false" do
        result = submission_type.resolve("ltiAssetReportsConnection(latest: false) { nodes { _id } }")
        expect(result).to eq [lti_asset_report.id.to_s]
      end

      it "returns nil when latest is true (not implemented yet)" do
        result = submission_type.resolve("ltiAssetReportsConnection(latest: true) { nodes { _id } }")
        expect(result).to be_nil
      end
    end

    context "when the current user is a student" do
      let(:current_user) { @student }

      it "returns LTI asset reports" do
        lti_asset_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PROCESSED)
        result = submission_type.resolve("ltiAssetReportsConnection { nodes { _id } }")
        expect(result).to eq [lti_asset_report.id.to_s]
      end

      it "returns [] when there are reports, but not processed" do
        result = submission_type.resolve("ltiAssetReportsConnection { nodes { _id } }")
        expect(result).to eq []
      end

      it "returns nil when student cannot read their own grade" do
        allow_any_instance_of(Submission).to receive(:user_can_read_grade?).with(@student, for_plagiarism: true).and_return(false)
        result = submission_type.resolve("ltiAssetReportsConnection { nodes { _id } }")
        expect(result).to be_nil
      end
    end

    context "when the current user is a different student" do
      let(:current_user) { student_in_course(active_all: true).user }

      it "returns nil when user cannot read the submission" do
        result = submission_type.resolve("ltiAssetReportsConnection { nodes { _id } }")
        expect(result).to be_nil
      end
    end

    context "when submission is a discussion_topic" do
      let(:discussion_entry_version) do
        @assignment.update!(submission_types: "discussion_topic")
        @discussion_topic = @assignment.discussion_topic
        @discussion_topic.discussion_entries.create!(user: @student, message: "I have a lot to say about this topic").discussion_entry_versions.first
      end

      let(:lti_asset) { lti_asset_model(submission:, discussion_entry_version:) }

      context "when the current user is a teacher" do
        let(:current_user) { assignment.context.instructors.first }

        it "returns nil with feature flag disabled" do
          root_account.disable_feature!(:lti_asset_processor_discussions)
          result = submission_type.resolve("ltiAssetReportsConnection { nodes { _id } }")
          expect(result).to be_nil
        end

        it "returns LTI asset reports" do
          result = submission_type.resolve("ltiAssetReportsConnection { nodes { _id } }")
          expect(result).to eq [lti_asset_report.id.to_s]
        end
      end

      context "when the current user is a student" do
        let(:current_user) { @student }

        it "returns nil with feature flag disabled" do
          root_account.disable_feature!(:lti_asset_processor_discussions)
          lti_asset_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PROCESSED)
          result = submission_type.resolve("ltiAssetReportsConnection { nodes { _id } }")
          expect(result).to be_nil
        end

        it "returns LTI asset reports" do
          lti_asset_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PROCESSED)
          result = submission_type.resolve("ltiAssetReportsConnection { nodes { _id } }")
          expect(result).to eq [lti_asset_report.id.to_s]
        end
      end
    end
  end

  describe "hasSubAssignmentSubmissions" do
    before do
      @checkpoint_assignment = @course.assignments.create!(
        name: "checkpoint assignment",
        has_sub_assignments: true
      )
      @sub_assignment = @checkpoint_assignment.sub_assignments.create!(
        name: "sub assignment",
        context: @course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
        points_possible: 5
      )
      @checkpoint_submission = @checkpoint_assignment.submissions.find_by!(user: @student)
    end

    it "returns true when assignment has active sub assignment submissions" do
      checkpoint_submission_type = GraphQLTypeTester.new(@checkpoint_submission, current_user: @teacher)
      expect(checkpoint_submission_type.resolve("hasSubAssignmentSubmissions")).to be true
    end

    it "returns false when assignment has no active sub assignment submissions" do
      @sub_assignment.submissions.update_all(workflow_state: "deleted")
      checkpoint_submission_type = GraphQLTypeTester.new(@checkpoint_submission, current_user: @teacher)
      expect(checkpoint_submission_type.resolve("hasSubAssignmentSubmissions")).to be false
    end

    it "returns false for non-checkpoint assignments" do
      expect(submission_type.resolve("hasSubAssignmentSubmissions")).to be false
    end
  end

  describe "subAssignmentSubmissions" do
    before do
      @checkpoint_assignment = @course.assignments.create!(
        name: "checkpoint assignment",
        has_sub_assignments: true
      )
      @sub_assignment1 = @checkpoint_assignment.sub_assignments.create!(
        name: "sub assignment 1",
        context: @course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
        points_possible: 5
      )
      @sub_assignment2 = @checkpoint_assignment.sub_assignments.create!(
        name: "sub assignment 2",
        context: @course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY,
        points_possible: 5
      )
      @checkpoint_submission = @checkpoint_assignment.submissions.find_by!(user: @student)
      @sub_submission1 = @sub_assignment1.find_or_create_submission(@student)
      @sub_submission2 = @sub_assignment2.find_or_create_submission(@student)
    end

    it "returns sub assignment submissions when they exist" do
      checkpoint_submission_type = GraphQLTypeTester.new(@checkpoint_submission, current_user: @teacher)
      result = checkpoint_submission_type.resolve("subAssignmentSubmissions { assignmentId }")
      expect(result).to contain_exactly(@sub_assignment1.id.to_s, @sub_assignment2.id.to_s)
    end

    it "does not return sub assignment submissions with deleted workflow state" do
      @sub_submission2.update(workflow_state: "deleted")

      checkpoint_submission_type = GraphQLTypeTester.new(@checkpoint_submission, current_user: @teacher)
      result = checkpoint_submission_type.resolve("subAssignmentSubmissions { assignmentId }")
      expect(result).to eq [@sub_assignment1.id.to_s]
    end

    it "returns nil for non-checkpoint assignments" do
      result = submission_type.resolve("subAssignmentSubmissions { assignmentId }")
      expect(result).to be_nil
    end

    it "returns empty array when checkpoint assignment has no sub assignments" do
      assignment_without_subs = @course.assignments.create!(
        name: "checkpoint without subs",
        has_sub_assignments: true
      )
      submission_without_subs = assignment_without_subs.submissions.find_by!(user: @student)

      submission_type_without_subs = GraphQLTypeTester.new(submission_without_subs, current_user: @teacher)
      result = submission_type_without_subs.resolve("subAssignmentSubmissions { assignmentId }")
      expect(result).to eq []
    end

    it "returns error when no submission existed ever" do
      @sub_submission1.delete
      checkpoint_submission_type = GraphQLTypeTester.new(@checkpoint_submission, current_user: @teacher)
      expect do
        checkpoint_submission_type.resolve("subAssignmentSubmissions { assignmentId }")
      end.to raise_error(Checkpoints::SubAssignmentSubmissionSerializer::MissingSubAssignmentSubmissionError, /Submission is missing for SubAssignment/)
    end

    it "returns deducted_points for sub assignment submissions with late policy" do
      @sub_submission1.update!(points_deducted: 1.5, late_policy_status: "late")
      @sub_submission2.update!(points_deducted: 0, late_policy_status: nil)

      checkpoint_submission_type = GraphQLTypeTester.new(@checkpoint_submission, current_user: @teacher)
      result = checkpoint_submission_type.resolve("subAssignmentSubmissions { deductedPoints }")
      expect(result).to contain_exactly(1.5, 0.0)
    end

    it "returns nil for deducted_points when post policies hide grades" do
      @sub_submission1.update!(points_deducted: 1.5, late_policy_status: "late", posted_at: nil)
      @sub_assignment1.ensure_post_policy(post_manually: true)

      checkpoint_submission_type = GraphQLTypeTester.new(@checkpoint_submission, current_user: @student)
      result = checkpoint_submission_type.resolve("subAssignmentSubmissions { deductedPoints }")
      # Students can't see grades when posts are hidden
      expect(result.first).to be_nil
    end

    it "returns submitted_at timestamp when sub assignment submissions have been submitted" do
      submitted_time_1 = 2.hours.ago
      submitted_time_2 = 1.hour.ago

      @sub_assignment1.submit_homework(@student, body: "test", submitted_at: submitted_time_1)
      @sub_assignment2.submit_homework(@student, body: "test", submitted_at: submitted_time_2)

      checkpoint_submission_type = GraphQLTypeTester.new(@checkpoint_submission, current_user: @teacher)
      result = checkpoint_submission_type.resolve("subAssignmentSubmissions { submittedAt }")

      expect(result.length).to eq 2
      expect(result).to contain_exactly(submitted_time_1.iso8601, submitted_time_2.iso8601)
    end

    it "returns nil for submitted_at when sub assignment submissions have not been submitted" do
      @sub_submission1.update!(submitted_at: nil, workflow_state: "unsubmitted")
      @sub_submission2.update!(submitted_at: nil, workflow_state: "unsubmitted")

      checkpoint_submission_type = GraphQLTypeTester.new(@checkpoint_submission, current_user: @teacher)
      result = checkpoint_submission_type.resolve("subAssignmentSubmissions { submittedAt }")

      expect(result).to contain_exactly(nil, nil)
    end
  end

  describe "provisionalGradesConnection" do
    before(:once) do
      @teacher1 = user_factory(active_all: true)
      @teacher2 = user_factory(active_all: true)
      @moderator = user_factory(active_all: true)
      @student = user_factory(active_all: true)
      @admin = account_admin_user(account: @account)

      @course = course_factory(active_all: true)
      @course.enroll_teacher(@teacher1, enrollment_state: "active")
      @course.enroll_teacher(@teacher2, enrollment_state: "active")

      @course.enroll_teacher(@moderator, enrollment_state: "active")
      @course.enroll_student(@student, enrollment_state: "active")

      @moderated_assignment = @course.assignments.create!(
        name: "moderated assignment",
        moderated_grading: true,
        grader_count: 2,
        final_grader: @moderator
      )
      @moderated_assignment.create_moderation_grader(@teacher1, occupy_slot: true)
      @moderated_assignment.create_moderation_grader(@teacher2, occupy_slot: true)
      @assignment = @course.assignments.create!(name: "regular assignment")

      @moderated_assignment.grade_student(@student, grader: @teacher1, provisional: true, score: 10)
      @moderated_assignment.grade_student(@student, grader: @teacher2, provisional: true, score: 20)
      @moderated_submission = @moderated_assignment.submissions.find_by!(user: @student)
      @submission = @assignment.submissions.find_by!(user: @student)
    end

    it "returns nil for non-moderated assignments" do
      submission_type = GraphQLTypeTester.new(@submission, current_user: @moderator)
      expect(submission_type.resolve("provisionalGradesConnection { nodes { _id } }")).to be_nil
    end

    ["admin", "moderator"].each do |user_type|
      it "returns all provisional grades for #{user_type}s" do
        user = instance_variable_get("@#{user_type}")
        submission_type = GraphQLTypeTester.new(@moderated_submission, current_user: user)
        expect(submission_type.resolve("provisionalGradesConnection { nodes { _id } }")).to eq(@moderated_assignment.provisional_grades.map { |x| x.id.to_s })
      end
    end

    it "returns scored provisional grades for teachers" do
      submission_type = GraphQLTypeTester.new(@moderated_submission, current_user: @teacher1)
      expect(submission_type.resolve("provisionalGradesConnection { nodes { _id } }")).to eq(
        @moderated_assignment.provisional_grades.where(scorer: @teacher1).map { |x| x.id.to_s }
      )
    end

    describe "provisional grading fields" do
      it "returns true for hasProvisionalGradeByCurrentUser when user has provided a provisional grade with non-null score" do
        submission_type = GraphQLTypeTester.new(@moderated_submission, current_user: @teacher1)
        expect(submission_type.resolve("hasProvisionalGradeByCurrentUser")).to be true
      end

      it "returns false for hasProvisionalGradeByCurrentUser when user has not provided a provisional grade" do
        submission_type = GraphQLTypeTester.new(@moderated_submission, current_user: @moderator)
        expect(submission_type.resolve("hasProvisionalGradeByCurrentUser")).to be false
      end

      it "returns false for hasProvisionalGradeByCurrentUser when provisional grade has null score" do
        @moderated_submission.provisional_grades.destroy_all
        @moderated_submission.provisional_grades.create!(scorer: @teacher1, score: nil)
        submission_type = GraphQLTypeTester.new(@moderated_submission, current_user: @teacher1)
        expect(submission_type.resolve("hasProvisionalGradeByCurrentUser")).to be false
      end

      it "returns false for hasProvisionalGradeByCurrentUser on non-moderated assignments" do
        submission_type = GraphQLTypeTester.new(@submission, current_user: @teacher1)
        expect(submission_type.resolve("hasProvisionalGradeByCurrentUser")).to be false
      end

      it "returns false for hasProvisionalGradeByCurrentUser after grades are published" do
        @moderated_assignment.update!(grades_published_at: Time.zone.now)
        submission_type = GraphQLTypeTester.new(@moderated_submission, current_user: @teacher1)
        expect(submission_type.resolve("hasProvisionalGradeByCurrentUser")).to be false
      end
    end
  end

  describe "hasOriginalityReport" do
    before(:once) do
      @assignment_with_report = @course.assignments.create!(
        name: "assignment with originality report",
        submission_types: "online_upload"
      )
      @attachment = attachment_model
      @submission_with_report = @assignment_with_report.submit_homework(
        @student,
        submission_type: "online_upload",
        attachments: [@attachment]
      )
    end

    let(:submission_with_report_type) { GraphQLTypeTester.new(@submission_with_report, current_user: @teacher) }

    it "returns false when submission has no originality report" do
      expect(submission_with_report_type.resolve("hasOriginalityReport")).to be false
    end

    it "returns false for unsubmitted submissions" do
      unsubmitted_assignment = @course.assignments.create!(name: "unsubmitted assignment")
      unsubmitted_submission = unsubmitted_assignment.submissions.find_by!(user: @student)
      unsubmitted_type = GraphQLTypeTester.new(unsubmitted_submission, current_user: @teacher)

      expect(unsubmitted_type.resolve("hasOriginalityReport")).to be false
    end

    context "when submission has an originality report" do
      before(:once) do
        @report = OriginalityReport.create!(
          attachment: @attachment,
          originality_score: 75,
          submission: @submission_with_report,
          submission_time: @submission_with_report.submitted_at
        )
      end

      it "returns true" do
        expect(submission_with_report_type.resolve("hasOriginalityReport")).to be true
      end

      it "delegates to submission.originality_report_matches_current_version? for matching logic" do
        # The resolver should call the model method - verify it returns the same result
        expect(submission_with_report_type.resolve("hasOriginalityReport")).to eq(
          @submission_with_report.originality_report_matches_current_version?(@report)
        )
      end

      it "works without throwing NoMethodError when originality reports exist" do
        # Should not raise NoMethodError
        expect { submission_with_report_type.resolve("hasOriginalityReport") }.not_to raise_error
      end
    end
  end

  describe "auto_grade_submission_issues" do
    before do
      allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_submission)
        .with(submission: @submission)
        .and_return({ level: "error", message: "Test error" })
    end

    it "returns nil when project_lhotse feature flag is disabled" do
      @course.disable_feature!(:project_lhotse)
      expect(GraphQLHelpers::AutoGradeEligibilityHelper).not_to receive(:validate_submission)
      expect(submission_type.resolve("autoGradeSubmissionIssues { level message }")).to be_nil
    end

    it "returns issues when project_lhotse feature flag is enabled" do
      @course.enable_feature!(:project_lhotse)
      expect(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_submission)
      level = submission_type.resolve("autoGradeSubmissionIssues { level }")
      message = submission_type.resolve("autoGradeSubmissionIssues { message }")
      expect(level).to eq "error"
      expect(message).to eq "Test error"
    end
  end

  describe "auto_grade_submission_errors" do
    before do
      allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_submission)
        .with(submission: @submission)
        .and_return({ level: "error", message: "Test error" })
    end

    it "returns empty array when project_lhotse feature flag is disabled" do
      @course.disable_feature!(:project_lhotse)
      expect(GraphQLHelpers::AutoGradeEligibilityHelper).not_to receive(:validate_submission)
      expect(submission_type.resolve("autoGradeSubmissionErrors")).to eq([])
    end

    it "returns error messages when project_lhotse feature flag is enabled" do
      @course.enable_feature!(:project_lhotse)
      expect(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_submission)
      expect(submission_type.resolve("autoGradeSubmissionErrors")).to eq(["Test error"])
    end
  end
end
