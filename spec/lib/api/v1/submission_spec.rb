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

require 'spec_helper'

describe Api::V1::Submission do
  include Api::V1::Submission
  include Rails.application.routes.url_helpers
  Rails.application.routes.default_url_options[:host] = 'localhost'

  let(:user) { User.create! }
  let(:course) { Course.create! }
  let(:assignment) { course.assignments.create! }
  let(:session) { {} }
  let(:context) { nil }
  let(:params) { { includes: [field]} }
  let(:submission) { assignment.submissions.build(user: user) }

  describe "submission status" do
    let(:field) { 'submission_status' }
    let(:submission_status) do
      -> (submission) do
        json = submission_json(submission, assignment, user, session, context, [field], params)
        json.fetch(field)
      end
    end

    it "can be Resubmitted" do
      submission.submission_type = 'online_text_entry'
      submission.grade_matches_current_submission = false
      submission.workflow_state = 'submitted'
      expect(submission_status.call(submission)).to be :resubmitted
    end

    it "can be Missing" do
      assignment.update!(due_at: 1.week.ago, submission_types: 'online_text_entry')
      submission.cached_due_date = 1.week.ago
      expect(submission_status.call(submission)).to be :missing
    end

    it "can be Late" do
      assignment.update!(due_at: 1.week.ago)
      submission.submission_type = 'online_text_entry'
      submission.cached_due_date = assignment.due_at
      submission.submitted_at = Time.zone.now
      expect(submission_status.call(submission)).to be :late
    end

    it "can be Unsubmitted by workflow state" do
      submission.workflow_state = 'unsubmitted'
      expect(submission_status.call(submission)).to be :unsubmitted
    end

    it "is Submitted by default" do
      expect(submission_status.call(submission)).to be :submitted
    end

    it "can be Submitted by workflow state" do
      # make it not submitted first, since submission is already submitted? => true
      submission.workflow_state = 'deleted'
      expect {
        submission.workflow_state = 'submitted'
      }.to change { submission_status.call(submission) }.from(:unsubmitted).to(:submitted)
    end

    it "can be Submitted by submission type" do
      submission.workflow_state = 'deleted'
      submission.submission_type = 'online_text_entry'
      expect(submission_status.call(submission)).to be :submitted
    end

    it "can be Submitted by quiz" do
      submission.workflow_state = 'deleted'
      submission.submission_type = 'online_quiz'
      quiz_submission = instance_double(Quizzes::QuizSubmission, completed?: true, versions: [])
      allow(submission).to receive(:quiz_submission).and_return(quiz_submission)
      expect(submission_status.call(submission)).to be :submitted
    end

    describe "ordinality" do
      describe "Resubmitted before all others," do
        it "is Resubmitted when it was first Missing" do
          # make a missing assignment
          assignment.update!(due_at: 1.week.ago, submission_types: 'online_text_entry')
          submission.cached_due_date = 1.week.ago
          # make it resubmitted
          submission.submission_type = 'online_text_entry'
          submission.grade_matches_current_submission = false
          submission.workflow_state = 'submitted'
          expect(submission_status.call(submission)).to be :resubmitted
        end

        it "is Resubmitted when it was first Late" do
          # make a late assignment
          assignment.update!(due_at: 1.week.ago)
          submission.submission_type = 'online_text_entry'
          submission.cached_due_date = assignment.due_at
          submission.submitted_at = Time.zone.now
          # make it resubmitted
          submission.submission_type = 'online_text_entry'
          submission.grade_matches_current_submission = false
          submission.workflow_state = 'submitted'
          expect(submission_status.call(submission)).to be :resubmitted
        end

        it "is Resubmitted when it was first Submitted" do
          # make a submitted assignment
          submission.workflow_state = 'submitted'
          # make it resubmitted
          submission.submission_type = 'online_text_entry'
          submission.grade_matches_current_submission = false
          submission.workflow_state = 'submitted'
          expect(submission_status.call(submission)).to be :resubmitted
        end

        it "is Resubmitted when it was first Unsubmitted" do
          # make an unsubmitted assignment
          submission.workflow_state = 'unsubmitted'
          # make it resubmitted
          submission.submission_type = 'online_text_entry'
          submission.grade_matches_current_submission = false
          submission.workflow_state = 'submitted'
          expect(submission_status.call(submission)).to be :resubmitted
        end
      end

      describe "Missing before Late, Unsubmitted, and Submitted" do
        it "is Missing when it was first Late" do
          # make a late assignment
          assignment.update!(due_at: 1.week.ago, submission_types: 'online_text_entry')
          submission.submission_type = 'online_text_entry'
          submission.cached_due_date = assignment.due_at
          submission.submitted_at = Time.zone.now
          # make it missing
          submission.submitted_at = nil
          submission.submission_type = nil
          expect(submission_status.call(submission)).to be :missing
        end

        it "is Missing when it was first Submitted" do
          # make a submission with a submitted label
          submission.workflow_state = 'submitted'
          # make it missing
          assignment.update!(due_at: 1.week.ago, submission_types: 'online_text_entry')
          submission.assignment = assignment
          submission.cached_due_date = assignment.due_at
          expect(submission_status.call(submission)).to be :missing
        end

        it "is Missing when it was first Unsubmitted" do
          # make an unsubmitted assignment
          submission.workflow_state = 'unsubmitted'
          # make it missing
          assignment.update!(due_at: 1.week.ago, submission_types: 'online_text_entry')
          submission.assignment = assignment
          submission.cached_due_date = assignment.due_at
          expect(submission_status.call(submission)).to be :missing
        end
      end

      describe "Late before Unsubmitted, and Submitted," do
        it "is Late when it was first Submitted" do
          # make a submitted submisison
          submission.workflow_state = 'submitted'
          # make it late
          assignment.update!(due_at: 1.week.ago)
          submission.assignment = assignment
          submission.cached_due_date = assignment.due_at
          submission.submission_type ='online_text_entry'
          submission.submitted_at = Time.zone.now
          expect(submission_status.call(submission)).to be :late
        end

        it "is Late when it was first Unsubmitted" do
          # make an unsubmitted assignment
          submission.workflow_state = 'unsubmitted'
          # make it late
          assignment.update!(due_at: 1.week.ago)
          submission.assignment = assignment
          submission.cached_due_date = assignment.due_at
          submission.submission_type ='online_text_entry'
          submission.submitted_at = Time.zone.now
          expect(submission_status.call(submission)).to be :late
        end
      end

      it "is Unsubmitted when it was first submitted" do
        # make a submitted submission
        submission.workflow_state = 'submitted'
        # make it unsubmitted
        submission.workflow_state = 'unsubmitted'
        expect(submission_status.call(submission)).to be :unsubmitted
      end
    end
  end

  describe "grading status" do
    let(:field) { 'grading_status' }
    let(:grading_status) do
      -> (submission) do
        json = submission_json(submission, assignment, user, session, context, [field], params)
        json.fetch(field)
      end
    end

    it "can be Excused" do
      submission.excused = true
      expect(grading_status.call(submission)).to be :excused
    end

    it "can be Needs Review" do
      submission.workflow_state = 'pending_review'
      expect(grading_status.call(submission)).to be :needs_review
    end

    it "can be Needs Grading" do
      submission.submission_type = 'online_text_entry'
      submission.workflow_state = 'submitted'
      expect(grading_status.call(submission)).to be :needs_grading
    end

    it "can be Graded" do
      submission.score = 10
      submission.workflow_state = 'graded'
      expect(grading_status.call(submission)).to be :graded
    end

    it "otherwise returns nil" do
      submission.workflow_state = 'deleted'
      expect(grading_status.call(submission)).to be_nil
    end

    describe "ordinality" do
      describe "Excused before all others," do
        it "is Excused when it was first Pending Review" do
          # make a submission that is pending review
          submission.workflow_state = 'pending_review'
          # make it excused
          submission.excused = true
          expect(grading_status.call(submission)).to be :excused
        end

        it "is Excused when it was first Needs Grading" do
          # make a submission that needs grading
          submission.submission_type = 'online_text_entry'
          submission.workflow_state = 'submitted'
          # make it excused
          submission.excused = true
          expect(grading_status.call(submission)).to be :excused
        end

        it "is Excused when it was first graded" do
          # make a submission graded
          submission.workflow_state = 'graded'
          submission.score = 10
          # make it excused
          submission.excused = true
          expect(grading_status.call(submission)).to be :excused
        end

        it "is Excused when it was first nil" do
          # make a submission with a nil label
          submission.workflow_state = 'deleted'
          # make it excused
          submission.excused = true
          expect(grading_status.call(submission)).to be :excused
        end
      end

      describe "Needs Review before Needs Grading, Graded, and nil," do
        it "is Needs Review when it was first Needs Grading" do
          # make a submission that needs grading
          submission.submission_type = 'online_text_entry'
          submission.workflow_state = 'submitted'
          # make it needs_review
          submission.workflow_state = 'pending_review'
          expect(grading_status.call(submission)).to be :needs_review
        end

        it "is Needs Review when it was first graded" do
          # make a submission graded
          submission.workflow_state = 'graded'
          submission.score = 10
          # make it needs_review
          submission.workflow_state = 'pending_review'
          expect(grading_status.call(submission)).to be :needs_review
        end

        it "is Needs Review when it was first nil" do
          # make a submission with a nil label
          submission.workflow_state = 'deleted'
          # make it needs_review
          submission.workflow_state = 'pending_review'
          expect(grading_status.call(submission)).to be :needs_review
        end
      end

      describe "Needs Grading before Graded and nil," do
        it "is Needs Grading when it was first graded" do
          # make a submission graded
          submission.workflow_state = 'graded'
          submission.score = 10
          # make it needs_grading
          submission.submission_type = 'online_text_entry'
          submission.workflow_state = 'submitted'
          expect(grading_status.call(submission)).to be :needs_grading
        end

        it "is Needs Grading when it was first nil" do
          # make a submission with a nil label
          submission.workflow_state = 'deleted'
          # make it needs_grading
          submission.submission_type = 'online_text_entry'
          submission.workflow_state = 'submitted'
          expect(grading_status.call(submission)).to be :needs_grading
        end
      end

      it "is Graded when it was first nil" do
        # make a submission with a nil label
        submission.workflow_state = 'deleted'
        # make it graded
        submission.workflow_state = 'graded'
        submission.score = 10
        expect(grading_status.call(submission)).to be :graded
      end
    end
  end
end
