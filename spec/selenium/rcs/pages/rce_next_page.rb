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
require_relative '../../common'

module RCENextPage

  # ---------------------- Controls ----------------------

  def pages_accordion_button
    fj('[data-testid="instructure_links-AccordionSection"] button:contains("Pages")')
  end

  def assignments_accordion_button
    fj('[data-testid="instructure_links-AccordionSection"] button:contains("Assignments")')
  end

  def quizzes_accordion_button
    fj('[data-testid="instructure_links-AccordionSection"] button:contains("Quizzes")')
  end

  def announcements_accordion_button
    fj('[data-testid="instructure_links-AccordionSection"] button:contains("Announcements")')
  end

  def discussions_accordion_button
    fj('[data-testid="instructure_links-AccordionSection"] button:contains("Discussions")')
  end

  def modules_accordion_button
    fj('[data-testid="instructure_links-AccordionSection"] button:contains("Modules")')
  end

  def navigation_accordion_button
    fj('[data-testid="instructure_links-AccordionSection"] button:contains("Course Navigation")')
  end

  def new_page_link
    f('#rcs-LinkToNewPage-btn-link')
  end

  def new_page_name_input
    f('#new-page-name-input')
  end

  def new_page_submit_button
    f('#rcs-LinkToNewPage-submit')
  end

  def wiki_body_anchor
    f('#tinymce p a')
  end

  def wiki_body_image
    f('#tinymce p img')
  end

  def sidebar_link(title)
    fj("aside li:contains('#{title}')")
  end

  def files_tab
    fj('[role="presentation"]:contains("Files")')
  end

  def upload_new_file
    fj('button:contains("Upload a new file")')
  end

  def images_tab
    fj('[role="presentation"]:contains("Images")')
  end

  def upload_new_image
    fj('button:contains("Upload a new image")')
  end

  def image_link(title)
    fj("[aria-label='Course Images'] button:contains('#{title}')")
  end

  def assignment_published_status
    # add selector
  end

  def assignment_unpublished_status
    # add selector
  end

  def assignment_due_date
    # add (selector).text
  end

  def possibly_hidden_toolbar_button(selector)
    button = driver.execute_script("return document.querySelector('#{selector}')")
    more_toolbar_button.click unless button
    f(selector)
  end

  def links_toolbar_button
    possibly_hidden_toolbar_button('button[title="Links"]')
  end

  def course_links
    f('[role="menuitem"][title="Course Links"]')
  end

  def images_toolbar_button
    possibly_hidden_toolbar_button('button[aria-label="Images"]')
  end

  def course_images
    f('[role="menuitem"][title="Course Images"]')
  end

  def rce_page_body_ifr_id
    f('iframe.tox-edit-area__iframe')['id']
  end

  def course_item_link(title)
    fj("[data-testid='instructure_links-Link'] button:contains('#{title}')")
  end

  def more_toolbar_button
    f('button[aria-label="More..."]')
  end

  def list_toggle_button
    # put side arrow to switch list locator here
  end

  def bullet_list_button
    # put bullet list button locator here
  end

  def numbered_list_button
    # put numbered list button locator here
  end

  def editor_window
    f("form.edit-form .edit-content")
  end

  def indent_toggle_button
    # put side arrow to switch indent locator here
  end

  def indent_button
    # put indent button locator here
  end

  def outdent_button
    # put outdent button locator here
  end

  def super_toggle_button
    # put side arrow to switch super locator here
  end

  def superscript_button
    # put superscript button locator here
  end

  def subscript_button
    # put subscript button locator here
  end

  def align_toggle_button
    # put side arrow to switch align locator here
  end

  def align_left_button
    # put align left button locator here
  end

  def align_center_button
    # put align center button locator here
  end

  def align_right_button
    # put align right button locator here
  end

  # ---------------------- Actions ----------------------

  def click_pages_accordion
    pages_accordion_button.click
  end

  def click_assignments_accordion
    assignments_accordion_button.click
  end

  def click_quizzes_accordion
    quizzes_accordion_button.click
  end

  def click_announcements_accordion
    announcements_accordion_button.click
  end

  def click_discussions_accordion
    discussions_accordion_button.click
  end

  def click_modules_accordion
    modules_accordion_button.click
  end

  def click_navigation_accordion
    navigation_accordion_button.click
  end

  def click_course_item_link(title)
    course_item_link(title).click
  end

  def click_new_page_link
    new_page_link.click
  end

  def click_new_page_submit
    new_page_submit_button.click
  end

  def click_sidebar_link(title)
    sidebar_link(title).click
  end

  def click_files_tab
    files_tab.click
  end

  def click_images_tab
    images_tab.click
  end

  def click_image_link(title)
    image_link(title).click
  end

  def click_links_toolbar_button
    links_toolbar_button.click
  end

  def click_course_links
    course_links.click
  end

  def click_images_toolbar_button
    images_toolbar_button.click
  end

  def click_course_images
    course_images.click
    wait_for_ajaximations
  end

  def click_more_toolbar_button
    more_toolbar_button.click
  end

  def click_list_toggle_button
    list_toggle_button.click
  end

  def click_bullet_list_button
    bullet_list_button.click
  end

  def click_numbered_list_button
    numbered_list_button.click
  end

  def click_indent_toggle_button
    indent_toggle_button.click
  end

  def click_indent_button
    indent_button.click
  end

  def click_outdent_button
    outdent_button.click
  end

  def click_super_toggle_button
    super_toggle_button.click
  end

  def click_superscript_button
    superscript_button.click
  end

  def click_subscript_button
    subscript_button.click
  end

  def click_align_toggle_button
    align_toggle_button.click
  end

  def click_align_left_button
    align_left_button.click
  end

  def click_align_center_button
    align_center_button.click
  end

  def click_align_right_button
    align_right_button.click
  end

  def click_editor_window
    editor_window.click
  end
end
