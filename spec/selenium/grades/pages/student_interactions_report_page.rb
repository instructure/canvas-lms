#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../../common'

class StudentInteractionsReport
  class << self
    include SeleniumDependencies

    def report
      f('.report')
    end

    def current_score(student_name)
      ff('td', student_row_number(student_name))[2].text
    end

    def student_row_number(student_name)
      rows = ff('.report>tbody>tr')
      rows.each do |row|
        if ff('td')[0].text == student_name
          return row
        end
      end
    end
  end
end
