# Copyright (C) 2014 Jacob Fugal

require 'active_support/callbacks/suspension/registry'
require 'active_support/core_ext/array' # extract_options!
require 'active_support/version'

module ActiveSupport::Callbacks
  module Suspension
    # Ignores the specified callbacks for the duration of the block.
    #
    # suspend_callbacks{ ... }
    #   all callbacks ignored
    #
    # suspend_callbacks(:validate) { ... }
    #   callbacks to validate ignored
    #
    # [ActiveSupport 2.3]
    # suspend_callbacks(kind: :before_save) { ... }
    #   before_save callbacks ignored
    #
    # suspend_callbacks(:validate, kind: :before_save) { ... }
    #   before_save callbacks to validate ignored
    #
    # [ActiveSupport 3+]
    # suspend_callbacks(kind: :save) { ... }
    #   save callbacks ignored
    #
    # suspend_callbacks(kind: :save, type: :before) { ... }
    #   before save callbacks ignored
    #
    # suspend_callbacks(:validate, kind: :save) { ... }
    #   save callbacks to validate ignored
    #
    # suspend_callbacks(:validate, kind: :save, type: :before) { ... }
    #   before save callbacks to validate ignored
    def suspend_callbacks(*callbacks)
      options = callbacks.extract_options!
      kinds = Array(options[:kind])
      types = (ActiveSupport::VERSION::STRING < '3') ? [] : Array(options[:type])
      delta = suspended_callbacks.update(callbacks, kinds, types)
      yield
    ensure
      suspended_callbacks.revert(delta)
    end

    protected
    # checks whether a specific callback combination (e.g. :validate, :save,
    # :before) is currently suspended, whether by the receiver or the
    # receiver's ancestor (its class for an instance, its superclass for a
    # class). ancestry check is so that the following example can work:
    #
    #   class Person < ActiveRecord::Base; end
    #   class Student < Person; end
    #   @student = Student.first
    #
    #   Person.suspend_callbacks(:validate) do
    #     Person.send(:suspended_callback?, :validate, :save, :before) #=> true
    #     Student.send(:suspended_callback?, :validate, :save, :before) #=> true
    #     @student.send(:suspended_callback?, :validate, :save, :before) #=> true
    #   end
    #
    #   Student.suspend_callbacks(:validate) do
    #     Person.send(:suspended_callback?, :validate, :save, :before) #=> false
    #     Student.send(:suspended_callback?, :validate, :save, :before) #=> true
    #     @student.send(:suspended_callback?, :validate, :save, :before) #=> true
    #   end
    #
    #   @student.suspend_callbacks(:validate) do
    #     Person.send(:suspended_callback?, :validate, :save, :before) #=> false
    #     Student.send(:suspended_callback?, :validate, :save, :before) #=> false
    #     @student.send(:suspended_callback?, :validate, :save, :before) #=> true
    #   end
    #
    def suspended_callback?(callback, kind, type=nil)
      val = suspended_callbacks_defined? &&
        suspended_callbacks.include?(callback, kind, type) ||
      suspended_callback_ancestor &&
        suspended_callback_ancestor.suspended_callback?(callback, kind, type)

      val
    end

    def suspended_callback_ancestor
      unless defined?(@suspended_callback_ancestor)
        @suspended_callback_ancestor = is_a?(Class) ? superclass : self.class
        @suspended_callback_ancestor = nil unless @suspended_callback_ancestor.respond_to?(:suspended_callback?, true)
      end
      @suspended_callback_ancestor
    end

    module ClassMethods
      def suspended_callbacks_defined?
        # If this is a class, we need to save the suspension state in thread
        # storage to remain thread safe. We could also instead store a Hash on
        # the class of <Thread, Hash>, but that would grow indefinitely as threads
        # will grow faster than number of classes.
        all_classes_state = Thread.current[:suspended_callbacks]
        all_classes_state && all_classes_state[self]
      end

      def suspended_callbacks
        all_classes_state = Thread.current[:suspended_callbacks] ||= {}
        all_classes_state[self] ||= Registry.new
      end
    end

    module InstanceMethods
      def suspended_callbacks_defined?
        instance_variable_defined?(:@suspended_callbacks)
      end

      def suspended_callbacks
        @suspended_callbacks ||= Registry.new
      end

      protected
      # as ActiveSupport::Callbacks#run_callbacks, but with the step filtering on
      # suspended_callback? added
      if ActiveSupport::VERSION::STRING < '4'
        # [ActiveSupport 3]
        def run_callbacks(kind, key=nil)
          cbs = send("_#{kind}_callbacks")
          if cbs.empty?
            yield if block_given?
          else
            if cbs.detect{ |cb| suspended_callback?(cb.filter, kind, cb.kind) }
              cbs = cbs.dup
              cbs.delete_if{ |cb| suspended_callback?(cb.filter, kind, cb.kind) }
              runner = cbs.compile(key, self)
              # provided block (if any) is executed by yields statements in the
              # compiled runner
              instance_eval(runner, __FILE__)
            else
              super
            end
          end
        end
      elsif ActiveSupport::VERSION::STRING < '4.1'
        # [ActiveSupport 4.0]
        def run_callbacks(kind)
          cbs = send("_#{kind}_callbacks")
          if cbs.empty?
            yield if block_given?
          else
            if cbs.detect{ |cb| suspended_callback?(cb.filter, kind, cb.kind) }
              cbs = cbs.dup
              cbs.delete_if{ |cb| suspended_callback?(cb.filter, kind, cb.kind) }
              runner = cbs.compile
              # provided block (if any) is executed by yields statements in the
              # compiled runner
              instance_eval(runner, __FILE__)
            else
              super
            end
          end
        end
      elsif ActiveSupport::VERSION::STRING < '4.2'
        # [ActiveSupport 4.1]
        def run_callbacks(kind, &block)
          cbs = send("_#{kind}_callbacks").dup

          # emulate cbs.delete_if{ ... } since CallbackChain doesn't proxy it
          filtered = cbs.dup
          filtered.clear
          cbs.each{ |cb| filtered.insert(-1, cb) unless suspended_callback?(cb.filter, kind, cb.kind) }

          if filtered.empty?
            yield if block_given?
          else
            runner = filtered.compile
            e = Filters::Environment.new(self, false, nil, block)
            runner.call(e).value
          end
        end
      else
        # [ActiveSupport 4.2]
        def __run_callbacks__(cbs, &block)
          # emulate cbs.delete_if{ ... } since CallbackChain doesn't proxy it
          filtered = cbs.dup
          filtered.clear
          cbs.each{ |cb| filtered.insert(-1, cb) unless suspended_callback?(cb.filter, cbs.name, cb.kind) }

          if filtered.empty?
            yield if block_given?
          else
            runner = filtered.compile
            e = Filters::Environment.new(self, false, nil, block)
            runner.call(e).value
          end
        end
      end
    end

    def self.included(base)
      base.extend self
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end
  end
end
