# frozen_string_literal: true

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
require_relative "../../common"

module RCENextPage
  #=====================================================================================================================
  # General UI

  def tray_container
    f('[data-testid="CanvasContentTray"]')
  end

  def tray_container_exists?
    element_exists?('[data-testid="CanvasContentTray"]')
  end

  def visible_keyboard_shortcut_button
    ffj('button:has([name="IconKeyboardShortcuts"])')[1]
  end

  def click_visible_keyboard_shortcut_button
    visible_keyboard_shortcut_button.click
  end

  def full_screen_button
    f('button[title="Fullscreen"]')
  end

  def click_full_screen_button
    full_screen_button.click
  end

  def exit_full_screen_button
    f('button[title="Exit Fullscreen"]')
  end

  def full_screen_menu_item
    menubar_open_menu("View")
    menu_item_by_name("Fullscreen")
  end

  def exit_full_screen_menu_item
    menubar_open_menu("View")
    menu_item_by_name("Exit Fullscreen")
  end

  def find_and_replace_menu_item
    menubar_open_menu("Tools")
    menu_item_by_name("Find and Replace")
  end

  def keyboard_shortcut_modal
    f('[role="dialog"][aria-label="Keyboard Shortcuts"]')
  end

  def alt_text_textbox
    f('textarea[aria-describedby="alt-text-label-tooltip"]')
  end

  def tiny_rce_ifr_id
    f(".tox-editor-container iframe")["id"]
  end

  def save_button
    find_button("Save")
  end

  def fullscreen_element
    driver.execute_script("return document.fullscreenElement")
  end

  def rce_page_body_ifr_id
    f("iframe.tox-edit-area__iframe")["id"]
  end

  def rce_page_body_ifr_style
    element_value_for_attr(f("iframe.tox-edit-area__iframe"), "style")
  end

  def editor_window
    f("form.edit-form .edit-content")
  end

  def click_editor_window
    editor_window.click
  end

  def formatting_dropdown
    f("button[aria-label='Blocks'")
  end

  def click_formatting_dropdown
    formatting_dropdown.click
  end

  def preformatted_option
    f('[role^="menuitem"][title=" Preformatted"]')
  end

  def click_preformatted_option
    preformatted_option.click
  end

  def decorative_options_checkbox
    fxpath('//div/input[@type="checkbox"]/..')
  end

  def click_decorative_options_checkbox
    decorative_options_checkbox.click
  end

  def overflow_toolbar_selector
    ".tox-toolbar__overflow"
  end

  def overflow_toolbar
    f(overflow_toolbar_selector)
  end

  def embed_code_textarea
    fj('label:contains("Embed Code")')
  end

  def embed_submit_button
    f('[aria-label="Embed"] button[type="submit"]')
  end

  def click_embed_submit_button
    embed_submit_button.click
  end

  def editor_view_button
    f('button[data-btn-id="rce-edit-btn"]')
  end

  def click_editor_view_button
    force_click('button[data-btn-id="rce-edit-btn"]')
  end

  def switch_to_html_view
    click_editor_view_button
  end

  def switch_to_raw_html_editor
    button = f('button[data-btn-id="rce-editormessage-btn"]')
    if button.text == "Switch to raw HTML Editor"
      button.click
    end
  end

  def switch_to_editor_view
    click_editor_view_button
  end

  def insert_tiny_text(text = "hello")
    in_frame tiny_rce_ifr_id do
      tinyrce_element = f("body")
      tinyrce_element.click
      tinyrce_element.send_keys("#{text}\n") # newline guarantees a tinymce change event
    end
  end

  def count_elems_by_tagname(tagname)
    # if I use ff('a').length, it takes much longer to timeout before finally
    # throwing the Selenium::WebDriver::Error::NoSuchElementError
    # so ignore Gergich's whining.
    driver.execute_script("return document.querySelectorAll('#{tagname}').length")
  end

  def select_text_of_element_by_id(id)
    script = <<~JS
      const id = arguments[0]
      const win = document.querySelector('iframe.tox-edit-area__iframe').contentWindow
      const rng = win.document.createRange()
      rng.setStart(win.document.getElementById(id).firstChild, 0)
      rng.setEnd(win.document.getElementById(id).firstChild, 9)
      const sel = win.getSelection()
      sel.removeAllRanges()
      sel.addRange(rng)
    JS

    driver.execute_script script, id
  end

  def rce_validate_wiki_style_attrib(type, value, selectors)
    in_frame rce_page_body_ifr_id do
      expect(f("#tinymce #{selectors}").attribute("style")).to match("#{type}: #{value};")
    end
  end

  def rce_validate_wiki_style_attrib_empty(selectors)
    in_frame rce_page_body_ifr_id do
      expect(f("#tinymce #{selectors}").attribute("style")).to be_empty
    end
  end

  def enter_search_data(search_term)
    replace_content(search_field, search_term)
    driver.action.send_keys(:enter).perform
  end

  #=====================================================================================================================
  # Accordions

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

  #=====================================================================================================================
  # Content tray

  def content_tray_content_type
    f('[data-testid="filter-content-type"]')
  end

  def content_tray_content_type_links
    f("#links")
  end

  def content_tray_content_subtype
    f('[data-testid="filter-content-subtype"]')
  end

  def content_tray_content_subtype_images
    f("#images")
  end

  def content_tray_sort_by
    f('[data-testid="filter-sort-by"]')
  end

  def content_tray_sort_by_date_added
    f("#date_added")
  end

  def change_content_tray_content_type(which)
    content_type = content_tray_content_type
    content_type.click
    options_id = content_type.attribute("aria-owns")
    options = f("##{options_id}")
    option = fj(":contains(#{which})", options)
    option.click
  end

  def change_content_tray_content_subtype(subtype)
    content_subtype = content_tray_content_subtype
    content_subtype.click
    options_id = content_subtype.attribute("aria-owns")
    options = f("##{options_id}")
    option = fj(":contains(#{subtype})", options)
    option.click
  end

  def content_tray_close_button
    fj('[data-testid="CanvasContentTray"] button:contains("Close")')
  end

  def click_content_tray_close_button
    content_tray_close_button.click
    wait_for_animations
  end

  #=====================================================================================================================
  # New Page

  def new_page_link
    f("#rcs-LinkToNewPage-btn-link")
  end

  def click_new_page_link
    new_page_link.click
  end

  def new_page_name_input
    f("#new-page-name-input")
  end

  def new_page_submit_button
    f("#rcs-LinkToNewPage-submit")
  end

  def click_new_page_submit
    new_page_submit_button.click
  end

  #=====================================================================================================================
  # Wiki

  def wiki_body
    f("#tinymce")
  end

  def wiki_body_paragraph
    f("#tinymce p")
  end

  def wiki_body_anchor
    f("#tinymce p a")
  end

  def wiki_body_image
    f("#tinymce p img")
  end

  #=====================================================================================================================
  # Header

  def header_option
    f('[role="menuitemcheckbox"][title="Heading 2"]')
  end

  def click_header_option
    header_option.click
  end

  def subheader_option
    f('[role="menuitemcheckbox"][title=" Heading 3"]')
  end

  def click_subheader_option
    subheader_option.click
  end

  def small_header_option
    f('[role="menuitemcheckbox"][title=" Heading 4"]')
  end

  def click_small_header_option
    small_header_option.click
  end

  #=====================================================================================================================
  # Files

  def files_tab
    fj('[role="presentation"]:contains("Files")')
  end

  def click_files_tab
    files_tab.click
  end

  def upload_new_file
    fj('button:contains("Upload a new file")')
  end

  def upload_file_modal
    f('[role="dialog"][aria-label="Upload File"]')
  end

  def create_course_text_file(title)
    @root_folder = Folder.root_folders(@course).first
    @text_file =
      @root_folder
      .attachments
      .create!(filename: title, context: @course) { |a| a.content_type = "text/plain" }
  end

  #=====================================================================================================================
  # Links

  def links_toolbar_menubutton
    toolbar_menubutton("Links")
  end

  def links_toolbar_menuitems
    toolbar_menuitems(links_toolbar_menubutton)
  end

  def course_links_toolbar_menuitem
    toolbar_menuitem(links_toolbar_menubutton, "Course Link")
  end

  def click_course_links_toolbar_menuitem
    course_links_toolbar_menuitem.click
  end

  def group_links_toolbar_menuitem
    toolbar_menuitem(links_toolbar_menubutton, "Group Link")
  end

  def click_group_links
    group_links_toolbar_menuitem.click
  end

  def external_link_toolbar_menuitem
    toolbar_menuitem(links_toolbar_menubutton, "External Link")
  end

  def click_external_link_toolbar_menuitem
    external_link_toolbar_menuitem.click
  end

  def remove_link_toolbar_menuitem
    toolbar_menuitem(links_toolbar_menubutton, "Remove Link")
  end

  def click_remove_link_toolbar_menuitem
    remove_link_toolbar_menuitem.click
  end

  def remove_links_toolbar_menuitem
    toolbar_menuitem(links_toolbar_menubutton, "Remove Links")
  end

  def click_remove_links_toolbar_menuitem
    remove_links_toolbar_menuitem.click
  end

  def course_links_tray
    f('[role="dialog"][aria-label="Course Links"]')
  end

  def link_options_button
    f('button[aria-label="Show link options"]')
  end

  def click_link_options_button
    link_options_button.click
  end

  def link_options_tray
    f('[role="dialog"][aria-label="Link Options"]')
  end

  def link_options_done_button
    fj('[aria-label="Link Options"] button:contains("Done")')
  end

  def click_link_options_done_button
    link_options_done_button.click
  end

  def validate_course_links_tray_closed
    expect(f("body")).not_to contain_css('[role="dialog"][aria-label="Course Links"]')
  end

  def course_item_link(title)
    fj("[data-testid='instructure_links-Link'] [role='button']:contains('#{title}')")
  end

  def click_course_item_link(title)
    course_item_link(title).click
  end

  def course_item_link_exists?(title)
    element_exists?("//*[@data-testid = 'instructure_links-Link']//*[text() = '#{title}']", true)
  end

  def pages_list_item_exists?(title)
    element_exists?("//a[. = '#{title}']", true)
  end

  def course_item_links_list
    ff('[data-testid="instructure_links-Link"]')
  end

  def display_text_link_option
    fj('label:contains("Display Text Link (Opens in a new tab)")')
  end

  def current_link_label
    f('[data-testid="selected-link-name"]')
  end

  def click_replace_link_button
    f('[data-testid="replace-link-button"]').click
  end

  def click_cancel_replace_button
    f('[data-testid="cancel-replace-button"]').click
  end

  def click_display_text_link_option
    display_text_link_option.click
  end

  def click_upload_media_submit_button
    upload_media_submit_button.click
  end

  def create_external_link(text, href)
    click_external_link_toolbar_menuitem
    expect(insert_link_modal).to be_displayed

    # linktext.clear doesn't work because it doesn't fire any events to update
    # the react component's state

    if text
      linktext = f('input[name="linktext')

      linktext.send_keys(:backspace) until linktext.property("value").empty?
      linktext.send_keys(text) if text
    end
    if href
      linklink = f('input[name="linklink"]')
      linklink.send_keys(:backspace) until linklink.property("value").empty?
      linklink.send_keys(href)
    end
    fj('[role="dialog"] button:contains("Done")').click
  end

  def insert_link_modal
    f('[role="dialog"][aria-label="Insert Link"]')
  end

  def click_sidebar_link(title)
    sidebar_link(title).click
  end

  def click_link_for_options
    in_frame tiny_rce_ifr_id do
      f("a").click
    end
  end

  def sidebar_link(title)
    fj("aside li:contains('#{title}')")
  end

  def create_wiki_page_link(title)
    click_course_links_toolbar_menuitem
    click_pages_accordion
    click_course_item_link(title)
  end

  def open_edit_link_tray
    click_link_for_options
    click_link_options_button
  end

  def change_link_text_input(new_text)
    input = f('[data-testid="link-text-input"]')
    input.send_keys(:backspace) until input.property("value").empty?
    input.send_keys(new_text)
  end

  #=====================================================================================================================
  # Images

  def images_toolbar_menubutton
    toolbar_menubutton("Images")
  end

  def course_images_toolbar_menuitem
    toolbar_menuitem(images_toolbar_menubutton, "Course Images")
  end

  def click_course_images_toolbar_menuitem
    course_images_toolbar_menuitem.click
    wait_for_ajaximations
  end

  def user_images_toolbar_menuitem
    toolbar_menuitem(images_toolbar_menubutton, "User Images")
  end

  def click_user_images_toolbar_menuitem
    user_images_toolbar_menuitem.click
    wait_for_ajaximations
  end

  def upload_image_toolbar_menuitem
    toolbar_menuitem(images_toolbar_menubutton, "Upload Image")
  end

  def click_upload_image_toolbar_menuitem
    upload_image_toolbar_menuitem.click
    wait_for_ajaximations
  end

  def images_tab
    fj('[role="presentation"]:contains("Images")')
  end

  def image_link(title)
    fxpath("//button[.//img[contains(@title,'Click to embed #{title}')]]")
  end

  def image_links
    ffxpath("//button[.//img[contains(@title,'Click to embed')]]")
  end

  def user_image_links
    ff("[data-testid='instructure_links-ImagesPanel'] button")
  end

  def course_images_tray
    f('[role="dialog"][aria-label="Course Images"]')
  end

  def upload_image_modal
    f('[role="dialog"][aria-label="Upload Image"]')
  end

  def image_options_button
    f('button[aria-label="Show image options"]')
  end

  def click_image_options_button
    image_options_button.click
  end

  def image_options_tray
    f('[role="dialog"][aria-label="Image Options Tray"]')
  end

  def image_options_done_button
    fj('[aria-label="Image Options Tray"] button:contains("Done")')
  end

  def click_image_options_done_button
    image_options_done_button.click
  end

  def click_image_menubar_button
    click_insert_menu_button
    menu_option_by_name("Image").click
  end

  def click_in_body_image(title)
    in_body_image(title).click
  end

  def click_images_tab
    images_tab.click
  end

  def click_image_link(title)
    image_link(title).click
  end

  #=====================================================================================================================
  # Superscript and Subscript

  def superscript_toolbar_menubutton
    toolbar_menubutton("Superscript and Subscript")
  end

  def superscript_toolbar_menuitem
    toolbar_menuitem(superscript_toolbar_menubutton, "Superscript")
  end

  def subscript_toolbar_menuitem
    toolbar_menuitem(superscript_toolbar_menubutton, "Subscript")
  end

  #=====================================================================================================================
  # Media

  #---------------------------------------------------------------------------------------------------------------------
  # Toolbar

  def media_toolbar_menubutton
    toolbar_menubutton("Record/Upload Media")
  end

  def upload_media_toolbar_menuitem
    toolbar_menuitem(media_toolbar_menubutton, "Upload/Record Media")
  end

  def click_upload_media_toolbar_menuitem
    upload_media_toolbar_menuitem.click
    wait_for_ajaximations
  end

  def course_media_toolbar_menuitem
    toolbar_menuitem(media_toolbar_menubutton, "Course Media")
  end

  def click_course_media_toolbar_menuitem
    course_media_toolbar_menuitem.click
    wait_for_ajaximations
  end

  def user_media_toolbar_menuitem
    toolbar_menuitem(media_toolbar_menubutton, "User Media")
  end

  def click_user_media_toolbar_menuitem
    user_media_toolbar_menuitem.click
    wait_for_ajaximations
  end

  #---------------------------------------------------------------------------------------------------------------------

  def upload_media_submit_button
    f('[aria-label="Upload Media"] button[type="submit"]')
  end

  def upload_media_modal
    f('[role="dialog"][aria-label="Upload Media"')
  end

  def course_media_links
    ff("[data-testid='instructure_links-Link']")
  end

  #=====================================================================================================================
  # Documents

  #---------------------------------------------------------------------------------------------------------------------
  # Toolbar

  def document_toolbar_menubutton
    toolbar_menubutton("Documents")
  end

  def upload_document_toolbar_menuitem
    toolbar_menuitem(document_toolbar_menubutton, "Upload Document")
  end

  def click_upload_document_toolbar_menuitem
    upload_document_toolbar_menuitem.click
    wait_for_ajaximations
  end

  def course_documents_toolbar_menuitem
    toolbar_menuitem(document_toolbar_menubutton, "Course Documents")
  end

  def click_course_documents_toolbar_menuitem
    course_documents_toolbar_menuitem.click
    wait_for_ajaximations
  end

  def user_documents_toolbar_menuitem
    toolbar_menuitem(document_toolbar_menubutton, "User Documents")
  end

  def click_user_documents_toolbar_menuitem
    user_documents_toolbar_menuitem.click
    wait_for_ajaximations
  end

  def group_documents_toolbar_menuitem
    toolbar_menuitem(document_toolbar_menubutton, "Group Documents")
  end

  def click_group_documents_toolbar_menuitem
    group_documents_toolbar_menuitem.click
    wait_for_ajaximations
  end

  #---------------------------------------------------------------------------------------------------------------------

  def upload_document_modal
    f('[role="dialog"][aria-label="Upload File"')
  end

  def click_document_menubar_button
    click_insert_menu_button
    menu_option_by_name("Document").click
  end

  def click_document_link(title)
    document_link(title).click
  end

  def document_link(title)
    fj("[aria-label='Course Documents'] [role='button']:contains('#{title}')")
  end

  def course_document_links
    ff("[data-testid='instructure_links-Link']")
  end

  #=====================================================================================================================
  # Embed

  def embed_toolbar_button
    possibly_hidden_toolbar_button('button[title="Embed"]')
  end

  def click_embed_toolbar_button
    embed_toolbar_button.click
  end

  #=====================================================================================================================
  # LTI Tools

  def lti_tools_modal
    f('[role="dialog"][aria-label="Apps"]')
  end

  def lti_favorite_button
    possibly_hidden_toolbar_button('button[aria-label="Commons Favorites"')
  end

  def lti_favorite_modal
    f('[role="dialog"][aria-label="Embed content from External Tool"]')
  end

  def lti_tools_button
    possibly_hidden_toolbar_button('button[aria-label="Apps"][aria-hidden="false"]')
  end

  def lti_tools_button_with_mru
    possibly_hidden_toolbar_button('button[aria-label="Apps"][aria-expanded]')
  end

  #=====================================================================================================================
  # Alignment

  def alignment_toolbar_menubutton
    toolbar_menubutton("Align")
  end

  def left_align_toolbar_menuitem
    toolbar_menuitem(alignment_toolbar_menubutton, "Left Align")
  end

  def center_align_toolbar_menuitem
    toolbar_menuitem(alignment_toolbar_menubutton, "Center Align")
  end

  def right_align_toolbar_menuitem
    toolbar_menuitem(alignment_toolbar_menubutton, "Right Align")
  end

  #=====================================================================================================================
  # Lists

  def lists_toolbar_splitbutton
    possibly_hidden_toolbar_button('[role="button"][title="Ordered and Unordered Lists"]')
  end

  def lists_toolbar_quickaction
    possibly_hidden_toolbar_button('[role="button"][title="Ordered and Unordered Lists"] .tox-tbtn')
  end

  def click_lists_toolbar_quickaction
    lists_toolbar_quickaction.click
  end

  def lists_toolbar_menubutton
    possibly_hidden_toolbar_button('[role="button"][title="Ordered and Unordered Lists"] .tox-split-button__chevron')
  end

  def click_lists_toolbar_menubutton
    lists_toolbar_menubutton.click
  end

  def bullet_list_toolbar_menuitem
    toolbar_menuitem(lists_toolbar_menubutton, "default bulleted unordered list")
  end

  def click_bullet_list_toolbar_menuitem
    bullet_list_toolbar_menuitem.click
  end

  def numbered_list_toolbar_menuitem
    toolbar_menuitem(lists_toolbar_menubutton, "default numerical ordered list")
  end

  def click_numbered_list_toolbar_menuitem
    numbered_list_toolbar_menuitem.click
  end

  #=====================================================================================================================
  # Indentation

  def indent_toolbar_menubutton
    toolbar_menubutton("Increase Indent")
  end

  def increase_indent_toolbar_menuitem
    toolbar_menuitem(indent_toolbar_menubutton, "Increase Indent")
  end

  def decrease_indent_toolbar_menuitem
    toolbar_menuitem(indent_toolbar_menubutton, "Decrease Indent")
  end

  #=====================================================================================================================
  # Formatting

  #=====================================================================================================================
  # Tables

  #=====================================================================================================================
  # Text Direction

  def click_ltr
    menu_item_by_name("Format").click
    menu_option_by_name("Directionality").click
    menu_option_by_name("Left-to-Right").click
  end

  def click_rtl
    menu_item_by_name("Format").click
    menu_option_by_name("Directionality").click
    menu_option_by_name("Right-to-Left").click
  end

  def click_right_to_left_option
    right_to_left_button.click
  end

  #=====================================================================================================================
  # Math

  def mathjax_element_exists_in_title?
    element_exists?(".assignment-title .MathJax_Preview")
  end

  def equation_editor_modal_exists?
    element_exists?("[aria-label='Equation Editor']")
  end

  def math_rendering_exists?
    element_exists?("#MathJax-Element-1-Frame")
  end

  def equation_editor_button
    possibly_hidden_toolbar_button('button[aria-label="Insert Math Equation"]')
  end

  def equation_editor_done_button
    f("[data-testid='equation-editor-modal-done']")
  end

  def equation_editor_close_button
    f("[data-testid='equation-editor-modal-close']")
  end

  def math_image
    f(".equation_image")
  end

  def edit_math_image_button
    find_button("Edit Equation")
  end

  def advanced_editor_toggle
    parent_fxpath(advanced_editor_toggle_child)
  end

  def advanced_editor_toggle_child
    f("[data-testid='advanced-toggle']")
  end

  def advanced_editor_textarea
    f("[data-testid='advanced-editor']")
  end

  def basic_editor_textarea
    f("[data-testid='math-field")
  end

  def first_math_symbol_button
    find_from_element_fxpath(ff('[data-testid="math-symbol-icon"]')[0], "../../../../..")
  end

  #=====================================================================================================================
  # Embed

  #=====================================================================================================================
  # Search

  def search_field
    f('[placeholder="Search"')
  end

  #=====================================================================================================================
  # Icon Maker

  def iconmaker_toolbar_menubutton
    toolbar_menubutton("Icon Maker Icons")
  end

  def create_icon_toolbar_menuitem
    toolbar_menuitem(iconmaker_toolbar_menubutton, "Create Icon Maker Icon")
  end

  def saved_icons_toolbar_menuitem
    toolbar_menuitem(iconmaker_toolbar_menubutton, "Saved Icon Maker Icons")
  end

  def iconmaker_addimage_menu
    f('[data-testid="add-image"]')
  end

  def iconmaker_singlecolor_option
    f('[id="SingleColor"]')
  end

  def iconmaker_singlecolor_articon
    f('[data-testid="icon-art"]')
  end

  def iconmaker_image_preview
    f('[data-testid="selected-image-preview"]')
  end

  #=====================================================================================================================
  # Assignment related

  def assignment_published_status
    f('[name="IconPublish"]')
  end

  def assignment_unpublished_status
    f('[name="IconUnpublished"]')
  end

  def assignment_due_date_exists?(due_date)
    modified_due_date = due_date.strftime("%B %-d, %Y")
    element_exists?("//*[contains(text(),'#{modified_due_date}')]", true)
  end

  #=====================================================================================================================
  # A11y Checker

  def a11y_checker_button
    fj('button:has([name="IconA11y"])')
  end

  def click_a11y_checker_button
    a11y_checker_button.click
  end

  def a11y_checker_tray
    f("div[aria-label='Accessibility Checker'")
  end

  #=====================================================================================================================
  # Toolbar Util

  def rce_next_toolbar
    f(".tox-toolbar__primary")
  end

  def more_toolbar_button
    f('button[aria-label="More..."]')
  end

  def click_more_toolbar_button
    more_toolbar_button.click
  end

  def possibly_hidden_toolbar_button(selector)
    element = f(selector)
    if !element.displayed? || !element.enabled?
      more_toolbar_button.click

      # Wait for the toolbar opening animation to finish
      # Toolbar buttons can't be interacted with until it's done
      wait_for_no_such_element { f(".tox-toolbar__overflow--growing") }
    end
    element
  end

  def toolbar_button(button_label)
    possibly_hidden_toolbar_button("[role=toolbar] [aria-label=\"#{button_label}\"]")
  end

  def toolbar_menubutton(button_label)
    # There are two types of buttons in the toolbar with menus:
    # Menu buttons are actual <button> elements and can be selected directly
    # Split buttons aren't <button> but have role="button", and we need the chevron
    possibly_hidden_toolbar_button("[role=toolbar] button[aria-label=\"#{button_label}\"]")
  rescue Selenium::WebDriver::Error::NoSuchElementError
    f("[role=toolbar] [aria-label=\"#{button_label}\"] .tox-split-button__chevron")
  end

  def toolbar_menuitem(button_or_label, menuitem_label)
    selector = "[role=menu] [role^=menuitem][title=\"#{menuitem_label}\"]"

    begin
      f(selector)
    rescue Selenium::WebDriver::Error::NoSuchElementError
      if button_or_label.is_a?(String)
        toolbar_menubutton(button_or_label).click
      else
        button_or_label.click
      end
      f(selector)
    end
  end

  def toolbar_menuitems(button_or_label)
    menubutton = button_or_label.is_a?(String) ? toolbar_menubutton(button_or_label) : button_or_label

    # The aria-owns attribute is only present when the menu is open
    # So we click the menubutton unless it's already open
    menubutton.click unless menubutton.attribute("aria-owns")

    menuid = menubutton.attribute("aria-owns")

    ff("##{menuid} [role^=menuitem]")
  end

  #=====================================================================================================================
  # Menubar Util

  def menubar_open_menu(menu_name)
    menubar_button(menu_name).click
  end

  def click_menubar_menu_item(item_name)
    menubar_menu_item(item_name).click
  end

  def click_menubar_submenu_item(menu_name, item_name)
    menubar_button(menu_name).click
    menubar_menu_item(item_name).click
  end

  def menu_items_by_menu_id(menu_id)
    ffj("##{menu_id} [role^='menuitem']")
  end

  def menu_item_by_menu_id(menu_id, item_label)
    fj("##{menu_id}:contains('#{item_label}')")
  end

  def menu_item_by_name(menu_name)
    fj("[role='menuitem']:contains('#{menu_name}')")
  end

  def menu_option_by_name(menu_option)
    fj("div.tox-collection__item:contains('#{menu_option}')")
  end

  def menubar_button(menu_name)
    fj("[role='menubar'] button[role^='menuitem']:contains('#{menu_name}')")
  end

  def menubar_menu_item_css(item_name)
    "[role^='menuitem'][title='#{item_name}']"
  end

  def menubar_menu_item(item_name)
    # works for sub-menus too
    f(menubar_menu_item_css(item_name))
  end

  def click_insert_menu_button
    menu_item_by_name("Insert").click
  end

  # ---- menubar items ---

  def external_link_menubar_button
    menu_option_by_name("External Link")
  end

  def image_menubar_button
    menu_option_by_name("Upload Image")
  end

  def media_menubar_button
    menu_option_by_name("Course Media")
  end

  def document_menubar_button
    menu_option_by_name("Upload Document")
  end

  def rce_selection_focus_offset
    # rubocop:disable Specs/NoExecuteScript
    driver.execute_script(
      # language=javascript
      "return document.querySelector('#wiki_page_body_ifr').contentDocument.getSelection().focusOffset"
    )
    # rubocop:enable Specs/NoExecuteScript
  end

  def clear_rce_selection
    # rubocop:disable Specs/NoExecuteScript
    driver.execute_script(
      # language=javascript
      "return document.querySelector('#wiki_page_body_ifr').contentDocument.getSelection().removeAllRanges()"
    )
    # rubocop:enable Specs/NoExecuteScript
  end
  #=====================================================================================================================
  # Find and Replace Tray

  def find_and_replace_tray_header
    f('[role="dialog"][aria-label="Find and Replace"]')
  end

  def find_and_replace_tray_find_input
    f('input[name="findtext"]')
  end

  def find_and_replace_tray_replace_input
    f('input[name="replacetext"]')
  end

  def find_and_replace_tray_replace_button
    f('button[data-testid="replace-button"]')
  end
end
