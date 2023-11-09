# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
require_relative "../../spec_helper"

describe Submission::ShowPresenter do
  include Rails.application.routes.url_helpers

  let(:course) { Course.create! }
  let(:assignment) do
    course.assignments.create!(
      anonymous_peer_reviews: true,
      peer_reviews: true,
      title: "hi"
    )
  end

  let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
  let(:reviewer) { course.enroll_student(User.create!, active_all: true).user }
  let(:reviewee) { course.enroll_student(User.create!, active_all: true).user }
  let(:reviewer_submission) { assignment.submission_for_student(reviewer) }
  let(:reviewee_submission) { assignment.submission_for_student(reviewee) }
  let(:assessment_request) { reviewee_submission.assign_assessor(reviewer_submission) }

  let(:presenter_for_teacher) { Submission::ShowPresenter.new(submission: reviewee_submission, current_user: teacher) }
  let(:presenter_for_reviewer) do
    Submission::ShowPresenter.new(
      submission: reviewee_submission,
      current_user: reviewer,
      assessment_request:
    )
  end

  let(:submission_path) { course_assignment_submission_path(course, assignment, reviewee_submission.user_id) }
  let(:anonymous_submission_path) do
    course_assignment_anonymous_submission_path(course, assignment, reviewee_submission.anonymous_id)
  end

  describe "#anonymize_submission_owner?" do
    context "when an assessment request is present" do
      it "returns true if anonymous peer reviews are enabled" do
        expect(presenter_for_reviewer).to be_anonymize_submission_owner
      end

      it "returns false if anonymous peer reviews are not enabled" do
        assignment.update!(anonymous_peer_reviews: false)
        expect(presenter_for_reviewer).not_to be_anonymize_submission_owner
      end
    end

    it "returns false if no assessment request is present" do
      presenter = Submission::ShowPresenter.new(submission: reviewee_submission, current_user: reviewer)
      expect(presenter).not_to be_anonymize_submission_owner
    end
  end

  describe "#add_comment_url" do
    it "returns a gradebook-based update URL if the viewer is a grader" do
      expect(presenter_for_teacher.add_comment_url).to match_path(update_submission_course_gradebook_path(course))
    end

    it "returns an anonymized submission URL if the viewer is not a grader and the submitter is anonymized" do
      expect(presenter_for_reviewer.add_comment_url).to match_path(anonymous_submission_path)
    end

    it "returns a non-anonymized submission URL if the submitter is not anonymized" do
      assignment.update!(anonymous_peer_reviews: false)
      expect(presenter_for_reviewer.add_comment_url).to match_path(submission_path)
    end
  end

  describe "#add_comment_method" do
    it "returns 'POST' if the viewing user is a grader" do
      expect(presenter_for_teacher.add_comment_method).to eq "POST"
    end

    it "returns 'PUT' if the viewing user is not a grader" do
      expect(presenter_for_reviewer.add_comment_method).to eq "PUT"
    end
  end

  describe "#submission_data_url" do
    it "returns an anonymized submission URL if the submitter is anonymized" do
      expect(presenter_for_reviewer.submission_data_url).to match_path(anonymous_submission_path)
    end

    it "returns a non-anonymized submission URL if the submitter is not anonymized" do
      assignment.update!(anonymous_peer_reviews: false)
      expect(presenter_for_reviewer.submission_data_url).to match_path(submission_path)
    end

    it "returns any additional parameters as part of the URL" do
      expect(presenter_for_reviewer.submission_data_url(another_param: "z")).to match_path(anonymous_submission_path)
        .and_query({ "another_param" => "z" })
    end
  end

  describe "#submission_preview_frame_url" do
    it "calls submission_data_url with 'preview' and 'rand' parameters" do
      expect(presenter_for_reviewer).to receive(:submission_data_url).with(hash_including(preview: 1, rand: instance_of(Integer)))
      presenter_for_reviewer.submission_preview_frame_url
    end
  end

  describe "#submission_details_tool_launch_url" do
    subject do
      presenter_for_reviewer.submission_details_tool_launch_url
    end

    let(:resource_link_lookup_uuid) { SecureRandom.uuid }
    let(:parameters) do
      {
        assignment_id: assignment.id,
        display: "borderless",
        url: reviewee_submission.external_tool_url,
        resource_link_lookup_uuid:
      }
    end
    let(:launch_params) do
      "assignment_id=#{assignment.id}&display=borderless&resource_link_lookup_uuid=#{resource_link_lookup_uuid}"
    end

    before do
      reviewee_submission.resource_link_lookup_uuid = resource_link_lookup_uuid
    end

    context "when `current_host` is not given" do
      it "return the tool launch url using the host from the domain config file (config/domain.yml)" do
        expect(subject).to eq "http://localhost/courses/#{course.id}/external_tools/retrieve?#{launch_params}"
      end
    end

    context "when `current_host` is given" do
      let(:current_host) { "edu.com" }
      let(:presenter_for_reviewer) do
        Submission::ShowPresenter.new(
          submission: reviewee_submission,
          current_user: reviewer,
          assessment_request:,
          current_host:
        )
      end

      before do
        allow(HostUrl).to receive(:context_host).and_return(current_host)
      end

      it "return the tool launch url using the host from the `current_host`" do
        expect(subject).to eq "http://edu.com/courses/#{course.id}/external_tools/retrieve?#{launch_params}"
      end
    end
  end

  describe "#comment_attachment_download_url" do
    it "calls submission_data_url with parameters from the passed-in comment and attachment" do
      attachment = Attachment.create!(
        context: reviewer,
        filename: "a_file.txt",
        uploaded_data: StringIO.new("hi"),
        user: reviewer
      )
      submission_comment = reviewee_submission.add_comment(author: reviewer, comment: "ok I guess")

      expect(presenter_for_reviewer).to receive(:submission_data_url)
        .with(hash_including(comment_id: submission_comment.id, download: attachment.id))
      presenter_for_reviewer.comment_attachment_download_url(submission_comment:, attachment:)
    end
  end

  describe "#comment_attachment_template_url" do
    it "calls submission_data_url with template-style parameters" do
      expect(presenter_for_reviewer).to receive(:submission_data_url)
        .with(hash_including(comment_id: "{{ comment_id }}", download: "{{ id }}"))

      presenter_for_reviewer.comment_attachment_template_url
    end
  end

  describe "#currently_peer_reviewing?" do
    it "returns true if an assessment request is present and in the 'assigned' state" do
      expect(presenter_for_reviewer).to be_currently_peer_reviewing
    end

    it "returns false if an assessment request is present and in a non-assigned state" do
      assessment_request.complete!
      expect(presenter_for_teacher).not_to be_currently_peer_reviewing
    end

    it "returns false if no assessment request is present" do
      expect(presenter_for_teacher).not_to be_currently_peer_reviewing
    end
  end

  describe "#default_url_options" do
    subject { presenter.default_url_options }

    let(:current_host) { nil }
    let(:presenter) do
      Submission::ShowPresenter.new(
        submission: reviewee_submission,
        current_user: teacher,
        current_host:
      )
    end

    context "when `current_host` is not given" do
      it "return the `host` from the domain config file (config/domain.yml)" do
        expect(subject[:host]).to eq "localhost"
        expect(subject[:protocol]).to eq "http"
      end
    end

    context "when `current_host` is given" do
      let(:current_host) { "edu.com" }

      before do
        allow(HostUrl).to receive(:context_host).and_return(current_host)
      end

      it "return the current host and protocol" do
        expect(subject[:host]).to eq current_host
        expect(subject[:protocol]).to eq "http"
      end
    end
  end

  describe "#entered_grade" do
    before do
      @teacher = course.enroll_teacher(User.create!, active_all: true).user
      @student = course.enroll_student(User.create!, active_all: true).user
      @assignment = course.assignments.create!(points_possible: 10, grading_type: "points")
    end

    let(:en_dash) { "-" }
    let(:minus) { "−" }
    let(:presenter) do
      Submission::ShowPresenter.new(submission: @assignment.submissions.find_by(user: @student), current_user: @student)
    end

    it "returns the entered grade" do
      @assignment.grade_student(@student, grader: @teacher, grade: "8")
      expect(presenter.entered_grade).to eq "8"
    end

    it "returns a letter grade with trailing en-dash replaced with minus if 'Restrict Quantitative Data' is enabled" do
      course.root_account.enable_feature!(:restrict_quantitative_data)
      course.update!(restrict_quantitative_data: true)
      @assignment.grade_student(@student, grader: @teacher, grade: "8")
      expect(presenter.entered_grade).to eq "B#{minus}"
    end

    it "returns complete/incomplete if the assignment type is pass/fail with 'Restrict Quantitative Data' enabled" do
      course.root_account.enable_feature!(:restrict_quantitative_data)
      course.update!(restrict_quantitative_data: true)
      @assignment.update!(grading_type: "pass_fail")
      @assignment.grade_student(@student, grader: @teacher, grade: "complete")
      expect(presenter.entered_grade).to eq "complete"
    end

    it "returns a letter grade with trailing en-dash replaced with minus if the assignment type is letter grade" do
      @assignment.update!(grading_type: "letter_grade")
      @assignment.grade_student(@student, grader: @teacher, grade: "B#{en_dash}")
      expect(presenter.entered_grade).to eq "B#{minus}"
    end
  end
end
