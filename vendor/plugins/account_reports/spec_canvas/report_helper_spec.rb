#
# Copyright (C) 2013 Instructure, Inc.
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
  let(:report){Canvas::AccountReports::TestReport.new(account_report)}

  describe "#send_report" do
    before do
      Canvas::AccountReports.stubs(:for_account => {account_report.report_type => {:title => 'test_report'}})
    end

    it "Should not break for nil parameters" do
      Canvas::AccountReports.expects(:message_recipient)
      report.send_report
    end
  end
end