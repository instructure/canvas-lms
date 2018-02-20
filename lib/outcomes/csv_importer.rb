#
# Copyright (C) 2013 - present Instructure, Inc.
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
require 'csv'
require 'set'

module Outcomes
  class CsvImporter
    include Outcomes::Import

    REQUIRED_FIELDS = %i[
      title
      vendor_guid
      object_type
      parent_guids
    ].freeze

    OPTIONAL_FIELDS = %i[
      canvas_id
      description
      display_name
      calculation_method
      calculation_int
      workflow_state
    ].freeze

    BATCH_SIZE = 1000

    def initialize(path, context)
      @path = path
      @context = context
    end

    def run
      headers = nil
      CSV.new(File.new(@path, 'r:UTF-8')).each_slice(BATCH_SIZE) do |batch|
        headers ||= validate_headers(batch.shift)
        Account.transaction do
          batch.each do |row|
            import_row(headers, row)
          end
        end
      end
    end

    private

    def validate_headers(row)
      main_columns_end = row.find_index('ratings') || row.length
      headers = row.slice(0, main_columns_end).map(&:to_sym).to_a

      # OUT-1885 : validate that ratings headers are empty

      missing = REQUIRED_FIELDS - headers
      raise ParseError, "Missing required fields: #{missing.inspect}" unless missing.empty?

      invalid = headers - OPTIONAL_FIELDS - REQUIRED_FIELDS
      raise ParseError, "Invalid fields: #{invalid.inspect}" unless invalid.empty?

      headers
    end

    def import_row(headers, row)
      simple = headers.zip(row).to_h
      ratings = row[headers.length..-1]

      object = simple.to_h
      object[:ratings] = parse_ratings(ratings)
      import_object(object)
    end

    def parse_ratings(ratings)
      drop_trailing_nils(ratings).each_slice(2).to_a.map do |points, description|
        # OUT-1885 : validate that points are in order and not nil
        { points: points, description: description }
      end
    end

    def drop_trailing_nils(array)
      array.pop while array.last.nil? && !array.empty?
      array
    end
  end
end
