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
  let(:course) { Course.create! }
  let(:teacher) { course_with_user("TeacherEnrollment", name: "Teacher", course:, active_all: true).user }

  describe "validations" do
    subject { AnonymousOrModerationEvent.new(params) }

    let(:params) do
      {
        user_id: teacher.id,
        assignment_id: assignment.id,
        event_type: :assignment_created,
        payload: { foo: :bar }
      }
    end
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

    context "docviewer events" do
      subject(:event) { AnonymousOrModerationEvent.new(params.merge(event_type: :docviewer_comment_created)) }

      it "requires the payload to have an annotation body" do
        event.validate
        expect(event.errors[:payload]).to include "annotation_body can't be blank"
      end
    end

    context '"provisional_grade_selected" events' do
      subject(:event) { AnonymousOrModerationEvent.new(params.merge(event_type: :provisional_grade_selected)) }

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

  describe "#events_for" do
    let(:student_1) { course_with_user("StudentEnrollment", name: "Student 1", course:, active_all: true).user }
    let(:student_2) { course_with_user("StudentEnrollment", name: "Student 2", course:, active_all: true).user }

    let(:assignment_1) { course.assignments.create!(name: "anonymous", anonymous_grading: true, updating_user: teacher) }
    let(:submission_1_1) { assignment_1.submit_homework(student_1, body: "Submission for Assignment 1 by Student 1") }
    let(:submission_1_2) { assignment_1.submit_homework(student_2, body: "Submission for Assignment 1 by Student 2") }

    let(:assignment_2) { course.assignments.create!(name: "anonymous2", anonymous_grading: true, updating_user: teacher) }
    let(:submission_2_1) { assignment_2.submit_homework(student_1, body: "Submission for Assignment 2 by Student 1") }

    before do
      submission_1_1.submission_comments.create!(author: teacher, comment: "no")
      submission_1_2.submission_comments.create!(author: teacher, comment: "no")
      submission_2_1.submission_comments.create!(author: teacher, comment: "no")
    end

    describe "submission" do
      let(:events) do
        AnonymousOrModerationEvent.events_for_submission(assignment_id: assignment_1.id, submission_id: submission_1_1.id)
      end

      it "returns events ordered by created_at ASC" do
        expect(events[0].created_at).to be < events[1].created_at
      end

      it "includes AnonymousOrModerationEvents related to assignment [1] and submission [1]" do
        expect(events.count).to be 2
      end

      it "calls events_for_submissions with the correct parameters" do
        allow(AnonymousOrModerationEvent).to receive(:events_for_submissions).and_call_original
        AnonymousOrModerationEvent
          .events_for_submission(assignment_id: 1, submission_id: 2)

        expect(AnonymousOrModerationEvent).to have_received(:events_for_submissions)
          .with([{ assignment_id: 1, submission_id: 2 }])
      end
    end

    describe "submissions" do
      let(:events) do
        ids = [{ assignment_id: assignment_1.id, submission_id: submission_1_1.id },
               { assignment_id: assignment_1.id, submission_id: submission_1_2.id },
               { assignment_id: assignment_2.id, submission_id: submission_2_1.id }]
        AnonymousOrModerationEvent.events_for_submissions(ids)
      end

      it "returns events ordered by created_at ASC" do
        expect(events[0].created_at).to be < events[1].created_at
      end

      it "includes AnonymousOrModerationEvents related to assignment [1, 2] and submission [1, 2]" do
        expect(events.count).to be 5
      end

      it "includes AnonymousOrModerationEvents of event_type assignment_*" do
        assignment_events = events.select { |event| event.event_type.include?("assignment_") }
        expect(assignment_events.count).to be 2
      end

      it "includes AnonymousOrModerationEvents of event_type submission_comment_*" do
        submission_comment_events = events.select { |event| event.event_type.include?("submission_comment_") }
        expect(submission_comment_events.count).to be 3
      end

      it "does not include AnonymousOrModerationEvents not related to assignment" do
        expect do
          course.assignments.create!(name: "another assignment", anonymous_grading: true, updating_user: teacher)
        end.not_to change { events.count }
      end

      it "does not include AnonymousOrModerationEvents not related to submission" do
        second_student = course_with_user("StudentEnrollment", name: "Student", course:, active_all: true).user
        expect do
          assignment_1.submit_homework(second_student, body: "please give bad grade")
        end.not_to change { events.count }
      end
    end
  end
end
