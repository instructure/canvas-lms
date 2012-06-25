require 'active_record'
require 'hair_trigger'

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
        attr_writer :current_shard

        def current_shard
          @current_shard || Shard.default
        end

        # be aware that some strand functionality is controlled by triggers on
        # the database. see
        # db/migrate/20110831210257_add_delayed_jobs_next_in_strand.rb
        #
        # next_in_strand defaults to true. if we insert a new job, and it has a
        # strand, and it's not the next in the strand, we set it to false.
        #
        # if we delete a job, and it has a strand, mark the next job in that
        # strand to be next_in_strand
        # (this is safe even if we're not deleting the job that was currently
        # next_in_strand)

        # special mysql support, since its triggers don't support modifying the
        # underlying table from within the trigger.
        # this means that deleting the first job from a strand from
        # outside rails is *not* safe when using mysql for the queue.
        after_destroy :update_strand_on_destroy
        cattr_accessor :adapter_name
        def update_strand_on_destroy
          if adapter_name.nil?
            self.class.adapter_name = connection.adapter_name
          end
          if strand.present? && next_in_strand? && adapter_name == 'MySQL'
            # this funky sub-sub-select is to force mysql to create a temporary
            # table, otherwise it fails complaining that you can't select from
            # the same table you are updating
            connection.execute(sanitize_sql(["UPDATE delayed_jobs SET next_in_strand = 1 WHERE id = (SELECT _id.id FROM (SELECT id FROM delayed_jobs j2 WHERE j2.strand = ? ORDER BY j2.strand, j2.id ASC LIMIT 1) AS _id)", strand]))
          end
        end

        # postgresql needs this lock to be taken before the before_insert
        # trigger starts, or we risk deadlock inside of the trigger when trying
        # to raise the lock level
        before_create :lock_strand_on_create
        def lock_strand_on_create
          if adapter_name.nil?
            self.class.adapter_name = connection.adapter_name
          end
          if strand.present? && adapter_name == 'PostgreSQL'
            connection.execute(sanitize_sql(["SELECT pg_advisory_xact_lock(half_md5_as_bigint(?))", strand]))
          end
        end

        cattr_accessor :default_priority
        self.default_priority = Delayed::NORMAL_PRIORITY

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
          { :conditions => ["run_at <= ? AND locked_at IS NULL AND next_in_strand = ?", db_time_now, true] }
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

          min_priority ||= Delayed::MIN_PRIORITY
          max_priority ||= Delayed::MAX_PRIORITY

          @batch_size ||= Setting.get_cached('jobs_get_next_batch_size', '5').to_i
          loop do
            jobs = find_available(worker_name, @batch_size, max_run_time, queue, min_priority, max_priority)
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

        # Clear all pending jobs for a specified strand
        #
        # Note that it *does* not clear out currently running or held jobs, for
        # synchronization purposes: If you're using a strand for a "singleton" job,
        # the currently running instance should complete, before the next instance
        # starts.
        def self.clear_strand!(strand_name)
          self.delete_all(['strand=? AND locked_at IS NULL', strand_name])
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
          affected_rows = self.class.update_all(["locked_at = ?, locked_by = ?", now, worker], ["id = ? and locked_at is null and run_at <= ?", id, now])
          if affected_rows == 1
            mark_as_locked!(now, worker)
            return true
          else
            return false
          end
        end

        def mark_as_locked!(time, worker)
          self.locked_at    = time
          self.locked_by    = worker
          # we cheated ActiveRecord::Dirty with the update_all calls above, so
          # we'll fix things up here.
          changed_attributes['locked_at'] = time
          changed_attributes['locked_by'] = worker
        end

        def create_and_lock!(worker)
          raise "job already exists" unless new_record?
          self.locked_at = Delayed::Job.db_time_now
          self.locked_by = worker
          save!
        end

        def fail!
          attrs = self.attributes
          attrs['original_id'] = attrs.delete('id')
          attrs['failed_at'] ||= self.class.db_time_now
          attrs.delete('next_in_strand')
          self.class.transaction do
            Failed.create(attrs)
            self.destroy
          end
        rescue
          # we got an error while failing the job -- we need to at least get
          # the job out of the queue
          self.destroy
          # re-raise so the worker logs the error, at least
          raise
        end

        # hold/unhold jobs with a scope
        def self.hold!
          update_all({ :locked_by => ON_HOLD_LOCKED_BY, :locked_at => db_time_now, :attempts => ON_HOLD_COUNT })
        end

        def self.unhold!
          now = db_time_now
          update_all(["locked_by = NULL, locked_at = NULL, attempts = 0, run_at = (CASE WHEN run_at > ? THEN run_at ELSE ? END), failed_at = NULL", now, now])
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
