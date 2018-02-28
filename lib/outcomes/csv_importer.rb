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

    def initialize(import, file)
      @import = import
      @file = file
    end

    delegate :context, to: :@import

    def run(&update)
      status = { progress: 0, errors: [] }
      yield status

      begin
        parse_file(&update)
      rescue ParseError => e
        status = {
          errors: [[1, e.message]],
          progress: 100,
        }
        yield status
      end
    end

    def parse_file
      headers = nil
      total = file_line_count
      rows = CSV.new(@file).to_enum
      rows.with_index(1).each_slice(BATCH_SIZE) do |batch|
        headers ||= validate_headers(*batch.shift)
        errors = parse_batch(headers, batch)
        status = {
          errors: errors,
          progress: (batch.last[1].to_f / total * 100).floor
        }
        yield status
      end
    end

    def parse_batch(headers, batch)
      Account.transaction do
        results = batch.map do |row, line|
          begin
            utf8_row = row.map(&method(:check_encoding))
            import_row(headers, utf8_row)
            []
          rescue ParseError => e
            [[line, e.message]]
          rescue ActiveRecord::RecordInvalid => e
            errors = e.record.errors
            errors.set_reporter(:array, :human)
            errors.to_a.map { |err| [line, err] }
          end
        end

        results.flatten(1)
      end
    end

    private

    def file_line_count
      count = @file.each.inject(0) { |c, _line| c + 1}
      @file.rewind
      count
    end

    def check_encoding(str)
      encoded = str&.force_encoding('utf-8')
      valid = (encoded || '').valid_encoding?
      raise ParseError, I18n.t('Not a valid utf-8 string: %{string}', string: str.inspect) unless valid
      encoded
    end

    def validate_headers(row, _index)
      main_columns_end = row.find_index('ratings') || row.length
      headers = row.slice(0, main_columns_end).map(&:to_sym)

      after_ratings = row[(main_columns_end + 1)..-1] || []
      after_ratings = after_ratings.select(&:present?).map(&:to_s)
      raise ParseError, I18n.t("Invalid fields after ratings: %{fields}", fields: after_ratings.inspect) unless after_ratings.empty?

      missing = (REQUIRED_FIELDS - headers).map(&:to_s)
      raise ParseError, I18n.t("Missing required fields: %{fields}", fields: missing.inspect) unless missing.empty?

      invalid = (headers - OPTIONAL_FIELDS - REQUIRED_FIELDS).map(&:to_s)
      raise ParseError, I18n.t("Invalid fields: %{fields}", fields: invalid.inspect) unless invalid.empty?

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
      prior = nil
      drop_trailing_nils(ratings).each_slice(2).to_a.map.with_index(1) do |(points, description), index|
        raise ParseError, I18n.t("Points for rating tier %{index} not present", index: index) if points.nil? || points.blank?
        points = strict_parse_int(points, index)

        if prior.present? && prior < points
          raise ParseError, I18n.t(
            "Points for tier %{index} must be less than points for prior tier (%{points} is greater than %{prior})",
            index: index, prior: prior, points: points
          )
        end

        prior = points
        { points: points, description: description }
      end
    end

    def strict_parse_int(v, index)
      Integer(v)
    rescue ArgumentError
      raise ParseError, I18n.t('Invalid points for rating tier %{index}: "%{i}"', index: index, i: v)
    end

    def drop_trailing_nils(array)
      array.pop while array.last.nil? && !array.empty?
      array
    end
  end
end
