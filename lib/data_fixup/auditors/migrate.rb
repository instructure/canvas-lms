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
          rescue ActiveRecord::StatementInvalid
            # we might have inserted some of these already, try again with only new recs
            uuids = ar_attributes_list.map{|h| h['uuid']}
            existing_uuids = auditor_ar_type.where(uuid: uuids).map(&:uuid)
            new_attrs_list = ar_attributes_list.reject{|h| existing_uuids.include?(h['uuid']) }
            auditor_ar_type.bulk_insert(new_attrs_list) if new_attrs_list.size > 0
          end
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

      def perform
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
      end

      def auditor_type
        raise "NOT IMPLEMENTED"
      end

      def perform_migration
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

      def perform_migration
        collection = Auditors::Authentication.for_account(account, cassandra_query_options)
        migrate_in_pages(collection, Auditors::ActiveRecord::AuthenticationRecord)
      end
    end

    class CourseWorker
      include AuditorWorker

      def auditor_type
        :course
      end

      def perform_migration
        collection = Auditors::Course.for_account(account, cassandra_query_options)
        migrate_in_pages(collection, Auditors::ActiveRecord::CourseRecord)
      end
    end

    class GradeChangeWorker
      include AuditorWorker

      def auditor_type
        :grade_change
      end

      def perform_migration
        account.courses.where("created_at <= ?", @date + 2.days).find_in_batches do |course_batch|
          course_batch.each do |course|
            collection = Auditors::GradeChange.for_course(course, cassandra_query_options)
            migrate_in_pages(collection, Auditors::ActiveRecord::GradeChangeRecord)
          end
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
      WORKER_TAGS = [
        "DataFixup::Auditors::Migrate::CourseWorker#perform".freeze,
        "DataFixup::Auditors::Migrate::GradeChangeWorker#perform".freeze,
        "DataFixup::Auditors::Migrate::AuthenticationWorker#perform".freeze
      ].freeze

      class << self
        def queue_depth
          Delayed::Job.where("run_at < ?", Time.zone.now).count
        end

        def backfill_jobs
          Delayed::Job.where("tag IN ('#{WORKER_TAGS.join("','")}')")
        end

        def other_jobs
          Delayed::Job.where("tag NOT IN ('#{WORKER_TAGS.join("','")}')")
        end

        def schedular_jobs
          Delayed::Job.where(tag: "DataFixup::Auditors::Migrate::BackfillEngine#perform")
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
          Shard.current.database_server_id
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

      def singleton_tag
        "AuditorsBackfillEngine::Shard_#{Shard.current.id}::Range_#{@start_date}_#{@end_date}"
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
          next_time = Time.now.utc + 5.minutes
          log("More work to do. Scheduling another job for #{next_time}")
          Delayed::Job.enqueue(schedule_worker, run_at: next_time, priority: Delayed::LOW_PRIORITY, singleton: singleton_tag)
        else
          log("WE DID IT.  Shard #{Shard.current.id} has auditors migrated (probably, check the migration cell records to be sure)")
        end
      end
    end

  end
end