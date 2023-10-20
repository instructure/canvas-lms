# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Auditors::GradeChange do
  before(:all) do
    Auditors::ActiveRecord::Partitioner.process
  end

  let(:request_id) { 42 }

  before do
    allow(RequestContextGenerator).to receive_messages(request_id:)

    shard_class = Class.new do
      define_method(:activate) { |&b| b.call }
    end

    EventStream.current_shard_lookup = lambda do
      shard_class.new
    end

    @account = Account.default
    @sub_account = Account.create!(parent_account: @account)
    @sub_sub_account = Account.create!(parent_account: @sub_account)

    course_with_teacher(account: @sub_sub_account, active_all: true)
    student_in_course(active_all: true)

    @assignment = @course.assignments.create!(title: "Assignment", points_possible: 10)
    @submission = @assignment.grade_student(@student, grade: 8, grader: @teacher).first
    @event_time = Time.zone.at(1.hour.ago.to_i)
  end

  let(:override_grade_change) do
    Auditors::GradeChange::OverrideGradeChange.new(
      grader: @teacher,
      old_grade: nil,
      old_score: nil,
      score: @student.enrollments.first.find_score
    )
  end

  def course_grade_changes(course)
    Auditors::GradeChange.for_course(course).paginate(per_page: 10)
  end

  it "inserts submission grade change records" do
    expect(Auditors::GradeChange::Stream).to receive(:insert).once
    Auditors::GradeChange.record(submission: @submission)
  end

  it "inserts override grade change records" do
    expect(Auditors::GradeChange::Stream).to receive(:insert).once
    Auditors::GradeChange.record(override_grade_change:)
  end

  it "does not accept both a submission and an override in the same call" do
    expect do
      Auditors::GradeChange.record(submission: @submission, override_grade_change:)
    end.to raise_error(ArgumentError)
  end

  it "returns submission grade changes in results" do
    expect(course_grade_changes(@course).length).to eq 1
    Auditors::GradeChange.record(submission: @submission)
    aggregate_failures do
      cgc = course_grade_changes(@course)
      expect(cgc.length).to eq 2
      expect(cgc.last.submission_id).to eq @submission.id
    end
  end

  it "returns override grade changes in results" do
    expect(course_grade_changes(@course).count).to eq 1
    Auditors::GradeChange.record(override_grade_change:)
    expect(course_grade_changes(@course).count).to eq 2
  end

  it "stores override grade changes in the database" do
    expect do
      Auditors::GradeChange.record(override_grade_change:)
    end.to change {
      Auditors::ActiveRecord::GradeChangeRecord.where(
        context_id: @course.id,
        context_type: "Course"
      ).count
    }.by(1)
  end

  it "can restrict results to override grades" do
    Auditors::GradeChange.record(submission: @submission)
    Auditors::GradeChange.record(override_grade_change:)

    records = Auditors::GradeChange.for_course_and_other_arguments(
      @course,
      {
        assignment: Auditors::GradeChange::COURSE_OVERRIDE_ASSIGNMENT
      }
    ).paginate(per_page: 10)

    aggregate_failures do
      expect(records.length).to eq 1
      expect(records.first).to be_override_grade
    end
  end

  it "can return results restricted to override grades in combination with other filters" do
    Auditors::GradeChange.record(submission: @submission)
    Auditors::GradeChange.record(override_grade_change:)

    other_teacher = @course.enroll_teacher(User.create!, workflow_state: "active").user
    other_override = Auditors::GradeChange::OverrideGradeChange.new(
      grader: other_teacher,
      old_grade: nil,
      old_score: nil,
      score: @student.enrollments.first.find_score
    )
    Auditors::GradeChange.record(override_grade_change: other_override)

    grade_changes = Auditors::GradeChange.for_course_and_other_arguments(
      @course,
      {
        assignment: Auditors::GradeChange::COURSE_OVERRIDE_ASSIGNMENT,
        grader: @teacher
      }
    ).paginate(per_page: 10)

    aggregate_failures do
      expect(grade_changes.length).to eq 1
      expect(grade_changes.first).to be_override_grade
      expect(grade_changes.first.grader).to eq @teacher
    end
  end

  describe "grading period ID" do
    let(:grading_period) do
      grading_period_group = @course.root_account.grading_period_groups.create!
      now = Time.zone.now
      grading_period_group.grading_periods.create!(
        close_date: 2.weeks.from_now(now),
        end_date: 1.week.from_now(now),
        start_date: 1.week.ago(now),
        title: "aaa"
      )
    end

    it "saves the grading period ID for submission grade changes" do
      @submission.update!(grading_period_id: grading_period.id)
      Auditors::GradeChange.record(submission: @submission)
      expect(Auditors::ActiveRecord::GradeChangeRecord.last.grading_period_id).to eq grading_period.id
    end

    it "saves the grading period ID for override grade changes" do
      override_grade_change.score.update!(grading_period_id: grading_period.id)
      Auditors::GradeChange.record(override_grade_change:)
      expect(Auditors::ActiveRecord::GradeChangeRecord.last.grading_period_id).to eq grading_period.id
    end
  end

  describe ".filter_by_assignment" do
    it "only changes the scope for nil assignment ids" do
      attributes = {
        assignment_id: @assignment.id,
        account_id: @account.id,
        root_account_id: @account.id,
        student_id: @student.id,
        context_id: @course.id,
        context_type: "Course",
        excused_after: false,
        excused_before: false,
        event_type: "grade"
      }
      r1 = Auditors::ActiveRecord::GradeChangeRecord.create!(attributes.merge({
                                                                                uuid: "asdf",
                                                                                request_id: "asdf"
                                                                              }))
      r2 = Auditors::ActiveRecord::GradeChangeRecord.create!(attributes.merge({
                                                                                assignment_id: nil,
                                                                                uuid: "fdsa",
                                                                                request_id: "fdsa"
                                                                              }))
      scope1 = Auditors::ActiveRecord::GradeChangeRecord.where(assignment_id: @assignment.id)
      scope2 = Auditors::ActiveRecord::GradeChangeRecord.where(assignment_id: Auditors::GradeChange::NULL_PLACEHOLDER)
      scope1 = Auditors::GradeChange.filter_by_assignment(scope1)
      scope2 = Auditors::GradeChange.filter_by_assignment(scope2)
      expect(r2.reload.assignment_id).to be_nil
      expect(scope1.pluck(:id)).to include(r1.id)
      expect(scope1.pluck(:id)).to_not include(r2.id)
      expect(scope2.pluck(:id)).to_not include(r1.id)
      expect(scope2.pluck(:id)).to include(r2.id)
    end
  end

  describe Auditors::GradeChange::Record do
    describe "#in_grading_period?" do
      it "returns true if the record has a valid grading period" do
        grading_period_group = @account.grading_period_groups.create!
        now = Time.zone.now
        grading_period = grading_period_group.grading_periods.create!(
          close_date: 1.week.from_now(now),
          end_date: 1.week.from_now(now),
          start_date: 1.week.ago(now),
          title: "a"
        )

        @submission.update!(grading_period:)
        event = Auditors::GradeChange.record(submission: @submission)
        expect(event).to be_in_grading_period
      end

      it "returns false if the record does not have a valid grading period" do
        event = Auditors::GradeChange.record(submission: @submission)
        expect(event).not_to be_in_grading_period
      end
    end
  end

  describe "bulk_record_submission_events" do
    it "records grade change events for all submissions" do
      submission1 = @assignment.grade_student(@student, grade: 8, grader: @teacher).first
      submission2 = @assignment.grade_student(@student, grade: 2, grader: @teacher).first
      submission3 = @assignment.grade_student(@student, grade: 3, grader: @teacher).first

      expect do
        Auditors::GradeChange.bulk_record_submission_events([submission1, submission2, submission3])
      end.to change { Auditors::ActiveRecord::GradeChangeRecord.count }.by(3)

      expect(Auditors::ActiveRecord::GradeChangeRecord.third_to_last.score_after).to eq 8.0
      expect(Auditors::ActiveRecord::GradeChangeRecord.second_to_last.score_after).to eq 2.0
      expect(Auditors::ActiveRecord::GradeChangeRecord.last.score_after).to eq 3.0
    end
  end

  describe "create_content_participations" do
    it "does not create a content participation record if one already exists" do
      plucked_submissions = [[@student.id, @submission.id, @course.id]]
      expect(@submission.content_participations.count).to eq 1
      cpc = ContentParticipationCount.where(context_id: @submission.course_id, user_id: @submission.user_id, content_type: "Submission")
      expect(cpc.count).to eq 1
      expect(cpc.first.unread_count).to eq 1
      @assignment.grade_student(@student, grade: nil, grader: @teacher)
      @submission.update_columns(score: nil, grade: nil, workflow_state: "unsubmitted")
      Auditors::GradeChange.create_content_participations(plucked_submissions, @assignment, [@student.id])
      expect(@submission.content_participations.count).to eq 1
    end

    it "does not create a duplicate content participation count record if one already exists for the course" do
      ContentParticipation.mark_all_as_read_for_user(@student, @student.submissions, @course)
      @submission.update_columns(score: nil, grade: nil, workflow_state: "unsubmitted")
      plucked_submissions = [[@student.id, @submission.id, @course.id]]
      Auditors::GradeChange.create_content_participations(plucked_submissions, @assignment, [@student.id])

      cpc = ContentParticipationCount.where(context_id: @submission.course_id, user_id: @submission.user_id, content_type: "Submission")
      expect(cpc.count).to eq 1

      second_assignment = @course.assignments.create!(title: "Assignment 2", points_possible: 10)
      second_submission = second_assignment.submissions.first
      second_submission.update_columns(score: nil, grade: nil, workflow_state: "unsubmitted")
      plucked_submissions = [[@student.id, second_assignment.submissions.first.id, @course.id]]
      Auditors::GradeChange.create_content_participations(plucked_submissions, second_assignment, [@student.id])

      expect(second_submission.content_participations.count).to eq 1
      cpc = ContentParticipationCount.where(context_id: second_submission.course_id, user_id: second_submission.user_id, content_type: "Submission")
      expect(cpc.count).to eq 1
    end
  end
end
