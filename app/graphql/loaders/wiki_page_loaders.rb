# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Loaders
  module WikiPageLoaders
    class CanUnpublishLoader < GraphQL::Batch::Loader
      def initialize(context)
        super()
        @context = context
      end

      def perform(wiki_page_ids)
        # Load wiki pages with their current_lookup association
        wiki_pages = WikiPage.where(id: wiki_page_ids).to_a
        ActiveRecord::Associations.preload(wiki_pages, :current_lookup)
        wiki_pages = wiki_pages.index_by(&:id)

        # Get front page URL once for the context
        front_page_url = @context.wiki.get_front_page_url

        # Batch check can_unpublish for all pages
        wiki_page_ids.each do |id|
          wiki_page = wiki_pages[id]
          if wiki_page
            # Use the same logic as WikiPage#can_unpublish? but without the memoization
            can_unpublish = wiki_page.url != front_page_url
            fulfill(id, can_unpublish)
          else
            fulfill(id, true) # Default to true if page doesn't exist
          end
        end
      end
    end
  end
end
