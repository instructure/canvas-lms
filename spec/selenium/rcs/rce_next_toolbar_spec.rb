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

require_relative "../helpers/wiki_and_tiny_common"
require_relative "pages/rcs_sidebar_page"
require_relative "../test_setup/common_helper_methods/custom_selenium_actions"
require_relative "pages/rce_next_page"

# while there's a mix of instui 6 and 7 in canvas we're getting
# "Warning: [themeable] A theme registry has already been initialized." js errors
# Ignore js errors so specs can pass
describe "RCE Next toolbar features", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage
  include CustomSeleniumActions
  include RCENextPage

  context "WYSIWYG generic as a teacher" do
    before do
      course_with_teacher_logged_in
      stub_rcs_config
    end

    def create_wiki_page_with_text(page_title)
      @course.wiki_pages.create!(title: page_title, body: "<p>The sleeper must awaken.</p>")
    end

    def assert_insert_buttons_enabled(is_enabled)
      expect(links_toolbar_menubutton.enabled?).to be is_enabled
      expect(images_toolbar_menubutton.enabled?).to be is_enabled
      expect(media_toolbar_menubutton.enabled?).to be is_enabled
      expect(document_toolbar_menubutton.enabled?).to be is_enabled
    end

    context "links" do
      it "menu should include external and course links" do
        rce_wysiwyg_state_setup(@course)

        links_toolbar_menubutton.click
        # it's the links_toolbar_button that owns the popup menu, not the chevron
        # use it to find the menu, then assert we have the right number of menu items
        expect(links_toolbar_menuitems.length).to eq(2)
        expect(external_link_toolbar_menuitem).to be_displayed
        expect(course_links_toolbar_menuitem).to be_displayed
      end

      it "menu should include Remove Link when a link is selected" do
        rce_wysiwyg_state_setup(@course, 'this is <div id="one_link"><a>a link</a></div> <a>another link</a>.', html: true)
        select_in_tiny(f("textarea.body"), "#one_link")

        expect(links_toolbar_menuitems.length).to eq(3)
        expect(remove_link_toolbar_menuitem).to be_displayed

        click_remove_link_toolbar_menuitem
        driver.switch_to.frame("wiki_page_body_ifr")
        link_count = count_elems_by_tagname("a")
        expect(link_count).to eq(1)
      end

      it "menu should include Remove Links when multiple links are selected" do
        rce_wysiwyg_state_setup(@course, "this is <a>a link</a> and <a>another link</a>.", html: true)
        select_all_wiki

        links_toolbar_menubutton.click
        expect(links_toolbar_menuitems.length).to eq(3)
        expect(remove_links_toolbar_menuitem).to be_displayed

        click_remove_links_toolbar_menuitem
        driver.switch_to.frame("wiki_page_body_ifr")
        link_count = count_elems_by_tagname("a")
        expect(link_count).to eq(0)
      end

      it "shows links popup toolbar" do
        skip "routinely fails flakey spec catcher 1/10 times with 'no such window', but passes flakey spec catcher locally"
        rce_wysiwyg_state_setup(@course, 'this is <a href="http://example.com">a link</a>.', html: true)

        driver.switch_to.frame("wiki_page_body_ifr")
        f("a").click

        driver.switch_to.default_content
        expect(fj('.tox-pop__dialog button:contains("Link Options")')).to be_displayed
        expect(fj('.tox-pop__dialog button:contains("Remove Link")')).to be_displayed
      end
    end

    context "list types" do
      it "adds bullet lists" do
        rce_wysiwyg_state_setup(@course)

        click_bullet_list_toolbar_menuitem

        in_frame rce_page_body_ifr_id do
          expect(ff("#tinymce ul li").length).to eq 3
        end
      end

      it "removes bullet lists" do
        text = "<ul><li>1</li><li>2</li><li>3</li></ul>"
        rce_wysiwyg_state_setup(@course, text, html: true)

        click_bullet_list_toolbar_menuitem

        in_frame rce_page_body_ifr_id do
          expect(wiki_body).not_to contain_css("li")
        end
      end

      it "adds numbered lists", priority: "1" do
        rce_wysiwyg_state_setup(@course)

        click_numbered_list_toolbar_menuitem

        in_frame rce_page_body_ifr_id do
          expect(ff("#tinymce ol li").length).to eq 3
        end
      end

      it "removes numbered lists", priority: "1" do
        text = "<ol><li>1</li><li>2</li><li>3</li></ol>"
        rce_wysiwyg_state_setup(@course, text, html: true)

        click_numbered_list_toolbar_menuitem

        in_frame rce_page_body_ifr_id do
          expect(f("#tinymce")).not_to contain_css("li")
        end
      end
    end

    context "indent and outdent" do
      it "indents and remove indentation for embedded images" do
        title = "email.png"
        @root_folder = Folder.root_folders(@course).first
        @image = @root_folder.attachments.build(context: @course)
        path = File.expand_path(File.dirname(__FILE__) + "/../../../public/images/email.png")
        @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
        @image.save!

        visit_front_page_edit(@course)
        click_course_images_toolbar_menuitem
        click_image_link(title)

        select_all_wiki
        increase_indent_toolbar_menuitem.click

        rce_validate_wiki_style_attrib("padding-left", "40px", "p")

        decrease_indent_toolbar_menuitem.click

        rce_validate_wiki_style_attrib_empty("p")
      end

      it "indents and remove indentation for text" do
        rce_wysiwyg_state_setup(@course, "test")

        increase_indent_toolbar_menuitem.click
        rce_validate_wiki_style_attrib("padding-left", "40px", "p")

        decrease_indent_toolbar_menuitem.click

        rce_validate_wiki_style_attrib_empty("p")
      end
    end

    context "super and sub script" do
      it "makes text superscript in rce" do
        rce_wysiwyg_state_setup(@course)

        superscript_toolbar_menuitem.click

        in_frame rce_page_body_ifr_id do
          expect(f("#tinymce sup")).to be_displayed
        end
      end

      it "removes superscript from text in rce" do
        text = "<p><sup>This is my text</sup></p>"

        rce_wysiwyg_state_setup(@course, text, html: true)

        superscript_toolbar_menuitem.click

        in_frame rce_page_body_ifr_id do
          expect(f("#tinymce")).not_to contain_css("sup")
        end
      end

      it "makes text subscript in rce" do
        rce_wysiwyg_state_setup(@course)

        subscript_toolbar_menuitem.click

        in_frame rce_page_body_ifr_id do
          expect(f("#tinymce sub")).to be_displayed
        end
      end

      it "removes subscript from text in rce" do
        text = "<p><sub>This is my text</sub></p>"
        rce_wysiwyg_state_setup(@course, text, html: true)
        select_in_tiny(f("#wiki_page_body"), "sub")

        subscript_toolbar_menuitem.click

        in_frame rce_page_body_ifr_id do
          expect(f("#tinymce")).not_to contain_css("sub")
        end
      end
    end

    context "text alignment" do
      it "aligns text to the left" do
        rce_wysiwyg_state_setup(@course, "text to align")

        left_align_toolbar_menuitem.click

        rce_validate_wiki_style_attrib("text-align", "left", "p")
      end

      it "removes left align from text" do
        text = '<p style="text-align: left;">1</p>'
        rce_wysiwyg_state_setup(@course, text, html: true)

        left_align_toolbar_menuitem.click

        rce_validate_wiki_style_attrib_empty("p")
      end

      it "aligns text to the center" do
        rce_wysiwyg_state_setup(@course, "text to align")

        center_align_toolbar_menuitem.click

        rce_validate_wiki_style_attrib("text-align", "center", "p")
      end

      it "removes center align from text" do
        text = '<p style="text-align: center;">1</p>'
        rce_wysiwyg_state_setup(@course, text, html: true)

        center_align_toolbar_menuitem.click

        rce_validate_wiki_style_attrib_empty("p")
      end

      it "aligns text to the right" do
        rce_wysiwyg_state_setup(@course, "text to align")

        right_align_toolbar_menuitem.click

        rce_validate_wiki_style_attrib("text-align", "right", "p")
      end

      it "removes right align from text" do
        text = '<p style="text-align: right;">1</p>'
        rce_wysiwyg_state_setup(@course, text, html: true)

        right_align_toolbar_menuitem.click

        rce_validate_wiki_style_attrib_empty("p")
      end
    end

    it "changes text to right-to-left in the rce" do
      rce_wysiwyg_state_setup(@course, text = "rtl")
      click_rtl
      in_frame rce_page_body_ifr_id do
        expect(f("#tinymce p").attribute("dir")).to eq text
      end
    end

    it "changes text to left-to-right in the rce" do
      text = '<p dir="rtl">This is my text</p>'
      rce_wysiwyg_state_setup(@course, text, html: true)
      click_ltr
      in_frame rce_page_body_ifr_id do
        expect(f("#tinymce p").attribute("dir")).to eq "ltr"
      end
    end

    it "verifies the rce-next toolbar is one row" do
      visit_front_page_edit(@course)

      expect(rce_next_toolbar.size.height).to be 39
    end

    it "verifies selecting Header from dropdown sets H2" do
      page_title = "header"
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_header_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css("h2")
      end
    end

    it "verifies selecting subeader from dropdown sets H3" do
      page_title = "header"
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_subheader_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css("h3")
      end
    end

    it "verifies selecting small header from dropdown sets H4" do
      page_title = "header"
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_small_header_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css("h4")
      end
    end

    it "verifies selecting preformatted from dropdown sets pre" do
      page_title = "header"
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_preformatted_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css("pre")
      end
    end

    context "math equations" do
      it "renders math equation from math modal" do
        page_title = "math_rendering"
        create_wiki_page_with_text(page_title)
        visit_existing_wiki_edit(@course, page_title)
        equation_editor_button.click
        advanced_editor_toggle.click
        advanced_editor_textarea.send_keys '\sqrt{81}'
        equation_editor_done_button.click

        in_frame rce_page_body_ifr_id do
          expect(wiki_body).to contain_css("img.equation_image")
          expect(math_image.attribute("title")).to eq '\sqrt{81}'
          click_repeat(math_image)
        end
        edit_math_image_button.click
        expect(advanced_editor_textarea.text).to eq '\sqrt{81}'

        equation_editor_done_button.click
        save_button.click
        wait_for_ajaximations
        expect(math_rendering_exists?).to be true
      end

      it "renders inline LaTeX in the equation editor" do
        page_title = "math_rendering"
        body = "<p>\\(\\LaTeX\\)</p>"
        @course.wiki_pages.create!(title: page_title, body:)
        visit_existing_wiki_edit(@course, page_title)
        in_frame rce_page_body_ifr_id do
          double_click("#tinymce p")
        end
        equation_editor_button.click
        editor_text = advanced_editor_textarea.text
        expect(editor_text).to eq("\\LaTeX")
      end

      it "redirects focus in the equation editor" do
        def active_element
          driver.execute_script("return document.activeElement") # rubocop:disable Specs/NoExecuteScript
        end

        page_title = "math_focus"
        create_wiki_page_with_text(page_title)
        visit_existing_wiki_edit(@course, page_title)
        equation_editor_button.click
        advanced_editor_toggle.click
        first_math_symbol_button.click
        expect(active_element).to eq(advanced_editor_textarea)

        advanced_editor_toggle.click
        first_math_symbol_button.click
        expect(active_element).to eq(basic_editor_textarea)
      end

      it 'renders math equations for inline math with "\("' do
        Account.site_admin.disable_feature!(:explicit_latex_typesetting)
        title = "Assignment-Title with Math \\(x^2\\)"
        @assignment = @course.assignments.create!(name: title)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/"
        wait_for_ajaximations
        expect(mathjax_element_exists_in_title?).to be true
      end

      it "renders math equations for inline math with $$" do
        Account.site_admin.disable_feature!(:explicit_latex_typesetting)
        title = "Assignment-Title with Math $$x^2$$"
        @assignment = @course.assignments.create!(name: title)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/"
        wait_for_ajaximations
        expect(mathjax_element_exists_in_title?).to be true
      end

      it "does not render math equations for inline math with $$" do
        Account.site_admin.enable_feature!(:explicit_latex_typesetting)
        title = "Assignment-Title with Math $$x^2$$"
        @assignment = @course.assignments.create!(name: title)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/"
        wait_for_ajaximations
        expect(mathjax_element_exists_in_title?).to be false
      end
    end

    context "in a narrow window" do
      before do
        rce_wysiwyg_state_setup(@course)
        driver.manage.window.resize_to(500, 800)
      end

      it "list button in overflow menu should indicate active when appropriate" do
        click_lists_toolbar_quickaction
        expect(lists_toolbar_splitbutton).to contain_css(".tox-tbtn--enabled")

        click_lists_toolbar_quickaction
        expect(lists_toolbar_splitbutton).not_to contain_css(".tox-tbtn--enabled")
      end

      it "alignment button in overflow menu should indicate active when appropriate" do
        left_align_toolbar_menuitem.click
        expect(alignment_toolbar_menubutton).to have_class("tox-tbtn--enabled")

        left_align_toolbar_menuitem.click
        expect(alignment_toolbar_menubutton).not_to have_class("tox-tbtn--enabled")
      end

      it "superscript button in overflow menu should indicate active when appropriate" do
        superscript_toolbar_menuitem.click
        expect(superscript_toolbar_menubutton).to have_class("tox-tbtn--enabled")

        superscript_toolbar_menuitem.click
        expect(superscript_toolbar_menubutton).not_to have_class("tox-tbtn--enabled")
      end
    end

    context "content insertion buttons" do
      before do
        body = <<~HTML
          <p><span id="ok">i am OK!</span></p>
          <p><span id="ifr">cannot link <iframe>me</iframe></span></p>
          <p><span id="vid">nor <video>me</video></span></p>
        HTML
        @course.wiki_pages.create!(title: "title", body:)
        visit_existing_wiki_edit(@course, "title")

        driver.execute_script(<<~JS)
          window.selectNodeById = function(nid) {
            const win = document.querySelector('iframe.tox-edit-area__iframe').contentWindow
            const rng = win.document.createRange()
            rng.selectNode(win.document.getElementById(nid))
            const rng2 = win.document.createRange()
            rng2.setStart(win.document.getElementById(nid).firstChild, 0) // put the text cursor w/in the selection
            const sel = win.getSelection()
            sel.removeAllRanges()
            sel.addRange(rng)
            sel.addRange(rng2)
          }
        JS
      end

      it "is disabled in toolbar when linking is invalid" do
        driver.manage.window.resize_to(1_350, 800) # wide enough to display the insert buttons

        # nothing selected, insert buttons are enabled
        assert_insert_buttons_enabled(true)

        driver.execute_script('window.selectNodeById("ok")')
        assert_insert_buttons_enabled(true)

        driver.execute_script('window.selectNodeById("ifr")')
        assert_insert_buttons_enabled(false)

        driver.execute_script('window.selectNodeById("vid")')
        assert_insert_buttons_enabled(false)
      end

      it "is disabled in floating toolbar if linking is invalid" do
        driver.execute_script('window.selectNodeById("ifr")')
        driver.manage.window.resize_to(800, 800) # small enough that the insert buttons are hidden in the overflow
        assert_insert_buttons_enabled(false) # buttons should still be disabled without selecting anything else

        driver.execute_script('window.selectNodeById("ok")')
        assert_insert_buttons_enabled(true)
      end
    end

    context "find and replace plugin" do
      before(:once) do
        Account.site_admin.enable_feature!(:rce_find_replace)
      end

      it "finds and replaces text" do
        rce_wysiwyg_state_setup(@course, "find me")

        find_and_replace_menu_item.click
        find_and_replace_tray_find_input.send_keys("find me")
        find_and_replace_tray_replace_input.send_keys("replace me")
        find_and_replace_tray_replace_button.click

        in_frame rce_page_body_ifr_id do
          expect(wiki_body).to contain_css("p", text: "replace me")
        end
      end

      it "opens with shortcut" do
        rce_wysiwyg_state_setup(@course)
        driver.switch_to.frame("wiki_page_body_ifr")
        wiki_body.click
        wiki_body.send_keys [:control, "f"]
        driver.switch_to.default_content
        expect(find_and_replace_tray_header).to be_displayed
      end
    end
  end
end
