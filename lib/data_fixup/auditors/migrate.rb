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
    DEFAULT_BATCH_SIZE = 100

    module AuditorWorker
      def initialize(account_id, date, operation_type: :backfill)
        @account_id = account_id
        @date = date
        @_operation = operation_type
      end

      def operation
        @_operation ||= :backfill
      end

      def account
        @_account ||= Account.find(@account_id)
      end

      def previous_sunday
        date_time - date_time.wday.days
      end

      def next_sunday
        previous_sunday + 7.days
      end

      def date_time
        @_dt ||= CanvasTime.try_parse("#{@date.strftime('%Y-%m-%d')} 00:00:00 -0000")
      end

      def cassandra_query_options
        # auditors cassandra partitions span one week.
        # querying a week at a time is more efficient
        # than separately for each day.
        # this query will usually span 2 partitions
        # because the alignment of the partitions is
        # to number of second from epoch % seconds_in_week
        {
          oldest: previous_sunday,
          newest: next_sunday,
          fetch_strategy: :serial
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

      def bulk_insert_auditor_recs(auditor_ar_type, attrs_lists)
        partition_groups = attrs_lists.group_by{|a| auditor_ar_type.infer_partition_table_name(a) }
        partition_groups.each do |partition_name, partition_attrs|
          uuids = partition_attrs.map{|h| h['uuid']}
          Rails.logger.info("INSERTING INTO #{partition_name} #{uuids.size} IDs (#{uuids.join(',')})")
          auditor_ar_type.transaction do
            auditor_ar_type.connection.bulk_insert(partition_name, partition_attrs)
          end
        end
      end

      def migrate_in_pages(collection, auditor_ar_type, batch_size=DEFAULT_BATCH_SIZE)
        next_page = 1
        until next_page.nil?
          page_args = { page: next_page, per_page: batch_size}
          auditor_recs = get_cassandra_records_resiliantly(collection, page_args)
          ar_attributes_list = auditor_recs.map do |rec|
            auditor_ar_type.ar_attributes_from_event_stream(rec)
          end
          begin
            bulk_insert_auditor_recs(auditor_ar_type, ar_attributes_list)
          rescue ActiveRecord::RecordNotUnique, ActiveRecord::InvalidForeignKey
            # this gets messy if we act specifically; let's just apply both remedies
            new_attrs_list = filter_for_idempotency(ar_attributes_list, auditor_ar_type)
            new_attrs_list = filter_dead_foreign_keys(new_attrs_list)
            bulk_insert_auditor_recs(auditor_ar_type, new_attrs_list) if new_attrs_list.size > 0
          end
          next_page = auditor_recs.next_page
        end
      end

      # repairing is run after a scheduling pass.  In most cases this means some records
      # made it over and then the scheduled migration job failed, usually due to
      # repeated cassandra timeouts.  For this reason, we don't wish to load ALL
      # scanned records from cassandra, only those that are not yet in the database.
      # therefore "repair" is much more careful.  It scans each batch of IDs from the cassandra
      # index, sees which ones aren't currently in postgres, and then only loads attributes for
      # that subset to insert.  This makes it much faster for traversing a large dataset
      # when some or most of the records are filled in already.  Obviously it would be somewhat
      # slower than the migrate pass if there were NO records migrated.
      def repair_in_pages(ids_collection, stream_type, auditor_ar_type, batch_size=DEFAULT_BATCH_SIZE)
        next_page = 1
        until next_page.nil?
          page_args = { page: next_page, per_page: batch_size}
          auditor_id_recs = get_cassandra_records_resiliantly(ids_collection, page_args)
          collect_propsed_ids = auditor_id_recs.map{|rec| rec['id']}
          existing_ids = auditor_ar_type.where(uuid: collect_propsed_ids).pluck(:uuid)
          insertable_ids = collect_propsed_ids - existing_ids
          if insertable_ids.size > 0
            auditor_recs = stream_type.fetch(insertable_ids, strategy: :serial)
            ar_attributes_list = auditor_recs.map do |rec|
              auditor_ar_type.ar_attributes_from_event_stream(rec)
            end
            begin
              bulk_insert_auditor_recs(auditor_ar_type, ar_attributes_list)
            rescue ActiveRecord::RecordNotUnique, ActiveRecord::InvalidForeignKey
              # this gets messy if we act specifically; let's just apply both remedies
              new_attrs_list = filter_for_idempotency(ar_attributes_list, auditor_ar_type)
              new_attrs_list = filter_dead_foreign_keys(new_attrs_list)
              bulk_insert_auditor_recs(auditor_ar_type, new_attrs_list) if new_attrs_list.size > 0
            end
          end
          next_page = auditor_id_recs.next_page
        end
      end

      def audit_in_pages(ids_collection, auditor_ar_type, batch_size=DEFAULT_BATCH_SIZE)
        @audit_results ||= {
          'uuid_count' => 0,
          'failure_count' => 0,
          'missed_ids' => []
        }
        audit_failure_uuids = []
        audit_uuid_count = 0
        next_page = 1
        until next_page.nil?
          page_args = { page: next_page, per_page: batch_size}
          auditor_id_recs = get_cassandra_records_resiliantly(ids_collection, page_args)
          uuids = auditor_id_recs.map{|rec| rec['id']}
          audit_uuid_count += uuids.size
          existing_uuids = auditor_ar_type.where(uuid: uuids).pluck(:uuid)
          audit_failure_uuids += (uuids - existing_uuids)
          next_page = auditor_id_recs.next_page
        end
        @audit_results['uuid_count'] += audit_uuid_count
        @audit_results['failure_count'] += audit_failure_uuids.size
        @audit_results['missed_ids'] += audit_failure_uuids
      end

      def cell_attributes(target_date: nil)
        target_date = @date if target_date.nil?
        {
          auditor_type: auditor_type,
          account_id: account.id,
          year: target_date.year,
          month: target_date.month,
          day: target_date.day
        }
      end

      def find_migration_cell(attributes: cell_attributes)
        attributes = cell_attributes if attributes.nil?
        ::Auditors::ActiveRecord::MigrationCell.find_by(attributes)
      end

      def migration_cell
        @_cell ||= find_migration_cell
      end

      def create_cell!(attributes: nil)
        attributes = cell_attributes if attributes.nil?
        ::Auditors::ActiveRecord::MigrationCell.create!(attributes.merge({ completed: false, repaired: false }))
      rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
        created_cell = find_migration_cell(attributes: attributes)
        raise "unresolvable auditors migration state #{attributes}" if created_cell.nil?
        created_cell
      end

      def reset_cell!
        migration_cell&.destroy
        @_cell = nil
      end

      def mark_cell_queued!(delayed_job_id: nil)
        (@_cell = create_cell!) if migration_cell.nil?
        migration_cell.update_attribute(:failed, false) if migration_cell.failed
        # queueing will take care of a week, so let's make sure we don't get
        # other jobs vying for the same slot
        current_date = previous_sunday
        while current_date < next_sunday do
          cur_cell_attrs =  cell_attributes(target_date: current_date)
          current_cell = find_migration_cell(attributes: cur_cell_attrs)
          current_cell = create_cell!(attributes: cur_cell_attrs) if current_cell.nil?
          current_cell.update(completed: false, failed: false, job_id: delayed_job_id, queued: true)
          current_date += 1.day
        end
        @_cell.reload
      end

      def auditors_cassandra_db_lambda
        lambda do
          timeout_value = Setting.get("auditors_backfill_cassandra_timeout", 360).to_i
          opts = { override_options: { 'timeout' => timeout_value } }
          Canvas::Cassandra::DatabaseBuilder.from_config(:auditors, opts)
        end
      end

      def already_complete?
        migration_cell&.completed
      end

      def currently_queueable?
        return true if migration_cell.nil?
        return true if migration_cell.failed
        if operation == :repair
          return false if migration_cell.repaired
        else
          return false if migration_cell.completed
        end
        return true unless migration_cell.queued
        # this cell is currently in the queue (maybe)
        # If that update happened more than a few
        # days ago, it's likely dead, and should
        # get rescheduled.  Worst case
        # it scans and fails to find anything to do,
        # and marks the cell complete.
        return migration_cell.updated_at < 3.days.ago
      end

      def mark_week_complete!
        current_date = previous_sunday
        while current_date < next_sunday do
          cur_cell_attrs =  cell_attributes(target_date: current_date)
          current_cell = find_migration_cell(attributes: cur_cell_attrs)
          current_cell = create_cell!(attributes: cur_cell_attrs) if current_cell.nil?
          repaired = (operation == :repair)
          current_cell.update(completed: true, failed: false, repaired: repaired)
          current_date += 1.day
        end
      end

      def mark_week_audited!(results)
        current_date = previous_sunday
        failed_count = results['failure_count']
        while current_date < next_sunday do
          cur_cell_attrs =  cell_attributes(target_date: current_date)
          current_cell = find_migration_cell(attributes: cur_cell_attrs)
          current_cell = create_cell!(attributes: cur_cell_attrs) if current_cell.nil?
          current_cell.update(audited: true, missing_count: failed_count)
          current_date += 1.day
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
        if operation == :repair
          perform_repair
        elsif operation == :backfill
          perform_migration
        else
          raise "Unknown Auditor Backfill Operation: #{operation}"
        end
        # the reason this works is the rescheduling plan.
        # if the job passes, the whole week gets marked "complete".
        # If it fails, the target cell for this one job will get rescheduled
        # later in the reconciliation pass.
        # at that time it will again run for this whole week.
        # any failed day results in a job spanning a week.
        # If a job for another day in the SAME week runs,
        # and this one is done already, it will quickly short circuit because this
        # day is marked complete.
        # If two jobs from the same week happened to run at the same time,
        # they would contend over Uniqueness violations, which we catch and handle.
        mark_week_complete!
      ensure
        cell.update_attribute(:failed, true) unless cell.reload.completed
        cell.update_attribute(:queued, false)
        clear_cassandra_stream_timeout!
      end

      def audit
        extend_cassandra_stream_timeout!
        @audit_results = {
          'uuid_count' => 0,
          'failure_count' => 0,
          'missed_ids' => []
        }
        perform_audit
        mark_week_audited!(@audit_results)
        return @audit_results
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

      def perform_repair
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

      def cassandra_id_collection
        Auditors::Authentication::Stream.ids_for_account(account, cassandra_query_options)
      end

      def perform_migration
        migrate_in_pages(cassandra_collection, Auditors::ActiveRecord::AuthenticationRecord)
      end

      def perform_repair
        repair_in_pages(cassandra_id_collection, Auditors::Authentication::Stream, Auditors::ActiveRecord::AuthenticationRecord)
      end

      def perform_audit
        audit_in_pages(cassandra_id_collection, Auditors::ActiveRecord::AuthenticationRecord)
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

      def cassandra_id_collection
        Auditors::Course::Stream.ids_for_account(account, cassandra_query_options)
      end

      def perform_migration
        migrate_in_pages(cassandra_collection, Auditors::ActiveRecord::CourseRecord)
      end

      def perform_repair
        repair_in_pages(cassandra_id_collection, Auditors::Course::Stream, Auditors::ActiveRecord::CourseRecord)
      end

      def perform_audit
        audit_in_pages(cassandra_id_collection, Auditors::ActiveRecord::CourseRecord)
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

      def cassandra_id_collection_for(course)
        Auditors::GradeChange::Stream.ids_for_course(course, cassandra_query_options)
      end

      def migrateable_course_ids
        s_scope = Submission.where("course_id=courses.id").where("updated_at > ?", @date - 7.days)
        account.courses.active.where(
          "EXISTS (?)", s_scope).where(
          "courses.created_at <= ?", @date + 2.days).pluck(:id)
      end

      def perform_migration
        all_course_ids = migrateable_course_ids.to_a
        all_course_ids.in_groups_of(1000) do |course_ids|
          Course.where(id: course_ids).each do |course|
            migrate_in_pages(cassandra_collection_for(course), Auditors::ActiveRecord::GradeChangeRecord)
          end
        end
      end

      def perform_repair
        all_course_ids = migrateable_course_ids.to_a
        all_course_ids.in_groups_of(1000) do |course_ids|
          Course.where(id: course_ids).each do |course|
            repair_in_pages(cassandra_id_collection_for(course), Auditors::GradeChange::Stream, Auditors::ActiveRecord::GradeChangeRecord)
          end
        end
      end

      def perform_audit
        all_course_ids = migrateable_course_ids.to_a
        all_course_ids.in_groups_of(1000) do |course_ids|
          Course.where(id: course_ids).each do |course|
            audit_in_pages(cassandra_id_collection_for(course), Auditors::ActiveRecord::GradeChangeRecord)
          end
        end
      end

      def filter_dead_foreign_keys(attrs_list)
        student_ids = attrs_list.map{|a| a['student_id'] }
        grader_ids = attrs_list.map{|a| a['grader_id'] }
        user_ids = (student_ids + grader_ids).uniq
        existing_user_ids = User.where(id: user_ids).pluck(:id)
        missing_uids = user_ids - existing_user_ids
        filtered_attrs_list = attrs_list.reject do |h|
          missing_uids.include?(h['student_id']) || missing_uids.include?(h['grader_id'])
        end
        submission_ids = filtered_attrs_list.map{|a| a['submission_id'] }
        existing_submission_ids = Submission.where(id: submission_ids).pluck(:id)
        missing_sids = submission_ids - existing_submission_ids
        filtered_attrs_list.reject {|h| missing_sids.include?(h['submission_id']) }
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
      DEFAULT_PARALLELISM_GRADES = 20
      DEFAULT_PARALLELISM_COURSES = 10
      DEFAULT_PARALLELISM_AUTHS = 5
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
          Delayed::Job::Failed.where("tag IN ('#{WORKER_TAGS.join("','")}')")
        end

        def failed_schedulars
          Delayed::Job::Failed.where(tag: SCHEDULAR_TAG)
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
          (shard.respond_to?(:delayed_jobs_shard_id) ? shard.delayed_jobs_shard_id : "NONE")
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
          "auditors_migration_num_strands"
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
            'schedular_count': schedular_jobs.where(shard_id: Shard.current.id).count,
            'schedular_job_ids': schedular_jobs.where(shard_id: Shard.current.id).limit(10).map(&:id)
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
            # it does not work to check these with jobs from other shards
            # because deserializing them fails to find accounts
            'dates_being_worked': working_dates(running_jobs.where(shard_id: Shard.current.id)),
            'config': {
              'threshold': "#{queue_threshold} jobs",
              'interval': "#{backfill_interval} seconds",
              'parallelism': check_parallelism
            },
            'longest_runner': longest_running,
            'schedular_count': schedular_jobs.count,
            'schedular_job_ids': schedular_jobs.limit(10).map(&:id)
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

      def initialize(start_date, end_date, operation_type: :schedule)
        if start_date < end_date
          raise "You probably didn't read the comment on this job..."
        end
        @start_date = start_date
        @end_date = end_date
        @_operation = operation_type
      end

      def operation
        @_operation ||= :schedule
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
        return @_accounts if @_accounts
        root_account_ids = Account.root_accounts.active.pluck(:id)
        @_accounts = Account.active.where(
          "root_account_id IS NULL OR root_account_id IN (?)", root_account_ids
        ).select(:id, :root_account_id)
      end

      def cluster_name
        self.class.cluster_name
      end

      def conditionally_enqueue_worker(worker, n_strand)
        if worker.currently_queueable?
          job = Delayed::Job.enqueue(worker, n_strand: n_strand, priority: Delayed::LOW_PRIORITY)
          worker.mark_cell_queued!(delayed_job_id: job.id)
        end
      end

      def generate_worker(worker_type, account, current_date)
        worker_operation = (operation == :repair) ? :repair : :backfill
        worker_type.new(account.id, current_date, operation_type: worker_operation)
      end

      def enqueue_one_day_for_account(account, current_date)
        if account.root_account?
          # auth records are stored at the root account level,
          # we only need to enqueue these jobs for root accounts
          auth_worker = generate_worker(AuthenticationWorker, account, current_date)
          conditionally_enqueue_worker(auth_worker, "auditors_migration")
        end

        course_worker = generate_worker(CourseWorker, account, current_date)
        conditionally_enqueue_worker(course_worker, "auditors_migration")
        grade_change_worker = generate_worker(GradeChangeWorker, account, current_date)
        conditionally_enqueue_worker(grade_change_worker, "auditors_migration")
      end

      def enqueue_one_day(current_date)
        slim_accounts.each do |account|
          enqueue_one_day_for_account(account, current_date)
        end
      end

      def schedular_strand_tag
        "AuditorsBackfillEngine::Job_Shard_#{self.class.jobs_id}"
      end

      def next_schedule_date(current_date)
        # each job spans a week, so when we're scheduling
        # the initial job we can schedule one week at a time.
        # In a repair pass, we want to make sure we hit every
        # cell that failed, or that never got queued (just in case),
        # so we actually line up jobs for each day that is
        # missing/failed.  It's possible to schedule multiple jobs
        # for the same week.  If one completes before the next one starts,
        # they will bail immediately.  If two from the same week are running
        # at the same time the uniqueness-constraint-and-conflict-handling
        # prevents them from creating duplicates
        if operation == :schedule
          current_date - 7.days
        elsif operation == :repair
          current_date - 1.day
        else
          raise "Unknown backfill operation: #{operation}"
        end
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
          # jobs span a week now, we can schedule them at week intervals arbitrarily
          current_date = next_schedule_date(current_date)
        end
        if current_date >= @end_date
          schedule_worker = BackfillEngine.new(current_date, @end_date)
          next_time = Time.now.utc + backfill_interval
          log("More work to do. Scheduling another job for #{next_time}")
          Delayed::Job.enqueue(schedule_worker, run_at: next_time, priority: Delayed::LOW_PRIORITY, n_strand: schedular_strand_tag, max_attempts: 5)
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