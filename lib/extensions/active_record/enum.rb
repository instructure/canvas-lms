# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
#

module Extensions
  module ActiveRecord
    module Enum
      # Defines an enum attribute for an ActiveRecord model.
      #
      # Overrides ActiveRecord::Enum#enum to provide a consistent
      # enum key/value convention that avoids potentially meaningless
      # numeric enum values in the database.
      #
      # @param name [Symbol, String] the name of the enum attribute.
      # @param values [Array] the possible values for the enum attribute.
      # @param **options [Hash] additional options to pass to the enum definition.
      #
      # @raise [ArgumentError] if the name is blank.
      # @raise [ArgumentError] if the values are not an Array.
      #
      # @example
      #   enum :color, [:red, :yellow, :green]
      def enum(name, values, **)
        raise ArgumentError, "Enum name is required" if name.blank?
        raise ArgumentError, "Enum values must be an Array" unless values.is_a?(Array)

        unless values.all?(Symbol) || values.all?(String)
          raise ArgumentError, "Enum values #{values} must only contain symbols or strings."
        end

        # Pass an "identity" hash based on the values array where the key and value are the same.
        super(name, values.index_with(&:to_s), **)
      end
    end
  end
end
