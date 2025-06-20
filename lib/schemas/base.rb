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
    class InvalidSchema < RuntimeError
    end

    def self.create_schema
      raise "Implement self.create_schema or define @schema directly"
    end

    def self.schema
      unless @schema
        @schema = superclass.schema.deep_dup.with_indifferent_access
        raise "One of your base classes must define a schema" unless @schema

        create_schema
      end

      @schema
    end

    class << self
      delegate :validate, :valid?, to: :schema_checker

      # Returns nil if no errors
      def simple_validation_errors(json_hash, error_format: :string)
        validate(json_hash).to_a.presence&.map { simple_validation_error it, error_format: }
      end

      def validation_errors(json_hash, allow_nil: false)
        if allow_nil
          json_hash = Utils::HashUtils.nested_compact(json_hash)
        end
        validate(json_hash).pluck("error")
      end

      def filter_and_validate!(json_hash)
        unless schema_checker_with_filter.valid?(json_hash)
          raise InvalidSchema, "Invalid #{name}: #{validation_errors(json_hash)}"
        end

        json_hash
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

        if error_format == :hash
          return {
            error: raw_error["error"],
            schema: raw_error["schema"],
            details: raw_error["details"]
          }
        end
        "The following fields are required: #{raw_error["error"]}"
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

      def schema_checker
        @schema_checker ||= JSONSchemer.schema(schema)
      end

      def schema_checker_with_filter
        @schema_checker_with_filter ||= JSONSchemer.schema(schema, before_property_validation: property_stripper_hook)
      end

      def property_stripper_hook
        proc do |data, _property, _property_schema, parent_shema|
          if data.is_a?(Hash) && parent_shema.is_a?(Hash) && parent_shema.key?("properties") && parent_shema["additionalProperties"].blank?
            defined_properties = parent_shema["properties"].keys.to_set(&:to_s)
            data.each_key do |key|
              unless defined_properties.include?(key.to_s)
                data.delete(key)
              end
            end
          end
        end
      end
    end
  end
end
