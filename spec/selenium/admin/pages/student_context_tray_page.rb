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

class StudentContextTray
  class << self
    include SeleniumDependencies

    # selectors
    def student_tray_header
      f(".StudentContextTray-Header")
    end

    def student_avatar_link
      f(".StudentContextTray__Avatar a")
    end

    def student_name_link
      f(".StudentContextTray-Header__NameLink a")
    end

    # actions & methods
    def wait_for_student_tray
      wait_for(method: nil, timeout: 1) { student_name_link.displayed? }
    end
  end
end
