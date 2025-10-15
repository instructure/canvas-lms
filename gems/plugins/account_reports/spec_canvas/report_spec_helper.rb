# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module ReportSpecHelper
  def read_report(type = @type, options = {})
    account_report = run_report(type, options)
    if account_report.workflow_state == "error" || !account_report.attachment_id
      error_report = ErrorReport.last
      # using the cerror_class was often leading to different args needed or other
      # failures that made attempting to use the class less helpful
      error_class = error_report&.category&.constantize
      error = ReportSpecHelperError.new([error_class, error_report&.message].join("_"))
      error.set_backtrace(error_report&.backtrace&.split("\n") || caller)
      raise error
    end
    parse_report(account_report, options)
  end

  def run_report(type = @type, options = {})
    account = options[:account] || @account
    parameters = options[:params]
    account_report = AccountReport.new(user: @admin || user_factory,
                                       account:,
                                       report_type: type)
    parameters ||= {}
    account_report.parameters = parameters.merge({ "skip_message" => true })
    account_report.save!
    if AccountReport.available_reports[type]
      AccountReports.generate_report(account_report)
    else
      raise ReportSpecHelperError, "report is not properly configured in engine."
    end
    run_jobs
    account_report.reload
  end

  def parse_report(report, options = {})
    a = report.attachment
    if a.content_type == "application/zip"
      parsed = {}
      Zip::InputStream.open(a.open) do |io|
        while (entry = io.get_next_entry)
          parsed[entry.name] = parse_csv(io.read, options)
        end
      end
    else
      parsed = parse_csv(a.open, options)
    end
    parsed
  end

  def parse_csv(csv, options = {})
    csv_parse_opts = {
      col_sep: options[:col_sep] || ",",
      headers: options[:parse_header] || false,
      return_headers: true,
    }
    skip_order = true if options[:order] == "skip"
    order = Array(options[:order]).presence || [0, 1]
    all_parsed = CSV.parse(csv, **csv_parse_opts).map.to_a
    raise "Must order report results to avoid brittle specs" unless options[:order].present? || all_parsed.count < 3

    header = all_parsed.shift
    if all_parsed.present? && !skip_order
      # cast any numbery looking things so we sort them intuitively
      type_casts = order.map { |k| /\A\d+(\.\d+)?\z/.match?(all_parsed.filter_map { |row| row[k] }.first) ? :to_f : :to_s }
      all_parsed.sort_by! { |r| r.values_at(*order).each_with_index.map { |v, i| v.send type_casts[i] } }
    end
    all_parsed.unshift(header) if options[:header]
    all_parsed
  end

  class ReportSpecHelperError < StandardError; end
end

RSpec::Matchers.define :eq_stringified_array do |expected|
  stringify_csv_record = lambda do |item|
    if item.nil?
      nil
    elsif item.is_a? Array
      item.map { |arr_item| stringify_csv_record.call(arr_item) }
    else
      item.to_s
    end
  end

  match do |actual|
    actual == expected.map { |item| stringify_csv_record.call(item) }
  end
end
