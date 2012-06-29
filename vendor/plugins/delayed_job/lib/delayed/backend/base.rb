module Delayed
  module Backend
    class DeserializationError < StandardError
    end

    class RecordNotFound < DeserializationError
    end

    module Base
      ON_HOLD_LOCKED_BY = 'on hold'
      ON_HOLD_COUNT = 50

      def self.included(base)
        base.extend ClassMethods
        base.default_priority = Delayed::NORMAL_PRIORITY
      end

      attr_writer :current_shard

      def current_shard
        @current_shard || Shard.default
      end

      module ClassMethods
        attr_accessor :batches
        attr_accessor :default_priority

        # Add a job to the queue
        # The first argument should be an object that respond_to?(:perform)
        # The rest should be named arguments, these keys are expected:
        # :priority, :run_at, :queue, :strand, :singleton
        # Example: Delayed::Job.enqueue(object, :priority => 0, :run_at => time, :queue => queue)
        def enqueue(*args)
          object = args.shift
          unless object.respond_to?(:perform)
            raise ArgumentError, 'Cannot enqueue items which do not respond to perform'
          end

          options = args.first || {}
          options[:priority] ||= self.default_priority
          options[:payload_object] = object
          options[:queue] = Delayed::Worker.queue unless options.key?(:queue)
          options[:max_attempts] ||= Delayed::Worker.max_attempts
          options[:current_shard] = Shard.current

          if options[:n_strand]
            strand_name = options.delete(:n_strand)
            num_strands = Setting.get_cached("#{strand_name}_num_strands", "1").to_i
            strand_num = num_strands > 1 ? rand(num_strands) + 1 : 1
            strand_name += ":#{strand_num}" if strand_num > 1
            options[:strand] = strand_name
          end

          if options[:singleton]
            options[:strand] = options.delete :singleton
            self.create_singleton(options)
          elsif batches && options.slice(:strand, :run_at).empty?
            batch_enqueue_args = options.slice(:priority, :queue)
            batches[batch_enqueue_args] << options
          else
            self.create(options)
          end
        end

        def in_delayed_job?
          !!Thread.current[:in_delayed_job]
        end

        def in_delayed_job=(val)
          Thread.current[:in_delayed_job] = val
        end

        # Get the current time (GMT or local depending on DB)
        # Note: This does not ping the DB to get the time, so all your clients
        # must have syncronized clocks.
        def db_time_now
          Time.now.in_time_zone
        end
      end

      def failed?
        failed_at
      end
      alias_method :failed, :failed?

      def payload_object
        @payload_object ||= deserialize(self['handler'])
      end

      def name
        @name ||= begin
          payload = payload_object
          if payload.respond_to?(:display_name)
            payload.display_name
          else
            payload.class.name
          end
        end
      end

      def full_name
        obj = payload_object rescue nil
        if obj && obj.respond_to?(:full_name)
          obj.full_name
        else
          name
        end
      end

      def payload_object=(object)
        @payload_object = object
        self['handler'] = object.to_yaml
        self['tag'] = if object.respond_to?(:tag)
          object.tag
        elsif object.is_a?(Module)
          "#{object}.perform"
        else
          "#{object.class}#perform"
        end
      end

      # Moved into its own method so that new_relic can trace it.
      def invoke_job
        Delayed::Job.in_delayed_job = true
        payload_object.perform
        Delayed::Job.in_delayed_job = false
      end

      def batch?
        payload_object.is_a?(Delayed::Batch::PerformableBatch)
      end

      # Unlock this job (note: not saved to DB)
      def unlock
        self.locked_at    = nil
        self.locked_by    = nil
      end

      def locked?
        !!(self.locked_at || self.locked_by)
      end

      def reschedule_at
        new_time = self.class.db_time_now + (attempts ** 4) + 5
        begin
          if payload_object.respond_to?(:reschedule_at)
            new_time = payload_object.reschedule_at(
                                        self.class.db_time_now, attempts)
          end
        rescue
          # TODO: just swallow errors from reschedule_at ?
        end
        new_time
      end

      def hold!
        self.locked_by = ON_HOLD_LOCKED_BY
        self.locked_at = self.class.db_time_now
        self.attempts = ON_HOLD_COUNT
        self.save!
      end

      def unhold!
        self.locked_by = nil
        self.locked_at = nil
        self.attempts = 0
        self.run_at = [self.class.db_time_now, self.run_at].max
        self.failed_at = nil
        self.save!
      end

      def on_hold?
        self.locked_by == 'on hold' && self.locked_at && self.attempts == ON_HOLD_COUNT
      end

    private

      ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/

      def deserialize(source)
        handler = nil
        begin
          handler = YAML.load(source)
        rescue TypeError
          attempt_to_load_from_source(source)
          handler = YAML.load(source)
        end

        return handler if handler.respond_to?(:perform)

        raise DeserializationError,
          'Job failed to load: Unknown handler. Try to manually require the appropriate file.'
      rescue TypeError, LoadError, NameError => e
        raise DeserializationError,
          "Job failed to load: #{e.message}. Try to manually require the required file."
      end

      def attempt_to_load_from_source(source)
        if md = ParseObjectFromYaml.match(source)
          md[1].constantize
        end
      end

    protected

      def before_save
        self.run_at ||= self.class.db_time_now
      end

    end
  end
end
