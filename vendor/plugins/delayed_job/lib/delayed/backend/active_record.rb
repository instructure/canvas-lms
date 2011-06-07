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
          { :conditions => ["run_at <= ? AND failed_at IS NULL", db_time_now] }
        }

        named_scope :future, lambda {
          { :conditions => ["run_at > ? AND failed_at IS NULL", db_time_now] }
        }

        named_scope :failed, :conditions => ["failed_at IS NOT NULL"]

        named_scope :not_running, :conditions => ["locked_at is NULL"]

        named_scope :running, :conditions => ["locked_at is NOT NULL and locked_by <> 'on hold'"]

        # this query could be a bit more efficient if we didn't check for the
        # locked_at/max_run_time condition, and instead had a periodic job to
        # unlock and reschedule jobs that are stuck due to a dead worker.
        named_scope :ready_to_run, lambda {|worker_name, max_run_time|
          {:conditions => ['(run_at <= ? AND (locked_at IS NULL OR locked_at < ?)) AND failed_at IS NULL', db_time_now, db_time_now - max_run_time]}
        }
        named_scope :strand_ready, { :conditions => ["strand IS NULL or strand NOT IN (SELECT strand FROM #{table_name} WHERE locked_at IS NOT NULL AND locked_by <> 'on hold' AND strand IS NOT NULL)"] }
        # we have to order by id, because if a bunch of jobs on the same strand
        # have the exact same run_at time, we could otherwise end up always
        # getting back the subsequent jobs and never the first initial job that
        # needs to run
        named_scope :by_priority, :order => 'priority ASC, run_at ASC, id ASC'

        # When a worker is exiting, make sure we don't have any locked jobs.
        def self.clear_locks!(worker_name)
          update_all("locked_by = null, locked_at = null", ["locked_by = ?", worker_name])
        end

        def self.get_and_lock_next_available(worker_name,
                                             max_run_time,
                                             queue = nil,
                                             min_priority = nil,
                                             max_priority = nil)
          loop do
            jobs = find_available(worker_name, 5, max_run_time, queue, min_priority, max_priority)
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
          scope.strand_ready.by_priority
        end

        # Lock this job for this worker.
        # Returns true if we have the lock, false otherwise.
        def lock_exclusively!(max_run_time, worker)
          now = self.class.db_time_now
          affected_rows = if locked_by != worker
            # We don't own this job so we will update the locked_by name and the locked_at
            self.class.update_all(["locked_at = ?, locked_by = ?", now, worker], ["id = ? and (locked_at is null or locked_at < ?) and (run_at <= ?)", id, (now - max_run_time.to_i), now])
          else
            # We already own this job, this may happen if the job queue crashes.
            # Simply resume and update the locked_at
            self.class.update_all(["locked_at = ?", now], ["id = ? and locked_by = ?", id, worker])
          end
          if affected_rows == 1
            self.locked_at    = now
            self.locked_by    = worker
            # we cheated ActiveRecord::Dirty with the update_all calls above, so
            # we'll fix things up here.
            changed_attributes['locked_at'] = now
            changed_attributes['locked_by'] = worker

            # if this job is part of a strand, make sure no earlier jobs in the
            # strand are running.
            if self.strand.present?
              blocking_job = self.class.first(:conditions => ["strand = ? AND id < ? and failed_at is null", self.strand, self.id], :order => 'run_at desc')
              if blocking_job
                self.locked_at = self.locked_by = nil
                if self.run_at < blocking_job.run_at
                  self.run_at = blocking_job.run_at.advance(:seconds => 1)
                end
                self.save
                return false
              end
            end

            return true
          else
            return false
          end
        end

        # Get the current time (GMT or local depending on DB)
        # Note: This does not ping the DB to get the time, so all your clients
        # must have syncronized clocks.
        def self.db_time_now
          Time.now.in_time_zone
        end

      end
    end
  end
end
