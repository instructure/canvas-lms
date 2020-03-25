#
# Copyright (C) 2015 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GradeSummaryAssignmentPresenter do
  before :each do
    attachment_model
    course_factory(active_all: true)
    student_in_course active_all: true
    teacher_in_course active_all: true
    @assignment = @course.assignments.create!(title: "some assignment",
                                                assignment_group: @group,
                                                points_possible: 12,
                                                tool_settings_tool: @tool)
    @attachment.context = @student
    @attachment.save!
    @submission = @assignment.submit_homework(@student, attachments: [@attachment])
  end

  let(:summary) {
    GradeSummaryPresenter.new :first, :second, :third
  }

  let(:presenter) {
    GradeSummaryAssignmentPresenter.new(summary,
                                        @student,
                                        @assignment,
                                        @submission)
  }

  describe '#plagiarism_attachment?' do
    it 'returns true if the submission has an OriginalityReport' do
      OriginalityReport.create(originality_score: 0.8,
                               attachment: @attachment,
                               submission: @submission,
                               workflow_state: 'scored')

      expect(presenter.plagiarism_attachment?(@attachment)).to eq true
    end

    it 'returns true when the attachment has a pending originality report' do
      OriginalityReport.create(attachment: @attachment,
                               submission: @submission)

      expect(presenter.plagiarism_attachment?(@attachment)).to eq true
    end

    it 'returns when submission was automatically created by group assignment submission' do
      submission_two = @submission.dup
      submission_two.update!(user: User.create!(name: 'second student'))
      AttachmentAssociation.create!(context: @submission, attachment_id: @attachment)
      AttachmentAssociation.create!(context: submission_two, attachment_id: @attachment)
      OriginalityReport.create(originality_score: 0.8,
                               attachment: @attachment,
                               submission: @submission,
                               workflow_state: 'pending')
      expect(presenter.plagiarism_attachment?(submission_two.attachments.first)).to eq true
    end
  end

  describe '#upload_status' do
    it 'returns attachment upload_status when upload_status is pending' do
      allow(Rails.cache).to receive(:read).and_return('pending')
      expect(presenter.upload_status).to eq('pending')
    end

    it 'returns attachment upload_status when upload_status is failed' do
      allow(Rails.cache).to receive(:read).and_return('failed')
      expect(presenter.upload_status).to eq('failed')
    end

    it 'returns the proper attachment when there are multiple attachments in different states' do
      attachment_1 = attachment_model(context: @student)
      attachment_1.workflow_state = 'success'
      attachment_1.save!
      attachment_2 = attachment_model(context: @student)
      attachment_2.workflow_state = 'errored'
      attachment_2.save!
      attachment_3 = attachment_model(context: @student)
      @assignment.submit_homework @student, attachments: [attachment_1, attachment_2, attachment_3]
      AttachmentUploadStatus.success!(attachment_1)
      AttachmentUploadStatus.failed!(attachment_2, 'bad things')
      AttachmentUploadStatus.pending!(attachment_3)
      expect(presenter.upload_status).to eq('failed')
    end
  end

  describe '#originality_report' do
    it 'returns true when an originality report exists' do
      OriginalityReport.create(originality_score: 0.8,
                               attachment: @attachment,
                               submission: @submission,
                               workflow_state: 'pending')
      expect(presenter.originality_report?).to be_truthy
    end

    it 'returns true when an originality report exists with no attachment' do
      OriginalityReport.create(originality_score: 0.8,
                               submission: @submission,
                               workflow_state: 'pending')
      expect(presenter.originality_report?).to be_truthy
    end

    it 'returns false if no originailty report exists' do
      expect(presenter.originality_report?).not_to be_truthy
    end
  end

  describe "#grade_distribution" do
    context "when a summary's assignment_stats is empty" do
      before { allow(summary).to receive(:assignment_stats).and_return({}) }

      it "does not raise an error " do
        expect { presenter.grade_distribution }.to_not raise_error
      end

      it "returns nil when a summary's assignment_stats is empty" do
        expect(presenter.grade_distribution).to be_nil
      end
    end
  end

  describe "#original_points" do
    it "returns an empty string when grades are hidden" do
      allow(@submission).to receive(:hide_grade_from_student?).and_return(true)
      expect(presenter.original_points).to eq ''
    end

    it "returns an empty string when submission is nil" do
      test_presenter = GradeSummaryAssignmentPresenter.new(summary, @student, @assignment, nil)
      expect(test_presenter.original_points).to eq ''
    end

    it "returns the published score" do
      expect(presenter.original_points).to eq @submission.published_score
    end
  end

  describe '#deduction_present?' do
    it 'returns true when submission has positive points_deducted' do
      allow(@submission).to receive(:points_deducted).and_return(10)
      expect(presenter.deduction_present?).to eq(true)
    end

    it 'returns false when submission has zero points_deducted' do
      allow(@submission).to receive(:points_deducted).and_return(0)
      expect(presenter.deduction_present?).to eq(false)
    end

    it 'returns false when submission has nil points_deducted' do
      allow(@submission).to receive(:points_deducted).and_return(nil)
      expect(presenter.deduction_present?).to eq(false)
    end

    it 'returns false when submission is not present' do
      allow(presenter).to receive(:submission).and_return(nil)
      expect(presenter.deduction_present?).to eq(false)
    end
  end

  describe '#entered_grade' do
    it 'returns empty string when neither letter graded nor gpa scaled' do
      @assignment.update(grading_type: 'points')
      expect(presenter.entered_grade).to eq('')
    end

    it 'returns empty string when ungraded' do
      @submission.update(grade: nil)
      expect(presenter.entered_grade).to eq('')
    end

    it 'returns entered grade in parentheses' do
      @assignment.update(grading_type: 'letter_grade')
      @submission.update(grade: 'A', score: 12)

      expect(presenter.entered_grade).to eq('(A)')
    end
  end

  describe "#show_submission_details?" do
    before :each do
      @submission_stub = double()
      allow(@submission_stub).to receive(:originality_reports_for_display)
    end

    it "returns false when assignment is not an assignment" do
      @assignment = {}
      allow(@submission_stub).to receive(:can_view_details?).and_return(true)
      presenter = GradeSummaryAssignmentPresenter.new(summary, @student, @assignment, @submission_stub)
      expect(presenter.show_submission_details?).to be false
    end

    it "returns false when assignment is an assignment and user cannot view details on submission" do
      allow(@submission_stub).to receive(:can_view_details?).and_return(false)
      presenter = GradeSummaryAssignmentPresenter.new(summary, @student, @assignment, @submission_stub)
      expect(presenter.show_submission_details?).to be false
    end

    it "returns true when assignment is an assignment and use can view details on submission" do
      allow(@submission_stub).to receive(:can_view_details?).and_return(true)
      presenter = GradeSummaryAssignmentPresenter.new(summary, @student, @assignment, @submission_stub)
      expect(presenter.show_submission_details?).to be true
    end

    it "returns false when submission is nil" do
      presenter = GradeSummaryAssignmentPresenter.new(summary, @student, @assignment, nil)
      expect(presenter.show_submission_details?).to be false
    end
  end

  describe "#missing?" do
    it "returns the value of the submission method" do
      expect(@submission).to receive(:missing?).and_return('foo')
      expect(presenter.missing?).to eq('foo')
    end
  end

  describe "#late?" do
    it "returns the value of the submission method" do
      expect(@submission).to receive(:late?).and_return('foo')
      expect(presenter.late?).to eq('foo')
    end
  end

  describe "#hide_grade_from_student?" do
    it "returns true if the submission object is nil" do
      submissionless_presenter = GradeSummaryAssignmentPresenter.new(summary, @student, @assignment, nil)
      expect(submissionless_presenter).to be_hide_grade_from_student
    end

    context "when assignment posts manually" do
      before(:each) do
        @assignment.ensure_post_policy(post_manually: true)
      end

      it "returns false when the student's submission is posted" do
        @submission.update!(posted_at: Time.zone.now)
        expect(presenter).not_to be_hide_grade_from_student
      end

      it "returns true when the student's submission is not posted" do
        @submission.update!(posted_at: nil)
        expect(presenter).to be_hide_grade_from_student
      end
    end

    context "when assignment posts automatically" do
      before(:each) do
        @assignment.ensure_post_policy(post_manually: false)
      end

      it "returns false when the student's submission is posted" do
        @submission.update!(posted_at: Time.zone.now)
        expect(presenter).not_to be_hide_grade_from_student
      end

      it "returns false when the student's submission is not posted and no grade has been issued" do
        expect(presenter).not_to be_hide_grade_from_student
      end

      it "returns false when the student has submitted something but no grade is posted" do
        @assignment.update!(submission_types: "online_text_entry")
        @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "hi")
        expect(presenter).not_to be_hide_grade_from_student
      end

      it "returns true when the student's submission is graded and not posted" do
        @assignment.grade_student(@student, grader: @teacher, score: 5)
        @submission.reload
        @submission.update!(posted_at: nil)
        expect(presenter).to be_hide_grade_from_student
      end

      it "returns true when the student has resubmitted to a previously graded and subsequently hidden submission" do
        @assignment.update!(submission_types: "online_text_entry")
        @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "hi")
        @assignment.grade_student(@student, score: 0, grader: @teacher)
        @assignment.hide_submissions
        @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "I will not lose")
        @submission.reload
        expect(presenter).to be_hide_grade_from_student
      end
    end
  end
end
