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

module CanvasOperations
  module BaseConcerns
    module ProgressTracking
      # Get the current progress tracking setting for this operation.
      #
      # By default, progress tracking is enabled.
      #
      # @return [Boolean] true if progress tracking is enabled, false otherwise
      def progress_tracking
        # By default, progress tracking is enabled.
        @progress_tracking.nil? || @progress_tracking
      end

      # Enable or disable progress tracking for this operation.
      #
      # When enabled, a Progress object will be attached to the `context`
      # to track progress of the operation.
      #
      # Operations are responsible for incrementing progress, but `BaseOperation`
      # will automatically set the Progress state to completed or failed as appropriate.
      #
      # @param value [Boolean] true to enable progress tracking, false to disable
      def progress_tracking=(value)
        raise CanvasOperations::Errors::InvalidPropertyValue, "progress_tracking must be a boolean" unless [true, false].include?(value)

        @progress_tracking = value
      end

      # Convenience instance methods for accessing the class-level progress_tracking property.
      def self.extended(base)
        base.class_eval do
          protected

          def progress_tracking?
            self.class.progress_tracking
          end
        end
      end
    end
  end
end
