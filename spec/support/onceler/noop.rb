# dummy methods for CANVAS_RAILS2
module Onceler
  def self.base_transactions
    1
  end

  module Noop
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def onceler!
      end

      def before(scope = nil, &block)
        scope = :each if scope == :once || scope.nil?
        return if scope == :record || scope == :replay
        super(scope, &block)
      end

      def after(scope = nil, &block)
        scope = :each if scope.nil?
        return if scope == :record || scope == :replay
        super(scope, &block)
      end

      %w{let_once subject_once let_each let_each! subject_each subject_each!}.each do |method|
        define_method(method) do |*args, &block|
          # make _once behave like !, because that's essentially what onceler is doing
          frd_method = method.sub(/_each!?\z/, '').sub(/_once!?\z/, '!')
          send frd_method, args.first, &block
        end
      end
    end
  end
end
