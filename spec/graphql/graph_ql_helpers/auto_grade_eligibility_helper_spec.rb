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
        expect(issues).to include("Grading Assistance is not available right now.")
      end
    end

    context "when no rubric is attached" do
      it "returns a missing rubric error" do
        allow(CedarClient).to receive(:enabled?).and_return(true)
        issues = described_class.validate_assignment(assignment:)
        expect(issues).to include("No rubric is attached to this assignment.")
      end
    end

    context "when a rating is missing long_description" do
      it "returns a rating description error" do
        rubric.data[0][:ratings][0][:long_description] = nil
        rubric.save!

        ra = rubric_association_model(
          association: assignment,
          rubric:,
          purpose: "grading",
          use_for_grading: true
        )
        ra.save!
        assignment.reload

        allow(CedarClient).to receive(:enabled?).and_return(true)
        expect(assignment.rubric_association).to be_present
        expect(assignment.rubric_association.rubric).to eq(rubric)

        issues = described_class.validate_assignment(assignment:)
        expect(issues).to include("Rubric is missing rating description.")
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
        expect(issues).to be_empty
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
        expect(issues).to include("No essay submission found.")
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
        issues = described_class.validate_submission(submission:)
        expect(issues).to include("Submission must be at least 5 words.")
      end
    end

    context "when submission type is not text entry" do
      it "returns submission type error" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "This is a valid essay submission.",
          submission_type: "online_upload",
          attachments: []
        )
        issues = described_class.validate_submission(submission:)
        expect(issues).to include("Submission must be a text entry type.")
      end
    end

    context "when word count is null" do
      it "returns missing submission error like this" do
        submission = submission_model(
          user: @student,
          assignment: @assignment,
          body: "This is a valid-looking submission.",
          submission_type: "online_text_entry",
          attachments: []
        )
        allow(submission).to receive(:word_count).and_return(nil)
        issues = described_class.validate_submission(submission:)
        expect(issues).to include("No essay submission found.")
      end
    end

    context "when submission contains attachments" do
      it "returns attachment error" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "This is a valid essay.",
          submission_type: "online_text_entry",
          attachments: []
        )

        fake_attachment = double("Attachment", id: 123, context: assignment, recently_created?: true)
        allow(submission).to receive(:attachments).and_return([fake_attachment])

        issues = described_class.validate_submission(submission:)
        expect(issues).to include("Submission contains file attachments.")
      end
    end

    context "when submission has multiple issues" do
      it "returns all applicable issues" do
        submission = submission_model(
          user: @student,
          assignment:,
          body: "",
          submission_type: "online_upload",
          attachments: []
        )

        fake_attachment = double("Attachment", id: 123, context: assignment, recently_created?: true)
        allow(submission).to receive_messages(word_count: nil, attachments: [fake_attachment])

        issues = described_class.validate_submission(submission:)

        expect(issues).to include("Submission must be a text entry type.")
        expect(issues).to include("Submission contains file attachments.")
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
        expect(issues).to include("No essay submission found.")
      end
    end

    context "when submission body contains an RCE file link" do
      it "returns true" do
        html_body = '<p><a class="instructure_file_link" data-api-returntype="File" href="/files/123">file.txt</a></p>'

        result = GraphQLHelpers::AutoGradeEligibilityHelper.contains_rce_file_link?(html_body)

        expect(result).to be true
      end
    end

    context "when submission body does not contain an RCE file link" do
      it "returns false" do
        html_body = '<p><a href="/files/123">file.txt</a></p>'

        result = GraphQLHelpers::AutoGradeEligibilityHelper.contains_rce_file_link?(html_body)

        expect(result).to be false
      end
    end

    context "when submission body is blank" do
      it "returns false" do
        result = GraphQLHelpers::AutoGradeEligibilityHelper.contains_rce_file_link?("")

        expect(result).to be false
      end
    end
  end
end
