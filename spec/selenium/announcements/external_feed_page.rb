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
      f("#external-rss-feed__toggle-button")
    end

    def feed_url_textbox
      f('input[name="external-rss-feed__url-input"]')
    end

    def display_length_option(type)
      input_id = f("input[type='radio'][name='verbosity-selection'][value='#{type}']").attribute('id')
      f("label[for='#{input_id}']")
    end

    def phrase_textbox
      f('input[name="external-rss-feed__phrase-input"]')
    end

    def add_feed_button
      f('#external-rss-feed__submit-button')
    end

    def feed_list
      # f('#external-rss-feed__rss-list')
    end

    def external_feeds
      ff('.announcements-tray-feed-row')
    end

    def feed_name(name)
      # TODO: Implement feed_name to grab specific feed
    end

    # ---------------------- Actions ----------------------
    def click_rss_feed_link
      rss_feed_link.click
    end

    def type_in_box(box, text)
      set_value(box, text)
      driver.action.send_keys(:enter).perform
      wait_for_ajaximations
    end

    def add_external_feed(url, article_length)
      sleep 0.5 #have to wait for instUI animations
      add_external_feed_expander.click
      type_in_box(feed_url_textbox, url)
      display_length_option(article_length).click
      add_feed_button.click
      wait_for_ajaximations
    end

    def delete_first_feed
      f('button', external_feeds[0]).click
      wait_for_ajaximations
    end
  end
end
