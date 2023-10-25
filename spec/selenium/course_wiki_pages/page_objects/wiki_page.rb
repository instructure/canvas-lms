# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "../../common"

module CourseWikiPage
  #------------------------------ Selectors -----------------------------
  def publish_btn_selector
    ".btn-publish"
  end

  def published_btn_selector
    ".btn-published"
  end

  def edit_btn_selector
    ".edit-wiki"
  end

  def more_options_btn_selector
    ".al-trigger"
  end

  def delete_page_menu_item_selector
    ".delete_page"
  end

  def delete_pages_btn_selector
    ".delete_pages"
  end

  #------------------------------ Elements ------------------------------
  def publish_btn
    f(publish_btn_selector)
  end

  def published_btn
    f(published_btn_selector)
  end

  def published_status_published
    f(".published-status.published")
  end

  def wiki_page_show
    f("#wiki_page_show")
  end

  def more_options_btn
    f(more_options_btn_selector)
  end

  def wiki_page_more_options_menu_open
    f(".ui-menu.ui-state-open")
  end

  def wiki_page_body
    f("body")
  end

  def wiki_page_settings_button
    fj("[role='button']:contains('Settings')")
  end

  def wiki_page_send_to_menu
    fj("li:contains('Send To...')")
  end

  def wiki_page_copy_to_menu
    fj("li:contains('Copy To...')")
  end

  def bulk_delete_btn
    f(delete_pages_btn_selector)
  end

  def confirm_delete_wiki_pages_btn
    f("#confirm_delete_wiki_pages")
  end

  def select_wiki_page_checkbox
    f("tbody.collectionViewItems input[type='checkbox']")
  end

  def immersive_reader_btn
    fj("#immersive_reader_mount_point [type='button']:contains('Immersive Reader')")
  end

  def edit_page_title_input
    f("input[data-testid='wikipage-title-input']")
  end

  def tiny_mce_input
    f("#tinymce")
  end

  def course_home_nav_menu
    fj("a:contains('Home')")
  end

  #------------------------------ Actions -------------------------------

  def visit_wiki_page_view(course_id, page_title)
    get "/courses/#{course_id}/pages/#{page_title}"
  end

  def visit_wiki_edit_page(course_id, page_title)
    get "/courses/#{course_id}/pages/#{page_title}/edit"
  end

  def publish_wiki_page
    publish_btn.click
    wait_for_ajaximations
  end

  def unpublish_wiki_page
    published_btn.click
    wait_for_ajaximations
  end

  def click_more_options_menu
    more_options_btn.click
    wait_for_ajaximations
  end

  def delete_selected_pages
    bulk_delete_btn.click
    wait_for_ajaximations
  end

  def confirm_delete_pages
    confirm_delete_wiki_pages_btn.click
    wait_for_ajaximations
  end
end
