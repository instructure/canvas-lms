# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require "active_support/callbacks/suspension/registry"
require "active_support/version"

module ActiveSupport::Callbacks
  module Suspension
    def self.included(base)
      # use extend to avoid this callback being called again
      base.extend(self)
      base.singleton_class.include(ClassMethods)
      base.include(InstanceMethods)
    end

    # Ignores the specified callbacks for the duration of the block.
    #
    # suspend_callbacks{ ... }
    #   all callbacks ignored
    #
    # suspend_callbacks(:validate) { ... }
    #   callbacks to validate ignored
    #
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
    def suspend_callbacks(*callbacks, kind: nil, type: nil)
      kinds = Array(kind)
      types = Array(type)
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
    def suspended_callback?(callback, kind, type = nil)
      (suspended_callbacks_defined? &&
            suspended_callbacks.include?(callback, kind, type)) ||
        suspended_callback_ancestor&.suspended_callback?(callback, kind, type)
    end

    def any_suspensions_active?(kind)
      (suspended_callbacks_defined? && suspended_callbacks.any_registered?(kind)) ||
        suspended_callback_ancestor&.any_suspensions_active?(kind)
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

      def filter_callbacks(callbacks)
        # common case, we can skip a bunch of tests
        return callbacks if callbacks.empty?
        # short-circuit re-allocating the chain if no suspensions are active
        return callbacks unless any_suspensions_active?(callbacks.name)

        filtered = ActiveSupport::Callbacks::CallbackChain.new(callbacks.name, callbacks.config)
        callbacks.each { |cb| filtered.insert(-1, cb) unless suspended_callback?(cb.filter, callbacks.name, cb.kind) }
        filtered
      end

      # this are copy/paste, except wrapping in a filter_callbacks
      def run_callbacks(kind)
        callbacks = filter_callbacks(__callbacks[kind.to_sym])

        if callbacks.empty?
          yield if block_given?
        else
          env = Filters::Environment.new(self, false, nil)
          next_sequence = (ActiveSupport.version < Gem::Version.new("7.1")) ? callbacks.compile : callbacks.compile(nil)

          invoke_sequence = proc do
            skipped = nil
            while true
              current = next_sequence
              current.invoke_before(env)
              if current.final?
                env.value = !env.halted && (!block_given? || yield)
              elsif current.skip?(env)
                (skipped ||= []) << current
                next_sequence = next_sequence.nested
                next
              else
                next_sequence = next_sequence.nested
                begin
                  target, block, method, *arguments = current.expand_call_template(env, invoke_sequence)
                  target.send(method, *arguments, &block)
                ensure
                  next_sequence = current
                end
              end
              current.invoke_after(env)
              skipped.pop.invoke_after(env) while skipped&.first
              break env.value
            end
          end

          # Common case: no 'around' callbacks defined
          if next_sequence.final?
            next_sequence.invoke_before(env)
            env.value = !env.halted && (!block_given? || yield)
            next_sequence.invoke_after(env)
            env.value
          else
            invoke_sequence.call
          end
        end
      end
    end
  end
end
