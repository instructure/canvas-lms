# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# Callbacks for CanvasOperations::BaseOperation and its subclasses.
#
# Subclasses can use `<before|after|around>_run` and `<before|after|around>_failure` callbacks to hook into
# the operation lifecycle.
module CanvasOperations
  module BaseConcerns
    module Callbacks
      SUPPORTED_CALLBACKS = [:run, :failure].freeze

      def self.extended(base)
        base.include ActiveSupport::Callbacks
      end

      # before, after, and around callbacks for supported lifecycle events (:run, :failure)
      SUPPORTED_CALLBACKS.each do |callback|
        define_method("before_#{callback}") do |*args, &block|
          set_callback(callback, :before, *args, &block)
        end

        define_method("after_#{callback}") do |*args, &block|
          set_callback(callback, :after, *args, &block)
        end

        define_method("around_#{callback}") do |*args, &block|
          set_callback(callback, :around, *args, &block)
        end
      end
    end
  end
end
