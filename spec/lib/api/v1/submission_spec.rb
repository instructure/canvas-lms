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
  subject(:fake_controller) do
    Class.new do
      include Api::V1::Submission
      include Rails.application.routes.url_helpers

      private

      def default_url_options
        {host: :localhost}
      end
    end.new
  end

  let(:user) { User.create! }
  let(:course) { Course.create! }
  let(:assignment) { course.assignments.create! }
  let(:teacher) {
    teacher = User.create!
    course.enroll_teacher(teacher)
    teacher
  }
  let(:session) { {} }
  let(:context) { nil }
  let(:params) { { includes: [field]} }
  let(:submission) { assignment.submissions.create!(user: user) }
  let(:provisional_grade) { submission.provisional_grades.create!(scorer: teacher) }

  describe '#provisional_grade_json' do
    describe 'speedgrader_url' do
      it "links to the speed grader for a student's submission" do
        expect(assignment).to receive(:can_view_student_names?).with(user).and_return true
        json = fake_controller.provisional_grade_json(
          course: course,
          assignment: assignment,
          submission: submission,
          provisional_grade: provisional_grade,
          current_user: user
        )
        path = "/courses/#{course.id}/gradebook/speed_grader"
        query = { 'assignment_id' => assignment.id.to_s }
        fragment = { 'provisional_grade_id' => provisional_grade.id, 'student_id' => user.id }
        expect(json.fetch('speedgrader_url')).to match_path(path).and_query(query).and_fragment(fragment)
      end

      it "links to the speed grader for a student's anonymous submission when grader cannot view student names" do
        expect(assignment).to receive(:can_view_student_names?).with(user).and_return false
        json = fake_controller.provisional_grade_json(
          course: course,
          assignment: assignment,
          submission: submission,
          provisional_grade: provisional_grade,
          current_user: user
        )
        path = "/courses/#{course.id}/gradebook/speed_grader"
        query = { 'assignment_id' => assignment.id.to_s }
        fragment = { 'provisional_grade_id' => provisional_grade.id, 'anonymous_id' => submission.anonymous_id }
        expect(json.fetch('speedgrader_url')).to match_path(path).and_query(query).and_fragment(fragment)
      end
    end
  end

  describe '#submission_json' do
    describe 'anonymous_id' do
      let(:field) { 'anonymous_id' }
      let(:submission) { assignment.submissions.build(user: user) }
      let(:json) do
        fake_controller.submission_json(submission, assignment, user, session, context, [field], params)
      end

      context 'when not an account user' do
        it 'does not include anonymous_id' do
          expect(json).not_to have_key 'anonymous_id'
        end
      end

      context 'when an account user' do
        let(:user) do
          user = User.create!
          Account.default.account_users.create!(user: user)
          user
        end

        it 'does include anonymous_id' do
          expect(json.fetch('anonymous_id')).to eql submission.anonymous_id
        end
      end
    end

    describe "submission status" do
      let(:field) { 'submission_status' }
      let(:submission) { assignment.submissions.build(user: user) }
      let(:submission_status) do
        -> (submission) do
          json = fake_controller.submission_json(submission, assignment, user, session, context, [field], params)
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
            # make a submitted submission
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
          json = fake_controller.submission_json(submission, assignment, user, session, context, [field], params)
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

    describe "canvadoc url" do
      let(:course) { Course.create! }
      let(:assignment) { course.assignments.create! }
      let(:teacher) { course_with_user("TeacherEnrollment", course: course, active_all: true, name: "Teacher").user }
      let(:student) { course_with_user("StudentEnrollment", course: course, active_all: true, name: "Student").user }
      let(:attachment) { attachment_model(content_type: "application/pdf", context: student) }
      let(:submission) { assignment.submit_homework(student, submission_type: 'online_upload', attachments: [attachment]) }
      let(:json) { fake_controller.submission_json(submission, assignment, teacher, session) }

      before(:each) do
        allow(Canvadocs).to receive(:annotations_supported?).and_return(true)
        allow(Canvadocs).to receive(:enabled?).and_return(true)
        Canvadoc.create!(document_id: "abc123#{attachment.id}", attachment_id: attachment.id)
      end

      it "includes the submission id in the attachment's preview url" do
        expect(json.fetch(:attachments).first.fetch(:preview_url)).to include("submission_id%22:#{submission.id}")
      end
    end

    describe "Quizzes.Next" do
      before do
        allow(assignment).to receive(:quiz_lti?).and_return(true)
        url_grades.each do |h|
          grade = "#{TextHelper.round_if_whole(h[:grade] * 100)}%"
          grade, score = assignment.compute_grade_and_score(grade, nil)
          submission.grade = grade
          submission.score = score
          submission.submission_type = 'basic_lti_launch'
          submission.workflow_state = 'submitted'
          submission.submitted_at = Time.zone.now
          submission.url = h[:url]
          submission.grader_id = -1
          submission.with_versioning(:explicit => true) { submission.save! }
        end
      end

      let(:field) { 'submission_history' }

      let(:submission) { assignment.submissions.build(user: user) }

      let(:json) do
        fake_controller.submission_json(submission, assignment, user, session, context, [field], params)
      end

      let(:urls) do
        %w(
          https://abcdef.com/uuurrrlll00
          https://abcdef.com/uuurrrlll01
          https://abcdef.com/uuurrrlll02
          https://abcdef.com/uuurrrlll03
        )
      end

      let(:url_grades) do
        [
          # url 0 group
          { url: urls[0], grade: 0.11 },
          { url: urls[0], grade: 0.12 },
          # url 1 group
          { url: urls[1], grade: 0.22 },
          { url: urls[1], grade: 0.23 },
          { url: urls[1], grade: 0.24 },
          # url 2 group
          { url: urls[2], grade: 0.33 },
          # url 3 group
          { url: urls[3], grade: 0.44 },
          { url: urls[3], grade: 0.45 },
          { url: urls[3], grade: 0.46 },
          { url: urls[3], grade: 0.47 },
          { url: urls[3], grade: 0.48 }
        ]
      end

      it "outputs submission histories only for distinct urls" do
        expect(json.fetch(field).count).to be 4
      end
    end
  end

  describe '#submission_zip' do
    let(:attachment) { fake_controller.submission_zip(assignment) }

    it 'locks the attachment if the assignment is anonymous and muted' do
      assignment.muted = true
      assignment.anonymous_grading = true
      expect(attachment).to be_locked
    end

    it 'does not lock the attachment if the assignment is anonymous and unmuted' do
      assignment.anonymous_grading = true
      expect(attachment).not_to be_locked
    end

    it 'does not lock the attachment if the assignment is not anonymous' do
      expect(attachment).not_to be_locked
    end
  end
end
