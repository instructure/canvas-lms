# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "zip"

module SIS
  module CSV
    class DiffGenerator
      def initialize(root_account, batch)
        @root_account = root_account
        @batch = batch
      end

      def generate(previous_data_path, current_data_path)
        previous_import = SIS::CSV::ImportRefactored.new(@root_account, files: [previous_data_path], batch: @batch, read_only: true, previous_diff_import: true)
        previous_csvs = previous_import.prepare
        current_import = SIS::CSV::ImportRefactored.new(@root_account, files: [current_data_path], batch: @batch, read_only: true)
        current_csvs = current_import.prepare

        output_csvs = generate_csvs(previous_csvs, current_csvs)
        return unless output_csvs.any?

        output_file = Tempfile.new(["sis_csv_diff_generator", ".zip"])
        output_path = output_file.path
        output_file.close!
        row_count = 0
        Zip::File.open(output_path, Zip::File::CREATE) do |zip|
          output_csvs.each do |csv|
            row_count += csv[:row_count] if csv[:row_count]
            zip.add(csv[:file], csv[:fullpath])
          end
        end
        { file_io: File.open(output_path, "rb"), row_count: }
      end

      VALID_ENROLLMENT_DROP_STATUS = %w[deleted inactive completed deleted_last_completed].freeze
      VALID_USER_REMOVE_STATUS = %w[deleted suspended].freeze

      def generate_csvs(previous_csvs, current_csvs)
        generated = []
        current_csvs.each do |(import_type, csvs)|
          previous_csvs_of_type = previous_csvs[import_type] || []

          if csvs.empty? || previous_csvs_of_type.empty?
            generated.concat(csvs)
            next
          end

          prev_csv_map = {}.compare_by_identity
          if csvs.size == previous_csvs_of_type.size
            if csvs.size == 1
              # there's only one file of each type; diff them like we did before
              prev_csv_map[csvs.first] = previous_csvs_of_type.first
            elsif csvs.pluck(:file).uniq.size == csvs.size
              # with multiple files, match them up by filename (assuming all filenames are distinct)
              csvs.each do |csv|
                match = previous_csvs_of_type.find { |p| p[:file] == csv[:file] }
                prev_csv_map[csv] = match if match
              end
            end
          end

          if prev_csv_map.size != csvs.size
            add_warning(csvs.first,
                        I18n.t("Unable to perform diffing against mismatched previous and current %{type} imports", type: import_type))
            generated.concat(csvs)
            next
          end

          begin
            csvs.each do |current_csv|
              previous_csv = prev_csv_map[current_csv]
              status = case import_type
                       when :enrollment
                         diffing_drop_status = @batch.options && @batch.options[:diffing_drop_status].presence
                         diffing_drop_status if VALID_ENROLLMENT_DROP_STATUS.include?(diffing_drop_status)
                       when :user
                         diffing_user_remove_status = @batch.options && @batch.options[:diffing_user_remove_status].presence
                         diffing_user_remove_status if VALID_USER_REMOVE_STATUS.include?(diffing_user_remove_status)
                       end
              status ||= "deleted"
              diff = generate_diff(class_for_importer(import_type), previous_csv[:fullpath], current_csv[:fullpath], status)
              io = diff[:file_io]
              generated << {
                row_count: diff[:row_count],
                file: current_csv[:file],
                fullpath: io.path,
                tmpfile: io # returning the Tempfile alongside its path, to keep it in scope
              }
            end
          rescue CsvDiff::Failure => e
            add_warning(csvs.first, I18n.t("Couldn't generate diff: %{message}", message: e.message))
            generated.concat(csvs)
          end
        end
        generated
      end

      protected

      def class_for_importer(import_type)
        SIS::CSV.const_get(import_type.to_s.camelcase + "Importer")
      end

      def generate_diff(importer, previous_input, current_input, status = "deleted")
        previous_csv = ::CSV.open(previous_input, **CSVBaseImporter::PARSE_ARGS)
        current_csv = ::CSV.open(current_input, **CSVBaseImporter::PARSE_ARGS)
        diff = CsvDiff::Diff.new(importer.identifying_fields)
        diff.generate(previous_csv, current_csv, deletes: ->(row) { row["status"] = status }, return_count: true)
      end

      def add_warning(csv, message, failure: false)
        @batch.sis_batch_errors.create!(root_account: @batch.account,
                                        message:,
                                        failure:,
                                        file: csv ? csv[:file] : "")
      end
    end
  end
end
