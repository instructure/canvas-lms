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

require_relative '../helpers/wiki_and_tiny_common'
require_relative 'pages/rcs_sidebar_page'
require_relative '../test_setup/common_helper_methods/custom_selenium_actions'
require_relative 'pages/rce_next_page'

# while there's a mix of instui 6 and 7 in canvas we're getting
# "Warning: [themeable] A theme registry has already been initialized." js errors
# Ignore js errors so specs can pass
describe 'RCE Next toolbar features', ignore_js_errors: true do
  include_context 'in-process server selenium tests'
  include WikiAndTinyCommon
  include RCSSidebarPage
  include CustomSeleniumActions
  include RCENextPage

  context 'WYSIWYG generic as a teacher' do
    before(:each) do
      course_with_teacher_logged_in
      Account.default.enable_feature!(:rce_enhancements)
      Account.site_admin.enable_feature!(:new_math_equation_handling)
      Account.site_admin.enable_feature!(:inline_math_everywhere)
      stub_rcs_config
    end

    def create_wiki_page_with_text(page_title)
      @course.wiki_pages.create!(title: page_title, body: '<p>The sleeper must awaken.</p>')
    end

    def assert_insert_buttons_enabled(is_enabled)
      expect(
        links_toolbar_button.enabled? && links_toolbar_button.attribute('aria-disabled') == 'false'
      ).to be is_enabled
      expect(
        images_toolbar_button.enabled? &&
          images_toolbar_button.attribute('aria-disabled') == 'false'
      ).to be is_enabled
      expect(
        media_toolbar_button.enabled? && media_toolbar_button.attribute('aria-disabled') == 'false'
      ).to be is_enabled
      expect(
        document_toolbar_button.enabled? &&
          document_toolbar_button.attribute('aria-disabled') == 'false'
      ).to be is_enabled

      click_link_menubar_button
      expect(external_link_menubar_button.enabled? && external_link_menubar_button.attribute('aria-disabled') == 'false').to be is_enabled
      click_insert_menu_button

      click_image_menubar_button
      expect(image_menubar_button.enabled? && image_menubar_button.attribute('aria-disabled') == 'false').to be is_enabled
      click_insert_menu_button

      click_media_menubar_button
      expect(media_menubar_button.enabled? && media_menubar_button.attribute('aria-disabled') == 'false').to be is_enabled
      click_insert_menu_button

      click_document_menubar_button
      expect(document_menubar_button.enabled? && document_menubar_button.attribute('aria-disabled') == 'false').to be is_enabled
      click_insert_menu_button
    end

    context 'links' do
      it 'menu should include external and course links' do
        rce_wysiwyg_state_setup(@course)

        click_links_toolbar_menu_button
        # it's the links_toolbar_button that owns the popup menu, not the chevron
        # use it to find the menu, then assert we have the right number of menu items
        expect(ff("##{links_toolbar_button.attribute('aria-owns')} [role='menuitemcheckbox']").length).to eq(2)
        expect(external_links).to be_displayed
        expect(course_links).to be_displayed
      end

      it 'menu should include Remove Link when a link is selected' do
        rce_wysiwyg_state_setup(@course, 'this is <div id="one_link"><a>a link</a></div> <a>another link</a>.', html: true)
        select_in_tiny(f("textarea.body"), '#one_link')
        click_links_toolbar_menu_button
        expect(ff("##{links_toolbar_button.attribute('aria-owns')} [role='menuitemcheckbox']").length).to eq(3)
        expect(remove_link).to be_displayed

        click_remove_link
        driver.switch_to.frame('wiki_page_body_ifr')
        link_count = count_elems_by_tagname('a')
        expect(link_count).to eq(1)
      end

      it 'menu should include Remove Links when multiple links are selected' do
        rce_wysiwyg_state_setup(@course, 'this is <a>a link</a> and <a>another link</a>.', html: true)
        select_all_wiki
        click_links_toolbar_menu_button
        expect(ff("##{links_toolbar_button.attribute('aria-owns')} [role='menuitemcheckbox']").length).to eq(3)
        expect(remove_links).to be_displayed

        click_remove_links
        driver.switch_to.frame('wiki_page_body_ifr')
        link_count = count_elems_by_tagname('a')
        expect(link_count).to eq(0)
      end

      it 'should show links popup toolbar' do
        skip "routinely fails flakey spec catcher 1/10 times with 'no such window', but passes flakey spec catcher locally"
        rce_wysiwyg_state_setup(@course, 'this is <a href="http://example.com">a link</a>.', html: true)

        driver.switch_to.frame('wiki_page_body_ifr')
        f('a').click

        driver.switch_to.default_content
        expect(fj('.tox-pop__dialog button:contains("Link Options")')).to be_displayed
        expect(fj('.tox-pop__dialog button:contains("Remove Link")')).to be_displayed
      end
    end

    context 'list types' do
      it 'should add bullet lists' do
        rce_wysiwyg_state_setup(@course)

        click_list_toggle_button
        click_bullet_list_button

        in_frame rce_page_body_ifr_id do
          expect(ff('#tinymce ul li').length).to eq 3
        end
      end

      it 'should remove bullet lists' do
        text = '<ul><li>1</li><li>2</li><li>3</li></ul>'
        rce_wysiwyg_state_setup(@course, text, html: true)

        click_list_toggle_button
        click_bullet_list_button

        in_frame rce_page_body_ifr_id do
          expect(wiki_body).not_to contain_css('li')
        end
      end

      it 'should add numbered lists', priority: '1', test_id: 307_625 do
        rce_wysiwyg_state_setup(@course)

        click_list_toggle_button
        click_numbered_list_button

        in_frame rce_page_body_ifr_id do
          expect(ff('#tinymce ol li').length).to eq 3
        end
      end

      it 'should remove numbered lists', priority: '1', test_id: 537_619 do
        text = '<ol><li>1</li><li>2</li><li>3</li></ol>'
        rce_wysiwyg_state_setup(@course, text, html: true)

        click_list_toggle_button
        click_numbered_list_button

        in_frame rce_page_body_ifr_id do
          expect(f('#tinymce')).not_to contain_css('li')
        end
      end
    end

    context 'indent and outdent' do
      it 'should indent and remove indentation for embedded images' do
        title = 'email.png'
        @root_folder = Folder.root_folders(@course).first
        @image = @root_folder.attachments.build(context: @course)
        path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/email.png')
        @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
        @image.save!

        visit_front_page_edit(@course)
        click_images_toolbar_menu_button
        click_course_images
        click_image_link(title)

        select_all_wiki
        click_indent_button

        rce_validate_wiki_style_attrib('padding-left', '40px', 'p')

        click_indent_toggle_button
        click_outdent_button

        rce_validate_wiki_style_attrib_empty('p')
      end

      it 'should indent and remove indentation for text' do
        rce_wysiwyg_state_setup(@course, 'test')

        click_indent_button
        rce_validate_wiki_style_attrib('padding-left', '40px', 'p')

        click_indent_toggle_button
        click_outdent_button

        rce_validate_wiki_style_attrib_empty('p')
      end
    end

    context 'super and sub script' do
      it 'should make text superscript in rce' do
        rce_wysiwyg_state_setup(@course)

        click_superscript_button

        in_frame rce_page_body_ifr_id do
          expect(f('#tinymce sup')).to be_displayed
        end
      end

      it 'should remove superscript from text in rce' do
        text = '<p><sup>This is my text</sup></p>'

        rce_wysiwyg_state_setup(@course, text, html: true)

        shift_click_button(superscript_button_selector)

        in_frame rce_page_body_ifr_id do
          expect(f('#tinymce')).not_to contain_css('sup')
        end
      end

      it 'should make text subscript in rce' do
        rce_wysiwyg_state_setup(@course)

        click_super_toggle_button
        click_subscript_menu_button

        in_frame rce_page_body_ifr_id do
          expect(f('#tinymce sub')).to be_displayed
        end
      end

      it 'should remove subscript from text in rce' do
        text = '<p><sub>This is my text</sub></p>'
        rce_wysiwyg_state_setup(@course, text, html: true)
        select_in_tiny(f('#wiki_page_body'), 'sub')
        shift_click_button(subscript_button_selector)

        in_frame rce_page_body_ifr_id do
          expect(f('#tinymce')).not_to contain_css('sub')
        end
      end
    end

    context 'text alignment' do
      it 'should align text to the left' do
        rce_wysiwyg_state_setup(@course, 'text to align')

        click_align_toggle_button
        click_align_left_button
        rce_validate_wiki_style_attrib('text-align', 'left', 'p')
      end

      it 'should remove left align from text' do
        text = '<p style="text-align: left;">1</p>'
        rce_wysiwyg_state_setup(@course, text, html: true)

        click_align_toggle_button
        click_align_left_button
        rce_validate_wiki_style_attrib_empty('p')
      end

      it 'should align text to the center' do
        rce_wysiwyg_state_setup(@course, 'text to align')

        click_align_toggle_button
        click_align_center_button
        rce_validate_wiki_style_attrib('text-align', 'center', 'p')
      end

      it 'should remove center align from text' do
        text = '<p style="text-align: center;">1</p>'
        rce_wysiwyg_state_setup(@course, text, html: true)

        click_align_toggle_button
        click_align_center_button
        rce_validate_wiki_style_attrib_empty('p')
      end

      it 'should align text to the right' do
        rce_wysiwyg_state_setup(@course, 'text to align')

        click_align_toggle_button
        click_align_right_button
        rce_validate_wiki_style_attrib('text-align', 'right', 'p')
      end

      it 'should remove right align from text' do
        text = '<p style="text-align: right;">1</p>'
        rce_wysiwyg_state_setup(@course, text, html: true)

        click_align_toggle_button
        click_align_right_button
        rce_validate_wiki_style_attrib_empty('p')
      end
    end

    it 'should change text to right-to-left in the rce' do
      rce_wysiwyg_state_setup(@course, text = 'rtl')
      click_rtl
      in_frame rce_page_body_ifr_id do
        expect(f('#tinymce p').attribute('dir')).to eq text
      end
    end

    it 'should change text to left-to-right in the rce' do
      text = '<p dir="rtl">This is my text</p>'
      rce_wysiwyg_state_setup(@course, text, html: true)
      click_ltr
      in_frame rce_page_body_ifr_id do
        expect(f('#tinymce p').attribute('dir')).to eq 'ltr'
      end
    end

    it 'should verify the rce-next toolbar is one row' do
      visit_front_page_edit(@course)

      expect(rce_next_toolbar.size.height).to be 39
    end

    it 'should verify selecting Header from dropdown sets H2' do
      page_title = 'header'
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_header_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css('h2')
      end
    end

    it 'should verify selecting subeader from dropdown sets H3' do
      page_title = 'header'
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_subheader_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css('h3')
      end
    end

    it 'should verify selecting small header from dropdown sets H4' do
      page_title = 'header'
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_small_header_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css('h4')
      end
    end

    it 'should verify selecting preformatted from dropdown sets pre' do
      page_title = 'header'
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_preformatted_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css('pre')
      end
    end

    context 'math equations' do
      it 'renders math equation from math modal' do
        skip 'LS-1839 (1/27/2021)'
        page_title = 'math_rendering'
        create_wiki_page_with_text(page_title)
        visit_existing_wiki_edit(@course, page_title)

        select_math_equation_from_toolbar
        select_squareroot_symbol
        add_squareroot_value
        click_insert_equation

        # Verify image in rce
        in_frame rce_page_body_ifr_id do
          expect(wiki_body).to contain_css('img.equation_image')
        end
        # Select to re-edit math equation
        in_frame rce_page_body_ifr_id do
          select_math_image
        end
        click_edit_equation
        expect(math_dialog_exists?).to eq true

        # Save and look for the image on the saved page
        click_insert_equation
        click_page_save_button
        wait_for_ajaximations
        expect(math_rendering_exists?).to eq true
      end

      it 'renders math equations for inline math with "\("' do
        title = 'Assignment-Title with Math \(x^2\)'
        @assignment = @course.assignments.create!(name: title)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/"
        wait_for_ajaximations
        expect(mathjax_element_exists_in_title?).to eq true
      end

      it 'renders math equations for inline math with $$' do
        title = 'Assignment-Title with Math $$x^2$$'
        @assignment = @course.assignments.create!(name: title)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/"
        wait_for_ajaximations
        expect(mathjax_element_exists_in_title?).to eq true
      end
    end

    describe 'floating toolbar' do
      before(:each) do
        create_wiki_page_with_text('hello')
        visit_existing_wiki_edit(@course, 'hello')
        driver.manage.window.resize_to(1_000, 800)
      end

      it 'should close on executing any command' do
        more_toolbar_button.click
        expect(overflow_toolbar).to be_displayed
        click_list_toggle_button
        click_bullet_list_button
        expect(f('body')).not_to contain_css(overflow_toolbar_selector)
      end

      it 'should close on losing focus' do
        in_frame rce_page_body_ifr_id do
          f('#tinymce').send_keys('') # focus
        end
        more_toolbar_button.click
        wait_for_animations
        expect(overflow_toolbar).to be_displayed
        f('#title').click
        expect(f('body')).not_to contain_css(overflow_toolbar_selector)
      end
    end

    context 'in a narrow window' do
      before :each do
        rce_wysiwyg_state_setup(@course)
        driver.manage.window.resize_to(500, 800)
      end

      it 'list button in overflow menu should indicate active when appropriate' do
        click_list_button
        more_toolbar_button.click
        expect(list_button).to contain_css('.tox-tbtn--enabled')
        click_list_button
        more_toolbar_button.click
        expect(list_button).not_to contain_css('.tox-tbtn--enabled')
      end

      it 'alignment button in overflow menu should indicate active when appropriate' do
        click_align_button
        more_toolbar_button.click
        expect(align_button).to contain_css('.tox-tbtn--enabled')
        click_align_button
        more_toolbar_button.click
        expect(align_button).not_to contain_css('.tox-tbtn--enabled')
      end

      it 'superscript button in overflow menu should indicate active when appropriate' do
        click_superscript_button
        more_toolbar_button.click
        expect(superscript_button).to contain_css('.tox-tbtn--enabled')
        click_superscript_button
        more_toolbar_button.click
        expect(superscript_button).not_to contain_css('.tox-tbtn--enabled')
      end
    end

    context 'content insertion buttons' do
      before :each do
        body = <<-HTML
        <p><span id="ok">i am OK!</span></p>
        <p><span id="ifr">cannot link <iframe/> me</span></p>
        <p><span id="vid">nor <video/> me</span></p>
        HTML
        @course.wiki_pages.create!(title: 'title', body: body)
        visit_existing_wiki_edit(@course, 'title')

        driver.execute_script(<<-JS)
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

      it 'should be disabled in toolbar when linking is invalid' do
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

      it 'should be disabled in floating toolbar if linking is invalid' do
        driver.execute_script('window.selectNodeById("ifr")')
        driver.manage.window.resize_to(800, 800) # small enough that the insert buttons are hidden in the overflow
        assert_insert_buttons_enabled(false) # buttons should still be disabled without selecting anything else

        driver.execute_script('window.selectNodeById("ok")')
        assert_insert_buttons_enabled(true)
      end
    end
  end
end
