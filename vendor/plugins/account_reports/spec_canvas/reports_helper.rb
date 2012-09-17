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

module CustomReportsSpecHelper
  def self.find_account_module_and_reports(account_id)
    module_name = Canvas::AccountReports::AvailableReports.module_names[account_id]
    Canvas::AccountReports.const_defined?(module_name).should == true
    Canvas::AccountReports::AvailableReports.reports[account_id].each do |report|
      Canvas::AccountReports.const_get(module_name).respond_to?(report.first).should == true
    end
  end
end