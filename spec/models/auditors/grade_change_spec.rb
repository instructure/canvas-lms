#
# Copyright (C) 2013 Instructure, Inc.
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
  include_examples "cassandra audit logs"

  let(:request_id) { 42 }

  before do
    RequestContextGenerator.stubs( :request_id => request_id )

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
    @event_time = Time.at(1.hour.ago.to_i) # cassandra doesn't remember microseconds
    Timecop.freeze(@event_time) { @event = Auditors::GradeChange.record(@submission) }
  end

  context "nominal cases" do
    it "should include event" do
      expect(@event.created_at).to eq @event_time
      expect(Auditors::GradeChange.for_assignment(@assignment).paginate(:per_page => 5)).to include(@event)
      expect(Auditors::GradeChange.for_course(@course).paginate(:per_page => 5)).to include(@event)
      expect(Auditors::GradeChange.for_root_account_student(@account, @student).paginate(:per_page => 5)).to include(@event)
      expect(Auditors::GradeChange.for_root_account_grader(@account, @teacher).paginate(:per_page => 5)).to include(@event)
    end

    it "should include event for nil grader" do
      # We don't want to index events for nil graders.

      @submission = @assignment.grade_student(@student, grade: 6, grader: @teacher).first
      @event = Auditors::GradeChange.record(@submission)

      expect(Auditors::GradeChange.for_assignment(@assignment).paginate(:per_page => 5)).to include(@event)
      expect(Auditors::GradeChange.for_course(@course).paginate(:per_page => 5)).to include(@event)
      expect(Auditors::GradeChange.for_root_account_student(@account, @student).paginate(:per_page => 5)).to include(@event)
    end

    it "should include event for auto grader" do
      # Currently we are not indexing events for auto grader in cassandra.

      @submission.score = 5
      @submission.grader_id = -1
      @event = Auditors::GradeChange.record(@submission)

      expect(Auditors::GradeChange.for_assignment(@assignment).paginate(:per_page => 5)).to include(@event)
      expect(Auditors::GradeChange.for_course(@course).paginate(:per_page => 5)).to include(@event)
      expect(Auditors::GradeChange.for_root_account_student(@account, @student).paginate(:per_page => 5)).to include(@event)
    end

    it "should set request_id" do
      expect(@event.request_id).to eq request_id.to_s
    end
  end

  it "reports excused submissions" do
    @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
    @event = Auditors::GradeChange.record(@excused)

    for_assignment = Auditors::GradeChange.for_assignment(@assignment)
    for_course = Auditors::GradeChange.for_course(@course)
    for_root_account_student = Auditors::GradeChange.for_root_account_student(@account, @student)

    expect(for_assignment.paginate(per_page: 5)).to include(@event)
    expect(for_course.paginate(per_page: 5)).to include(@event)
    expect(for_root_account_student.paginate(per_page: 5)).to include(@event)
  end

  it "reports formerly excused submissions" do
    @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
    Auditors::GradeChange.record(@excused)
    @unexcused = @assignment.grade_student(@student, grader: @teacher, excused: false).first
    @event = Auditors::GradeChange.record(@unexcused)

    for_assignment = Auditors::GradeChange.for_assignment(@assignment)
    for_course = Auditors::GradeChange.for_course(@course)
    for_root_account_student = Auditors::GradeChange.for_root_account_student(@account, @student)

    expect(for_assignment.paginate(per_page: 5)).to include(@event)
    expect(for_course.paginate(per_page: 5)).to include(@event)
    expect(for_root_account_student.paginate(per_page: 5)).to include(@event)
  end

  it "records excused_before and excused_after as booleans on initial grading" do
    expect(@event.excused_before).to eql(false)
    expect(@event.excused_after).to eql(false)
  end

  it "records excused submissions" do
    @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
    @event = Auditors::GradeChange.record(@excused)

    expect(@event.grade_before).to eql(@submission.grade)
    expect(@event.grade_after).to be_nil
    expect(@event.excused_before).to eql(false)
    expect(@event.excused_after).to eql(true)
  end

  it "records formerly excused submissions" do
    @excused = @assignment.grade_student(@student, grader: @teacher, excused: true).first
    Auditors::GradeChange.record(@excused)
    @unexcused = @assignment.grade_student(@student, grader: @teacher, excused: false).first
    @event = Auditors::GradeChange.record(@unexcused)

    expect(@event.grade_before).to be_nil
    expect(@event.grade_after).to be_nil
    expect(@event.excused_before).to eql(true)
    expect(@event.excused_after).to eql(false)
  end

  it "records regraded submissions" do
    @submission.score = 5
    @submission.with_versioning(:explicit => true, &:save!)
    @event = Auditors::GradeChange.record(@submission)

    expect(@event.score_before).to eq 8
    expect(@event.score_after).to eq 5
  end

  it "records grades affected by assignment update" do
    @assignment.points_possible = 15
    @assignment.save!
    @submission.assignment_changed_not_sub = true
    @event = Auditors::GradeChange.record(@submission)

    expect(@event.points_possible_before).to eq 10
    expect(@event.points_possible_after).to eq 15
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
end
