# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe AnonymousOrModerationEvent do
  subject { AnonymousOrModerationEvent.new(params) }

  let(:params) do
    {
      user_id: user.id,
      assignment_id: assignment.id,
      event_type: :assignment_created,
      payload: { foo: :bar }
    }
  end
  let(:course) { Course.create! }
  let(:user) { course_with_user("TeacherEnrollment", name: "Teacher", course:, active_all: true).user }
  let(:assignment) { course.assignments.create!(name: "assignment") }
  let(:quiz) { quiz_model }
  let(:external_tool) do
    Account.default.context_external_tools.create!(
      name: "Undertow",
      url: "http://www.example.com",
      consumer_key: "12345",
      shared_secret: "secret"
    )
  end

  it { is_expected.to be_valid }

  describe "relationships" do
    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:submission) }
    it { is_expected.to belong_to(:canvadoc) }
    it { is_expected.to belong_to(:quiz) }
    it { is_expected.to belong_to(:context_external_tool) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:assignment_id) }
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_inclusion_of(:event_type).in_array(AnonymousOrModerationEvent::EVENT_TYPES) }
    it { is_expected.to validate_presence_of(:payload) }

    it { expect { AnonymousOrModerationEvent.new.validate }.not_to raise_error }

    context "event ownership validations" do
      it "is valid with a user and no other owners" do
        expect(AnonymousOrModerationEvent.new(params)).to be_valid
      end

      it "is valid with a external tool and no other owners" do
        params.delete(:user_id)
        params[:context_external_tool_id] = external_tool.id
        expect(AnonymousOrModerationEvent.create!(params)).to be_valid
      end

      it "is valid with a quiz and no other owners" do
        # remove user_id from param, add quiz
        params.delete(:user_id)
        params[:quiz_id] = quiz.id
        expect(AnonymousOrModerationEvent.create!(params)).to be_valid
      end

      it "is invalid with multiple owners of user and tool" do
        params[:context_external_tool_id] = external_tool.id
        expect(AnonymousOrModerationEvent.new(params)).not_to be_valid
      end

      it "is invalid with multiple owners of user and quiz" do
        params[:quiz_id] = quiz.id
        expect { AnonymousOrModerationEvent.create!(params) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "is invalid with multiple owners of tool and quiz" do
        params.delete(:user_id)
        params[:context_external_tool_id] = external_tool.id
        params[:quiz_id] = quiz.id
        expect { AnonymousOrModerationEvent.create!(params) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "is invalid with no owners" do
        params.delete(:user_id)
        expect { AnonymousOrModerationEvent.create!(params) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "assignment_created events" do
      subject { AnonymousOrModerationEvent.new(params) }

      it { is_expected.to validate_absence_of(:canvadoc_id) }
      it { is_expected.to validate_absence_of(:submission_id) }
    end

    context "assignment_updated events" do
      subject { AnonymousOrModerationEvent.new(params.merge(event_type: :assignment_updated)) }

      it { is_expected.to validate_absence_of(:canvadoc_id) }
      it { is_expected.to validate_absence_of(:submission_id) }
    end

    context "docviewer events" do
      subject(:event) { AnonymousOrModerationEvent.new(params.merge(event_type: :docviewer_comment_created)) }

      it { is_expected.to validate_presence_of(:canvadoc_id) }
      it { is_expected.to validate_presence_of(:submission_id) }

      it "requires the payload to have an annotation body" do
        event.validate
        expect(event.errors[:payload]).to include "annotation_body can't be blank"
      end
    end

    context '"grades_posted" events' do
      subject { AnonymousOrModerationEvent.new(params.merge(event_type: :grades_posted)) }

      it { is_expected.to validate_absence_of(:canvadoc_id) }
      it { is_expected.to validate_absence_of(:submission_id) }
    end

    context '"provisional_grade_selected" events' do
      subject(:event) { AnonymousOrModerationEvent.new(params.merge(event_type: :provisional_grade_selected)) }

      it { is_expected.to validate_absence_of(:canvadoc_id) }
      it { is_expected.to validate_presence_of(:submission_id) }

      it "requires the payload to have an id" do
        event.validate
        expect(event.errors[:payload]).to include "id can't be blank"
      end

      it "requires the payload to have a student_id" do
        event.validate
        expect(event.errors[:payload]).to include "student_id can't be blank"
      end
    end
  end

  describe "#events_for_submission" do
    let(:course) { Course.create! }
    let(:teacher) { course_with_user("TeacherEnrollment", name: "Teacher", course:, active_all: true).user }
    let(:student) { course_with_user("StudentEnrollment", name: "Student", course:, active_all: true).user }
    let(:assignment) { course.assignments.create!(name: "anonymous", anonymous_grading: true, updating_user: teacher) }
    let(:submission) { assignment.submit_homework(student, body: "please give good grade") }
    let(:events) do
      AnonymousOrModerationEvent.events_for_submission(assignment_id: assignment.id, submission_id: submission.id)
    end

    before do
      submission.submission_comments.create!(author: teacher, comment: "no")
    end

    it "includes AnonymousOrModerationEvents related to assignment and submission" do
      expect(events.count).to be 2
    end

    it "includes AnonymousOrModerationEvents of event_type assignment_*" do
      assignment_events = events.select { |event| event.event_type.include?("assignment_") }
      expect(assignment_events.count).to be 1
    end

    it "includes AnonymousOrModerationEvents of event_type submission_comment_*" do
      submission_comment_events = events.select { |event| event.event_type.include?("submission_comment_") }
      expect(submission_comment_events.count).to be 1
    end

    it "does not include AnonymousOrModerationEvents not related to assignment" do
      expect do
        course.assignments.create!(name: "another assignment", anonymous_grading: true, updating_user: teacher)
      end.not_to change { events.count }
    end

    it "does not include AnonymousOrModerationEvents not related to submission" do
      second_student = course_with_user("StudentEnrollment", name: "Student", course:, active_all: true).user
      expect do
        assignment.submit_homework(second_student, body: "please give bad grade")
      end.not_to change { events.count }
    end
  end
end
