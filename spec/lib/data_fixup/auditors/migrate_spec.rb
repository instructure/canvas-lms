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
require_relative '../../../../lib/data_fixup/auditors/migrate'
require File.expand_path(File.dirname(__FILE__) + '/../../../cassandra_spec_helper')

module DataFixup::Auditors::Migrate
  describe 'cassandra backfill functionality' do
    before(:each) do
      allow(::Auditors).to receive(:config).and_return({'write_paths' => ['cassandra'], 'read_path' => 'cassandra'})
    end

    let(:account){ Account.default }

    it "writes authentication data to postgres that's in cassandra" do
      ::Auditors::ActiveRecord::AuthenticationRecord.delete_all
      user_with_pseudonym(active_all: true)
      20.times { ::Auditors::Authentication.record(@pseudonym, 'login') }
      date = Time.zone.today
      expect(::Auditors::ActiveRecord::AuthenticationRecord.count).to eq(0)
      worker = AuthenticationWorker.new(account.id, date)
      missing_uuids = worker.audit
      expect(missing_uuids.size).to eq(20)
      worker.perform
      expect(::Auditors::ActiveRecord::AuthenticationRecord.count).to eq(20)
      missing_uuids = worker.audit
      expect(missing_uuids.size).to eq(0)
    end

    it "recovers if user has been hard deleted" do
      # simulates when a user has been hard-deleted
      ::Auditors::ActiveRecord::AuthenticationRecord.delete_all
      u1 = user_with_pseudonym(active_all: true)
      p1 = @pseudonym
      ::Auditors::Authentication.record(p1, 'login')
      u2 = user_with_pseudonym(active_all: true)
      p2 = @pseudonym
      expect(p1).to_not eq(p2)
      ::Auditors::Authentication.record(p2, 'login')
      [CommunicationChannel, UserAccountAssociation].each do |klass|
        klass.where(user_id: u2.id).delete_all
      end
      Pseudonym.where(id: p2.id).delete_all
      User.where(id: p2.user_id).delete_all
      date = Time.zone.today
      worker = AuthenticationWorker.new(account.id, date)
      allow(::Auditors::ActiveRecord::AuthenticationRecord).to receive(:bulk_insert) do |recs|
        # should only migrate the existing user, so the second time is only one rec
        if recs.find{|r| r['user_id'] == p2.user_id}
          raise ActiveRecord::InvalidForeignKey
        end
      end
      expect { worker.perform }.to_not raise_exception
    end

    it "handles missing submissions" do
      submission = submission_model
      user = user_model
      expect(submission.id).to_not be_nil
      expect(user.id).to_not be_nil
      worker = GradeChangeWorker.new(account.id, Time.now.utc)
      filtered = worker.filter_dead_foreign_keys([
        {'student_id' => user.id, 'grader_id' => user.id, 'submission_id' => 0},
        {'student_id' => user.id, 'grader_id' => user.id, 'submission_id' => submission.id},
      ])
      expect(filtered.size).to eq(1)
      expect(filtered[0]['submission_id']).to eq(submission.id)
    end

    it "writes course data to postgres that's in cassandra" do
      ::Auditors::ActiveRecord::CourseRecord.delete_all
      user_with_pseudonym(active_all: true)
      sub_account = Account.create!(parent_account: account)
      sub_sub_account = Account.create!(parent_account: sub_account)
      course_with_teacher(course_name: "Course 1", account: sub_sub_account)
      @course.name = "Course 2"
      @course.start_at = Time.zone.today
      @course.conclude_at = Time.zone.today + 7.days
      10.times { ::Auditors::Course.record_updated(@course, @teacher, @course.changes) }
      date = Time.zone.today
      expect(::Auditors::ActiveRecord::CourseRecord.count).to eq(0)
      worker = CourseWorker.new(sub_sub_account.id, date)
      missing_uuids = worker.audit
      expect(missing_uuids.size).to eq(10)
      worker.perform
      expect(::Auditors::ActiveRecord::CourseRecord.count).to eq(10)
      missing_uuids = worker.audit
      expect(missing_uuids.size).to eq(0)
    end

    it "writes grade change data to postgres that's in cassandra" do
      ::Auditors::ActiveRecord::GradeChangeRecord.delete_all
      sub_account = Account.create!(parent_account: account)
      sub_sub_account = Account.create!(parent_account: sub_account)
      course_with_teacher(account: sub_sub_account)
      student_in_course
      assignment = @course.assignments.create!(title: 'Assignment', points_possible: 10)
      assignment.grade_student(@student, grade: 8, grader: @teacher).first
      # no need to call anything, THIS invokes an auditor record^
      date = Time.zone.today
      expect(::Auditors::ActiveRecord::GradeChangeRecord.count).to eq(0)
      expect(::Auditors::GradeChange.for_assignment(assignment).paginate(per_page: 10).size).to eq(1)
      worker = GradeChangeWorker.new(sub_sub_account.id, date)
      missing_uuids = worker.audit
      expect(missing_uuids.size).to eq(1)
      worker.perform
      expect(::Auditors::ActiveRecord::GradeChangeRecord.count).to eq(1)
      missing_uuids = worker.audit
      expect(missing_uuids.size).to eq(0)
    end

    it "can update the cassandra timeout" do
      cdb = ::Auditors::GradeChange::Stream.database
      expect(cdb.db.instance_variable_get(:@thrift_client_options)[:timeout]).to_not eq(360)
      worker = GradeChangeWorker.new(Account.default.id, Time.zone.today)
      worker.extend_cassandra_stream_timeout!
      expect(worker.auditor_cassandra_stream).to eq(::Auditors::GradeChange::Stream)
      cdb = ::Auditors::GradeChange::Stream.database
      expect(cdb.db.instance_variable_get(:@thrift_client_options)[:timeout]).to eq(360)
      worker.clear_cassandra_stream_timeout!
      cdb = ::Auditors::GradeChange::Stream.database
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
      worker = GradeChangeWorker.new(Account.default.id, Time.zone.today)
      output = worker.get_cassandra_records_resiliantly(collection, {})
      expect(collection.threw_already).to eq(true)
      expect(output).to eq(['test'])
    end

    describe "worker cell state" do
      describe "currently_queueable?" do
        it 'is true for any non-queued state' do
          worker = GradeChangeWorker.new(Account.default.id, Time.zone.today)
          expect(worker.migration_cell).to be_nil
          expect(worker.currently_queueable?).to be(true)
          worker.create_cell!
          expect(worker.migration_cell.failed).to eq(false)
          expect(worker.migration_cell.completed).to eq(false)
          expect(worker.currently_queueable?).to eq(false)
          worker.migration_cell.update_attribute(:failed, true)
          expect(worker.currently_queueable?).to eq(true)
          worker.migration_cell.update_attribute(:completed, true)
          expect(worker.currently_queueable?).to eq(false)
        end
      end
    end

    describe "AuditorWorker" do
      it "selects a date range of a week around target date" do
        # aligns sunday to sunday
        date = Date.civil(2020, 5, 15)
        worker = AuthenticationWorker.new(Account.default.id, date)
        cassandra_args = worker.cassandra_query_options
        expect(cassandra_args[:oldest].strftime("%Y-%m-%d %H:%M:%S")).to eq("2020-05-10 00:00:00")
        expect(cassandra_args[:newest].strftime("%Y-%m-%d %H:%M:%S")).to eq("2020-05-17 00:00:00")
      end
    end

    describe "GradeChangeWorker" do
      it "pulls courses for an account only if they have enrollments and assignments" do
        course1 = course_model(account_id: Account.default.id)
        course2 = course_model(account_id: Account.default.id)
        student_in_course(course: course1)
        assignment_model(course: course1)
        worker = GradeChangeWorker.new(Account.default.id, Time.zone.today)
        cids = worker.migrateable_course_ids
        expect(cids.include?(course1.id)).to eq(true)
        expect(cids.include?(course2.id)).to eq(false)
      end
    end

    describe "record keeping" do
      let(:date){ Time.zone.today }

      before(:each) do
        ::Auditors::ActiveRecord::AuthenticationRecord.delete_all
        ::Auditors::ActiveRecord::MigrationCell.delete_all
        user_with_pseudonym(active_all: true)
        10.times { ::Auditors::Authentication.record(@pseudonym, 'login') }
      end

      it "keeps a record of the migration" do
        worker = AuthenticationWorker.new(account.id, date)
        cell = worker.migration_cell
        expect(cell).to be_nil
        worker.perform
        expect(::Auditors::ActiveRecord::MigrationCell.count).to eq(7)
        expect(::Auditors::ActiveRecord::MigrationCell.all.pluck(:completed)).to eq([true] * 7)
        expect(::Auditors::ActiveRecord::MigrationCell.all.pluck(:failed)).to eq([false] * 7)
        cell = worker.migration_cell
        expect(cell.id).to_not be_nil
        expect(cell.auditor_type).to eq("authentication")
        expect(cell.completed).to eq(true)
        expect(cell.failed).to eq(false)
        expect(::Auditors::ActiveRecord::AuthenticationRecord.count).to eq(10)
      end

      it "will not run if the migration is already flagged as complete" do
        worker = AuthenticationWorker.new(account.id, date)
        cell = worker.create_cell!
        cell.update_attribute(:completed, true)
        worker.perform
        # no records get transfered because it's already "complete"
        expect(::Auditors::ActiveRecord::AuthenticationRecord.count).to eq(0)
      end

      it "recovers from multiple creates" do
        worker = AuthenticationWorker.new(account.id, date)
        cell1 = worker.create_cell!
        cell2 = worker.create_cell!
        expect(cell1.id).to eq(cell2.id)
      end

      it "reconciles partial successes" do
        worker = AuthenticationWorker.new(account.id, date)
        worker.perform
        expect(::Auditors::ActiveRecord::AuthenticationRecord.count).to eq(10)
        # kill the cell so we can run again
        worker.reset_cell!
        3.times { ::Auditors::Authentication.record(@pseudonym, 'login') }
        # worker reconciles which ones are already in the table and which are not
        worker.perform
        expect(::Auditors::ActiveRecord::AuthenticationRecord.count).to eq(13)
      end
    end

    describe "BackfillEngine" do
      around(:each) do |example|
        Delayed::Job.delete_all
        example.run
        Delayed::Job.delete_all
      end

      it "only uses accounts with an active root account" do
        a1 = account_model(root_account_id: nil, workflow_state: 'active')
        a2 = account_model(root_account_id: nil, workflow_state: 'deleted')
        a3 = account_model(root_account_id: a1.id, workflow_state: 'active')
        a4 = account_model(root_account_id: a2.id, workflow_state: 'active')
        start_date = Time.zone.today
        end_date = start_date - 1.day
        ids = BackfillEngine.new(start_date, end_date).slim_accounts.map(&:id)
        expect(ids).to include(a1.id)
        expect(ids).to include(a3.id)
        expect(ids).to_not include(a2.id)
        expect(ids).to_not include(a4.id)
      end

      it "stops enqueueing after one day with a low threshold" do
        start_date = Time.zone.today
        end_date = start_date - 1.year
        engine = BackfillEngine.new(start_date, end_date)
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
        output = BackfillEngine.summary
        expect(output).to_not be_empty
      end

      it "buckets settings uniformly" do
        pk = BackfillEngine.parallelism_key("grade_changes")
        expect(pk).to eq("auditors_migration_num_strands")
      end

      it "wont enqueue complete jobs" do
        start_date = Time.zone.today
        end_date = start_date - 1.year
        engine = BackfillEngine.new(start_date, end_date)
        account = Account.default
        AuthenticationWorker.new(account.id, start_date).create_cell!.update_attribute(:completed, true)
        CourseWorker.new(account.id, start_date).create_cell!.update_attribute(:completed, true)
        GradeChangeWorker.new(account.id, start_date)
        engine.enqueue_one_day_for_account(account, start_date)
        # only the grade change worker should be enqueued because it's
        # not marked complete
        expect(Delayed::Job.count).to eq(1)
      end

      context "when enqueued" do
        let(:start_date) { Time.zone.today }
        let(:end_date) { start_date - 1.year }
        let(:engine) { BackfillEngine.new(start_date, end_date) }
        let(:sched_job){ Delayed::Job.first }

        before(:each) do
          Delayed::Job.enqueue(engine)
          Setting.set(engine.class.queue_setting_key, -1)
        end

        it "gets full tagname" do
          expect(Delayed::Job.count).to eq(1)
          expect(Delayed::Job.first.tag).to eq(BackfillEngine::SCHEDULAR_TAG)
        end

        context "filling queue" do
          it "schedules multiple jobs a week apart" do
            Setting.set(engine.class.queue_setting_key, 10)
            Delayed::Job.first.update(locked_by: 'test_run', locked_at: Time.now.utc)
            d_worker = Delayed::Worker.new
            d_worker.perform(sched_job)
            expect(Delayed::Job.count).to eq(10)
            dates = engine.class.backfill_jobs.pluck(:handler).map{|h| YAML.unsafe_load(h).instance_variable_get(:@date) }.uniq
            sorted = dates.sort
            expect(sorted.size).to eq(3)
            expect((sorted[1] - sorted[0]).to_i.days).to eq(7.days)
            expect((sorted[2] - sorted[1]).to_i.days).to eq(7.days)
          end
        end

        context "rescheduling" do
          before(:each) do
            d_worker = Delayed::Worker.new
            sched_job.update(locked_by: 'test_run', locked_at: Time.now.utc)
            d_worker.perform(sched_job)
          end

          it "strands by job cluster" do
            new_job = Delayed::Job.where(tag: BackfillEngine::SCHEDULAR_TAG).first
            expect(new_job.strand).to eq("AuditorsBackfillEngine::Job_Shard_#{BackfillEngine.jobs_id}")
          end

          it "enqueues even if it made no progress" do
            expect(Delayed::Job.count).to eq(1)
            expect(Delayed::Job.first.tag).to eq(BackfillEngine::SCHEDULAR_TAG)
            expect(sched_job.id).to_not eq(Delayed::Job.first.id)
          end
        end
      end
    end
  end
end