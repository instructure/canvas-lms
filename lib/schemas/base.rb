# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Schemas
  class Base
    delegate :validate, :valid?, to: :schema_checker

    class << self
      # TODO: Legacy behavior -- eventually update usage to return
      # an array of error hashes instead of the first error, and
      # each error should always be ahash instead of sometimes a string
      def simple_validation_first_error(json_hash, error_format: :string)
        err = new.validate(json_hash).to_a.first
        err && simple_validation_error(err, error_format:)
      end

      # Returns nil if no errors
      def simple_validation_errors(json_hash, error_format: :string)
        new.validate(json_hash).to_a.presence&.map { simple_validation_error _1, error_format: }
      end

      def validation_errors(json_hash)
        new.validate(json_hash).pluck("error")
      end

      private

      def simple_validation_error(raw_error, error_format: :string)
        if raw_error["data_pointer"].present?
          if error_format == :hash
            return {
              error: raw_error["data"],
              field: raw_error["data_pointer"],
              schema: raw_error["schema"]
            }
          else
            return "#{raw_error["data"]} #{raw_error["data_pointer"]}. Schema: #{raw_error["schema"]}"
          end
        end

        # TODO: Legacy behavior -- consider changing to return a hash,
        # make sure use of simple_validation_first_error_as_hash is OK with it
        "The following fields are required: #{raw_error.dig("schema", "required").join(", ")}"
      end

      # Filters to the defined properties only at the top level of the hash.
      # Doesn't filter using nested schemas.
      def filter_properties!(hash, schema)
        if hash.is_a?(Array)
          hash.each { |h| filter_properties!(h, schema) }
        else
          hash.slice!(*(schema[:properties] || schema["properties"]).keys.map(&:to_s))
        end
      end
    end

    private

    def schema_checker
      @schema_checker ||= JSONSchemer.schema(schema)
    end

    def schema
      raise "Abstract method"
    end
  end
end
