# Copyright (C) 2014 Jacob Fugal

require 'active_support/callbacks'

# Used to maintain a registry of which callbacks have been suspended for which
# kinds (e.g. :save) and types (e.g. :before) in a specific scope.
module ActiveSupport::Callbacks
  module Suspension
    class Registry
      def initialize
        @callbacks = {}
      end

      def [](kind, type)
        @callbacks.has_key?(kind) && @callbacks[kind].has_key?(type) ?
          @callbacks[kind][type] :
          []
      end

      def []=(kind, type, value)
        @callbacks[kind] ||= {}
        @callbacks[kind][type] = value
      end

      # registers each of the callbacks for each of the kinds and types. if
      # kinds and/or types is empty, it means to register the callbacks for all
      # kinds and/or all types, respectively. if callbacks is empty, it means
      # to register a blanket for the kinds and types. see include?(...) below.
      #
      # returns the delta from what was already registered, so that it can be
      # reverted later (see revert(...) below).
      def update(callbacks, kinds, types)
        callbacks << nil if callbacks.empty?
        kinds << nil if kinds.empty?
        types << nil if types.empty?

        delta = self.class.new
        kinds.each do |kind|
          types.each do |type|
            delta[kind, type] = callbacks - self[kind, type]
            self[kind, type] += delta[kind, type]
          end
        end
        delta
      end

      # removes the registrations from an earlier update.
      def revert(delta)
        delta.each do |kind, type, callbacks|
          self[kind, type] -= callbacks
        end
      end

      # checks if the callback has been registered for that kind (e.g. :save) and
      # type (e.g. :before) via any of the following:
      #
      #  * explicitly for that kind and that type (e.g. update([:validate], [:save], [:before])),
      #  * explicitly for all kinds and that type (e.g. update([:validate], [], [:before])),
      #  * explicitly for that kind and all types (e.g. update([:validate], [:save], [])),
      #  * explicitly for all kinds and all types (e.g. update([:validate], [], [])),
      #  * a blanket for that kind and that type (e.g. update([], [:save], [:before]),
      #  * a blanket for all kinds and that type (e.g. update([], [], [:before])),
      #  * a blanket for that kind and all types (e.g. update([], [:save], [])),
      #  * a blanket for all kinds and all types (e.g. update([], [], []))
      def include?(callback, kind, type)
        [ self[kind, type],
          self[kind, nil],
          self[nil, type],
          self[nil, nil] ].any? do |cbs|
            cbs.include?(nil) ||
            cbs.include?(callback)
          end
      end

      def each
        @callbacks.each do |kind, callbacks|
          callbacks.each do |type, skipped|
            yield kind, type, skipped
          end
        end
      end
    end
  end
end
