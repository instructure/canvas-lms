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
    f("#rcs-LinkToNewPage-btn-link")
  end

  def new_page_name_input
    f("#new-page-name-input")
  end

  def new_page_submit_button
    f("#rcs-LinkToNewPage-submit")
  end

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

  def image_link(title)
    fxpath("//button[.//img[contains(@title,'Click to embed #{title}')]]")
  end

  def image_links
    ffxpath("//button[.//img[contains(@title,'Click to embed')]]")
  end

  def user_image_links
    ff("[data-testid='instructure_links-ImagesPanel'] button")
  end

  def document_link(title)
    fj("[aria-label='Course Documents'] [role='button']:contains('#{title}')")
  end

  def course_document_links
    ff("[data-testid='instructure_links-Link']")
  end

  def course_media_links
    ff("[data-testid='instructure_links-Link']")
  end

  def search_field
    f('[placeholder="Search"')
  end

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

  def possibly_hidden_toolbar_button(selector)
    f(selector)
  rescue Selenium::WebDriver::Error::NoSuchElementError
    more_toolbar_button.click
    f(selector)
  end

  def iconmaker_toolbar_button
    possibly_hidden_toolbar_button('[role="button"][title="Icon Maker Icons"]')
  end

  def iconmaker_addimage_menu
    f('[data-position-target="AddImageMenu"]')
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

  def links_toolbar_button
    possibly_hidden_toolbar_button('[role="button"][title="Links"]')
  end

  def links_toolbar_menu_button
    possibly_hidden_toolbar_button('[role="button"][aria-label="Links"] .tox-split-button__chevron')
  end

  def course_links
    f('[role^="menuitem"][title="Course Link"]')
  end

  def group_links
    f('[role^="menuitem"][title="Group Link"]')
  end

  def external_links
    f('[role^="menuitem"][title="External Link"]')
  end

  def remove_link
    f('[role^="menuitem"][title="Remove Link"]')
  end

  def remove_links
    f('[role^="menuitem"][title="Remove Links"]')
  end

  def course_links_tray
    f('[role="dialog"][aria-label="Course Links"]')
  end

  def validate_course_links_tray_closed
    expect(f("body")).not_to contain_css('[role="dialog"][aria-label="Course Links"]')
  end

  def link_options_button
    f('button[aria-label="Show link options"]')
  end

  def link_options_tray
    f('[role="dialog"][aria-label="Link Options"]')
  end

  def link_options_done_button
    fj('[aria-label="Link Options"] button:contains("Done")')
  end

  def images_toolbar_button
    possibly_hidden_toolbar_button('[role="button"][aria-label="Images"]')
  end

  def images_toolbar_menu_button
    possibly_hidden_toolbar_button(
      '[role="button"][aria-label="Images"] .tox-split-button__chevron'
    )
  end

  def media_toolbar_button
    possibly_hidden_toolbar_button('[role="button"][aria-label="Record/Upload Media"]')
  end

  def media_toolbar_menu_button
    possibly_hidden_toolbar_button(
      '[role="button"][aria-label="Record/Upload Media"] .tox-split-button__chevron'
    )
  end

  def embed_toolbar_button
    possibly_hidden_toolbar_button('button[title="Embed"]')
  end

  def document_toolbar_button
    possibly_hidden_toolbar_button('[role="button"][aria-label="Documents"]')
  end

  def document_toolbar_menu_button
    possibly_hidden_toolbar_button(
      '[role="button"][aria-label="Documents"] .tox-split-button__chevron'
    )
  end

  def lti_tools_button
    possibly_hidden_toolbar_button('button[aria-label="Apps"][aria-hidden="false"]')
  end

  def lti_tools_button_with_mru
    possibly_hidden_toolbar_button('button[aria-label="Apps"][aria-expanded]')
  end

  def lti_tools_modal
    f('[role="dialog"][aria-label="Apps"]')
  end

  def lti_favorite_button
    possibly_hidden_toolbar_button('button[aria-label="Commons Favorites"')
  end

  def lti_favorite_modal
    f('[role="dialog"][aria-label="Embed content from External Tool"]')
  end

  def course_images
    f('[role^="menuitem"][title="Course Images"]')
  end

  def user_images
    f('[role^="menuitem"][title="User Images"]')
  end

  def upload_image_button
    f('[role^="menuitem"][title="Upload Image"]')
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

  def image_options_tray
    f('[role="dialog"][aria-label="Image Options Tray"]')
  end

  def upload_media_button
    f('[role^="menuitem"][title="Upload/Record Media"]')
  end

  def upload_media_modal
    f('[role="dialog"][aria-label="Upload Media"')
  end

  def course_media
    f('[role^="menuitem"][title="Course Media"]')
  end

  def user_media
    f('[role^="menuitem"][title="User Media"]')
  end

  def upload_document_button
    f('[role^="menuitem"][title="Upload Document"]')
  end

  def course_documents
    f('[role^="menuitem"][title="Course Documents"]')
  end

  def user_documents
    f('[role^="menuitem"][title="User Documents"]')
  end

  def group_documents
    f('[role^="menuitem"][title="Group Documents"]')
  end

  def upload_document_modal
    f('[role="dialog"][aria-label="Upload File"')
  end

  def rce_page_body_ifr_id
    f("iframe.tox-edit-area__iframe")["id"]
  end

  def rce_page_body_ifr_style
    element_value_for_attr(f("iframe.tox-edit-area__iframe"), "style")
  end

  def course_item_link(title)
    fj("[data-testid='instructure_links-Link'] [role='button']:contains('#{title}')")
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

  def more_toolbar_button
    f('button[aria-label="More..."]')
  end

  def list_button
    possibly_hidden_toolbar_button('[role="button"][title="Ordered and Unordered Lists"]')
  end

  def list_toggle_button
    f('[role="button"][title="Ordered and Unordered Lists"] .tox-split-button__chevron')
  end

  def bullet_list_button
    f('[role="menuitemcheckbox"][title="default bulleted unordered list"]')
  end

  def numbered_list_button
    f('[role="menuitemcheckbox"][title="default numerical ordered list"]')
  end

  def editor_window
    f("form.edit-form .edit-content")
  end

  def indent_toggle_button
    possibly_hidden_toolbar_button(
      '[role="button"][aria-label="Increase Indent"] .tox-split-button__chevron'
    )
  end

  def indent_button
    possibly_hidden_toolbar_button('[role="button"][aria-label="Increase Indent"')
  end

  def outdent_button
    possibly_hidden_toolbar_button('[role="menuitemcheckbox"][title="Decrease Indent"]')
  end

  def superscript_button
    possibly_hidden_toolbar_button('[role="button"][aria-label="Superscript and Subscript"]')
  end

  def subscript_button
    f('[role="button"][aria-label="Superscript and Subscript"]')
  end

  def superscript_toggle_button
    f('[role="button"][aria-label="Superscript and Subscript"] .tox-split-button__chevron')
  end

  def superscript_menu_button
    f('[role="menuitemcheckbox"][title="Superscript"]')
  end

  def subscript_menu_button
    f('[role="menuitemcheckbox"][title="Subscript"]')
  end

  def align_button
    possibly_hidden_toolbar_button('[role="button"][aria-label="Align"]')
  end

  def align_toggle_button
    possibly_hidden_toolbar_button('[role="button"][aria-label="Align"] .tox-split-button__chevron')
  end

  def align_left_button
    f('[role="menuitemcheckbox"][title="Left Align"]')
  end

  def align_center_button
    f('[role="menuitemcheckbox"][title="Center Align"]')
  end

  def align_right_button
    f('[role="menuitemcheckbox"][title="Right Align"]')
  end

  def formatting_dropdown
    f("button[aria-label='Blocks'")
  end

  def header_option
    f('[role="menuitemcheckbox"][title="Heading 2"]')
  end

  def subheader_option
    f('[role="menuitemcheckbox"][title=" Heading 3"]')
  end

  def small_header_option
    f('[role="menuitemcheckbox"][title=" Heading 4"]')
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

  def tray_container_exists?
    element_exists?('[data-testid="CanvasContentTray"]')
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

  def full_screen_button
    f('button[title="Fullscreen"]')
  end

  def exit_full_screen_button
    f('button[title="Exit Fullscreen"]')
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

  def overflow_toolbar_selector
    ".tox-toolbar__overflow"
  end

  def overflow_toolbar
    f(overflow_toolbar_selector)
  end

  def user_media_menu_item
    fj('[role^="menuitem"]:contains("User Media")')
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

  def embed_code_textarea
    fj('label:contains("Embed Code")')
  end

  def upload_media_submit_button
    f('[aria-label="Upload Media"] button[type="submit"]')
  end

  def embed_submit_button
    f('[aria-label="Embed"] button[type="submit"]')
  end

  def tiny_rce_ifr_id
    f(".tox-editor-container iframe")["id"]
  end

  def insert_link_modal
    f('[role="dialog"][aria-label="Insert Link"]')
  end

  def upload_file_modal
    f('[role="dialog"][aria-label="Upload File"]')
  end

  def math_builder_button
    possibly_hidden_toolbar_button('button[aria-label="Insert Math Equation"]')
  end

  def math_square_root_button
    f(".sqrt-prefix")
  end

  def editor_sqrt_textarea
    f("#mathquill-container textarea")
  end

  def math_builder_insert_equation_button
    find_button("Insert Equation")
  end

  def math_image
    f(".equation_image")
  end

  def edit_equation_button
    fxpath('//button[*[.="Edit Equation"]]')
  end

  def math_dialog_exists?
    element_exists?(".math-dialog")
  end

  def math_rendering_exists?
    element_exists?(".equation_image")
  end

  def mathjax_element_exists_in_title?
    element_exists?(".assignment-title .MathJax_Preview")
  end

  def save_button
    find_button("Save")
  end

  # ---- menubar items ---
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

  def content_tray_close_button
    fj('[data-testid="CanvasContentTray"] button:contains("Close")')
  end

  def content_tray_content_type
    f('input[aria-haspopup="listbox"]', fj(':contains("Content Type")'))
  end

  def editor_view_button
    f('button[data-btn-id="rce-edit-btn"]')
  end

  def fullscreen_element
    driver.execute_script("return document.fullscreenElement")
  end

  def change_content_tray_content_type(which)
    content_type = content_tray_content_type
    content_type.click
    options_id = content_type.attribute("aria-owns")
    options = f("##{options_id}")
    option = fj(":contains(#{which})", options)
    option.click
  end

  def content_tray_content_subtype
    fxpath('//input[ancestor::span[. = "Content Subtype"]]')
  end

  def change_content_tray_content_subtype(subtype)
    content_subtype = content_tray_content_subtype
    content_subtype.click
    options_id = content_subtype.attribute("aria-owns")
    options = f("##{options_id}")
    option = fj(":contains(#{subtype})", options)
    option.click
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

  def click_link_for_options
    in_frame tiny_rce_ifr_id do
      f("a").click
    end
  end

  def click_link_options_button
    link_options_button.click
  end

  def click_link_options_done_button
    link_options_done_button.click
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

  def click_links_toolbar_menu_button
    links_toolbar_menu_button.click
  end

  def click_course_links
    course_links.click
  end

  def click_group_links
    group_links.click
  end

  def click_external_links
    external_links.click
  end

  def click_remove_link
    remove_link.click
  end

  def click_remove_links
    remove_links.click
  end

  def click_images_toolbar_button
    images_toolbar_button.click
  end

  def click_images_toolbar_menu_button
    images_toolbar_menu_button.click
  end

  def click_media_toolbar_button
    media_toolbar_button.click
  end

  def click_embed_toolbar_button
    embed_toolbar_button.click
  end

  def click_media_toolbar_menu_button
    media_toolbar_menu_button.click
  end

  def click_document_toolbar_button
    document_toolbar_button.click
  end

  def click_document_toolbar_menu_button
    document_toolbar_menu_button.click
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

  def click_course_media
    course_media.click
    wait_for_ajaximations
  end

  def click_user_media
    user_media.click
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

  def click_group_documents
    group_documents.click
    wait_for_ajaximations
  end

  def click_user_documents
    user_documents.click
    wait_for_ajaximations
  end

  def click_more_toolbar_button
    more_toolbar_button.click
  end

  def click_list_button
    list_button.click
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
    superscript_toggle_button.click
  end

  def click_superscript_button
    superscript_button.click
  end

  def click_subscript_button
    subscript_button.click
  end

  def click_superscript_menu_button
    superscript_menu_button.click
  end

  def click_subscript_menu_button
    subscript_menu_button.click
  end

  def click_align_button
    align_button.click
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

  def click_upload_media_submit_button
    upload_media_submit_button.click
  end

  def click_embed_submit_button
    embed_submit_button.click
  end

  def click_content_tray_close_button
    content_tray_close_button.click
    wait_for_animations
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

  def create_external_link(text, href)
    click_links_toolbar_menu_button
    click_external_links
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

  def click_insert_menu_button
    menu_item_by_name("Insert").click
  end

  def click_link_menubar_button
    click_insert_menu_button
    menu_option_by_name("Link").click
  end

  def click_image_menubar_button
    click_insert_menu_button
    menu_option_by_name("Image").click
  end

  def click_media_menubar_button
    click_insert_menu_button
    menu_option_by_name("Media").click
  end

  def click_document_menubar_button
    click_insert_menu_button
    menu_option_by_name("Document").click
  end

  # Math toolbar and modal
  def select_squareroot_symbol
    math_square_root_button.click
  end

  def add_squareroot_value
    editor_sqrt_textarea.send_keys("81")
  end

  def select_math_equation_from_toolbar
    math_builder_button.click
  end

  def click_insert_equation
    math_builder_insert_equation_button.click
  end

  def click_page_save_button
    save_button.click
  end

  def select_math_image
    math_image.click
  end

  def click_edit_equation
    edit_equation_button.click
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
      expect(f("#tinymce #{selectors}").attribute("style")).to match("#{type}: #{value}\;")
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

  # menubar stuff
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

  def create_course_text_file(title)
    @root_folder = Folder.root_folders(@course).first
    @text_file =
      @root_folder
      .attachments
      .create!(filename: title, context: @course) { |a| a.content_type = "text/plain" }
  end
end
