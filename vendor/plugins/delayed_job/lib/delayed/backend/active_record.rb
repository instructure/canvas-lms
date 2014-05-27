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
        self.table_name = :delayed_jobs

        def self.reconnect!
          connection.reconnect!
        end

        class << self
          attr_accessor :batch_size, :select_random
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
        def update_strand_on_destroy
          if strand.present? && next_in_strand? && %w{MySQL Mysql2}.include?(self.class.connection.adapter_name)
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

        def self.current
          where("run_at<=?", db_time_now)
        end

        def self.future
          where("run_at>?", db_time_now)
        end

        def self.failed
          where("failed_at IS NOT NULL")
        end

        def self.running
          where("locked_at IS NOT NULL AND locked_by<>'on hold'")
        end

        # a nice stress test:
        # 10_000.times { |i| Kernel.send_later_enqueue_args(:system, { :strand => 's1', :run_at => (24.hours.ago + (rand(24.hours.to_i))) }, "echo #{i} >> test1.txt") }
        # 500.times { |i| "ohai".send_later_enqueue_args(:reverse, { :run_at => (12.hours.ago + (rand(24.hours.to_i))) }) }
        # then fire up your workers
        # you can check out strand correctness: diff test1.txt <(sort -n test1.txt)
         def self.ready_to_run
           where("run_at<=? AND locked_at IS NULL AND next_in_strand=?", db_time_now, true)
         end
        def self.by_priority
          order("priority ASC, run_at ASC")
        end

        # When a worker is exiting, make sure we don't have any locked jobs.
        def self.clear_locks!(worker_name)
          where(:locked_by => worker_name).update_all(:locked_by => nil, :locked_at => nil)
        end

        def self.strand_size(strand)
          self.where(:strand => strand).count
        end

        def self.running_jobs()
          self.running.order(:locked_at)
        end

        def self.scope_for_flavor(flavor, query)
          scope = case flavor.to_s
          when 'current'
            self.current
          when 'future'
            self.future
          when 'failed'
            Delayed::Job::Failed
          when 'strand'
            self.where(:strand => query)
          when 'tag'
            self.where(:tag => query)
          else
            raise ArgumentError, "invalid flavor: #{flavor.inspect}"
          end

          if %w(current future).include?(flavor.to_s)
            queue = query.presence || Delayed::Worker.queue
            scope = scope.where(:queue => queue)
          end

          scope
        end

        # get a list of jobs of the given flavor in the given queue
        # flavor is :current, :future, :failed, :strand or :tag
        # depending on the flavor, query has a different meaning:
        # for :current and :future, it's the queue name (defaults to Delayed::Worker.queue)
        # for :strand it's the strand name
        # for :tag it's the tag name
        # for :failed it's ignored
        def self.list_jobs(flavor,
                           limit,
                           offset = 0,
                           query = nil)
          scope = self.scope_for_flavor(flavor, query)
          order = flavor.to_s == 'future' ? 'run_at' : 'id desc'
          scope.order(order).limit(limit).offset(offset).all
        end

        # get the total job count for the given flavor
        # see list_jobs for documentation on arguments
        def self.jobs_count(flavor,
                            query = nil)
          scope = self.scope_for_flavor(flavor, query)
          scope.count
        end

        # perform a bulk update of a set of jobs
        # action is :hold, :unhold, or :destroy
        # to specify the jobs to act on, either pass opts[:ids] = [list of job ids]
        # or opts[:flavor] = <some flavor> to perform on all jobs of that flavor
        def self.bulk_update(action, opts)
          scope = if opts[:flavor]
            raise("Can't bulk update failed jobs") if opts[:flavor].to_s == 'failed'
            self.scope_for_flavor(opts[:flavor], opts[:query])
          elsif opts[:ids]
            self.where(:id => opts[:ids])
          end

          return 0 unless scope

          case action.to_s
          when 'hold'
            scope.update_all(:locked_by => ON_HOLD_LOCKED_BY, :locked_at => db_time_now, :attempts => ON_HOLD_COUNT)
          when 'unhold'
            now = db_time_now
            scope.update_all(["locked_by = NULL, locked_at = NULL, attempts = 0, run_at = (CASE WHEN run_at > ? THEN run_at ELSE ? END), failed_at = NULL", now, now])
          when 'destroy'
            scope.delete_all
          end
        end

        # returns a list of hashes { :tag => tag_name, :count => current_count }
        # in descending count order
        # flavor is :current or :all
        def self.tag_counts(flavor,
                            limit,
                            offset = 0)
          raise(ArgumentError, "invalid flavor: #{flavor}") unless %w(current all).include?(flavor.to_s)
          scope = case flavor.to_s
            when 'current'
              self.current
            when 'all'
              self
            end

          scope = scope.group(:tag).offset(offset).limit(limit)
          (CANVAS_RAILS2 ?
              scope.count(:tag, :order => "COUNT(tag) DESC") :
              scope.order("COUNT(tag) DESC").count).map { |t,c| { :tag => t, :count => c } }
        end

        def self.get_and_lock_next_available(worker_name,
                                             queue = Delayed::Worker.queue,
                                             min_priority = nil,
                                             max_priority = nil)

          check_queue(queue)
          check_priorities(min_priority, max_priority)

          self.batch_size ||= Setting.get('jobs_get_next_batch_size', '5').to_i
          if self.select_random.nil?
            self.select_random = Setting.get('jobs_select_random', 'false') == 'true'
          end
          loop do
            jobs = find_available(@batch_size, queue, min_priority, max_priority)
            return nil if jobs.empty?
            if self.select_random
              jobs = jobs.sort_by { rand }
            end
            job = jobs.detect do |job|
              job.lock_exclusively!(worker_name)
            end
            return job if job
          end
        end

        def self.find_available(limit,
                                queue = Delayed::Worker.queue,
                                min_priority = nil,
                                max_priority = nil)
          all_available(queue, min_priority, max_priority).limit(limit).all
        end

        def self.all_available(queue = Delayed::Worker.queue,
                               min_priority = nil,
                               max_priority = nil)
          min_priority ||= Delayed::MIN_PRIORITY
          max_priority ||= Delayed::MAX_PRIORITY

          check_queue(queue)
          check_priorities(min_priority, max_priority)

          self.ready_to_run.
              where(:priority => min_priority..max_priority, :queue => queue).
              by_priority
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
          when 'MySQL', 'Mysql2'
            if Rails.env.test? && connection.open_transactions > 0
              raise "cannot get table lock inside of transaction" if connection.open_transactions > 1
              # can't actually lock, but it's okay cause tests aren't multi-process
              yield
            else
              raise "cannot get table lock inside of transaction" if connection.open_transactions > 0
              begin
                # see http://dev.mysql.com/doc/refman/5.0/en/lock-tables-and-transactions.html
                connection.execute("SET autocommit=0")
                connection.execute("LOCK TABLES #{table_name} WRITE")
                connection.increment_open_transactions
                yield
                connection.execute("COMMIT")
              ensure
                connection.decrement_open_transactions
                connection.execute("UNLOCK TABLES")
                connection.execute("SET autocommit=1")
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
            job = self.where(:strand => strand, :locked_at => nil).order(:id).first
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
          affected_rows = self.class.where("id=? AND locked_at IS NULL AND run_at<=?", self, now).update_all(:locked_at => now, :locked_by => worker)
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
          attrs['original_job_id'] = attrs.delete('id')
          attrs['failed_at'] ||= self.class.db_time_now
          attrs.delete('next_in_strand')
          self.class.transaction do
            failed_job = Failed.create(attrs)
            self.destroy
            failed_job
          end
        rescue
          # we got an error while failing the job -- we need to at least get
          # the job out of the queue
          self.destroy
          # re-raise so the worker logs the error, at least
          raise
        end

        class Failed < Job
          include Delayed::Backend::Base
          self.table_name = :failed_jobs

          def original_job_id
            read_attribute(:original_job_id) || read_attribute(:original_id)
          end
        end
      end

    end
  end
end
