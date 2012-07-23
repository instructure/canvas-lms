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
        def update_strand_on_destroy
          if strand.present? && next_in_strand? && self.class.connection.adapter_name == 'MySQL'
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
          if strand.present? && self.class.connection.adapter_name == 'PostgreSQL'
            connection.execute(sanitize_sql(["SELECT pg_advisory_xact_lock(half_md5_as_bigint(?))", strand]))
          end
        end

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
        named_scope :ready_to_run, lambda {
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
                                             queue = nil,
                                             min_priority = nil,
                                             max_priority = nil)

          min_priority ||= Delayed::MIN_PRIORITY
          max_priority ||= Delayed::MAX_PRIORITY

          @batch_size ||= Setting.get_cached('jobs_get_next_batch_size', '5').to_i
          loop do
            jobs = find_available(@batch_size, queue, min_priority, max_priority)
            return nil if jobs.empty?
            job = jobs.detect do |job|
              job.lock_exclusively!(worker_name)
            end
            return job if job
          end
        end

        def self.find_available(limit,
                                queue = nil,
                                min_priority = nil,
                                max_priority = nil)
          all_available(queue, min_priority, max_priority).all(:limit => limit)
        end

        def self.all_available(queue = nil,
                               min_priority = nil,
                               max_priority = nil)
          scope = self.ready_to_run
          scope = scope.scoped(:conditions => ['priority >= ?', min_priority]) if min_priority
          scope = scope.scoped(:conditions => ['priority <= ?', max_priority]) if max_priority
          scope = scope.scoped(:conditions => ['queue = ?', queue]) if queue
          scope = scope.scoped(:conditions => ['queue is null']) unless queue
          scope.by_priority
        end

        # used internally by create_singleton to take the appropriate lock
        # depending on the db driver
        def self.transaction_for_singleton(strand)
          case self.connection.adapter_name
          when 'PostgreSQL'
            self.transaction do
              connection.execute(sanitize_sql(["SELECT pg_advisory_xact_lock(half_md5_as_bigint(?))", strand]))
              yield
            end
          when 'MySQL'
            self.transaction do
              begin
                connection.execute("LOCK TABLES #{table_name} WRITE")
                yield
              ensure
                connection.execute("UNLOCK TABLES")
              end
            end
          when 'SQLite'
            # can't use BEGIN EXCLUSIVE TRANSACTION here, since we might already be in a txn
            self.transaction do
              begin
                connection.execute("PRAGMA locking_mode = EXCLUSIVE")
                yield
              ensure
                connection.execute("PRAGMA locking_mode = NORMAL")
              end
            end
          end
        end

        # Create the job on the specified strand, but only if there aren't any
        # other non-running jobs on that strand.
        # (in other words, the job will still be created if there's another job
        # on the strand but it's already running)
        def self.create_singleton(options)
          strand = options[:strand]
          transaction_for_singleton(strand) do
            job = self.first(:conditions => ["strand = ? AND locked_at IS NULL", strand], :order => :id)
            job || self.create(options)
          end
        end

        # Lock this job for this worker.
        # Returns true if we have the lock, false otherwise.
        #
        # It's important to note that for performance reasons, this method does
        # not re-check the strand constraints -- so you could manually lock a
        # job using this method that isn't the next to run on its strand.
        def lock_exclusively!(worker)
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

        class Failed < Job
          include Delayed::Backend::Base
          set_table_name :failed_jobs
        end
      end

    end
  end
end
