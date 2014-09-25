module Delayed
  module MessageSending
    def send_later(method, *args)
      send_later_enqueue_args(method, {}, *args)
    end

    def send_later_enqueue_args(method, enqueue_args = {}, *args)
      enqueue_args = enqueue_args.dup
      # support procs/methods as enqueue arguments
      enqueue_args.each do |k,v|
        if v.respond_to?(:call)
          enqueue_args[k] = v.call(self)
        end
      end

      no_delay = enqueue_args.delete(:no_delay)
      if !no_delay
        # delay queuing up the job in another database until the results of the current
        # transaction are visible
        connection = self.connection if respond_to?(:connection)
        connection ||= ActiveRecord::Base.connection

        if (Delayed::Job != Delayed::Backend::ActiveRecord::Job || connection != Delayed::Job.connection)
          connection.after_transaction_commit do
            Delayed::Job.enqueue(Delayed::PerformableMethod.new(self, method.to_sym, args), enqueue_args)
          end
          return nil
        end
      end

      result = Delayed::Job.enqueue(Delayed::PerformableMethod.new(self, method.to_sym, args), enqueue_args)
      result = nil unless no_delay
      result
    end

    def send_later_with_queue(method, queue, *args)
      send_later_enqueue_args(method, { :queue => queue }, *args)
    end

    def send_at(time, method, *args)
      send_later_enqueue_args(method,
                          { :run_at => time }, *args)
    end

    def send_at_with_queue(time, method, queue, *args)
      send_later_enqueue_args(method,
                          { :run_at => time, :queue => queue },
                          *args)
    end

    def send_later_unless_in_job(method, *args)
      if Delayed::Job.in_delayed_job?
        send(method, *args)
      else
        send_later(method, *args)
      end
      nil # can't rely on the type of return value, so return nothing
    end

    def send_later_if_production(*args)
      if Rails.env.production?
        send_later(*args)
      else
        send(*args)
      end
    end

    def send_later_if_production_enqueue_args(method, enqueue_args, *args)
      if Rails.env.production?
        send_later_enqueue_args(method, enqueue_args, *args)
      else
        send(method, *args)
      end
    end

    def send_now_or_later(_when, *args)
      if _when == :now
        send(*args)
      else
        send_later(*args)
      end
    end

    def send_now_or_later_if_production(_when, *args)
      if _when == :now
        send(*args)
      else
        send_later_if_production(*args)
      end
    end

    module ClassMethods
      def add_send_later_methods(method, enqueue_args={}, default_async=false)
        aliased_method, punctuation = method.to_s.sub(/([?!=])$/, ''), $1

        with_method, without_method = "#{aliased_method}_with_send_later#{punctuation}", "#{aliased_method}_without_send_later#{punctuation}"

        define_method(with_method) do |*args|
          send_later_enqueue_args(without_method, enqueue_args, *args)
        end
        alias_method without_method, method

        if default_async
          alias_method method, with_method
          case
            when public_method_defined?(without_method)
              public method
            when protected_method_defined?(without_method)
              protected method
            when private_method_defined?(without_method)
              private method
          end
        end
      end

      def handle_asynchronously(method, enqueue_args={})
        add_send_later_methods(method, enqueue_args, true)
      end

      def handle_asynchronously_with_queue(method, queue)
        add_send_later_methods(method, {:queue => queue}, true)
      end

      def handle_asynchronously_if_production(method, enqueue_args={})
        add_send_later_methods(method, enqueue_args, Rails.env.production?)
      end
    end
  end
end
