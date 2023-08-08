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
    join_sql = WikiPage.sanitize_sql_array(["LEFT OUTER JOIN #{WikiPage.quoted_table_name} wp ON wp.url = wiki_pages.url AND wp.context_id = wiki_pages.context_id AND wp.context_type = wiki_pages.context_type AND wp.id <> wiki_pages.id AND wp.workflow_state<>'deleted' AND wp.id BETWEEN %i AND %i", start_id, end_id])
    loop do
      pages = WikiPage.not_deleted.where(id: start_id..end_id).where.not(url: nil).where(current_lookup_id: nil).limit(1000)
                      .joins(join_sql)
                      .distinct
      break if pages.empty?

      lookups = pages.where.not(wp: { url: nil }).map do |page|
        {
          slug: "page_id:#{page.id}",
          context_id: page.context_id,
          context_type: page.context_type,
          wiki_page_id: page.id,
          root_account_id: page.root_account_id
        }
      end
      lookups += pages.where(wp: { url: nil }).map do |page|
        {
          slug: page.url,
          context_id: page.context_id,
          context_type: page.context_type,
          wiki_page_id: page.id,
          root_account_id: page.root_account_id
        }
      end
      lookups.each_slice(1000) do |lookup_slice|
        WikiPageLookup.transaction do
          WikiPageLookup.upsert_all(
            lookup_slice,
            unique_by: %i[context_id context_type slug],
            on_duplicate: Arel.sql("slug = 'page_id:' || #{WikiPageLookup.quoted_table_name}.wiki_page_id")
          )
          WikiPage.joins(:wiki_page_lookups).where(current_lookup_id: nil).where(id: lookup_slice.pluck(:wiki_page_id)).update_all("current_lookup_id=wiki_page_lookups.id")
        end
      end
    end
  end
end
