# frozen_string_literal: true

# Copyright (C) 2014 - present Instructure, Inc.
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

class PastGlobalAnnouncements
  class << self
    include SeleniumDependencies

    def view_select
      f('[data-testid="GlobalAnnouncementSelect"]')
    end

    def current_select_option
      f("#current_option")
    end

    def past_select_option
      f("#recent_option")
    end

    def tabs
      f('[data-testid="GlobalAnnouncementTabs"]')
    end

    def current_tab
      f('[data-testid="GlobalAnnouncementCurrentTab"]')
    end

    def past_tab
      f('[data-testid="GlobalAnnouncementPastTab"]')
    end
  end
end
