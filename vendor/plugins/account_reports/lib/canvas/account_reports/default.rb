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

module Canvas::AccountReports
  module Default

    def self.student_assignment_outcome_map_csv(account_report)
      GradeReports.new(account_report).student_assignment_outcome_map
    end

    def self.grade_export_csv(account_report)
      GradeReports.new(account_report).grade_export
    end

    def self.sis_export_csv(account_report)
      SisExporter.new(account_report, {:sis_format => true}).csv
    end

    def self.provisioning_csv(account_report)
      SisExporter.new(account_report, {:sis_format => false}).csv
    end
  end
end
