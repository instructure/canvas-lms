#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../common'

class AnnouncementNewEdit
  class << self
    include SeleniumDependencies

    # ---------------------- Page ----------------------
    def visit(course)
      get("/courses/#{course.id}/discussion_topics/new?is_announcement=true")
    end

    def set_section_specific_announcements_flag(course, state)
      course.account.set_feature_flag! :section_specific_announcements, state
    end

    def new_announcement_url
      '/discussion_topics/new?is_announcement=true'
    end

    def individual_announcement_url(announcement)
      "/discussion_topics/#{announcement.id}"
    end

    # ---------------------- Controls ----------------------
    def section_autocomplete_css
      "#sections_autocomplete_root input[type='text']"
    end

    def submit_announcement_form
      submit_form('.form-actions')
    end

    def add_message(message)
      type_in_tiny('textarea[name=message]', message)
    end

    def add_title(title)
      replace_content(f('input[name=title]'), title)
    end

    def section_error
      f('#sections_autocomplete_root').text
    end

    def select_a_section(section_name)
      fj(section_autocomplete_css).click
      if !section_name.empty?
        set_value(fj(section_autocomplete_css), section_name)
        driver.action.send_keys(:enter).perform
      else
        driver.action.send_keys(:backspace).perform
      end
      wait_for_ajax_requests
    end
  end
end
