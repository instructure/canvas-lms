#
# Copyright (C) 2013 - present Instructure, Inc.
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

module DataFixup::FixImportedWikiPageWorkflow
  # finds unpublished wiki pages that are linked to active content_tags
  def self.broken_wiki_page_scope
    WikiPage.joins("INNER JOIN #{ContentTag.quoted_table_name} ON content_tags.content_id = wiki_pages.id"
    ).where(["content_tags.content_type = ? AND content_tags.workflow_state = ? AND
      wiki_pages.workflow_state = ?", "WikiPage", "active", "unpublished"])
  end

  def self.run
    self.broken_wiki_page_scope.find_in_batches do |wiki_pages|
      WikiPage.where(:id => wiki_pages).update_all(:workflow_state => 'active')
    end
  end
end
