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

require 'set'

module DataFixup::Auditors
  module Migrate
    DEFAULT_BATCH_SIZE = 1000

    module AuditorWorker
      def initialize(account_id, date)
        @account_id = account_id
        @date = date
      end

      def account
        @_account ||= Account.find(@account_id)
      end

      def cassandra_query_options
        {
          oldest: CanvasTime.try_parse("#{@date.strftime('%Y-%m-%d')} 00:00:00 -0000"),
          newest: CanvasTime.try_parse("#{(@date + 1.day).strftime('%Y-%m-%d')} 00:00:00 -0000")
        }
      end

      # rubocop:disable Lint/NoSleep
      def get_cassandra_records_resiliantly(collection, page_args)
        retries = 0
        max_retries = 10
        begin
          recs = collection.paginate(page_args)
          return recs
        rescue CassandraCQL::Thrift::TimedOutException
          raise if retries >= max_retries
          sleep 1.4 ** retries
          retries += 1
          retry
        end
      end
      # rubocop:enable Lint/NoSleep

      def filter_for_idempotency(ar_attributes_list, auditor_ar_type)
        # we might have inserted some of these already, try again with only new recs
        uuids = ar_attributes_list.map{|h| h['uuid']}
        existing_uuids = auditor_ar_type.where(uuid: uuids).pluck(:uuid)
        ar_attributes_list.reject{|h| existing_uuids.include?(h['uuid']) }
      end

      def migrate_in_pages(collection, auditor_ar_type, batch_size=DEFAULT_BATCH_SIZE)
        next_page = 1
        until next_page.nil?
          page_args = { page: next_page, per_page: batch_size }
          auditor_recs = collection.paginate(page_args)
          ar_attributes_list = auditor_recs.map do |rec|
            auditor_ar_type.ar_attributes_from_event_stream(rec)
          end
          begin
            auditor_ar_type.bulk_insert(ar_attributes_list)
          rescue ActiveRecord::RecordNotUnique, ActiveRecord::InvalidForeignKey
            # this gets messy if we act specifically; let's just apply both remedies
            new_attrs_list = filter_for_idempotency(ar_attributes_list, auditor_ar_type)
            new_attrs_list = filter_dead_foreign_keys(new_attrs_list)
            auditor_ar_type.bulk_insert(new_attrs_list) if new_attrs_list.size > 0
          end
          next_page = auditor_recs.next_page
        end
      end

      def audit_in_pages(collection, auditor_ar_type, batch_size=DEFAULT_BATCH_SIZE)
        @audit_failure_uuids ||= []
        next_page = 1
        until next_page.nil?
          page_args = { page: next_page, per_page: batch_size }
          auditor_recs = collection.paginate(page_args)
          uuids = auditor_recs.map(&:id)
          existing_uuids = auditor_ar_type.where(uuid: uuids).pluck(:uuid)
          @audit_failure_uuids += (uuids - existing_uuids)
          next_page = auditor_recs.next_page
        end
      end

      def cell_attributes
        {
          auditor_type: auditor_type,
          account_id: account.id,
          year: @date.year,
          month: @date.month,
          day: @date.day
        }
      end

      def migration_cell
        ::Auditors::ActiveRecord::MigrationCell.find_by(cell_attributes)
      end

      def create_cell!
        ::Auditors::ActiveRecord::MigrationCell.create!(cell_attributes.merge({ completed: false }))
      end

      def auditors_cassandra_db_lambda
        lambda do
          timeout_value = Setting.get("auditors_backfill_cassandra_timeout", 360).to_i
          opts = { override_options: { 'timeout' => timeout_value } }
          Canvas::Cassandra::DatabaseBuilder.from_config(:auditors, opts)
        end
      end

      def perform
        extend_cassandra_stream_timeout!
        cell = migration_cell
        return if cell&.completed
        cell = create_cell! if cell.nil?
        if account.root_account.created_at > @date + 2.days
          # this account wasn't active on this day, don't
          # waste time migrating
          return cell.update_attribute(:completed, true)
        end
        perform_migration
        cell.update_attribute(:completed, true)
      ensure
        cell.update_attribute(:failed, true) unless cell.completed
        clear_cassandra_stream_timeout!
      end

      def audit
        extend_cassandra_stream_timeout!
        @audit_failure_uuids = []
        perform_audit
        @audit_failure_uuids
      ensure
        clear_cassandra_stream_timeout!
      end

      def extend_cassandra_stream_timeout!
        Canvas::Cassandra::DatabaseBuilder.reset_connections!
        @_stream_db_proc = auditor_cassandra_stream.attr_config_values[:database]
        auditor_cassandra_stream.database(auditors_cassandra_db_lambda)
      end

      def clear_cassandra_stream_timeout!
        raise RuntimeError("stream db never cached!") unless @_stream_db_proc
        Canvas::Cassandra::DatabaseBuilder.reset_connections!
        auditor_cassandra_stream.database(@_stream_db_proc)
      end

      def auditor_cassandra_stream
        stream_map = {
          authentication: Auditors::Authentication::Stream,
          course: Auditors::Course::Stream,
          grade_change: Auditors::GradeChange::Stream
        }
        stream_map[auditor_type]
      end

      def auditor_type
        raise "NOT IMPLEMENTED"
      end

      def perform_migration
        raise "NOT IMPLEMENTED"
      end

      def perform_audit
        raise "NOT IMPLEMENTED"
      end

      def filter_dead_foreign_keys(_attrs_list)
        raise "NOT IMPLEMENTED"
      end
    end

    # account = Account.find(account_id)
    # date = Date.civil(2020, 4, 21)
    # cass_class = Auditors::Authentication
    # ar_class = Auditors::ActiveRecord::AuthenticationRecord
    # worker = AuthenticationWorker.new(account, date)
    # Delayed::Job.enqueue(worker)
    class AuthenticationWorker
      include AuditorWorker

      def auditor_type
        :authentication
      end

      def cassandra_collection
        Auditors::Authentication.for_account(account, cassandra_query_options)
      end

      def perform_migration
        migrate_in_pages(cassandra_collection, Auditors::ActiveRecord::AuthenticationRecord)
      end

      def perform_audit
        audit_in_pages(cassandra_collection, Auditors::ActiveRecord::AuthenticationRecord)
      end

      def filter_dead_foreign_keys(attrs_list)
        user_ids = attrs_list.map{|a| a['user_id'] }
        pseudonym_ids = attrs_list.map{|a| a['pseudonym_id'] }
        existing_user_ids = User.where(id: user_ids).pluck(:id)
        existing_pseud_ids = Pseudonym.where(id: pseudonym_ids).pluck(:id)
        missing_uids = user_ids - existing_user_ids
        missing_pids = pseudonym_ids - existing_pseud_ids
        new_attrs_list = attrs_list.reject{|h| missing_uids.include?(h['user_id']) }
        new_attrs_list.reject{|h| missing_pids.include?(h['pseudonym_id'])}
      end
    end

    class CourseWorker
      include AuditorWorker

      def auditor_type
        :course
      end

      def cassandra_collection
        Auditors::Course.for_account(account, cassandra_query_options)
      end

      def perform_migration
        migrate_in_pages(cassandra_collection, Auditors::ActiveRecord::CourseRecord)
      end

      def perform_audit
        audit_in_pages(cassandra_collection, Auditors::ActiveRecord::CourseRecord)
      end

      def filter_dead_foreign_keys(attrs_list)
        user_ids = attrs_list.map{|a| a['user_id'] }
        existing_user_ids = User.where(id: user_ids).pluck(:id)
        missing_uids = user_ids - existing_user_ids
        attrs_list.reject {|h| missing_uids.include?(h['user_id']) }
      end
    end

    class GradeChangeWorker
      include AuditorWorker

      def auditor_type
        :grade_change
      end

      def cassandra_collection_for(course)
        Auditors::GradeChange.for_course(course, cassandra_query_options)
      end

      def migrateable_courses
        account.courses.where("created_at <= ?", @date + 2.days)
      end

      def perform_migration
        migrateable_courses.find_in_batches do |course_batch|
          course_batch.each do |course|
            migrate_in_pages(cassandra_collection_for(course), Auditors::ActiveRecord::GradeChangeRecord)
          end
        end
      end

      def perform_audit
        migrateable_courses.find_in_batches do |course_batch|
          course_batch.each do |course|
            audit_in_pages(cassandra_collection_for(course), Auditors::ActiveRecord::GradeChangeRecord)
          end
        end
      end

      def filter_dead_foreign_keys(attrs_list)
        student_ids = attrs_list.map{|a| a['student_id'] }
        grader_ids = attrs_list.map{|a| a['grader_id'] }
        user_ids = (student_ids + grader_ids).uniq
        existing_user_ids = User.where(id: user_ids).pluck(:id)
        missing_uids = user_ids - existing_user_ids
        attrs_list.reject do |h|
          missing_uids.include?(h['student_id']) || missing_uids.include?(h['grader_id'])
        end
      end
    end

    # sets up ALL the backfill jobs for the current shard
    # given some date range
    # remember we START with the most recent becuase
    # they're typically most valuable, and walk backwards,
    # so start_date should be > end_date.
    #
    # This job tries to be nice to the db by scheduling a day at a time
    # and if the queue is over the set threshold it will schedule itself to
    # run again in 5 minutes and see if it can schedule in any more.
    # This should keep the queue from growing out of control.
    #
    # Setup is something like:
    # start_date = Date.today
    # end_date = start - 10.months
    # worker = DataFixup::Auditors::Migrate::BackfillEngine.new(start_date, end_date)
    # Delayed::Job.enqueue(worker)
    #
    # It will take care of re-scheduling itself until that backfill window is covered.
    class BackfillEngine
      DEFAULT_DEPTH_THRESHOLD = 100000
      DEFAULT_SCHEDULING_INTERVAL = 150
      # these jobs are all low-priority,
      # so high-ish parallelism is ok
      # (they mostly run in a few minutes or less).
      # we'll wind it down on clusters that are
      # in trouble if necessary.  For clusters
      # taking a long time, grades parallelism
      # could actually be increased very substantially overnight
      # as they will not try to overwrite each other.
      DEFAULT_PARALLELISM_GRADES = 200
      DEFAULT_PARALLELISM_COURSES = 100
      DEFAULT_PARALLELISM_AUTHS = 50
      LOG_PREFIX = "Auditors PG Backfill - ".freeze
      SCHEDULAR_TAG = "DataFixup::Auditors::Migrate::BackfillEngine#perform"
      WORKER_TAGS = [
        "DataFixup::Auditors::Migrate::CourseWorker#perform".freeze,
        "DataFixup::Auditors::Migrate::GradeChangeWorker#perform".freeze,
        "DataFixup::Auditors::Migrate::AuthenticationWorker#perform".freeze
      ].freeze

      class << self
        def non_future_queue
          Delayed::Job.where("run_at <= ?", Time.zone.now)
        end

        def queue_depth
          non_future_queue.count
        end

        def queue_tag_counts
          non_future_queue.group(:tag).count
        end

        def running_tag_counts
          non_future_queue.where('locked_by IS NOT NULL').group(:tag).count
        end

        def backfill_jobs
          non_future_queue.where("tag IN ('#{WORKER_TAGS.join("','")}')")
        end

        def other_jobs
          non_future_queue.where("tag NOT IN ('#{WORKER_TAGS.join("','")}')")
        end

        def schedular_jobs
          Delayed::Job.where(tag: SCHEDULAR_TAG)
        end

        def failed_jobs
          backfill_jobs.failed
        end

        def running_jobs
          backfill_jobs.where("locked_by IS NOT NULL")
        end

        def completed_cells
          Auditors::ActiveRecord::MigrationCell.where(completed: true)
        end

        def failed_cells
          Auditors::ActiveRecord::MigrationCell.where(failed: true, completed: false)
        end

        def jobs_id
          shard = Shard.current
          (shard.respond_to?(:delayed_jobs_shard_id) ? shard.delayed_jobs_shard_id : "")
        end

        def queue_setting_key
          "auditors_backfill_queue_threshold_jobs#{jobs_id}"
        end

        def backfill_key
          "auditors_backfill_interval_seconds_jobs#{jobs_id}"
        end

        def queue_threshold
          Setting.get(queue_setting_key, DEFAULT_DEPTH_THRESHOLD).to_i
        end

        def backfill_interval
          Setting.get(backfill_key, DEFAULT_SCHEDULING_INTERVAL).to_i.seconds
        end

        def cluster_name
          Shard.current.database_server.id
        end

        def parallelism_key(auditor_type)
          "auditors_migration_#{auditor_type}/#{cluster_name}_num_strands"
        end

        def check_parallelism
          {
            grade_changes: Setting.get(parallelism_key("grade_changes"), 1),
            courses: Setting.get(parallelism_key("courses"), 1),
            authentications: Setting.get(parallelism_key("authentications"), 1)
          }
        end

        def longest_running(on_shard: false)
          longest_scope = running_jobs
          if on_shard
            longest_scope = longest_scope.where(shard_id: Shard.current.id)
          end
          longest = longest_scope.order(:locked_at).first
          return {} if longest.blank?
          {
            id: longest.id,
            elapsed_seconds: (Time.now.utc - longest.locked_at),
            locked_by: longest.locked_by
          }
        end

        def update_parallelism!(hash)
          hash.each do |auditor_type, parallelism_value|
            Setting.set(parallelism_key(auditor_type), parallelism_value)
          end
          p_settings = check_parallelism
          gc_tag = 'DataFixup::Auditors::Migrate::GradeChangeWorker#perform'
          Delayed::Job.where(tag: gc_tag, locked_by: nil).update_all(max_concurrent: p_settings[:grade_changes])
          course_tag = 'DataFixup::Auditors::Migrate::CourseWorker#perform'
          Delayed::Job.where(tag: course_tag, locked_by: nil).update_all(max_concurrent: p_settings[:courses])
          auth_tag = 'DataFixup::Auditors::Migrate::AuthenticationWorker#perform'
          Delayed::Job.where(tag: auth_tag, locked_by: nil).update_all(max_concurrent: p_settings[:authentications])
        end

        # only set parallelism if it is not currently set at all.
        # If it's already been set (either from previous preset or
        # by manual action) it will have a > 0 value and this will
        # just exit after checking each setting
        def preset_parallelism!
          if Setting.get(parallelism_key("grade_changes"), -1).to_i < 0
            Setting.set(parallelism_key("grade_changes"), DEFAULT_PARALLELISM_GRADES)
          end
          if Setting.get(parallelism_key("courses"), -1).to_i < 0
            Setting.set(parallelism_key("courses"), DEFAULT_PARALLELISM_COURSES)
          end
          if Setting.get(parallelism_key("authentications"), -1).to_i < 0
            Setting.set(parallelism_key("authentications"), DEFAULT_PARALLELISM_AUTHS)
          end
        end

        def working_dates(current_jobs_scope)
          current_jobs_scope.pluck(:handler).map{|h| YAML.unsafe_load(h).instance_variable_get(:@date) }.uniq
        end

        def shard_summary
          {
            'total_depth': queue_depth,
            'backfill': backfill_jobs.where(shard_id: Shard.current.id).count,
            'others': other_jobs.where(shard_id: Shard.current.id).count,
            'failed': failed_jobs.where(shard_id: Shard.current.id).count,
            'currently_running': running_jobs.where(shard_id: Shard.current.id).count,
            'completed_cells': completed_cells.count,
            'dates_being_worked': working_dates(running_jobs.where(shard_id: Shard.current.id)),
            'config': {
              'threshold': "#{queue_threshold} jobs",
              'interval': "#{backfill_interval} seconds",
              'parallelism': check_parallelism
            },
            'longest_runner': longest_running(on_shard: true),
            'schedular_job_ids': schedular_jobs.where(shard_id: Shard.current.id).map(&:id)
          }
        end

        def summary
          {
            'total_depth': queue_depth,
            'backfill': backfill_jobs.count,
            'others': other_jobs.count,
            'failed': failed_jobs.count,
            'currently_running': running_jobs.count,
            'completed_cells': completed_cells.count,
            'dates_being_worked': working_dates(running_jobs),
            'config': {
              'threshold': "#{queue_threshold} jobs",
              'interval': "#{backfill_interval} seconds",
              'parallelism': check_parallelism
            },
            'longest_runner': longest_running,
            'schedular_job_ids': schedular_jobs.map(&:id)
          }
        end

        def date_summaries(start_date, end_date)
          cur_date = start_date
          output = {}
          while cur_date <= end_date
            cells = completed_cells.where(year: cur_date.year, month: cur_date.month, day: cur_date.day)
            output[cur_date.to_s] = cells.count
            cur_date += 1.day
          end
          output
        end

        def scan_for_holes(start_date, end_date)
          summaries = date_summaries(start_date, end_date)
          max_count = summaries.values.max
          {
            'max_value': max_count,
            'holes': summaries.keep_if{|_,v| v < max_count}
          }
        end

        def log(message)
          Rails.logger.info("#{LOG_PREFIX} #{message}")
        end

        def force_run_schedulars(id)
          d_worker = Delayed::Worker.new
          sched_job = Delayed::Job.find(id)
          sched_job.update(locked_by: 'force_run', locked_at: Time.now.utc)
          d_worker.perform(sched_job)
        end

        def total_reset_frd!
          conn = Auditors::ActiveRecord::GradeChangeRecord.connection
          conn.execute("set role dba")
          conn.truncate(Auditors::ActiveRecord::GradeChangeRecord.table_name)
          conn.truncate(Auditors::ActiveRecord::CourseRecord.table_name)
          conn.truncate(Auditors::ActiveRecord::AuthenticationRecord.table_name)
          conn.truncate(Auditors::ActiveRecord::MigrationCell.table_name)
        end
      end

      def initialize(start_date, end_date)
        if start_date < end_date
          raise "You probably didn't read the comment on this job..."
        end
        @start_date = start_date
        @end_date = end_date
      end

      def log(message)
        self.class.log(message)
      end

      def queue_threshold
        self.class.queue_threshold
      end

      def backfill_interval
        self.class.backfill_interval
      end

      def queue_depth
        self.class.queue_depth
      end

      def slim_accounts
        @_accounts ||= Account.active.select(:id, :root_account_id)
      end

      def cluster_name
        self.class.cluster_name
      end

      def enqueue_one_day(current_date)
        slim_accounts.each do |account|
          if account.root_account?
            # auth records are stored at the root account level,
            # we only need to enqueue these jobs for root accounts
            auth_worker = AuthenticationWorker.new(account.id, current_date)
            Delayed::Job.enqueue(auth_worker, n_strand: ["auditors_migration_authentications", cluster_name], priority: Delayed::LOW_PRIORITY)
          end

          course_worker = CourseWorker.new(account.id, current_date)
          grade_change_worker = GradeChangeWorker.new(account.id, current_date)
          # I think this makes the setting for specifying the n_strand max concurrency
          # apply to the first thing, but splits the constraint by uniqueness including everything in the array?
          Delayed::Job.enqueue(course_worker, n_strand: ["auditors_migration_courses", cluster_name], priority: Delayed::LOW_PRIORITY)
          Delayed::Job.enqueue(grade_change_worker, n_strand: ["auditors_migration_grade_changes", cluster_name], priority: Delayed::LOW_PRIORITY)
        end
      end

      def schedular_strand_tag
        "AuditorsBackfillEngine::Shard_#{Shard.current.id}"
      end

      def perform
        self.class.preset_parallelism!
        log("Scheduling Auditors Backfill!")
        current_date = @start_date
        while current_date >= @end_date
          if queue_depth >= queue_threshold
            log("Queue too deep (#{queue_depth}) for threshold (#{queue_threshold}), throttling...")
            break
          end
          enqueue_one_day(current_date)
          log("Scheduled Backfill for #{current_date} on #{Shard.current.id}")
          current_date -= 1.day
        end
        if current_date >= @end_date
          schedule_worker = BackfillEngine.new(current_date, @end_date)
          next_time = Time.now.utc + backfill_interval
          log("More work to do. Scheduling another job for #{next_time}")
          Delayed::Job.enqueue(schedule_worker, run_at: next_time, priority: Delayed::LOW_PRIORITY, strand: schedular_strand_tag)
        else
          log("WE DID IT.  Shard #{Shard.current.id} has auditors migrated (probably, check the migration cell records to be sure)")
        end
      end
    end

    # useful for generating cassandra records in test environments
    # to make migration practice more real.
    # Probably should never run in production.  Ever.
    class DataFixtures
      # pulled from one day on FFT
      # as a sample size
      AUTH_VOLUME = 275000
      COURSE_VOLUME = 8000
      GRADE_CHANGE_VOLUME = 175000

      def generate_authentications
        puts("generating auth records...")
        pseudonyms = Pseudonym.active.limit(2000)
        event_count = 0
        while event_count < AUTH_VOLUME
          event_record = Auditors::Authentication::Record.generate(pseudonyms.sample, 'login')
          Auditors::Authentication::Stream.insert(event_record, {backend_strategy: :cassandra})
          event_count += 1
          puts("...#{event_count}") if event_count % 1000 == 0
        end
      end

      def generate_courses
        puts("generating course event records...")
        courses = Course.active.limit(1000)
        users = User.active.limit(1000)
        event_count = 0
        while event_count < COURSE_VOLUME
          event_record = Auditors::Course::Record.generate(courses.sample, users.sample, 'published', {}, {})
          Auditors::Course::Stream.insert(event_record, {backend_strategy: :cassandra}) if Auditors.write_to_cassandra?
          event_count += 1
          puts("...#{event_count}") if event_count % 1000 == 0
        end
      end

      def generate_grade_changes
        puts("generating grade change records...")
        assignments = Assignment.active.limit(10000)
        event_count = 0
        while event_count < GRADE_CHANGE_VOLUME
          assignment = assignments.sample
          assignment.submissions.each do |sub|
            event_record = Auditors::GradeChange::Record.generate(sub, 'graded')
            Auditors::GradeChange::Stream.insert(event_record, {backend_strategy: :cassandra}) if Auditors.write_to_cassandra?
            event_count += 1
            puts("...#{event_count}") if event_count % 1000 == 0
          end
        end
      end

      def generate
        generate_authentications
        generate_courses
        generate_grade_changes
      end
    end
  end
end