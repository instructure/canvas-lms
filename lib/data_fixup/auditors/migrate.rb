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
      LOG_PREFIX = "Auditors PG Backfill - ".freeze
      def initialize(start_date, end_date)
        if start_date < end_date
          raise "You probably didn't read the comment on this job..."
        end
        @start_date = start_date
        @end_date = end_date
      end

      def queue_setting_key
        shard = Shard.current
        jobs_id = (shard.respond_to?(:delayed_jobs_shard_id) ? shard.delayed_jobs_shard_id : "")
        "auditors_backfill_queue_threshold_jobs#{jobs_id}"
      end

      def queue_threshold
        Setting.get(queue_setting_key, DEFAULT_DEPTH_THRESHOLD).to_i
      end

      def queue_depth
        Delayed::Job.where("run_at < ?", Time.zone.now).count
      end

      def slim_accounts
        @_accounts ||= Account.active.select(:id, :root_account_id)
      end

      def cluster_name
        Shard.current.database_server_id
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

      def perform
        Rails.logger.info("#{LOG_PREFIX} Scheduling Auditors Backfill!")
        current_date = @start_date
        while current_date >= @end_date
          break if queue_depth >= queue_threshold
          enqueue_one_day(current_date)
          Rails.logger.info("#{LOG_PREFIX} Scheduled Backfill for #{current_date} on #{Shard.current.id}")
          current_date -= 1.day
        end
        if current_date >= @end_date
          schedule_worker = BackfillEngine.new(current_date, @end_date)
          next_time = Time.now.utc + 5.minutes
          Rails.logger.info("#{LOG_PREFIX} More work to do. Scheduling another job for #{next_time}")
          Delayed::Job.enqueue(schedule_worker, run_at: next_time, priority: Delayed::LOW_PRIORITY)
        else
          Rails.logger.info("#{LOG_PREFIX} WE DID IT.  Shard #{Shard.current.id} has auditors migrated (probably, check the migration cell records to be sure)")
        end
      end
    end

  end
end