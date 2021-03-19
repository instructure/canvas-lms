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

require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

describe Auditors::GradeChange do
  before(:all) do
    Auditors::ActiveRecord::Partitioner.process
  end

  let(:request_id) { 42 }

  before(:each) do
    allow(RequestContextGenerator).to receive_messages(request_id: request_id)

    shard_class = Class.new {
      define_method(:activate) { |&b| b.call }
    }

    EventStream.current_shard_lookup = lambda {
      shard_class.new
    }

    @account = Account.default
    @sub_account = Account.create!(:parent_account => @account)
    @sub_sub_account = Account.create!(:parent_account => @sub_account)

    course_with_teacher(account: @sub_sub_account)
    student_in_course

    @assignment = @course.assignments.create!(:title => 'Assignment', :points_possible => 10)
    @submission = @assignment.grade_student(@student, grade: 8, grader: @teacher).first
    @event_time = Time.zone.at(1.hour.ago.to_i) # cassandra doesn't remember microseconds
  end

  describe "with cassandra backend" do
    include_examples "cassandra audit logs"
    before do
      allow(Audits).to receive(:config).and_return({'write_paths' => ['cassandra'], 'read_path' => 'cassandra'})
      Timecop.freeze(@event_time) { @event = Auditors::GradeChange.record(submission: @submission) }
    end

    def test_course_and_other_contexts
      # course assignment
      contexts = { assignment: @assignment }
      yield contexts
      # course assignment grader
      contexts[:grader] = @teacher
      yield contexts
      # course assignment grader student
      contexts[:student] = @student
      yield contexts
      # course assignment student
      contexts.delete(:grader)
      yield contexts
      # course grader
      contexts = { grader: @teacher }
      yield contexts
      # course grader student
      contexts[:student] = @student
      yield contexts
      # course student
      contexts.delete(:grader)
      yield contexts
    end

    context "nominal cases" do
      it "has its attributes accessible as methods" do
        expect(@event.assignment_id).to eq(@submission.assignment_id)
        expect(@event.submission_id).to eq(@submission.id)
      end

      it "should include event" do
        expect(@event.created_at).to eq @event_time
        expect(Auditors::GradeChange.for_assignment(@assignment).paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_course(@course).paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_root_account_student(@account, @student).
                paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_root_account_grader(@account, @teacher).
                paginate(:per_page => 5)).to include(@event)

        test_course_and_other_contexts do |contexts|
          expect(Auditors::GradeChange.for_course_and_other_arguments(@course, contexts).
            paginate(:per_page => 5)).to include(@event)
        end
      end

      it "should include event for nil grader" do
        # We don't want to index events for nil graders.

        @submission = @assignment.grade_student(@student, grade: 6, grader: @teacher).first
        @event = Auditors::GradeChange.record(submission: @submission)

        expect(Auditors::GradeChange.for_assignment(@assignment).paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_course(@course).paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_root_account_student(@account, @student).
          paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_course_and_other_arguments(@course, {assignment: @assignment}).
          paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_course_and_other_arguments(@course, {assignment: @assignment,
          student: @student}).paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_course_and_other_arguments(@course, {student: @student}).
          paginate(:per_page => 5)).to include(@event)
      end

      it "should include event for auto grader" do
        # Currently we are not indexing events for auto grader in cassandra.

        @submission.score = 5
        @submission.grader_id = -1
        @event = Auditors::GradeChange.record(submission: @submission)

        expect(Auditors::GradeChange.for_assignment(@assignment).paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_course(@course).paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_root_account_student(@account, @student).
          paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_course_and_other_arguments(@course, {assignment: @assignment}).
          paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_course_and_other_arguments(@course, {assignment: @assignment,
          student: @student}).paginate(:per_page => 5)).to include(@event)
        expect(Auditors::GradeChange.for_course_and_other_arguments(@course, {student: @student}).
          paginate(:per_page => 5)).to include(@event)
      end

      it "should set request_id" do
        expect(@event.request_id).to eq request_id.to_s
      end
    end

    it "reports excused submissions" do
      @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
      @event = Auditors::GradeChange.record(submission: @excused)

      for_assignment = Auditors::GradeChange.for_assignment(@assignment)
      for_course = Auditors::GradeChange.for_course(@course)
      for_root_account_student = Auditors::GradeChange.for_root_account_student(@account, @student)
      expect(for_assignment.paginate(per_page: 5)).to include(@event)
      expect(for_course.paginate(per_page: 5)).to include(@event)
      expect(for_root_account_student.paginate(per_page: 5)).to include(@event)

      test_course_and_other_contexts do |contexts|
        expect(Auditors::GradeChange.for_course_and_other_arguments(@course, contexts).paginate(per_page: 5)).
          to include(@event)
      end
    end

    it "reports formerly excused submissions" do
      @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
      Auditors::GradeChange.record(submission: @excused)
      @unexcused = @assignment.grade_student(@student, grader: @teacher, excused: false).first
      @event = Auditors::GradeChange.record(submission: @unexcused)

      for_assignment = Auditors::GradeChange.for_assignment(@assignment)
      for_course = Auditors::GradeChange.for_course(@course)
      for_root_account_student = Auditors::GradeChange.for_root_account_student(@account, @student)

      expect(for_assignment.paginate(per_page: 5)).to include(@event)
      expect(for_course.paginate(per_page: 5)).to include(@event)
      expect(for_root_account_student.paginate(per_page: 5)).to include(@event)
      test_course_and_other_contexts do |contexts|
        expect(Auditors::GradeChange.for_course_and_other_arguments(@course, contexts).paginate(per_page: 5)).
          to include(@event)
      end
    end

    it "records excused_before and excused_after as booleans on initial grading" do
      expect(@event.excused_before).to be(false)
      expect(@event.excused_after).to be(false)
    end

    it "records excused submissions" do
      @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
      @event = Auditors::GradeChange.record(submission: @excused)

      expect(@event.grade_before).to eq(@submission.grade)
      expect(@event.grade_after).to be_nil
      expect(@event.excused_before).to be(false)
      expect(@event.excused_after).to be(true)
    end

    it "records formerly excused submissions" do
      @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
      Auditors::GradeChange.record(submission: @excused)
      @unexcused = @assignment.grade_student(@student, grader: @teacher, excused: false).first
      @event = Auditors::GradeChange.record(submission: @unexcused)

      expect(@event.grade_before).to be_nil
      expect(@event.grade_after).to be_nil
      expect(@event.excused_before).to be(true)
      expect(@event.excused_after).to be(false)
    end

    it "records regraded submissions" do
      @submission.score = 5
      @submission.with_versioning(:explicit => true, &:save!)
      @event = Auditors::GradeChange.record(submission: @submission)

      expect(@event.score_before).to eq 8
      expect(@event.score_after).to eq 5
    end

    it "records grades affected by assignment update" do
      @assignment.points_possible = 15
      @assignment.save!
      @submission.assignment_changed_not_sub = true
      @event = Auditors::GradeChange.record(submission: @submission)

      expect(@event.points_possible_before).to eq 10
      expect(@event.points_possible_after).to eq 15
    end

    it "records the grading period ID of the affected submission if it has one" do
      grading_period_group = @account.grading_period_groups.create!
      now = Time.zone.now
      grading_period = grading_period_group.grading_periods.create!(
        close_date: 1.week.from_now(now),
        end_date: 1.week.from_now(now),
        start_date: 1.week.ago(now),
        title: "a"
      )

      @submission.update!(grading_period: grading_period)
      @event = Auditors::GradeChange.record(submission: @submission)
      expect(@event.grading_period_id).to eq @submission.grading_period_id
    end

    it "records a placeholder value for the grading period ID if there is no grading period" do
      @event = Auditors::GradeChange.record(submission: @submission)
      expect(@event.grading_period_id).to eq 0
    end

    describe "options forwarding" do
      before do
        record = Auditors::GradeChange::Record.new(
          'submission' => @submission,
          'created_at' => 1.day.ago
        )
        @event2 = Auditors::GradeChange::Stream.insert(record)
      end

      it "should recognize :oldest" do
        page = Auditors::GradeChange.for_assignment(@assignment, oldest: 12.hours.ago).paginate(:per_page => 2)
        expect(page).to include(@event)
        expect(page).not_to include(@event2)

        page = Auditors::GradeChange.for_course(@course, oldest: 12.hours.ago).paginate(:per_page => 2)
        expect(page).to include(@event)
        expect(page).not_to include(@event2)

        page = Auditors::GradeChange.for_root_account_student(@account, @student, oldest: 12.hours.ago).paginate(:per_page => 2)
        expect(page).to include(@event)
        expect(page).not_to include(@event2)

        page = Auditors::GradeChange.for_root_account_grader(@account, @teacher, oldest: 12.hours.ago).paginate(:per_page => 2)
        expect(page).to include(@event)
        expect(page).not_to include(@event2)
      end

      it "should recognize :newest" do
        page = Auditors::GradeChange.for_assignment(@assignment, newest: 12.hours.ago).paginate(:per_page => 2)
        expect(page).to include(@event2)
        expect(page).not_to include(@event)

        page = Auditors::GradeChange.for_course(@course, newest: 12.hours.ago).paginate(:per_page => 2)
        expect(page).to include(@event2)
        expect(page).not_to include(@event)

        page = Auditors::GradeChange.for_root_account_student(@account, @student, newest: 12.hours.ago).paginate(:per_page => 2)
        expect(page).to include(@event2)
        expect(page).not_to include(@event)

        page = Auditors::GradeChange.for_root_account_grader(@account, @teacher, newest: 12.hours.ago).paginate(:per_page => 2)
        expect(page).to include(@event2)
        expect(page).not_to include(@event)
      end
    end

    it "inserts a record" do
      expect(Auditors::GradeChange::Stream).to receive(:insert).once
      Auditors::GradeChange.record(submission: @submission)
    end

    it "does not insert a record if skip_insert is true" do
      expect(Auditors::GradeChange::Stream).not_to receive(:insert)
      Auditors::GradeChange.record(submission: @submission, skip_insert: true)
    end

    context "when inserting an override grade change" do
      let(:override_grade_change) do
        Auditors::GradeChange::OverrideGradeChange.new(
          grader: @teacher,
          old_grade: nil,
          old_score: nil,
          score: @student.enrollments.first.find_score
        )
      end

      it "sets a placeholder value for the assignment ID" do
        record = Auditors::GradeChange.record(override_grade_change: override_grade_change)
        expect(record.assignment_id).to eq 0
      end

      it "sets a placeholder value for the submission ID" do
        record = Auditors::GradeChange.record(override_grade_change: override_grade_change)
        expect(record.submission_id).to eq 0
      end
    end
  end

  describe "with postgres backend" do
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

    before do
      allow(Audits).to receive(:config).and_return({'write_paths' => ['active_record'], 'read_path' => 'active_record'})
    end

    it "inserts submission grade change records" do
      expect(Auditors::GradeChange::Stream).to receive(:insert).once
      Auditors::GradeChange.record(submission: @submission)
    end

    it "inserts override grade change records" do
      expect(Auditors::GradeChange::Stream).to receive(:insert).once
      Auditors::GradeChange.record(override_grade_change: override_grade_change)
    end

    it "does not accept both a submission and an override in the same call" do
      expect {
        Auditors::GradeChange.record(submission: @submission, override_grade_change: override_grade_change)
      }.to raise_error(ArgumentError)
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
      Auditors::GradeChange.record(override_grade_change: override_grade_change)
      expect(course_grade_changes(@course).count).to eq 2
    end

    it "stores override grade changes in the database" do
      expect {
        Auditors::GradeChange.record(override_grade_change: override_grade_change)
      }.to change {
        Auditors::ActiveRecord::GradeChangeRecord.where(
          context_id: @course.id,
          context_type: "Course"
        ).count
      }.by(1)
    end

    it "can restrict results to override grades" do
      Auditors::GradeChange.record(submission: @submission)
      Auditors::GradeChange.record(override_grade_change: override_grade_change)

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
      Auditors::GradeChange.record(override_grade_change: override_grade_change)

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
        Auditors::GradeChange.record(override_grade_change: override_grade_change)
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
          context_type: 'Course',
          excused_after: false,
          excused_before: false,
          event_type: 'grade'
        }
        r1 = Auditors::ActiveRecord::GradeChangeRecord.create!(attributes.merge({
          uuid: 'asdf',
          request_id: 'asdf'
        }))
        r2 = Auditors::ActiveRecord::GradeChangeRecord.create!(attributes.merge({
          assignment_id: nil,
          uuid: 'fdsa',
          request_id: 'fdsa'
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
  end

  describe "with dual writing enabled to postgres" do
    before do
      allow(Audits).to receive(:config).and_return({'write_paths' => ['cassandra', 'active_record'], 'read_path' => 'cassandra'})
    end

    it "writes to cassandra" do
      event = Auditors::GradeChange.record(submission: @submission)
      expect(Audits.write_to_cassandra?).to eq(true)
      expect(Auditors::GradeChange.for_assignment(@assignment).paginate(:per_page => 5)).to include(event)
    end

    it "writes to postgres" do
      event = Auditors::GradeChange.record(submission: @submission)
      expect(Audits.write_to_postgres?).to eq(true)
      pg_record = Auditors::ActiveRecord::GradeChangeRecord.where(uuid: event.id).first
      expect(pg_record).to_not be_nil
      expect(pg_record.submission_id).to eq(@submission.id)
    end
  end

  describe ".return_override_grades?" do
    it "returns true if the final_grade_override_in_gradebook_history flag is enabled" do
      Account.site_admin.enable_feature!(:final_grade_override_in_gradebook_history)
      expect(Auditors::GradeChange).to be_return_override_grades
    end

    it "returns false if the final_grade_override_in_gradebook_history flag is not enabled" do
      expect(Auditors::GradeChange).not_to be_return_override_grades
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

        @submission.update!(grading_period: grading_period)
        event = Auditors::GradeChange.record(submission: @submission)
        expect(event).to be_in_grading_period
      end

      it "returns false if the record does not have a valid grading period" do
        event = Auditors::GradeChange.record(submission: @submission)
        expect(event).not_to be_in_grading_period
      end
    end
  end
end
