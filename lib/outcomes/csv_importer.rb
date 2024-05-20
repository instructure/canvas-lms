# frozen_string_literal: true

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

module Outcomes
  class CSVImporter
    include Outcomes::Import

    class ParseError < RuntimeError; end

    REQUIRED_FIELDS = %i[
      title
      vendor_guid
      object_type
    ].freeze

    OPTIONAL_FIELDS = %i[
      canvas_id
      course_id
      description
      friendly_description
      display_name
      parent_guids
      calculation_method
      calculation_int
      mastery_points
      workflow_state
    ].freeze

    BATCH_SIZE = 1000

    def initialize(import, file)
      @import = import
      @file = file
    end

    delegate :context, to: :@import

    def run(&)
      status = { progress: 0, errors: [] }
      yield status

      file_errors = []
      begin
        parse_file(&)
      rescue CSV::MalformedCSVError
        raise DataFormatError, I18n.t("Invalid CSV File")
      rescue ParseError => e
        raise DataFormatError, e.message
      rescue ActiveRecord::StatementInvalid => e
        raise DataFormatError, I18n.t("Database error (%{err})", err: e.message)
      end
      status = {
        errors: file_errors,
        progress: 100
      }
      yield status
    end

    def parse_file
      headers = nil
      total = file_line_count
      raise ParseError, I18n.t("File has no data") if total < 1

      separator = test_header_i18n
      rows = CSV.new(@file, col_sep: separator).to_enum
      rows.with_index(1).each_slice(BATCH_SIZE) do |batch|
        headers ||= validate_headers(*batch.shift)
        raise ParseError, I18n.t("File has no outcomes data") if batch.empty?

        errors = parse_batch(headers, batch)
        status = {
          errors:,
          progress: (batch.last[1].to_f / total * 100).floor
        }
        yield status
      end
    end

    def parse_batch(headers, batch)
      Account.transaction do
        results = batch.map do |row, line|
          utf8_row = row.map(&method(:check_encoding))
          import_row(headers, utf8_row) unless utf8_row.all?(&:blank?)
          []
        rescue ParseError, InvalidDataError => e
          [[line, e.message]]
        rescue ActiveRecord::RecordInvalid => e
          errors = e.record.errors
          errors.set_reporter(:array, :human)
          errors.to_a.map { |err| [line, err] }
        end

        results.flatten(1)
      end
    end

    private

    def test_header_i18n
      header = @file.readline
      has_bom = header.start_with?((+"\xEF\xBB\xBF").force_encoding("ASCII-8BIT"))
      @file.rewind
      @file.read(3) if has_bom
      (header.count(";") > header.count(",")) ? ";" : ","
    end

    def file_line_count
      count = @file.each.inject(0) { |c, _line| c + 1 }
      @file.rewind
      count
    end

    def check_encoding(str)
      encoded = str&.force_encoding("utf-8")
      valid = (encoded || "").valid_encoding?
      raise ParseError, I18n.t("Not a valid utf-8 string: %{string}", string: str.inspect) unless valid

      encoded
    end

    def validate_headers(row, _index)
      main_columns_end = row.find_index("ratings") || row.length
      headers = row.slice(0, main_columns_end).map(&:to_sym)

      after_ratings = row[(main_columns_end + 1)..] || []
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
      ratings = row[headers.length..]

      object = simple.to_h
      object[:ratings] = parse_ratings(ratings)
      object[:learning_outcome_group_id] = @import[:learning_outcome_group_id]
      if object[:mastery_points].present?
        object[:mastery_points] = strict_parse_float(object[:mastery_points], I18n.t("mastery points"))
      end
      if object[:friendly_description].present? && object[:friendly_description].length > 255
        raise InvalidDataError, I18n.t("Friendly description is too long (maximum is 255 characters)")
      end

      import_object(object)
    end

    def parse_ratings(ratings)
      prior = nil
      drop_trailing_nils(ratings).each_slice(2).to_a.map.with_index(1) do |(points, description), index|
        raise InvalidDataError, I18n.t("Points for rating tier %{index} not present", index:) if points.nil? || points.blank?

        points = strict_parse_float(points, I18n.t("rating tier %{index} threshold", index:))

        if prior.present? && prior < points
          raise InvalidDataError, I18n.t(
            "Points for tier %{index} must be less than points for prior tier (%{points} is greater than %{prior})",
            index:,
            prior:,
            points:
          )
        end

        prior = points
        { points:, description: }
      end
    end

    def normalize_i18n(string)
      raise ArgumentError if string.blank?

      separator = I18n.t("number.format.separator")
      delimiter = I18n.t("number.format.delimiter")
      string.gsub(delimiter, "").gsub(separator, ".")
    end

    def strict_parse_float(v, name)
      Float(normalize_i18n(v))
    rescue ArgumentError
      raise InvalidDataError, I18n.t('Invalid value for %{name}: "%{i}"', name:, i: v)
    end

    def drop_trailing_nils(array)
      array.pop while array.last.nil? && !array.empty?
      array
    end
  end
end
