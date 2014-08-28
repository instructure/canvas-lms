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
      suspended_callbacks.include?(callback, kind, type) ||
      suspended_callback_ancestor &&
      suspended_callback_ancestor.suspended_callback?(callback, kind, type)
    end

    def suspended_callback_ancestor
      unless defined?(@suspended_callback_ancestor)
        @suspended_callback_ancestor = is_a?(Class) ? superclass : self.class
        @suspended_callback_ancestor = nil unless @suspended_callback_ancestor.respond_to?(:suspended_callback?, true)
      end
      @suspended_callback_ancestor
    end

    def suspended_callbacks
      @suspended_callbacks ||= Registry.new
    end

    module InstanceMethods
      protected
      # as ActiveSupport::Callbacks#run_callbacks, but with the step filtering on
      # suspended_callback? added
      if ActiveSupport::VERSION::STRING < '3'
        # [ActiveSupport 2.3]
        def run_callbacks(kind, options={}, &block)
          cbs = self.class.send("#{kind}_callback_chain").dup
          cbs.delete_if{ |cb| suspended_callback?(cb.method, kind) }
          cbs.run(self, options, &block)
        end
      elsif ActiveSupport::VERSION::STRING < '4'
        # [ActiveSupport 3]
        def run_callbacks(kind, key=nil)
          cbs = send("_#{kind}_callbacks").dup
          cbs.delete_if{ |cb| suspended_callback?(cb.filter, kind, cb.kind) }
          runner = cbs.compile(key, self)
          # provided block (if any) is executed by yields statements in the
          # compiled runner
          instance_eval(runner)
        end
      elsif ActiveSupport::VERSION::STRING < '4.1'
        # [ActiveSupport 4.0]
        def run_callbacks(kind)
          cbs = send("_#{kind}_callbacks").dup
          cbs.delete_if{ |cb| suspended_callback?(cb.filter, kind, cb.kind) }
          runner = cbs.compile
          # provided block (if any) is executed by yields statements in the
          # compiled runner
          instance_eval(runner)
        end
      else
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
      end
    end

    def self.included(base)
      base.extend self
      base.send(:include, InstanceMethods)
    end
  end
end
