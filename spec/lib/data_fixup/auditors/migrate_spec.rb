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

require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../../../cassandra_spec_helper')

describe 'DataFixup::Auditors::Migrate' do
  before(:each) do
    allow(Auditors).to receive(:config).and_return({'write_paths' => ['cassandra'], 'read_path' => 'cassandra'})
  end

  let(:account){ Account.default }

  it "writes authentication data to postgres that's in cassandra" do
    Auditors::ActiveRecord::AuthenticationRecord.delete_all
    user_with_pseudonym(active_all: true)
    20.times { Auditors::Authentication.record(@pseudonym, 'login') }
    date = Time.zone.today
    expect(Auditors::ActiveRecord::AuthenticationRecord.count).to eq(0)
    worker = DataFixup::Auditors::Migrate::AuthenticationWorker.new(account.id, date)
    missing_uuids = worker.audit
    expect(missing_uuids.size).to eq(20)
    worker.perform
    expect(Auditors::ActiveRecord::AuthenticationRecord.count).to eq(20)
    missing_uuids = worker.audit
    expect(missing_uuids.size).to eq(0)
  end

  it "recovers if user has been hard deleted" do
    # simulates when a user has been hard-deleted
    Auditors::ActiveRecord::AuthenticationRecord.delete_all
    u1 = user_with_pseudonym(active_all: true)
    p1 = @pseudonym
    Auditors::Authentication.record(p1, 'login')
    u2 = user_with_pseudonym(active_all: true)
    p2 = @pseudonym
    expect(p1).to_not eq(p2)
    Auditors::Authentication.record(p2, 'login')
    [CommunicationChannel, UserAccountAssociation].each do |klass|
      klass.where(user_id: u2.id).delete_all
    end
    Pseudonym.where(id: p2.id).delete_all
    User.where(id: p2.user_id).delete_all
    date = Time.zone.today
    worker = DataFixup::Auditors::Migrate::AuthenticationWorker.new(account.id, date)
    allow(Auditors::ActiveRecord::AuthenticationRecord).to receive(:bulk_insert) do |recs|
      # should only migrate the existing user, so the second time is only one rec
      if recs.find{|r| r['user_id'] == p2.user_id}
        raise ActiveRecord::InvalidForeignKey
      end
    end
    expect { worker.perform }.to_not raise_exception
  end

  it "writes course data to postgres that's in cassandra" do
    Auditors::ActiveRecord::CourseRecord.delete_all
    user_with_pseudonym(active_all: true)
    sub_account = Account.create!(parent_account: account)
    sub_sub_account = Account.create!(parent_account: sub_account)
    course_with_teacher(course_name: "Course 1", account: sub_sub_account)
    @course.name = "Course 2"
    @course.start_at = Time.zone.today
    @course.conclude_at = Time.zone.today + 7.days
    10.times { Auditors::Course.record_updated(@course, @teacher, @course.changes) }
    date = Time.zone.today
    expect(Auditors::ActiveRecord::CourseRecord.count).to eq(0)
    worker = DataFixup::Auditors::Migrate::CourseWorker.new(sub_sub_account.id, date)
    missing_uuids = worker.audit
    expect(missing_uuids.size).to eq(10)
    worker.perform
    expect(Auditors::ActiveRecord::CourseRecord.count).to eq(10)
    missing_uuids = worker.audit
    expect(missing_uuids.size).to eq(0)
  end

  it "writes grade change data to postgres that's in cassandra" do
    Auditors::ActiveRecord::GradeChangeRecord.delete_all
    sub_account = Account.create!(parent_account: account)
    sub_sub_account = Account.create!(parent_account: sub_account)
    course_with_teacher(account: sub_sub_account)
    student_in_course
    assignment = @course.assignments.create!(title: 'Assignment', points_possible: 10)
    assignment.grade_student(@student, grade: 8, grader: @teacher).first
    # no need to call anything, THIS invokes an auditor record^
    date = Time.zone.today
    expect(Auditors::ActiveRecord::GradeChangeRecord.count).to eq(0)
    expect(Auditors::GradeChange.for_assignment(assignment).paginate(per_page: 10).size).to eq(1)
    worker = DataFixup::Auditors::Migrate::GradeChangeWorker.new(sub_sub_account.id, date)
    missing_uuids = worker.audit
    expect(missing_uuids.size).to eq(1)
    worker.perform
    expect(Auditors::ActiveRecord::GradeChangeRecord.count).to eq(1)
    missing_uuids = worker.audit
    expect(missing_uuids.size).to eq(0)
  end

  it "can update the cassandra timeout" do
    cdb = Auditors::GradeChange::Stream.database
    expect(cdb.db.instance_variable_get(:@thrift_client_options)[:timeout]).to_not eq(360)
    worker = DataFixup::Auditors::Migrate::GradeChangeWorker.new(Account.default.id, Time.zone.today)
    worker.extend_cassandra_stream_timeout!
    expect(worker.auditor_cassandra_stream).to eq(Auditors::GradeChange::Stream)
    cdb = Auditors::GradeChange::Stream.database
    expect(cdb.db.instance_variable_get(:@thrift_client_options)[:timeout]).to eq(360)
    worker.clear_cassandra_stream_timeout!
    cdb = Auditors::GradeChange::Stream.database
    expect(cdb.db.instance_variable_get(:@thrift_client_options)[:timeout]).to_not eq(360)
  end

  it "handles transient timeouts" do
    collection = Class.new do
      attr_accessor :threw_already
      def paginate(_args)
        return ['test'] if threw_already
        @threw_already = true
        raise CassandraCQL::Thrift::TimedOutException
      end
    end.new
    worker = DataFixup::Auditors::Migrate::GradeChangeWorker.new(Account.default.id, Time.zone.today)
    output = worker.get_cassandra_records_resiliantly(collection, {})
    expect(collection.threw_already).to eq(true)
    expect(output).to eq(['test'])
  end

  describe "record keeping" do
    let(:date){ Time.zone.today }

    before(:each) do
      Auditors::ActiveRecord::AuthenticationRecord.delete_all
      Auditors::ActiveRecord::MigrationCell.delete_all
      user_with_pseudonym(active_all: true)
      10.times { Auditors::Authentication.record(@pseudonym, 'login') }
    end

    it "keeps a record of the migration" do
      worker = DataFixup::Auditors::Migrate::AuthenticationWorker.new(account.id, date)
      cell = worker.migration_cell
      expect(cell).to be_nil
      worker.perform
      cell = worker.migration_cell
      expect(cell.id).to_not be_nil
      expect(cell.auditor_type).to eq("authentication")
      expect(cell.completed).to eq(true)
      expect(cell.failed).to eq(false)
      expect(Auditors::ActiveRecord::AuthenticationRecord.count).to eq(10)
    end

    it "will not run if the migration is already flagged as complete" do
      worker = DataFixup::Auditors::Migrate::AuthenticationWorker.new(account.id, date)
      cell = worker.create_cell!
      cell.update_attribute(:completed, true)
      worker.perform
      # no records get transfered because it's already "complete"
      expect(Auditors::ActiveRecord::AuthenticationRecord.count).to eq(0)
    end

    it "reconciles partial successes" do
      worker = DataFixup::Auditors::Migrate::AuthenticationWorker.new(account.id, date)
      worker.perform
      expect(Auditors::ActiveRecord::AuthenticationRecord.count).to eq(10)
      # kill the cell so we can run again
      worker.migration_cell.destroy
      3.times { Auditors::Authentication.record(@pseudonym, 'login') }
      # worker reconciles which ones are already in the table and which are not
      worker.perform
      expect(Auditors::ActiveRecord::AuthenticationRecord.count).to eq(13)
    end
  end

  describe "BackfillEngine" do
    around(:each) do |example|
      Delayed::Job.delete_all
      example.run
      Delayed::Job.delete_all
    end

    it "stops enqueueing after one day with a low threshold" do
      start_date = Time.zone.today
      end_date = start_date - 1.year
      engine = DataFixup::Auditors::Migrate::BackfillEngine.new(start_date, end_date)
      Setting.set(engine.class.queue_setting_key, 1)
      expect(Delayed::Job.count).to eq(0)
      account = Account.default
      expect(account.workflow_state).to eq('active')
      expect(Account.active.count).to eq(1)
      engine.perform
      # one each per table for the day, and one as the future
      # scheduler thread.
      expect(Delayed::Job.count).to eq(4)
    end

    it "succeeds in all summary queries" do
      output = DataFixup::Auditors::Migrate::BackfillEngine.summary
      expect(output).to_not be_empty
    end

    it "buckets settings by JOB cluster" do
      pk = DataFixup::Auditors::Migrate::BackfillEngine.parallelism_key("grade_changes")
      # because default shard has a nil job id
      expect(pk).to eq("auditors_migration_grade_changes/jobs_num_strands")
    end

    it "enqueues even if it made no progress" do
      start_date = Time.zone.today
      end_date = start_date - 1.year
      engine = DataFixup::Auditors::Migrate::BackfillEngine.new(start_date, end_date)
      Delayed::Job.enqueue(engine)
      Setting.set(engine.class.queue_setting_key, -1)
      expect(Delayed::Job.count).to eq(1)
      expect(Delayed::Job.first.tag).to eq(DataFixup::Auditors::Migrate::BackfillEngine::SCHEDULAR_TAG)
      d_worker = Delayed::Worker.new
      sched_job = Delayed::Job.first
      sched_job.update(locked_by: 'test_run', locked_at: Time.now.utc)
      d_worker.perform(sched_job)
      expect(Delayed::Job.count).to eq(1)
      expect(Delayed::Job.first.tag).to eq(DataFixup::Auditors::Migrate::BackfillEngine::SCHEDULAR_TAG)
      expect(sched_job.id).to_not eq(Delayed::Job.first.id)
    end
  end
end