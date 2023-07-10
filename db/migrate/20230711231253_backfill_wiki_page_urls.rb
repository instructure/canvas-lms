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

class BackfillWikiPageUrls < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    WikiPage.find_ids_in_ranges(batch_size: 10_000) do |start_id, end_id|
      DataFixup::BackfillUrlsOnWikiPageLookups.delay_if_production(
        priority: Delayed::LOWER_PRIORITY,
        n_strand: ["backfill_urls_on_wiki_page_lookups", Shard.current.database_server.id]
      ).run(start_id, end_id)
    end
  end
end
