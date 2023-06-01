# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe Auditors::ActiveRecord::GradeChangeRecord do
  let(:request_id) { "abcde-12345" }

  it "appropriately connected to a table" do
    expect(Auditors::ActiveRecord::GradeChangeRecord.count).to eq(0)
  end

  describe "mapping from event stream record" do
    let(:submission_record) { graded_submission_model }
    let(:es_record) { Auditors::GradeChange::Record.generate(submission_record) }
    let(:grading_period) do
      root_account = submission_record.assignment.context.root_account
      grading_period_group = root_account.grading_period_groups.create!
      now = Time.zone.now

      grading_period_group.grading_periods.create!(
        close_date: 1.week.from_now(now),
        end_date: 1.week.from_now(now),
        start_date: 1.week.ago(now),
        title: "asdf"
      )
    end

    it "is creatable from an event_stream record of the correct type" do
      submission_record.update!(grading_period:)
      ar_rec = Auditors::ActiveRecord::GradeChangeRecord.create_from_event_stream!(es_record)
      expect(ar_rec.id).to_not be_nil
      expect(ar_rec.uuid).to eq(es_record.id)
      course = submission_record.assignment.context
      expect(ar_rec.grade_after).to eq(es_record.grade_after)
      expect(ar_rec.account_id).to eq(course.account.id)
      expect(ar_rec.root_account_id).to eq(course.account.root_account.id)
      expect(ar_rec.assignment_id).to eq(submission_record.assignment_id)
      expect(ar_rec.event_type).to eq("grade_change")
      expect(ar_rec.context_id).to eq(course.id)
      expect(ar_rec.course_id).to eq(course.id)
      expect(ar_rec.context_type).to eq("Course")
      expect(ar_rec.grader_id).to eq(submission_record.grader_id)
      expect(ar_rec.grading_period_id).to eq(submission_record.grading_period_id)
      expect(ar_rec.student_id).to eq(submission_record.user_id)
      expect(ar_rec.submission_id).to eq(submission_record.id)
      expect(ar_rec.submission_version_number).to eq(submission_record.version_number)
      expect(ar_rec.version_number).to eq(submission_record.version_number)
      expect(ar_rec.created_at).to_not be_nil
      expect(ar_rec.grading_period_id).to eq(grading_period.id)
    end

    it "saves the grading period ID as null if it receives a placeholder value" do
      ar_rec = Auditors::ActiveRecord::GradeChangeRecord.create_from_event_stream!(es_record)
      expect(ar_rec.grading_period_id).to be_nil
    end

    it "is updatable from ES record" do
      ar_rec = Auditors::ActiveRecord::GradeChangeRecord.create_from_event_stream!(es_record)
      es_record.request_id = "aaa-111-bbb-222"
      Auditors::ActiveRecord::GradeChangeRecord.update_from_event_stream!(es_record)
      expect(ar_rec.reload.request_id).to eq("aaa-111-bbb-222")
    end

    describe "ID/placeholder handling" do
      let(:override_grade_change) do
        submission = submission_record

        teacher = @course.enroll_teacher(User.create!, workflow_state: "active").user
        submission.update!(grader: teacher)
        score = @course.student_enrollments.first.find_score

        Auditors::GradeChange::OverrideGradeChange.new(
          grader: teacher,
          old_grade: nil,
          old_score: nil,
          score:
        )
      end

      let(:ar_override_grade_change) do
        Auditors::GradeChange.record(override_grade_change:)
        Auditors::ActiveRecord::GradeChangeRecord.last
      end

      let(:ar_assignment_grade_change) do
        Auditors::ActiveRecord::GradeChangeRecord.create_from_event_stream!(es_record)
      end

      describe "submission ID" do
        it "is set to the relative ID if the event stream record contains a non-placeholder value" do
          relative_id = Shard.relative_id_for(es_record.submission_id, Shard.current, Shard.current)
          expect(ar_assignment_grade_change.submission_id).to eq relative_id
        end

        it "is set to null if the event stream record contains the placeholder value" do
          expect(ar_override_grade_change.submission_id).to be_nil
        end
      end

      describe "assignment ID" do
        it "is set to the relative ID if the event stream record contains a non-placeholder value" do
          relative_id = Shard.relative_id_for(es_record.assignment_id, Shard.current, Shard.current)
          expect(ar_assignment_grade_change.assignment_id).to eq relative_id
        end

        it "is set to null if the event stream record contains the placeholder value" do
          expect(ar_override_grade_change.assignment_id).to be_nil
        end
      end
    end

    describe "#in_grading_period?" do
      let(:ar_assignment_grade_change) do
        Auditors::ActiveRecord::GradeChangeRecord.create_from_event_stream!(es_record)
      end

      it "returns true if the record has a valid grading period" do
        submission_record.update!(grading_period:)
        expect(ar_assignment_grade_change).to be_in_grading_period
      end

      it "returns false if the record does not have a valid grading period" do
        expect(ar_assignment_grade_change).not_to be_in_grading_period
      end
    end
  end
end
