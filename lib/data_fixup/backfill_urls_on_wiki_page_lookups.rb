# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module DataFixup::BackfillUrlsOnWikiPageLookups
  def self.run(start_id, end_id)
    WikiPage.not_deleted.where(id: start_id..end_id).where.not(url: nil).where(current_lookup_id: nil).find_in_batches(batch_size: 1_000) do |pages|
      unless pages.empty?
        WikiPageLookup.transaction do
          lookups = pages.map do |page|
            {
              slug: page.url,
              context_id: page.context_id,
              context_type: page.context_type,
              wiki_page_id: page.id,
              root_account_id: page.root_account_id
            }
          end
          WikiPageLookup.insert_all!(lookups)
          WikiPage.joins(:wiki_page_lookups).where(current_lookup_id: nil).update_all("current_lookup_id=wiki_page_lookups.id")
        end
      end
    end
  end
end
