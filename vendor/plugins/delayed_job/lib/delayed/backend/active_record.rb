require 'active_record'

class ActiveRecord::Base
  def self.load_for_delayed_job(id)
    if id
      find(id)
    else
      super
    end
  end
end

module Delayed
  module Backend
    module ActiveRecord
      # A job object that is persisted to the database.
      # Contains the work object as a YAML field.
      class Job < ::ActiveRecord::Base
        include Delayed::Backend::Base
        set_table_name :delayed_jobs

        cattr_accessor :default_priority
        self.default_priority = 0

        named_scope :current, lambda {
          { :conditions => ["run_at <= ?", db_time_now] }
        }

        named_scope :future, lambda {
          { :conditions => ["run_at > ?", db_time_now] }
        }

        named_scope :failed, :conditions => ["failed_at IS NOT NULL"]

        named_scope :running, :conditions => ["locked_at is NOT NULL AND locked_by <> 'on hold'"]

        # a nice stress test:
        # 10_000.times { |i| Kernel.send_later_enqueue_args(:system, { :strand => 's1', :run_at => (24.hours.ago + (rand(24.hours.to_i))) }, "echo #{i} >> test1.txt") }
        # 500.times { |i| "ohai".send_later_enqueue_args(:reverse, { :run_at => (12.hours.ago + (rand(24.hours.to_i))) }) }
        # then fire up your workers
        # you can check out strand correctness: diff test1.txt <(sort -n test1.txt)
        named_scope :ready_to_run, lambda {|worker_name, max_run_time|
          { :conditions => ["run_at <= ? AND locked_at IS NULL AND (strand IS NULL OR (SELECT id FROM #{table_name} j2 WHERE j2.strand = #{table_name}.strand ORDER BY j2.strand, j2.id ASC LIMIT 1) = id)", db_time_now] }
        }
        named_scope :by_priority, :order => 'priority ASC, run_at ASC'

        # When a worker is exiting, make sure we don't have any locked jobs.
        def self.clear_locks!(worker_name)
          update_all("locked_by = null, locked_at = null", ["locked_by = ?", worker_name])
        end

        def self.unlock_expired_jobs(max_run_time = Delayed::Worker.max_run_time)
          update_all("locked_by = null, locked_at = null", ["locked_by <> 'on hold' AND locked_at < ?", db_time_now - max_run_time])
        end

        def self.get_and_lock_next_available(worker_name,
                                             max_run_time,
                                             queue = nil,
                                             min_priority = nil,
                                             max_priority = nil)
          @batch_size ||= Setting.get_cached('jobs_get_next_batch_size', '5').to_i
          loop do
            jobs = Rails.logger.silence do
              find_available(worker_name, @batch_size, max_run_time, queue, min_priority, max_priority)
            end
            return nil if jobs.empty?
            job = jobs.detect do |job|
              job.lock_exclusively!(max_run_time, worker_name)
            end
            return job if job
          end
        end

        def self.find_available(worker_name,
                                limit,
                                max_run_time,
                                queue = nil,
                                min_priority = nil,
                                max_priority = nil)
          all_available(worker_name, max_run_time, queue, min_priority, max_priority).all(:limit => limit)
        end

        def self.all_available(worker_name,
                               max_run_time,
                               queue = nil,
                               min_priority = nil,
                               max_priority = nil)
          scope = self.ready_to_run(worker_name, max_run_time)
          scope = scope.scoped(:conditions => ['priority >= ?', min_priority]) if min_priority
          scope = scope.scoped(:conditions => ['priority <= ?', max_priority]) if max_priority
          scope = scope.scoped(:conditions => ['queue = ?', queue]) if queue
          scope = scope.scoped(:conditions => ['queue is null']) unless queue
          scope.by_priority
        end

        # Lock this job for this worker.
        # Returns true if we have the lock, false otherwise.
        #
        # It's important to note that for performance reasons, this method does
        # not re-check the strand constraints -- so you could manually lock a
        # job using this method that isn't the next to run on its strand.
        def lock_exclusively!(max_run_time, worker)
          now = self.class.db_time_now
          # We don't own this job so we will update the locked_by name and the locked_at
          affected_rows = Rails.logger.silence do
            self.class.update_all(["locked_at = ?, locked_by = ?", now, worker], ["id = ? and locked_at is null and run_at <= ?", id, now])
          end
          if affected_rows == 1
            self.locked_at    = now
            self.locked_by    = worker
            # we cheated ActiveRecord::Dirty with the update_all calls above, so
            # we'll fix things up here.
            changed_attributes['locked_at'] = now
            changed_attributes['locked_by'] = worker

            return true
          else
            return false
          end
        end

        def fail!
          attrs = self.attributes
          attrs['original_id'] = attrs.delete('id')
          attrs['failed_at'] ||= self.class.db_time_now
          self.class.transaction do
            Failed.create(attrs)
            self.destroy
          end
        end

        # Get the current time (GMT or local depending on DB)
        # Note: This does not ping the DB to get the time, so all your clients
        # must have syncronized clocks.
        def self.db_time_now
          Time.now.in_time_zone
        end

        class Failed < Job
          include Delayed::Backend::Base
          set_table_name :failed_jobs
        end
      end

    end
  end
end
