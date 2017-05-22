#
# Copyright (C) 2015 - present Instructure, Inc.
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

module DataFixup::SetWikiHasNoFrontPage
  def self.run
    while Wiki.where(:has_no_front_page => nil, :front_page_url => nil).
      where("NOT EXISTS (?)", WikiPage.where("id=wiki_pages.wiki_id AND wiki_pages.url = ?",
            Wiki::DEFAULT_FRONT_PAGE_URL)).
      limit(1000).update_all(:has_no_front_page => true) > 0
    end
  end
end
