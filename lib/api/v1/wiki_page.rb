# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  include Api::V1::Assignment

  WIKI_PAGE_JSON_ATTRS = %w[url title created_at editing_roles].freeze

  def wiki_page_json(wiki_page, current_user, session, include_body = true, opts = {})
    opts = opts.reverse_merge(include_assignment: true, assignment_opts: {})
    opts.delete(:include_assignment) unless wiki_page.context.try(:conditional_release?)

    hash = api_json(wiki_page, current_user, session, only: WIKI_PAGE_JSON_ATTRS)
    hash["page_id"] = wiki_page.id || 0 # for new page js_env; otherwise Backbone will try to POST instead of PUT
    hash["editing_roles"] ||= "teachers"
    hash["last_edited_by"] = user_display_json(wiki_page.user, wiki_page.context) if wiki_page.user
    hash["published"] = wiki_page.active?
    hash["hide_from_students"] = !hash["published"] # deprecated, but still here for now
    hash["front_page"] = wiki_page.is_front_page?
    hash["html_url"] = polymorphic_url([wiki_page.context, wiki_page])
    hash["todo_date"] = wiki_page.todo_date
    hash["publish_at"] = wiki_page.publish_at

    hash["updated_at"] = wiki_page.revised_at
    if opts[:include_assignment] && wiki_page.for_assignment?
      hash["assignment"] = assignment_json(wiki_page.assignment, current_user, session, opts[:assignment_opts])
      hash["assignment"]["assignment_overrides"] =
        assignment_overrides_json(
          wiki_page.assignment.overrides_for(current_user, ensure_set_not_empty: true)
        )
    end
    locked_json(hash, wiki_page, current_user, "page", deep_check_if_needed: opts[:deep_check_if_needed])
    if include_body && !hash["locked_for_user"] && !hash["lock_info"]
      hash["body"] = api_user_content(wiki_page.body, wiki_page.context)
      wiki_page.context_module_action(current_user, wiki_page.context, :read)
    end
    if opts[:master_course_status]
      hash.merge!(wiki_page.master_course_api_restriction_data(opts[:master_course_status]))
    end
    hash
  end

  def wiki_pages_json(wiki_pages, current_user, session, include_body = false, opts = {})
    wiki_pages.map { |page| wiki_page_json(page, current_user, session, include_body, opts) }
  end

  def wiki_page_revision_json(version, _current_user, _session, include_content = true, latest_version = nil)
    page = version.model
    hash = {
      "revision_id" => version.number,
      "updated_at" => page.revised_at
    }
    if latest_version
      hash["latest"] = version.number == latest_version.number
    end
    if include_content
      hash.merge!({
                    "url" => page.url,
                    "title" => page.title,
                    "body" => api_user_content(page.body)
                  })
    end
    hash["edited_by"] = user_display_json(page.user, page.context) if page.user
    hash
  end

  def wiki_page_revisions_json(versions, current_user, current_session, latest_version = nil)
    versions.map { |ver| wiki_page_revision_json(ver, current_user, current_session, false, latest_version) }
  end
end
