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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative "../graphql_spec_helper"

describe Types::SubmissionType do
  before(:once) do
    student_in_course(active_all: true)
    @assignment = @course.assignments.create! name: "asdf", points_possible: 10
    @submission, _ = @assignment.grade_student(@student, score: 8, grader: @teacher)
  end

  let(:submission_type) { GraphQLTypeTester.new(@submission, current_user: @teacher) }

  it "works" do
    expect(submission_type.resolve("user { _id }")).to eq @student.id.to_s
    expect(submission_type.resolve("excused")).to eq false
    expect(submission_type.resolve("assignment { _id }")).to eq @assignment.id.to_s
  end

  it "requires read permission" do
    other_student = student_in_course(active_all: true).user
    expect(submission_type.resolve("_id", current_user: other_student)).to be_nil
  end

  describe "posted" do
    it "returns the posted status of the submission" do
      PostPolicy.enable_feature!
      @submission.update!(posted_at: nil)
      expect(submission_type.resolve("posted")).to eq false
      @submission.update!(posted_at: Time.zone.now)
      expect(submission_type.resolve("posted")).to eq true
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

  describe 'unread_comment_count' do
    let(:valid_submission_comment_attributes) {{ comment: 'some comment' }}

    it 'returns 0 if the submission is read' do
      @submission.mark_read(@teacher)
      submission_unread_count = submission_type.resolve('unreadCommentCount')
      expect(submission_unread_count).to eq 0
    end

    it 'returns unread count if the submission is unread' do
      @submission.mark_unread(@teacher)
      @submission.submission_comments.create!(valid_submission_comment_attributes)
      @submission.submission_comments.create!(valid_submission_comment_attributes)
      @submission.submission_comments.create!(valid_submission_comment_attributes)
      submission_unread_count = submission_type.resolve('unreadCommentCount')
      expect(submission_unread_count).to eq 3
    end

    it 'returns 0 if the submission is unread and all comments are read' do
      comment = @submission.submission_comments.create!(valid_submission_comment_attributes)
      comment.mark_read!(@teacher)
      @submission.mark_unread(@teacher)
      submission_unread_count = submission_type.resolve('unreadCommentCount')
      expect(submission_unread_count).to eq 0
    end
  end

  describe "score and grade" do
    context "muted assignment" do
      before { @assignment.update_attribute(:muted, true) }

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

  describe "submissionStatus" do
    before do
      quiz_with_submission
      @quiz_assignment = @quiz.assignment
      @quiz_submission = @quiz_assignment.submission_for_student(@student)
    end

    let(:submission_type_quiz) { GraphQLTypeTester.new(@quiz_submission, current_user: @teacher) }

    it "should contain submissionStatus field" do
      expect(submission_type.resolve("submissionStatus")).to eq "unsubmitted"
    end

    it "should preload quiz type assignments" do
      expect(submission_type_quiz.resolve("submissionStatus")).to eq "submitted"
    end
  end

  describe "late policy" do
    it "should show late policy" do
      @submission.update!(late_policy_status: :missing)
      expect(submission_type.resolve("latePolicyStatus")).to eq "missing"
    end
  end

  describe '#attempt' do
    it 'should show the attempt' do
      @submission.update_column(:attempt, 1) # bypass infer_values callback
      expect(submission_type.resolve('attempt')).to eq 1
    end

    it 'should translate nil in the database to 0 in graphql' do
      @submission.update_column(:attempt, nil) # bypass infer_values callback
      expect(submission_type.resolve('attempt')).to eq 0
    end
  end

  describe 'submission comments' do
    before(:once) do
      student_in_course(active_all: true)
      @submission.update_column(:attempt, 2) # bypass infer_values callback
      @comment1 = @submission.add_comment(author: @teacher, comment: 'test1', attempt: 1)
      @comment2 = @submission.add_comment(author: @teacher, comment: 'test2', attempt: 2)
    end

    it 'will only be shown for the current submission attempt by default' do
      expect(
        submission_type.resolve('commentsConnection { nodes { _id }}')
      ).to eq [@comment2.id.to_s]
    end

    it 'will show comments for a given attempt using the target_attempt argument' do
      expect(
        submission_type.resolve('commentsConnection(filter: {forAttempt: 1}) { nodes { _id }}')
      ).to eq [@comment1.id.to_s]
    end

    it 'will show alll comments for all attempts if all_comments is true' do
      expect(
        submission_type.resolve('commentsConnection(filter: {allComments: true}) { nodes { _id }}')
      ).to eq [@comment1.id.to_s, @comment2.id.to_s]
    end

    it 'will combine comments for attempt nil, 0, and 1' do
      @comment0 = @submission.add_comment(author: @teacher, comment: 'test1', attempt: 0)
      @commentNil = @submission.add_comment(author: @teacher, comment: 'test1', attempt: nil)

      (0..1).each do |i|
        expect(
          submission_type.resolve("commentsConnection(filter: {forAttempt: #{i}}) { nodes { _id }}")
        ).to eq [@comment1.id.to_s, @comment0.id.to_s, @commentNil.id.to_s]
      end
    end

    it 'will only return published drafts' do
      @submission.add_comment(author: @teacher, comment: 'test3', attempt: 2, draft_comment: true)
      expect(
        submission_type.resolve('commentsConnection { nodes { _id }}')
      ).to eq [@comment2.id.to_s]
    end

    it 'requires permission' do
      other_course_student = student_in_course(course: course_factory).user
      expect(
        submission_type.resolve('commentsConnection { nodes { _id }}', current_user: other_course_student)
      ).to be nil
    end
  end

  describe 'submission_drafts' do
    it 'returns the draft for attempt 0 when the submission attempt is nil' do
      @submission.update_columns(attempt: nil) # bypass #infer_details for test
      SubmissionDraft.create!(submission: @submission, submission_attempt: 1)
      expect(
        submission_type.resolve('submissionDraft { submissionAttempt }')
      ).to eq 1
    end

    it 'returns nil for a non current submission history that has a draft' do
      assignment = @course.assignments.create! name: "asdf", points_possible: 10
      @submission1 = assignment.submit_homework(@student, body: 'Attempt 1', submitted_at: 2.hours.ago)
      @submission2 = assignment.submit_homework(@student, body: 'Attempt 2', submitted_at: 1.hour.ago)
      SubmissionDraft.create!(submission: @submission1, submission_attempt: @submission1.attempt + 1)
      SubmissionDraft.create!(submission: @submission2, submission_attempt: @submission2.attempt + 1)
      resolver = GraphQLTypeTester.new(@submission2, current_user: @teacher)
      expect(
        resolver.resolve(
          'submissionHistoriesConnection { nodes { submissionDraft { submissionAttempt }}}'
        )
      ).to eq [nil, @submission2.attempt + 1]
    end
  end

  describe 'attachments' do
    before(:once) do
      assignment = @course.assignments.create! name: "asdf", points_possible: 10
      @attachment1 = attachment_model
      @attachment2 = attachment_model
      @submission1 = assignment.submit_homework(@student, body: 'Attempt 1', submitted_at: 2.hours.ago)
      @submission1.attachments = [@attachment1]
      @submission1.save!
      @submission2 = assignment.submit_homework(@student, body: 'Attempt 2', submitted_at: 1.hour.ago)
      @submission2.attachments = [@attachment2]
      @submission2.save!
    end

    let(:submission_type) { GraphQLTypeTester.new(@submission2, current_user: @teacher) }

    it 'works for a submission' do
      expect(submission_type.resolve('attachments { _id }')).to eq [@attachment2.id.to_s]
    end

    it 'works for a submission history' do
      expect(
        submission_type.resolve(
          'submissionHistoriesConnection(first: 1) { nodes { attachments { _id }}}'
        )
      ).to eq [[@attachment1.id.to_s]]
    end
  end

  describe 'submission histories connection' do
    before(:once) do
      assignment = @course.assignments.create! name: "asdf2", points_possible: 10
      @submission1 = assignment.submit_homework(@student, body: 'Attempt 1', submitted_at: 2.hours.ago)
      @submission2 = assignment.submit_homework(@student, body: 'Attempt 2', submitted_at: 1.hour.ago)
      @submission3 = assignment.submit_homework(@student, body: 'Attempt 3')
    end

    let(:submission_history_type) { GraphQLTypeTester.new(@submission3, current_user: @teacher) }

    it 'returns the submission histories' do
      expect(
        submission_history_type.resolve('submissionHistoriesConnection { nodes { attempt }}')
      ).to eq [1, 2, 3]
    end

    it 'properly handles cursors for submission histories' do
      expect(
        submission_history_type.resolve('submissionHistoriesConnection { edges { cursor }}')
      ).to eq ["MQ", "Mg", "Mw"]
    end

    context 'filter' do
      describe 'states' do
        before(:once) do
          # Cannot use .first here, because versionable changes .first to .last :knife:
          history_version = @submission3.versions[0]
          history = YAML.load(history_version.yaml)
          history['workflow_state'] = 'unsubmitted'
          history_version.update!(yaml: history.to_yaml)
        end

        it 'does not filter by states by default' do
          expect(
            submission_history_type.resolve('submissionHistoriesConnection { nodes { attempt }}')
          ).to eq [1, 2, 3]
        end

        it 'can be used to filter by workflow state' do
          expect(
            submission_history_type.resolve(
              'submissionHistoriesConnection(filter: {states: [submitted]}) { nodes { attempt }}'
            )
          ).to eq [1, 2]
        end
      end

      describe 'include_current_submission' do
        it 'includes the current submission history by default' do
          expect(
            submission_history_type.resolve('submissionHistoriesConnection { nodes { attempt }}')
          ).to eq [1, 2, 3]
        end

        it 'includes the current submission history when true' do
          expect(
            submission_history_type.resolve(
              'submissionHistoriesConnection(filter: {includeCurrentSubmission: true}) { nodes { attempt }}'
            )
          ).to eq [1, 2, 3]
        end

        it 'does not includes the current submission history when false' do
          expect(
            submission_history_type.resolve(
              'submissionHistoriesConnection(filter: {includeCurrentSubmission: false}) { nodes { attempt }}'
            )
          ).to eq [1, 2]
        end
      end
    end
  end

  describe 'late' do
    before(:once) do
      assignment = @course.assignments.create!(name: "late assignment", points_possible: 10, due_at: 2.hours.ago)
      @submission1 = assignment.submit_homework(@student, body: 'late', submitted_at: 1.hour.ago)
    end

    let(:submission_type) { GraphQLTypeTester.new(@submission1, current_user: @teacher) }

    it 'returns late' do
      expect(submission_type.resolve("late")).to eq true
    end
  end

  describe 'missing' do
    before(:once) do
      assignment = @course.assignments.create!(
        name: "missing assignment",
        points_possible: 10,
        due_at: 1.hour.ago,
        submission_types: ['online_text_entry']
      )
      @submission1 = Submission.where(assignment_id: assignment.id, user_id: @student.id).first
    end

    let(:submission_type) { GraphQLTypeTester.new(@submission1, current_user: @teacher) }

    it 'returns missing' do
      expect(submission_type.resolve("missing")).to eq true
    end
  end

  describe 'gradeMatchesCurrentSubmission' do
    before(:once) do
      assignment = @course.assignments.create!(name: "assignment", points_possible: 10)
      assignment.submit_homework(@student, body: 'asdf')
      assignment.grade_student(@student, score: 8, grader: @teacher)
      @submission1 = assignment.submit_homework(@student, body: 'asdf')
    end

    let(:submission_type) { GraphQLTypeTester.new(@submission1, current_user: @teacher) }

    it 'returns gradeMatchesCurrentSubmission' do
      expect(submission_type.resolve("gradeMatchesCurrentSubmission")).to eq false
    end
  end

  describe 'rubric_Assessments_connection' do
    before(:once) do
      rubric_for_course
      rubric_association_model(
        context: @course,
        rubric: @rubric,
        association_object: @assignment,
        purpose: 'grading'
      )

      @assignment.submit_homework(@student, body: 'foo', submitted_at: 2.hour.ago)

      rubric_assessment_model(
        user: @student,
        assessor: @teacher,
        rubric_association: @rubric_association,
        assessment_type: 'grading'
      )
    end

    it 'works' do
      expect(
        submission_type.resolve('rubricAssessmentsConnection { nodes { _id } }')
      ).to eq [@rubric_assessment.id.to_s]
    end

    it 'requires permission' do
      expect(
        submission_type.resolve('rubricAssessmentsConnection { nodes { _id } }', current_user: @student)
      ).to eq [@rubric_assessment.id.to_s]
    end

    it 'grabs the assessment for the current submission attempt by default' do
      @submission2 = @assignment.submit_homework(@student, body: 'Attempt 2', submitted_at: 1.hour.ago)
      expect(
        submission_type.resolve('rubricAssessmentsConnection { nodes { _id } }')
      ).to eq []
    end

    it 'grabs the assessment for the given submission attempt when using the for_attempt filter' do
      @assignment.submit_homework(@student, body: 'bar', submitted_at: 1.hour.since)
      expect(
        submission_type.resolve('rubricAssessmentsConnection(filter: {forAttempt: 2}) { nodes { _id } }')
      ).to eq [@rubric_assessment.id.to_s]
    end

    it 'works with submission histories' do
      @assignment.submit_homework(@student, body: 'bar', submitted_at: 1.hour.since)
      expect(
        submission_type.resolve(
          'submissionHistoriesConnection { nodes { rubricAssessmentsConnection { nodes { _id } } } }'
        )
      ).to eq [[], [@rubric_assessment.id.to_s], []]
    end
  end

  describe 'turnitin_data' do
    tii_data = {
      similarity_score: 10,
      state: 'acceptable',
      report_url: 'http://example.com',
      status: 'scored'
    }

    before(:once) do
      @submission.turnitin_data[@submission.asset_string] = tii_data
      @submission.save!
    end

    it 'returns turnitin_data' do
      expect(
        submission_type.resolve('turnitinData { target { ...on Submission { _id } } }')
      ).to eq [@submission.id.to_s]
      expect(
        submission_type.resolve('turnitinData { status }')
      ).to eq [tii_data[:status]]
      expect(
        submission_type.resolve('turnitinData { score }')
      ).to eq [tii_data[:similarity_score]]
    end
  end

  describe 'submissionType' do
    before(:once) do
      @assignment.submit_homework(@student, body: 'bar', submission_type: 'online_text_entry')
    end

    it 'returns the submissionType' do
      expect(
        submission_type.resolve('submissionType')
      ).to eq 'online_text_entry'
    end
  end
end
