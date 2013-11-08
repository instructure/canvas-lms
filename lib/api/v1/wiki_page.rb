#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::WikiPage
  include Api::V1::Json
  include Api::V1::User
  include Api::V1::Locked

  WIKI_PAGE_JSON_ATTRS = %w(url title created_at updated_at hide_from_students editing_roles)

  def wiki_page_json(wiki_page, current_user, session, include_body = true)
    hash = api_json(wiki_page, current_user, session, :only => WIKI_PAGE_JSON_ATTRS)
    hash['editing_roles'] ||= 'teachers'
    hash['last_edited_by'] = user_display_json(wiki_page.user, wiki_page.context) if wiki_page.user
    if wiki_page.context.draft_state_enabled?
      hash['published'] = wiki_page.active?
      hash['hide_from_students'] = !hash['published']
    else
      hash['published'] = true
    end
    hash['front_page'] = wiki_page.is_front_page?
    if wiki_page.context.draft_state_enabled?
      hash['html_url'] = polymorphic_url([wiki_page.context, :named_page], :wiki_page_id => wiki_page)
    else
      hash['html_url'] = polymorphic_url([wiki_page.context, :named_wiki_page], :id => wiki_page)
    end
    locked_json(hash, wiki_page, current_user, 'page')
    hash['body'] = api_user_content(wiki_page.body) if include_body && !hash['locked_for_user'] && !hash['lock_info']
    hash
  end

  def wiki_pages_json(wiki_pages, current_user, session)
    wiki_pages.map { |page| wiki_page_json(page, current_user, session, false) }
  end

  def wiki_page_revision_json(version, current_user, current_session, include_content = true)
    page = version.model
    hash = {
      'revision_id' => version.number,
      'updated_at' => page.updated_at
    }
    if include_content
      hash.merge!({
        'url' => page.url,
        'title' => page.title,
        'body' => api_user_content(page.body)
      })
    end
    hash['edited_by'] = user_display_json(page.user, page.context) if page.user
    hash
  end

  def wiki_page_revisions_json(versions, current_user, current_session)
    versions.map { |ver| wiki_page_revision_json(ver, current_user, current_session, false) }
  end
end
