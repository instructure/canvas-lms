#
# Copyright (C) 2018 - present Instructure, Inc.
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
require_relative '../../common'

class Discussion
  class << self
    include SeleniumDependencies

    # ---------------------- Controls ----------------------
    def create_reply_button
      f('.discussion-reply-box')
    end

    def post_reply_button
      fj('button:contains("Post Reply")')
    end

    def add_media_button
      f('.mce-i-media')
    end

    def close_media_modal_button
      f('.mce-close')
    end

    def media_modal
      fj('div:contains("Insert/edit media")')
    end

    # ---------------------- Page ----------------------
    def visit(course, discussion)
      get("/courses/#{course.id}/discussion_topics/#{discussion.id}")
      wait_for_ajaximations
    end

    def start_reply_with_media
      create_reply_button.click
      add_media_button.click
    end
  end
end

