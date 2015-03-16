#
# Copyright (C) 2015 Instructure, Inc.
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

require 'tempfile'
require 'zip'

module SIS
  module CSV
    class DiffGenerator
      def initialize(root_account, batch)
        @root_account = root_account
        @batch = batch
      end

      def generate(previous_data_path, current_data_path)
        previous_import = SIS::CSV::Import.new(@root_account, files: [previous_data_path])
        previous_csvs = previous_import.prepare
        current_import = SIS::CSV::Import.new(@root_account, files: [current_data_path])
        current_csvs = current_import.prepare
        @batch.add_warnings(current_import.warnings)
        @batch.add_errors(current_import.errors)

        output_csvs = generate_csvs(previous_csvs, current_csvs)
        output_file = Tempfile.new(["sis_csv_diff_generator", ".zip"])
        output_path = output_file.path
        output_file.close!
        Zip::File.open(output_path, Zip::File::CREATE) do |zip|
          output_csvs.each do |csv|
            zip.add(csv[:file], csv[:fullpath])
          end
        end
        File.open(output_path, 'rb')
      end

      def generate_csvs(previous_csvs, current_csvs)
        generated = []
        current_csvs.each do |(import_type, csvs)|
          current_csv = csvs.first
          previous_csv = previous_csvs[import_type].try(:first)

          if current_csv.nil? || previous_csv.nil?
            generated.concat(csvs)
            next
          end

          if csvs.size > 1 || previous_csvs[import_type].size > 1
            add_warning(current_csv,
                        I18n.t("Can't perform diffing against more than one file of the same type"))
            generated.concat(csvs)
            next
          end

          begin
            io = generate_diff(class_for_importer(import_type), previous_csv[:fullpath], current_csv[:fullpath])
            generated << {
              file: current_csv[:file],
              fullpath: io.path,
              tmpfile: io # returning the Tempfile alongside its path, to keep it in scope
            }
          rescue CsvDiff::Failure => e
            add_warning(current_csv, I18n.t("Couldn't generate diff: %{message}", message: e.message))
            generated.concat(csvs)
          end
        end
        generated
      end

      protected

      def class_for_importer(import_type)
        SIS::CSV.const_get(import_type.to_s.camelcase + 'Importer')
      end

      def generate_diff(importer, previous_input, current_input)
        previous_csv = ::CSV.open(previous_input, CSVBaseImporter::PARSE_ARGS)
        current_csv = ::CSV.open(current_input, CSVBaseImporter::PARSE_ARGS)
        diff = CsvDiff::Diff.new(importer.identifying_fields)
        diff.generate(previous_csv, current_csv, deletes: ->(row) { row['status'] = 'deleted' })
      end

      def add_warning(csv, message)
        @batch.add_warnings([[csv ? csv[:file] : "", message]])
      end
    end
  end
end

