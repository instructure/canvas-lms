module Delayed
  module Backend
    class DeserializationError < StandardError
    end

    module Base
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        # Add a job to the queue
        # The first argument should be an object that respond_to?(:perform)
        # The rest should be named arguments, these keys are expected:
        # :priority, :run_at, :queue
        # Example: Delayed::Job.enqueue(object, :priority => 0, :run_at => time, :queue => queue)
        def enqueue(*args)
          object = args.shift
          unless object.respond_to?(:perform)
            raise ArgumentError, 'Cannot enqueue items which do not respond to perform'
          end
    
          options = args.first || {}
          options[:priority] ||= self.default_priority
          options[:payload_object] = object
          options[:queue] ||= Delayed::Worker.queue
          self.create(options)
        end
      end
      
      ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/

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

      def payload_object=(object)
        self['handler'] = object.to_yaml
        self['tag'] = object.tag if object.respond_to?(:tag)
      end
      
      # Moved into its own method so that new_relic can trace it.
      def invoke_job
        payload_object.perform
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
        if payload_object.respond_to?(:reschedule_at)
          begin
            new_time = payload_object.reschedule_at(
                                        self.class.db_time_now, attempts)
          rescue
            # TODO: just swallow errors from reschedule_at ?
          end
        end
        new_time
      end

    private

      def deserialize(source)
        handler = YAML.load(source) rescue nil

        unless handler.respond_to?(:perform)
          if handler.nil? && source =~ ParseObjectFromYaml
            handler_class = $1
          end
          attempt_to_load(handler_class || handler.class)
          handler = YAML.load(source)
        end

        return handler if handler.respond_to?(:perform)

        raise DeserializationError,
          'Job failed to load: Unknown handler. Try to manually require the appropriate file.'
      rescue TypeError, LoadError, NameError => e
        raise DeserializationError,
          "Job failed to load: #{e.message}. Try to manually require the required file."
      end

      # Constantize the object so that ActiveSupport can attempt
      # its auto loading magic. Will raise LoadError if not successful.
      def attempt_to_load(klass)
         klass.constantize
      end

    protected

      def before_save
        self.run_at ||= self.class.db_time_now
      end
    
    end
  end
end
