# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe GraphQLHelpers::AutoGradeEligibilityHelper do
  before :once do
    course_with_teacher(active_all: true)
    @student = student_in_course(course: @course).user
  end

  describe ".validate_assignment" do
    let!(:assignment) { assignment_model(course: @course) }

    let!(:rubric) do
      rubric_model(
        context: @course,
        data: [
          {
            points: 5,
            description: "Criterion 1",
            long_description: "Criterion 1 description",
            ratings: [
              {
                points: 5,
                description: "Excellent",
                long_description: "Excellent performance"
              }
            ]
          }
        ]
      )
    end

    context "when CedarClient is disabled" do
      it "returns a grading assistance error" do
        rubric_association_model(association: assignment, rubric:)
        assignment.reload

        allow(CedarClient).to receive(:enabled?).and_return(false)
        issues = described_class.validate_assignment(assignment:)
        expect(issues).to eq({ level: "error", message: "Grading assistance is not available right now." })
      end
    end

    context "when no rubric is attached" do
      it "returns a missing rubric error" do
        allow(CedarClient).to receive(:enabled?).and_return(true)
        issues = described_class.validate_assignment(assignment:)
        expect(issues).to eq({ level: "error", message: "No rubric is attached to this assignment." })
      end
    end

    context "with rubric" do
      before do
        ra = rubric_association_model(
          association: assignment,
          rubric:,
          purpose: "grading",
          use_for_grading: true
        )
        ra.save!
        assignment.reload
        allow(CedarClient).to receive(:enabled?).and_return(true)
      end

      context "when a rating is missing long_description" do
        it "returns a rating description error" do
          rubric.data[0][:ratings][0][:long_description] = nil
          rubric.save!
          assignment.reload

          expect(assignment.rubric_association).to be_present
          expect(assignment.rubric_association.rubric).to eq(rubric)

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq({ level: "error", message: "Rubric is missing rating description." })
        end
      end

      context "when assignment description is too long" do
        it "returns assignment description too long error" do
          assignment.description = "a" * 13_501
          assignment.save!
          assignment.reload

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq({ level: "error", message: "Assignment description exceeds maximum length of 13,500 characters." })
        end
      end

      context "when rubric category name is too long" do
        it "returns rubric category name too long error" do
          rubric.data[0][:description] = "a" * 1_001
          rubric.save!
          assignment.reload

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq({ level: "error", message: "Rubric category name exceeds maximum length of 1,000 characters." })
        end
      end

      context "when rubric criterion description is too long" do
        it "returns rubric criterion description too long error" do
          rubric.data[0][:ratings][0][:long_description] = "a" * 1_001
          rubric.save!
          assignment.reload

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq({ level: "error", message: "Rubric criterion description exceeds maximum length of 1,000 characters." })
        end
      end
    end
  end

  describe ".validate_submission" do
    let!(:assignment) do
      rubric = rubric_model(context: @course)
      assignment = assignment_model(course: @course)
      rubric_association_model(association: assignment, rubric:)
      assignment
    end

    context "with a valid submission" do
      it "returns no issues" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "This is a valid essay submission.",
          submission_type: "online_text_entry",
          attachments: []
        )
        issues = described_class.validate_submission(submission:)
        expect(issues).to be_nil
      end
    end

    context "when submission is blank" do
      it "returns missing submission error" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "",
          submission_type: "online_text_entry",
          attachments: []
        )
        issues = described_class.validate_submission(submission:)
        expect(issues).to eq({ level: "error", message: "No essay submission found." })
      end
    end

    context "when submission has less than 5 words" do
      it "returns word count error" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "Too short",
          submission_type: "online_text_entry",
          attachments: []
        )
        allow(submission).to receive(:word_count).and_return(nil)
        issues = described_class.validate_submission(submission:)
        expect(issues).to eq({ level: "error", message: "Submission must be at least 5 words." })
      end
    end

    context "when submission type is not text entry" do
      it "returns submission type error" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "This is a valid essay submission.",
          submission_type: "online_url",
          attachments: []
        )
        issues = described_class.validate_submission(submission:)
        expect(issues).to eq({ level: "error", message: "Submission must be a text entry type or file upload." })
      end
    end

    context "when word count is null" do
      it "returns submission must be at least 5 words." do
        submission = submission_model(
          user: @student,
          assignment: @assignment,
          body: "This is a valid-looking submission.",
          submission_type: "online_text_entry",
          attachments: []
        )
        allow(submission).to receive(:word_count).and_return(nil)
        issues = described_class.validate_submission(submission:)
        expect(issues).to eq({ level: "error", message: "Submission must be at least 5 words." })
      end
    end

    context "when submission contains attachments with invalid mime type" do
      it "returns file type error" do
        Account.site_admin.enable_feature!(:grading_assistance_file_uploads)
        submission = submission_model(
          user: @student,
          assignment:,
          submission_type: "online_upload",
          attachments: []
        )

        bad_attachment = instance_double(Attachment, mimetype: "text/plain")
        allow(submission).to receive_messages(attachments: [bad_attachment], extract_text_from_upload?: true, attachment_contains_images: false, word_count: 50)

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq({ level: "error", message: "Only PDF and DOCX files are supported." })
      end

      it "returns file uploads disabled error when feature flag is off" do
        Account.site_admin.disable_feature!(:grading_assistance_file_uploads)
        submission = submission_model(
          user: @student,
          assignment:,
          submission_type: "online_upload",
          attachments: []
        )

        bad_attachment = instance_double(Attachment, mimetype: "text/plain")
        allow(submission).to receive_messages(attachments: [bad_attachment], extract_text_from_upload?: true, attachment_contains_images: false, word_count: 50)

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq({ level: "error", message: "Grading assistance is disabled for file uploads." })
      end
    end

    context "when submission contains PDF attachments images" do
      it "returns there are images embedded in the file that can not be parsed" do
        Account.site_admin.enable_feature!(:grading_assistance_file_uploads)
        submission = submission_model(
          user: @student,
          assignment:,
          submission_type: "online_upload",
          attachments: []
        )

        bad_attachment = instance_double(Attachment, mimetype: "application/pdf")
        allow(submission).to receive_messages(attachments: [bad_attachment], extract_text_from_upload?: true, attachment_contains_images: true, word_count: 50)
        allow(submission).to receive(:read_extracted_text).and_return({ contains_images: true })

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq({ level: "warning", message: "Please note that AI Grading Assistance for this submission will ignore any embedded images and only evaluate the text portion of the submission." })
      end
    end

    context "when attempt is less than 1" do
      it "returns missing submission error" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "This is a valid essay.",
          submission_type: "online_text_entry",
          attachments: [],
          attempt: 0
        )

        allow(submission).to receive(:attempt).and_return(0)

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq({ level: "error", message: "No essay submission found." })
      end
    end

    context "when submission is an upload with no cached extracted text" do
      it "does not return the images warning (no issues)" do
        Account.site_admin.enable_feature!(:grading_assistance_file_uploads)

        submission = submission_model(
          user: @student,
          assignment:,
          body: "This is a valid essay.",
          submission_type: "online_text_entry",
          attachments: []
        )

        attachment = instance_double(Attachment, mimetype: "application/pdf")
        allow(submission).to receive_messages(
          attachments: [attachment],
          extract_text_from_upload?: true,
          extracted_text: ""
        )

        allow(submission).to receive(:read_extracted_text).and_return({ text: "", contains_images: false })

        issues = described_class.validate_submission(submission:)
        expect(issues).to be_nil
      end
    end

    context "when submission is an upload with cached extracted text indicating images" do
      it "returns a warning about embedded images" do
        Account.site_admin.enable_feature!(:grading_assistance_file_uploads)

        submission = submission_model(
          user: @student,
          assignment:,
          submission_type: "online_upload",
          attachments: []
        )

        attachment = instance_double(Attachment, mimetype: "application/pdf")
        allow(submission).to receive_messages(
          attachments: [attachment],
          extract_text_from_upload?: true
        )

        allow(submission).to receive(:read_extracted_text).and_return({ text: "Some text", contains_images: true })

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq(
          {
            level: "warning",
            message: "Please note that AI Grading Assistance for this submission will ignore any embedded images and only evaluate the text portion of the submission."
          }
        )
      end
    end

    context "when essay text is too long for text entry" do
      it "returns essay too long error" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "a b c d e " + ("a" * 13_495),
          submission_type: "online_text_entry",
          attachments: []
        )

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq({ level: "error", message: "Submission text exceeds maximum length of 13,500 characters." })
      end
    end

    context "when essay text is too long for file upload" do
      it "returns essay too long error" do
        Account.site_admin.enable_feature!(:grading_assistance_file_uploads)

        submission = submission_model(
          user: @student,
          assignment:,
          submission_type: "online_upload",
          attachments: []
        )

        attachment = instance_double(Attachment, mimetype: "application/pdf")
        allow(submission).to receive_messages(
          attachments: [attachment],
          extract_text_from_upload?: true,
          word_count: 10_000,
          extracted_text: "a" * 13_501
        )

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq({ level: "error", message: "Submission text exceeds maximum length of 13,500 characters." })
      end
    end
  end
end
