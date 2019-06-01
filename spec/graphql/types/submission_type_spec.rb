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

  describe "posted_at" do
    it "returns the posted_at of the submission" do
      now = Time.zone.now.change(usec: 0)
      @submission.update!(posted_at: now)
      posted_at = Time.zone.parse(submission_type.resolve("postedAt"))
      expect(posted_at).to eq now
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

  describe "submission and grading status" do
    before do
      quiz_with_submission
      @quiz_assignment = @quiz.assignment
      @quiz_submission = @quiz_assignment.submission_for_student(@student)
    end

    let(:submission_type_quiz) { GraphQLTypeTester.new(@quiz_submission, current_user: @teacher) }

    it "should contain submissionStatus and gradingStatus fields" do
      expect(submission_type.resolve("submissionStatus")).to eq "unsubmitted"
      expect(submission_type.resolve("gradingStatus")).to eq "graded"
    end

    it "should preload quiz type assignments" do
      expect(submission_type_quiz.resolve("submissionStatus")).to eq "submitted"
      expect(submission_type_quiz.resolve("gradingStatus")).to eq "graded"
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

    it 'will show alll comments for all attempts if all_comments is true' do
      expect(
        submission_type.resolve('commentsConnection(filter: {allComments: true}) { nodes { _id }}')
      ).to eq [@comment1.id.to_s, @comment2.id.to_s]
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

  describe 'submission histories connection' do
    before(:once) do
      # In the world code path that the initial submission takes, there is a bulk
      # insert directly into the database, which causes no version to be saved
      # for the zero submission. Delete the version_ids here to simulate that.
      @submission.update!(version_ids: [])
    end

    it 'works when there are no versions saved' do
      expect(
        submission_type.resolve('submissionHistoriesConnection { nodes { attempt }}')
      ).to eq [0]
    end

    it 'includes the zero submission when there are versions' do
      @submission.update!(attempt: 1)
      expect(
        submission_type.resolve('submissionHistoriesConnection { nodes { attempt }}')
      ).to eq [1, 0]
    end

    context 'custom pagination' do
      before(:once) do
        @submission.update!(attempt: 1)
      end

      it 'works for nodes' do
        expect(
          submission_type.resolve('submissionHistoriesConnection(first: 1) { nodes { attempt }}')
        ).to eq [1]
      end

      it 'works for edges node' do
        expect(
          submission_type.resolve('submissionHistoriesConnection(first: 1) { edges { node { attempt }}}')
        ).to eq [1]
      end

      it 'works for edges cursor' do
        expect(
          submission_type.resolve('submissionHistoriesConnection(first: 1) { edges { cursor }}')
        ).to eq ["MQ"] # Base64 encoded 1, per the graphql gem impmenetation of array paginating
      end

      it 'works for pageInfo endCursor' do
        expect(
          submission_type.resolve('submissionHistoriesConnection(first: 1) { pageInfo { endCursor }}')
        ).to eq "MQ" # Base64 encoded 1, per the graphql gem impmenetation of array paginating
      end

      it 'works for pageInfo hasNextPage' do
        expect(
          submission_type.resolve('submissionHistoriesConnection(first: 1) { pageInfo { hasNextPage }}')
        ).to eq true
      end
    end
  end
end
