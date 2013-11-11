#
# Copyright (C) 2012 - 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../../spec/spec_helper')

module ReportSpecHelper
  def self.find_account_module_and_reports(account_id)
    Canvas::AccountReports::REPORTS.each do |(report_name, details)|
      details[:proc].should_not == nil
    end
  end

  def read_report(type = @type, options = {})
    account_report = run_report(type, options)
    parse_report(account_report, options)
  end

  def run_report(type = @type, options = {})
    account = options[:account] || @account
    parameters = options[:params] || {}
    account_report = AccountReport.new(:user => @admin || user,
                                       :account => account,
                                       :report_type => type)
    account_report.parameters = {}
    account_report.parameters = parameters
    account_report.save
    Canvas::AccountReports.for_account(account)[type][:proc].call(account_report)
    account_report
  end

  def parse_report(report, options = {})
    a = report.attachment
    if a.content_type == 'application/zip'
      parsed = {}
      Zip::ZipInputStream::open(a.open) do |io|
        while (entry = io.get_next_entry)
          parsed[entry.name] = parse_csv(io.read, options)
        end
      end
    else
      parsed = parse_csv(a.open,options)
    end
    parsed
  end

  def parse_csv(csv, options = {})
    col_sep = options[:col_sep] || ','
    order = Array(options[:order]).presence || [0, 1]
    all_parsed = CSV.parse(csv, {:col_sep => col_sep}).to_a
    header = all_parsed[0]
    all_parsed = all_parsed[1..-1].sort_by { |r| r.values_at(*order).join }
    all_parsed.unshift(header) if options[:header]
    all_parsed
  end

  def report(type = @type, options = {})
    account = options[:account] || @account
    parameters = options[:params] || {}
    account_report = AccountReport.new(:user => @admin || user,
                                       :account => account,
                                       :report_type => type)
    account_report.parameters = {}
    account_report.parameters = parameters
    account_report.save
    Canvas::AccountReports.for_account(account)[type][:proc].call(account_report)
    parse_report(account_report, options)
  end

  def self.run_report(account, report_type, parameters = {}, sort_column_or_columns = [0, 1], headers = false, col_sep = ',')
    sort_columns = Array(sort_column_or_columns)
    account_report = AccountReport.new(:user => account_admin_user(account: account), :account => account, :report_type => report_type)
    account_report.parameters = {}
    account_report.parameters = parameters
    account_report.save!
    csv_report = Canvas::AccountReports.for_account(account)[report_type][:proc].call(account_report)
    row_range = headers ? (0..-1) : (1..-1)
    if csv_report.is_a? Hash
      csv_report.inject({}) do |result, (key, csv)|
        all_parsed = CSV.parse(csv).to_a
        all_parsed[row_range].sort_by { |r| r.values_at(*sort_columns).join }
        result[key] = all_parsed
        result
      end
    else
      all_parsed = CSV.parse(account_report.attachment.open, {:col_sep => col_sep}).to_a
      all_parsed[row_range].sort_by { |r| r.values_at(*sort_columns).join }
    end
  end
end
