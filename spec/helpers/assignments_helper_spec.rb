# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe AssignmentsHelper do
  include TextHelper
  include AssignmentsHelper

  describe "#assignment_publishing_enabled?" do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      assignment_model(course: @course)
    end

    it "is false if the user cannot update the assignment" do
      expect(assignment_publishing_enabled?(@assignment, @student)).to be_falsey
    end

    it "is true if the assignment already has submissions and is unpublished" do
      @assignment.submissions.find_by!(user_id: @student).update!(submission_type: "online_url")
      expect(assignment_publishing_enabled?(@assignment, @teacher)).to be_truthy
    end

    it "is true otherwise" do
      expect(assignment_publishing_enabled?(@assignment, @teacher)).to be_truthy
    end
  end

  describe "#due_at" do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @due_date = 1.month.from_now
      assignment_model(course: @course, due_at: @due_date)
    end

    it "renders due date" do
      expect(due_at(@assignment, @teacher)).to eq datetime_string(@due_date)
    end

    it "renders no due date when none present" do
      @assignment.due_at = nil
      expect(due_at(@assignment, @teacher)).to eq "No Due Date"
    end

    context "with multiple due dates" do
      before(:once) do
        @section = @course.course_sections.create!(name: "test section")
        student_in_section(@section, user: @student)
        @section_due_date = 2.months.from_now
        create_section_override_for_assignment(@assignment, course_section: @section, due_at: @section_due_date)
      end

      it "renders multiple dates" do
        expect(due_at(@assignment, @teacher)).to eq "Multiple Due Dates"
      end

      it "renders override date when it applies to all assignees" do
        @assignment.only_visible_to_overrides = true
        expect(due_at(@assignment, @teacher)).to eq datetime_string(@section_due_date)
      end

      it "renders applicable date to student" do
        expect(due_at(@assignment, @student)).to eq datetime_string(@section_due_date)
      end
    end
  end

  describe "#turnitin active?" do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      assignment_model(course: @course)
      @assignment.turnitin_enabled = true
      @assignment.update!({
                            submission_types: ["online_url"]
                          })
      @context = @assignment.context
      account = @context.account
      account.turnitin_account_id = 12_345
      account.turnitin_shared_secret = "the same combination on my luggage"
      account.settings[:enable_turnitin] = true
      account.save!
    end

    it "returns true if turnitin is active on the assignment and account" do
      expect(turnitin_active?).to be_truthy
    end

    it "returns false if the assignment does not require submissions" do
      @assignment.update!({
                            submission_types: ["none"]
                          })
      expect(turnitin_active?).to be_falsey
    end

    it "returns false if turnitin is disabled on the account level" do
      @context.account.update!({
                                 turnitin_account_id: nil,
                                 turnitin_shared_secret: nil
                               })
      expect(turnitin_active?).to be_falsey
    end
  end

  describe "#assignment_submission_button" do
    before do
      student_in_course
      assignment_model(course: @course)
      @assignment.update_attribute(:submission_types, "online_upload")
      allow(self).to receive(:can_do).and_return true
    end

    let(:submission) { @assignment.submissions.find_by!(user_id: @student) }

    it "returns a hidden button when passed true for hidden" do
      button = assignment_submission_button(@assignment, @student, submission, true)
      hidden_regex = /display: none/
      expect(hidden_regex.match?(button)).to be true
    end

    it "returns a visible button when passed false for hidden" do
      button = assignment_submission_button(@assignment, @student, submission, false)
      hidden_regex = /display: none/
      expect(hidden_regex.match?(button)).to be false
    end

    context "the submission has 0 attempts left" do
      it "returns a disabled button" do
        @assignment.update_attribute(:allowed_attempts, 2)
        submission.update_attribute(:attempt, 2)
        button = assignment_submission_button(@assignment, @student, submission, false)
        expect(button["disabled"]).to eq("disabled")
      end
    end

    context "the submission has > 0 attempts left" do
      it "returns an enabled button" do
        @assignment.update_attribute(:allowed_attempts, 2)
        submission.update_attribute(:attempt, 1)
        button = assignment_submission_button(@assignment, @student, submission, false)
        expect(button["disabled"]).to be_nil
      end
    end

    context "the submission has unlimited attempts" do
      it "returns an enabled button" do
        @assignment.update_attribute(:allowed_attempts, -1)
        submission = @assignment.submissions.find_by!(user_id: @student)
        submission.update_attribute(:attempt, 3)
        button = assignment_submission_button(@assignment, @student, submission, false)
        expect(button["disabled"]).to be_nil
      end
    end
  end

  describe "#i18n_grade" do
    it "returns nil when passed a nil grade and a grading_type of pass_fail" do
      expect(i18n_grade(nil, "pass_fail")).to be_nil
    end

    it "returns a grade with trailing en-dash replaced with minus when grading_type is letter_grade" do
      en_dash = "-"
      minus = "−"
      expect(i18n_grade("B#{en_dash}", "letter_grade")).to eq "B#{minus}"
    end
  end

  describe "#student_peer_review_link_for" do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create(peer_reviews: true, title: "hi") }
    let(:reviewer) { course.enroll_student(User.create!, active_all: true).user }
    let(:reviewee) { course.enroll_student(User.create!, active_all: true).user }
    let(:assessment) { assignment.submission_for_student(reviewer).assigned_assessments.first }

    before do
      assignment.assign_peer_review(reviewer, reviewee)

      # Avoid having to go down a rabbit hole of imports
      allow(self).to receive_messages(submission_author_name_for: "Nobody", link_to: "")
    end

    it "creates a URL containing the peer reviewee's user ID when peer reviewing is not anonymous" do
      allow(self).to receive(:submission_author_name_for).and_return("Nobody")
      expect(self).to receive(:context_url).with(course, :context_assignment_submission_url, assignment.id, assessment.asset.user_id)

      student_peer_review_link_for(course, assignment, assessment)
    end

    it "creates a URL containing the peer reviewee's anonymous ID when peer reviewing is anonymous" do
      assignment.update!(anonymous_peer_reviews: true)

      expect(self).to receive(:context_url).with(course, :context_assignment_anonymous_submission_url, assignment.id, assessment.asset.anonymous_id)

      student_peer_review_link_for(course, assignment, assessment)
    end
  end

  describe "#student_peer_review_url_in_a2_for" do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create(peer_reviews: true, title: "hi") }
    let(:reviewer) { course.enroll_student(User.create!, active_all: true).user }
    let(:reviewee) { course.enroll_student(User.create!, active_all: true).user }
    let(:assessment) { assignment.submission_for_student(reviewer).assigned_assessments.first }

    before do
      assignment.assign_peer_review(reviewer, reviewee)
    end

    it "creates a URL containing the peer reviewee's user ID as reviewee_id when peer reviewing is not anonymous" do
      expect(self).to receive(:context_url).and_return("")
      student_peer_review_url_in_a2_for(course, assignment, assessment)
    end

    it "creates a URL containing the peer reviewee's anonymous ID as anonymous_asset_id when peer reviewing is anonymous" do
      assignment.update!(anonymous_peer_reviews: true)
      expect(self).to receive(:context_url).and_return("")
      student_peer_review_url_in_a2_for(course, assignment, assessment)
    end
  end
end
