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

  def wiki_body
    f('#tinymce')
  end

  def wiki_body_paragraph
    f('#tinymce p')
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

  def image_links
    ff("[aria-label='Course Images'] button")
  end

  def user_image_links
    ff("[data-testid='instructure_links-ImagesPanel'] button")
  end

  def document_link(title)
    fj("[aria-label='Course Documents'] [role='button']:contains('#{title}')")
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
    f(selector)
  rescue Selenium::WebDriver::Error::NoSuchElementError
      more_toolbar_button.click
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

  def media_toolbar_button
    possibly_hidden_toolbar_button('button[aria-label="Record/Upload Media"]')
  end

  def document_toolbar_button
    possibly_hidden_toolbar_button('button[aria-label="Documents"]')
  end

  def lti_tools_button
    possibly_hidden_toolbar_button('button[aria-label="Apps"')
  end

  def lti_tools_modal
    f('[role="dialog"][aria-label="Apps"]')
  end

  def course_images
    f('[role="menuitem"][title="Course Images"]')
  end

  def user_images
    f('[role="menuitem"][title="My Images"]')
  end

  def upload_image_button
    f('[role="menuitem"][title="Upload Image"]')
  end

  def upload_image_modal
    f('[role="dialog"][aria-label="Upload Image"')
  end

  def image_options_button
    f('button[aria-label="Show image options"]')
  end

  def image_options_tray
    f('[role="dialog"][aria-label="Image Options Tray"]')
  end

  def upload_media_button
    f('[role="menuitem"][title="Upload/Record Media"]')
  end

  def upload_media_modal
    f('[role="dialog"][aria-label="Upload Media"')
  end

  def upload_document_button
    f('[role="menuitem"][title="Upload Document"]')
  end

  def course_documents
    f('[role="menuitem"][title="Course Documents"]')
  end

  def upload_document_modal
    f('[role="dialog"][aria-label="Upload File"')
  end

  def rce_page_body_ifr_id
    f('iframe.tox-edit-area__iframe')['id']
  end

  def course_item_link(title)
    fj("[data-testid='instructure_links-Link'] [role='button']:contains('#{title}')")
  end

  def more_toolbar_button
    f('button[aria-label="More..."]')
  end

  def list_toggle_button
    f('[role="button"][title="Ordered and Unordered Lists"] .tox-split-button__chevron')
  end

  def bullet_list_button
    f('[role="menuitemcheckbox"][title="default bulleted unordered list"]')
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

  def directionality_button
    f('[role="button"][title="directionality"]')
  end

  def directionality_toggle_button
    f('[role="button"][title="directionality"] .tox-split-button__chevron')
  end

  def right_to_left_button
    f('[role="menuitemcheckbox"][title="right to left"]')
  end

  def formatting_dropdown
    f("button[aria-label='Blocks'")
  end

  def header_option
    f('[role="menuitemcheckbox"][title="Header"]')
  end

  def subheader_option
    f('[role="menuitemcheckbox"][title=" Subheader"]')
  end

  def small_header_option
    f('[role="menuitemcheckbox"][title=" Small header"]')
  end

  def preformatted_option
    f('[role="menuitemcheckbox"][title=" Preformatted"]')
  end

  def rce_next_toolbar
    f(".tox-toolbar__primary")
  end

  def a11y_checker_button
    fj('button:has([name="IconA11y"])')
  end

  def a11y_checker_tray
    f("div[aria-label='Accessibility Checker'")
  end

  def tray_container
    f('[data-testid="CanvasContentTray"]')
  end

  def display_text_link_option
    fj('label:contains("Display Text Link (Opens in a new tab)")')
  end

  def image_options_done_button
    fj('[aria-label="Image Options Tray"] button:contains("Done")')
  end

  def visible_keyboard_shortcut_button
    ffj('button:has([name="IconKeyboardShortcuts"])')[1]
  end

  def keyboard_shortcut_modal
    f('[role="dialog"][aria-label="Keyboard Shortcuts"]')
  end

  def alt_text_textbox
    f('textarea[aria-describedby="alt-text-label-tooltip"]')
  end

  def decorative_options_checkbox
    fxpath('//div/input[@type="checkbox"]/..')
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

  def click_document_link(title)
    document_link(title).click
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

  def click_media_toolbar_button
    media_toolbar_button.click
  end

  def click_document_toolbar_button
    document_toolbar_button.click
  end

  def click_course_images
    course_images.click
    wait_for_ajaximations
  end

  def click_user_images
    user_images.click
    wait_for_ajaximations
  end

  def click_upload_image
    upload_image_button.click
    wait_for_ajaximations
  end

  def click_upload_media
    upload_media_button.click
    wait_for_ajaximations
  end

  def click_upload_document
    upload_document_button.click
    wait_for_ajaximations
  end

  def click_course_documents
    course_documents.click
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

  def click_directionality_button
    directionality_button.click
  end

  def click_directionality_toggle_button
    directionality_toggle_button.click
  end

  def click_right_to_left_option
    right_to_left_button.click
  end

  def click_formatting_dropdown
    formatting_dropdown.click
  end

  def click_header_option
    header_option.click
  end

  def click_subheader_option
    subheader_option.click
  end

  def click_small_header_option
    small_header_option.click
  end

  def click_preformatted_option
    preformatted_option.click
  end

  def click_editor_window
    editor_window.click
  end

  def click_a11y_checker_button
    a11y_checker_button.click
  end

  def click_image_options_button
    image_options_button.click
  end

  def click_in_body_image(title)
    in_body_image(title).click
  end

  def click_display_text_link_option
    display_text_link_option.click
  end

  def click_image_options_done_button
    image_options_done_button.click
  end

  def click_visible_keyboard_shortcut_button
    visible_keyboard_shortcut_button.click
  end

  def click_decorative_options_checkbox
    decorative_options_checkbox.click
  end
end
