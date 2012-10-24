#
# Copyright (C) 2012 Instructure, Inc.
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

module ReportsSpecHelper
  def self.find_account_module_and_reports(account_id)
    module_name = Canvas::AccountReports::AvailableReports.module_names[account_id]
    Canvas::AccountReports.const_defined?(module_name).should == true
    Canvas::AccountReports::AvailableReports.reports[account_id].each do |report|
      Canvas::AccountReports.const_get(module_name).respond_to?(report.first).should == true
    end
  end

  def self.run_report(account,report_type, parameters = {}, column = 0)

    account_report = AccountReport.new(:user => @admin, :account => account, :report_type => report_type)
    account_report.parameters = {}
    account_report.parameters = parameters
    account_report.save
    csv_report = Canvas::AccountReports::Default.send(report_type, account_report)
    if csv_report.is_a? Hash
      csv_report.inject({}) do |result, (key, csv)|
        all_parsed = FasterCSV.parse(csv).to_a
        all_parsed[1..-1].sort_by { |r| r[column] }
        result[key] = all_parsed
        result
      end
    else
      all_parsed = FasterCSV.parse(csv_report).to_a
      all_parsed[1..-1].sort_by { |r| r[column] }
    end
  end
end