# frozen_string_literal: true

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

module BroadcastPolicies
  class WikiPagePolicy
    attr_reader :wiki_page

    def initialize(wiki_page)
      @wiki_page = wiki_page
    end

    def should_dispatch_updated_wiki_page?
      if wiki_page.context
        return false if wiki_page.context.concluded?
        return false if wiki_page.context.respond_to?(:unpublished?) && wiki_page.wiki.context.unpublished?
      end
      return false unless created_before?(1.minutes.ago)
      changed_while_published? || wiki_page.changed_state(:active)
    end

    def created_before?(time)
      wiki_page.created_at < time
    end

    def changed_while_published?
      wiki_page.published? &&
        wiki_page.wiki_page_changed &&
        !wiki_page.just_created
    end
  end
end
