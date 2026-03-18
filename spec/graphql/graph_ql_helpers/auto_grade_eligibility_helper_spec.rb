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
      it "returns an array with grading assistance error" do
        rubric_association_model(association: assignment, rubric:, purpose: "grading", use_for_grading: true)
        assignment.reload

        allow(CedarClient).to receive(:enabled?).and_return(false)
        issues = described_class.validate_assignment(assignment:)
        expect(issues).to eq([{ level: "error", message: "Grading assistance is not available right now." }])
      end
    end

    context "when no rubric is attached" do
      it "returns an array with missing rubric error" do
        allow(CedarClient).to receive(:enabled?).and_return(true)
        issues = described_class.validate_assignment(assignment:)
        expect(issues).to eq([{ level: "error", message: "No rubric is attached to this assignment." }])
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
        it "returns an array with rating description error" do
          rubric.data[0][:ratings][0][:long_description] = nil
          rubric.save!
          assignment.reload

          expect(assignment.rubric_association).to be_present
          expect(assignment.rubric_association.rubric).to eq(rubric)

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq([{ level: "error", message: "Rubric is missing rating description." }])
        end
      end

      context "when a criterion is linked to a learning outcome" do
        it "does not return an error when long_description is blank but description is present" do
          rubric.data[0][:learning_outcome_id] = 123
          rubric.data[0][:ratings][0][:long_description] = ""
          rubric.data[0][:ratings][0][:description] = "Meets expectations"
          rubric.save!
          assignment.reload

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq([])
        end

        it "returns a rating description error when description is also blank" do
          rubric.data[0][:learning_outcome_id] = 123
          rubric.data[0][:ratings][0][:long_description] = ""
          rubric.data[0][:ratings][0][:description] = ""
          rubric.save!
          assignment.reload

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq([{ level: "error", message: "Rubric is missing rating description." }])
        end
      end

      context "when assignment description is too long" do
        it "returns an array with assignment description too long error" do
          assignment.description = "a" * 13_501
          assignment.save!
          assignment.reload

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq([{ level: "error", message: "Assignment description exceeds maximum length of 13,500 characters." }])
        end
      end

      context "when rubric category name is too long" do
        it "returns an array with rubric category name too long error" do
          rubric.data[0][:description] = "a" * 1_001
          rubric.save!
          assignment.reload

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq([{ level: "error", message: "Rubric category name exceeds maximum length of 1,000 characters." }])
        end
      end

      context "when rubric criterion description is too long" do
        it "returns an array with rubric criterion description too long error" do
          rubric.data[0][:ratings][0][:long_description] = "a" * 1_001
          rubric.save!
          assignment.reload

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq([{ level: "error", message: "Rubric criterion description exceeds maximum length of 1,000 characters." }])
        end
      end

      context "when no checks match" do
        it "returns an empty array" do
          # CedarClient is enabled (stubbed in before block),
          # rubric is attached with valid descriptions and ratings,
          # and assignment description is within the allowed length
          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq([])
        end
      end

      context "when multiple checks match" do
        it "returns all matching issues in ASSIGNMENT_CHECKS order" do
          assignment.description = "a" * 13_501
          assignment.save!
          rubric.data[0][:description] = "a" * 1_001
          rubric.save!
          assignment.reload

          issues = described_class.validate_assignment(assignment:)
          expect(issues).to eq([
                                 { level: "error", message: "Assignment description exceeds maximum length of 13,500 characters." },
                                 { level: "error", message: "Rubric category name exceeds maximum length of 1,000 characters." }
                               ])
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
      it "returns an empty array" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "This is a valid essay submission.",
          submission_type: "online_text_entry",
          attachments: []
        )
        issues = described_class.validate_submission(submission:)
        expect(issues).to eq([])
      end
    end

    context "when submission is blank" do
      it "returns only the no_submission error without running other checks" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "",
          submission_type: "online_text_entry",
          attachments: []
        )
        issues = described_class.validate_submission(submission:)
        expect(issues).to eq([{ level: "error", message: "No essay submission found." }])
      end
    end

    context "when submission has less than 5 words" do
      it "returns an array with word count error" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "Too short",
          submission_type: "online_text_entry",
          attachments: []
        )
        issues = described_class.validate_submission(submission:)
        expect(issues).to eq([{ level: "error", message: "Submission must be at least 5 words." }])
      end
    end

    context "when submission type is not text entry" do
      it "returns an array with submission type error" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "This is a valid essay submission.",
          submission_type: "online_url",
          attachments: []
        )
        issues = described_class.validate_submission(submission:)
        expect(issues).to eq([{ level: "error", message: "Submission must be a text entry type or file upload." }])
      end
    end

    context "when word count is null" do
      it "returns an array including submission must be at least 5 words" do
        submission = submission_model(
          user: @student,
          assignment: @assignment,
          body: "This is a valid-looking submission.",
          submission_type: "online_text_entry",
          attachments: []
        )
        allow(submission).to receive(:word_count).and_return(nil)
        issues = described_class.validate_submission(submission:)
        expect(issues).to eq([{ level: "error", message: "Submission must be at least 5 words." }])
      end
    end

    context "when submission contains attachments with invalid mime type" do
      it "returns an array with file type error" do
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
        expect(issues).to eq([{ level: "error", message: "Only PDF and DOCX files are supported." }])
      end

      it "returns an array with file uploads disabled error when feature flag is off" do
        Account.site_admin.disable_feature!(:grading_assistance_file_uploads)
        submission = submission_model(
          user: @student,
          assignment:,
          submission_type: "online_upload",
          attachments: []
        )

        valid_attachment = instance_double(Attachment, mimetype: "application/pdf")
        allow(submission).to receive_messages(attachments: [valid_attachment], extract_text_from_upload?: true, attachment_contains_images: false, word_count: 50, extracted_text: "short text")

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq([{ level: "error", message: "Grading assistance is disabled for file uploads." }])
      end
    end

    context "when submission is an upload with no attachments" do
      it "returns only the no_submission error" do
        submission = submission_model(
          user: @student,
          assignment:,
          submission_type: "online_upload",
          attachments: []
        )

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq([{ level: "error", message: "No essay submission found." }])
      end
    end

    context "when attempt is less than 1" do
      it "returns only the no_submission error" do
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
        expect(issues).to eq([{ level: "error", message: "No essay submission found." }])
      end
    end

    context "when submission is an upload with no cached extracted text" do
      it "returns an empty array (no issues)" do
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

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq([])
      end
    end

    context "when essay text is too long for text entry" do
      it "returns an array with essay too long error" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "a b c d e " + ("a" * 13_495),
          submission_type: "online_text_entry",
          attachments: []
        )

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq([{ level: "error", message: "Submission text exceeds maximum length of 13,500 characters." }])
      end
    end

    context "when multiple submission checks match" do
      it "returns all matching issues in SUBMISSION_CHECKS order" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "a b c d e " + ("a" * 13_495),
          submission_type: "online_text_entry",
          attachments: []
        )
        allow(submission).to receive(:word_count).and_return(nil)

        issues = described_class.validate_submission(submission:)
        expect(issues).to eq([
                               { level: "error", message: "Submission must be at least 5 words." },
                               { level: "error", message: "Submission text exceeds maximum length of 13,500 characters." }
                             ])
      end
    end

    context "when essay text is too long for file upload" do
      it "returns an array with essay too long error" do
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
        expect(issues).to eq([{ level: "error", message: "Submission text exceeds maximum length of 13,500 characters." }])
      end
    end
  end
end
