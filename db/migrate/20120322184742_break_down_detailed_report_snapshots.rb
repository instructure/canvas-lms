#
# Copyright (C) 2012 - present Instructure, Inc.
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

class BreakDownDetailedReportSnapshots < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.do_report_type(scope)
    detailed = scope.where(:account_id => nil).last
    return unless detailed
    detailed.data['detailed'].each do |(account_id, data)|
      new_detailed = detailed.clone
      new_detailed.account_id = account_id
      data['generated_at'] = detailed.data['generated_at']
      new_detailed.data = data
      new_detailed.save!
    end
  end

  def self.up
    do_report_type(ReportSnapshot.detailed)
    do_report_type(ReportSnapshot.progressive)
  end

  def self.down
  end
end
