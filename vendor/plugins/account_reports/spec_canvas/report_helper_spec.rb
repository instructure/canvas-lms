#
# Copyright (C) 2013 - 2014 Instructure, Inc.
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

module Canvas::AccountReports
  class TestReport
    include Canvas::AccountReports::ReportHelper

    def initialize(account_report)
      @account_report = account_report
    end
  end
end

describe "report helper" do
  let(:account) { Account.default }
  let(:account_report) { AccountReport.new(:report_type => 'test_report', :account => account) }
  let(:report) { Canvas::AccountReports::TestReport.new(account_report) }

  describe "#send_report" do
    before do
      Canvas::AccountReports.stubs(available_reports: {account_report.report_type => {title: 'test_report'}})
      report.stubs(:report_title).returns('TitleReport')
    end

    it "Should not break for nil parameters" do
      Canvas::AccountReports.expects(:message_recipient)
      report.send_report
    end
  end

  describe "timezone_strftime" do
    it "Should format DateTime" do
      date_time = DateTime.new(2003, 9, 13)
      formatted = report.timezone_strftime(date_time, '%d-%b')
      formatted.should == "13-Sep"
    end

    it "Should format Time" do
      time_zone = Time.use_zone('UTC') { Time.zone.parse('2013-09-13T00:00:00Z') }
      formatted = report.timezone_strftime(time_zone, '%d-%b')
      formatted.should == "13-Sep"
    end

    it "Should format String" do
      time_zone = Time.use_zone('UTC') { Time.zone.parse('2013-09-13T00:00:00Z') }
      formatted = report.timezone_strftime(time_zone.to_s, '%d-%b')
      formatted.should == "13-Sep"
    end
  end
end