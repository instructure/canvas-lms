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

module UserNotesHelper
  def pageless(total_pages, url = nil)
    js_env user_note_list_pageless_options: {
      totalPages: total_pages,
      url:,
      loaderHtml: <<~HTML
        <div id="pageless-loader" style="display:none;text-align:center;width:100%;">
          <div class="msg" style="color: #666;font-size:2em">
            #{t("#user_notes.messages.loading_more", "Loading more entries")}
          </div>
          <img src="/images/load.gif" title="load" alt="#{t("#user_notes.tooltips.loading_more", "loading more results")}" style="margin: 10px auto" />
        </div>
      HTML
    }
  end
end
