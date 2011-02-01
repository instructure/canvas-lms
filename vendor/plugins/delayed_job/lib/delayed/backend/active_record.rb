require 'active_record'

class ActiveRecord::Base
  def self.load_for_delayed_job(id)
    if id
      find(id)
    else
      super
    end
  end
  
  def dump_for_delayed_job
    "#{self.class};#{id}"
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

        # if true, we'll use the more efficient 'select ... for update' form
        # rather than selecting 5 rows and trying to lock each one in turn.
        # there's some deadlock issues with this right now though.
        cattr_accessor :use_row_locking
        self.use_row_locking = false

        named_scope :ready_to_run, lambda {|worker_name, max_run_time|
          {:conditions => ['(run_at <= ? AND (locked_at IS NULL OR locked_at < ?) OR locked_by = ?) AND failed_at IS NULL', db_time_now, db_time_now - max_run_time, worker_name]}
        }
        named_scope :by_priority, :order => 'priority ASC, run_at ASC'

        # When a worker is exiting, make sure we don't have any locked jobs.
        def self.clear_locks!(worker_name)
          update_all("locked_by = null, locked_at = null", ["locked_by = ?", worker_name])
        end

        def self.get_and_lock_next_available(worker_name,
                                             max_run_time = Worker.max_run_time,
                                             queue = nil)
          if self.use_row_locking
            scope = self.all_available(worker_name, max_run_time, queue)

            ::ActiveRecord::Base.silence do
              # it'd be a big win to do this in a DB function and avoid the extra
              # round trip.
              transaction do
                job = scope.find(:first, :lock => true)
                if job
                  job.update_attributes(:locked_at => db_time_now,
                                        :locked_by => worker_name)
                end
                job
              end
            end
          else
            job = find_available(worker_name, 5, max_run_time, queue).detect do |job|
              if job.lock_exclusively!(max_run_time, worker_name)
                true
              else
                false
              end
            end
            job
          end
        end

        def self.find_available(worker_name,
                                limit = 5,
                                max_run_time = Worker.max_run_time,
                                queue = nil)
          all_available(worker_name, max_run_time, queue).all(:limit => limit)
        end

        def self.all_available(worker_name,
                               max_run_time = Worker.max_run_time,
                               queue = nil)
          scope = self.ready_to_run(worker_name, max_run_time)
          scope = scope.scoped(:conditions => ['priority >= ?', Worker.min_priority]) if Worker.min_priority
          scope = scope.scoped(:conditions => ['priority <= ?', Worker.max_priority]) if Worker.max_priority
          scope = scope.scoped(:conditions => ['queue = ?', queue]) if queue
          scope = scope.scoped(:conditions => ['queue is null']) unless queue
          scope.by_priority
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
            return true
          else
            return false
          end
        end

        # Get the current time (GMT or local depending on DB)
        # Note: This does not ping the DB to get the time, so all your clients
        # must have syncronized clocks.
        def self.db_time_now
          if Time.zone
            Time.zone.now
          elsif ::ActiveRecord::Base.default_timezone == :utc
            Time.now.utc
          else
            Time.now
          end
        end

      end
    end
  end
end
