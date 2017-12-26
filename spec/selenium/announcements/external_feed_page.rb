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

class ExternalFeedPage
  class << self
    include SeleniumDependencies

    # ---------------------- Controls ----------------------
    def rss_feed_link
      f('#rss-feed-link')
    end

    def add_external_feed_expander
      # f('.feed_expander')
    end

    def feed_url_textbox
      # f('.feed_url')
    end

    def display_length_option(option)
      find_radio_button_by_value(option)
    end

    def add_feed_button
      # f('.add_feed_button')
    end

    def feed_list
      # f('.feed_list')
    end

    def feed_name(name)
      # f('.feed_name', feed_list)
    end

    # ---------------------- Actions ----------------------
    def click_rss_feed_link
      rss_feed_link.click
    end

    def add_external_feed(url, article_length)
      add_external_feed_expander.click
      type_in_tiny(feed_url_textbox, url)
      display_length_option(article_length).click
      add_feed_button.click
    end
  end
end
