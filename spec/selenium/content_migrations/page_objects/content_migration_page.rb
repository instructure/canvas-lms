#
# Copyright (C) 2020 - present Instructure, Inc.
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

class ContentMigrationPage
  class << self
    include SeleniumDependencies

    # Selectors
    def selective_imports(index)
      ff('[name=selective_import]')[index].click
    end

    def selective_content
      f('.migrationProgressItem .selectContentBtn').click
      wait_for_ajax_requests
    end
  end
end
