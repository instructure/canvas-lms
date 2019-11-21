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

describe "Wiki pages and Tiny WYSIWYG editor features" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage
  include CustomSeleniumActions

  equation_button_selector = "div[aria-label='Insert Math Equation'] button"

  context "WYSIWYG generic as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
      stub_rcs_config
    end

    it 'should be able to click on things in the sidebar' do
      @course.wiki_pages.create!(title: 'Page1')
      get "/courses/#{@course.id}/pages/Page1/edit"
      f('#right-side button').click
      sleep 2
      expect(f('#right-side ul')).to include_text('Page1')
    end

    it "should type a web address link, save it, "\
    "and validate auto link plugin worked correctly", priority: "1", test_id: 312410 do
      text = "http://www.google.com/"
      wysiwyg_state_setup(@course, text, val: true)
      save_wiki
      validate_link(text)
    end

    it "should remove web address link previously embedded, save it and persist", priority: "1", test_id: 312637 do
      text = "http://www.google.com/"
      wysiwyg_state_setup(@course, text, val: true)

      select_all_wiki
      f('.mce-i-unlink').click
      save_wiki

      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('a')
      end
    end

    it "should switch views and handle html code" do
      wysiwyg_state_setup(@course)

      in_frame wiki_page_body_ifr_id do
        expect(ff("#tinymce p").length).to eq 3
      end
    end

    it "should add bullet lists", priority: "1", test_id: 307623 do
      wysiwyg_state_setup(@course)

      f(".mce-i-bullist").click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce li').length).to eq 3
      end
    end

    it "should remove bullet lists", priority: "1", test_id: 535894 do
      text = "<ul><li>1</li><li>2</li><li>3</li></ul>"
      wysiwyg_state_setup(@course, text, html: true)

      # editor window needs focus in chrome to enable bullet list button
      f("form.edit-form .edit-content").click if driver.browser == :chrome
      f(".mce-i-bullist").click

      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('li')
      end
    end

    it "should add numbered lists", priority: "1", test_id: 307625 do
      wysiwyg_state_setup(@course)

      f('.mce-i-numlist').click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce li').length).to eq 3
      end
    end

    it "should remove numbered lists", priority: "1", test_id: 537619 do
      text = "<ol><li>1</li><li>2</li><li>3</li></ol>"
      wysiwyg_state_setup(@course, text, html: true)

      # editor window needs focus in chrome to enable number list button
      f("form.edit-form .edit-content").click if driver.browser == :chrome
      f('.mce-i-numlist').click

      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('li')
      end
    end

    it "should change font color for all selected text", priority: "1", test_id: 285357 do
      wysiwyg_state_setup(@course)

      # order-dependent ID of the forecolor button
      f("#mceu_3 .mce-caret").click
      f(".mce-colorbutton-grid div[title='Red']").click
      validate_wiki_style_attrib("color", "rgb(255, 0, 0)", "p span")
    end

    it "should remove font color for all selected text", priority: "1", test_id: 469876 do
      text = "<p><span style=\"color: rgb(255, 0, 0);\">1</span></p>"
      wysiwyg_state_setup(@course, text, html: true)

      # order-dependent ID of the forecolor button
      f("#mceu_3 .mce-caret").click
      f(".mce-colorbutton-grid div[title='No color']").click
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('span')
      end
    end

    it "should change background font color", priority: "1", test_id: 298747 do
      wysiwyg_state_setup(@course)

      # order-dependent ID of the backcolor button
      f("#mceu_4 .mce-caret").click
      f(".mce-colorbutton-grid div[title='Red']").click
      validate_wiki_style_attrib("background-color", "rgb(255, 0, 0)", "p span")
    end

    it "should remove background font color", priority: "1", test_id: 474035 do
      text = "<p><span style=\"background-color: rgb(255, 0, 0);\">1</span></p>"
      wysiwyg_state_setup(@course, text, html: true)

      # order-dependent ID of the backcolor button
      f("#mceu_4 .mce-caret").click
      f(".mce-colorbutton-grid div[title='No color']").click
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('span')
      end
    end

    it "should change font size", priority: "1", test_id: 401375 do
      wysiwyg_state_setup(@course)

      # I'm so, so sorry...
      driver.find_element(:xpath, "//button/span[text()[contains(.,'pt')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'36pt')]]").click
      validate_wiki_style_attrib("font-size", "36pt", "p span")
    end

    it "should change and remove all custom formatting on selected text", priority: "1", test_id: 298748 do
      wysiwyg_state_setup(@course)
      driver.find_element(:xpath, "//button/span[text()[contains(.,'pt')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'36pt')]]").click
      validate_wiki_style_attrib("font-size", "36pt", "p span")
      f(".mce-i-removeformat").click
      validate_wiki_style_attrib_empty("p")
    end

    it 'should insert image using embed image widget', priority: "2", test_id: 397971 do
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.build(:context => @course)
      path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/email.png')
      @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      @image.save!

      visit_front_page_edit(@course)
      f('.mce-ico.mce-i-image').click
      widget = f('.ui-dialog.ui-widget.ui-widget-content.ui-corner-all.ui-draggable.ui-dialog-buttons')
      widget.find_element(:link_text, 'Canvas').click
      fj("button:contains('Course files')").click
      fj("button:contains('email.png')").click
      f('.btn-primary.ui-button.ui-widget.ui-state-default.ui-corner-all.ui-button-text-only').click
      f('.btn.btn-primary.submit').click
      wait_for_new_page_load
      main = f('#main')
      expect(main.find_element(:tag_name, 'img')).to have_attribute('height', '16')
      expect(main.find_element(:tag_name, 'img')).to have_attribute('width', '16')
      expect(main.find_element(:tag_name, 'img')).to have_attribute('alt', 'email.png')
    end

    it "should indent and remove indentation for embedded images" do
      title = "email.png"
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.build(:context => @course)
      path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/email.png')
      @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      @image.save!

      visit_front_page_edit(@course)
      click_images_tab
      click_image_link(title)

      select_all_wiki
      force_click('.mce-i-indent')
      validate_wiki_style_attrib("padding-left", "40px", "p")
      force_click('.mce-i-outdent')
      validate_wiki_style_attrib_empty("p")
    end

    it "should indent and remove indentation for text" do
      wysiwyg_state_setup(@course, "test")

      f('.mce-i-indent').click
      validate_wiki_style_attrib("padding-left", "40px", "p")
      f('.mce-i-outdent').click
      validate_wiki_style_attrib_empty("p")
    end

    it "should align text to the left", priority: "1", test_id: 303702 do
      wysiwyg_state_setup(@course, text = "left")
      f(".mce-i-align#{text}").click
      validate_wiki_style_attrib("text-align", text, "p")
    end

    it "should remove left align from text", priority: "1", test_id: 526906 do
      text = "<p style=\"text-align: left;\">1</p>"
      wysiwyg_state_setup(@course, text, html: true)

      f(".mce-i-alignleft").click
      validate_wiki_style_attrib_empty("p")
    end

    it "should align text to the center", priority: "1", test_id: 303698 do
      wysiwyg_state_setup(@course, text = "center")
      f(".mce-i-align#{text}").click
      validate_wiki_style_attrib("text-align", text, "p")
    end

    it "should remove center align from text", priority: "1", test_id: 529217 do
      text = "<p style=\"text-align: center;\">1</p>"
      wysiwyg_state_setup(@course, text, html: true)

      f(".mce-i-aligncenter").click
      validate_wiki_style_attrib_empty("p")
    end

    it "should align text to the right", priority: "1", test_id: 303704 do
      wysiwyg_state_setup(@course, text = "right")
      f(".mce-i-align#{text}").click
      validate_wiki_style_attrib("text-align", text, "p")
    end

    it "should remove right align from text", priority: "1", test_id: 530886 do
      text = "<p style=\"text-align: right;\">1</p>"
      wysiwyg_state_setup(@course, text, html: true)

      f(".mce-i-alignright").click
      validate_wiki_style_attrib_empty("p")
    end

    it "should make text superscript in rce", priority: "1", test_id: 306263 do
      wysiwyg_state_setup(@course)

      f('.mce-i-superscript').click

      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce sup')).to be_displayed
      end
    end

    it "should remove superscript from text in rce", priority: "1", test_id: 532084 do
      skip_if_chrome('fragile in chrome')
      text = "<p><sup>This is my text</sup></p>"
      wysiwyg_state_setup(@course, text, html: true)
      shift_click_button('.mce-i-superscript')
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('sup')
      end
    end

    it "should make text subscript in rce", priority: "1", test_id: 306264, ignore_js_errors: true do
      wysiwyg_state_setup(@course)

      f('.mce-i-subscript').click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce sub')).to be_displayed
      end
    end

    it "should remove subscript from text in rce", priority: "1", test_id: 532799 do
      skip_if_chrome('fragile in chrome')
      text = "<p><sub>This is my text</sub></p>"
      wysiwyg_state_setup(@course, text, html: true)

      shift_click_button('.mce-i-subscript')
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('sub')
      end
    end

    it "should be able to add links to new wiki pages with special characters in title", priority: "2" do
      title = "this/is a weird-a%% page titlé?"

      visit_front_page_edit(@course)
      wait_for_tiny(edit_wiki_css)

      click_pages_accordion
      click_new_page_link
      expect(new_page_name_input).to be_displayed
      new_page_name_input.send_keys(title)
      click_new_page_submit

      in_frame wiki_page_body_ifr_id do
        link = f('#tinymce p a')
        expect(link.text).to eq title
      end

      expect_new_page_load { force_click('form.edit-form button.submit') }

      expect_new_page_load{ f('.user_content a').click }

      # should bring up the creation page for the new page

      new_title = f(".edit-header #title").attribute('value').to_s
      expect(new_title).to eq title
    end

    it "should change paragraph type to preformatted" do
      text = "<p>This is a sample paragraph</p><p>This is a test</p><p>I E O U A</p>"
      wysiwyg_state_setup(@course, text, html: true)
      driver.find_element(:xpath, "//button/span[text()[contains(.,'Paragraph')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'Preformatted')]]").click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce pre').length).to eq 1
      end
    end

    it "should change paragraph type to Header 2", priority: "1", test_id: 417581 do
      text = "<p>This is a sample paragraph</p><p>This is a test</p><p>I E O U A</p>"
      wysiwyg_state_setup(@course, text, html: true)
      driver.find_element(:xpath, "//button/span[text()[contains(.,'Paragraph')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'Header 2')]]").click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce h2').length).to eq 3
      end
    end

    it "should create a table", priority: "1", test_id: 307627 do
      wysiwyg_state_setup(@course)
      f('.mce-i-table').click
      driver.find_element(:xpath, "//div/span[text()[contains(.,'Table')]]").click
      driver.find_element(:xpath, "//td/a[@data-mce-x='3' and @data-mce-y='3']").click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce tr').length).to eq 4
        expect(ff('#tinymce td').length).to eq 16
      end
    end

    it "should edit a table from toolbar", priority: "1", test_id: 588944 do
      wysiwyg_state_setup(@course)
      f('.mce-i-table').click
      driver.find_element(:xpath, "//div/span[text()[contains(.,'Table')]]").click
      driver.find_element(:xpath, "//td/a[@data-mce-x='3' and @data-mce-y='3']").click

      f('.mce-i-table').click
      driver.find_element(:xpath, "//span[text()[contains(.,'Row')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'Insert row after')]]").click

      f('.mce-i-table').click
      driver.find_element(:xpath, "//span[text()[contains(.,'Table properties')]]").click
      driver.find_element(:xpath, "//div[text()[contains(.,'Advanced')]]").click
      ff('div>input[placeholder]')[1].send_keys("green")
      f('.mce-primary').click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce tr').length).to eq 5
        expect(ff('#tinymce td').length).to eq 20
      end
      validate_wiki_style_attrib("background-color", "green", "table")
    end

    it "should edit a table from context menu", priority: "1", test_id: 307628 do
      wysiwyg_state_setup(@course)
      f('.mce-i-table').click
      driver.find_element(:xpath, "//div/span[text()[contains(.,'Table')]]").click
      driver.find_element(:xpath, "//td/a[@data-mce-x='3' and @data-mce-y='3']").click

      f('.mce-i-table').click
      driver.find_element(:xpath, "//span[text()[contains(.,'Row')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'Insert row after')]]").click

      driver.find_element(:xpath, "(//i[contains(@class,'mce-i-table') and "\
                                  "not(contains(@class,'mce-i-tabledelete')) "\
                                  "and not(contains(@class,'mce-i-tableinsert'))])[3]").click
      driver.find_element(:xpath, "//div[text()[contains(.,'Advanced')]]").click

      ff('div>input[placeholder]')[1].send_keys("green")
      f('.mce-primary').click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce tr').length).to eq 5
        expect(ff('#tinymce td').length).to eq 20
      end
      validate_wiki_style_attrib("background-color", "green", "table")
    end


    it "should delete a table from toolbar", priority: "1", test_id: 588945 do
      table = "<table><tbody><tr><td></td><td></td></tr><tr><td></td><td></td></tr></tbody></table>"
      wysiwyg_state_setup(@course, table, html: true)
      in_frame wiki_page_body_ifr_id do
        f('.mce-item-table tr td').click
      end
      f('.mce-i-table').click
      driver.find_element(:xpath, "//span[text()[contains(.,'Delete table')]]").click
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('table')
      end
    end

    it "should delete a table from context menu", priority: "1", test_id: 588945 do
      wysiwyg_state_setup(@course)

      f('.mce-i-table').click
      driver.find_element(:xpath, "//div/span[text()[contains(.,'Table')]]").click
      driver.find_element(:xpath, "//td/a[@data-mce-x='3' and @data-mce-y='3']").click

      f('.mce-i-tabledelete').click
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('table')
      end
    end

    it "should add bold text to the rce", priority: "1", test_id: 285128 do
      wysiwyg_state_setup(@course)
      f('.mce-i-bold').click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce strong')).to be_displayed
      end
    end

    it "should remove bold from text in rce", priority: "1", test_id: 417603 do
      skip_if_chrome('fragile in chrome')
      text = "<p><strong>This is my text</strong></p>"
      wysiwyg_state_setup(@course, text, html: true)
      shift_click_button('.mce-i-bold')
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('strong')
      end
    end

    it "should add italic text to the rce", priority: "1", test_id: 285129 do
      wysiwyg_state_setup(@course)
      f('.mce-i-italic').click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce em')).to be_displayed
      end
    end

    it "should remove italic from text in rce", priority: "1", test_id: 417607 do
      skip_if_chrome('fragile in chrome')
      text = "<p><em>This is my text</em></p>"
      wysiwyg_state_setup(@course, text, html: true)
      shift_click_button('.mce-i-italic')
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('em')
      end
    end

    it "should underline text in the rce", priority: "1", test_id: 285356 do
      wysiwyg_state_setup(@course)
      f('.mce-i-underline').click
      validate_wiki_style_attrib("text-decoration", "underline", "p span")
    end

    it "should remove underline from text in the rce", priority: "1", test_id: 460408 do
      text = "<p><u>This is my text</u></p>"
      wysiwyg_state_setup(@course, text, html: true)
      shift_click_button('.mce-i-underline')
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('u')
      end
    end

    it "should change text to right-to-left in the rce", priority: "1", test_id: 401335 do
      wysiwyg_state_setup(@course, text = "rtl")
      f(".mce-i-#{text}").click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce p').attribute('dir')).to eq text
      end
    end

    it "should remove right-to-left from text in the rce", priority: "1", test_id: 547797 do
      text = "<p dir=\"rtl\">This is my text</p>"
      wysiwyg_state_setup(@course, text, html: true)
      shift_click_button('.mce-i-rtl')
      validate_wiki_style_attrib_empty("p")
    end

    it "should change text to left-to-right in the rce", priority: "1", test_id: 547548 do
      wysiwyg_state_setup(@course, text = "ltr")
      f(".mce-i-#{text}").click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce p').attribute('dir')).to eq text
      end
    end

    it "should remove left-to-right from text in the rce", priority: "1", test_id: 550312 do
      text = "<p dir=\"ltr\">This is my text</p>"
      wysiwyg_state_setup(@course, text, html: true)
      shift_click_button('.mce-i-ltr')
      validate_wiki_style_attrib_empty("p")
    end

    it "should not scroll to the top of the page after using an equation button", ignore_js_errors: true do
      resize_screen_to_small
      visit_front_page_edit(@course)
      scroll_page_to_bottom

      f(equation_button_selector).click
      wait_for_ajaximations

      misc_tab = f('.mathquill-tab-bar > li:last-child a')
      misc_tab.click
      f('#Misc_tab li:nth-child(35) a').click
      scroll_location = driver.execute_script("return window.scrollY")
      resize_screen_to_standard # set browser back to default
      expect(scroll_location).not_to be 0
    end

    it "should not load mathjax if no mathml" do
      text = '<p>o mathml here</p>'
      wysiwyg_state_setup(@course, text, html: true)
      wait_for_new_page_load{f('button.submit').click}
      mathjax_defined = driver.execute_script('return (window.MathJax !== undefined)')
      expect(mathjax_defined).to eq false
    end

    it "should load mathjax if mathml" do
      skip('CORE-2994')
      text = '<p><math> <mi>&pi;</mi> <mo>⁢</mo> <msup> <mi>r</mi> <mn>2</mn> </msup> </math></p>'
      wysiwyg_state_setup(@course, text, html: true)
      wait_for_new_page_load{f('button.submit').click}
      mathjax_defined = false
      keep_trying_until do
        mathjax_defined = driver.execute_script('return (window.MathJax !== undefined)')
      end
      expect(mathjax_defined).to eq true
    end

    it "should not load mathjax if displaying an equation editor image and non-visible mathml" do
      text = '<p><div class="hidden-readable"><math> <mi>&pi;</mi> <mo>⁢</mo> <msup> <mi>r</mi> <mn>2</mn> </msup> </math></div></p>'
      mathmanImg = '<p><img class="equation_image" title="\infty" src="/equation_images/%255Cinfty" alt="LaTeX: \infty" data-equation-content="\infty" /></p>'
      visit_front_page_edit(@course)
      add_html_to_tiny(text+mathmanImg)
      f('button.btn-primary').click
      wait_for_ajaximations
      mathjax_defined = driver.execute_script('return (window.MathJax !== undefined)')
      expect(mathjax_defined).to be false
    end

    it "should display record video dialog" do
      stub_kaltura

      visit_front_page_edit(@course)

      f("div[aria-label='Record/Upload Media'] button").click
      expect(f('#record_media_tab')).to be_displayed
      f('#media_comment_dialog a[href="#upload_media_tab"]').click
      expect(f('#media_comment_dialog #audio_upload')).to be_displayed
      close_visible_dialog
      expect(f('#media_comment_dialog')).not_to be_displayed
    end

    it "should save with an iframe in a list", ignore_js_errors: true do
      text = "<ul><li><iframe src=\"about:blank\"></iframe></li></ul>"
      wysiwyg_state_setup(@course, text, html: true)
      wait_for_new_page_load{f('form.edit-form button.submit').click}
      expect(f("#wiki_page_show")).to contain_css('ul iframe')
    end

    it "should save with an iframe in a table" do
      text = "<table><tr><td><iframe src=\"about:blank\"></iframe></td></tr></table>"
      wysiwyg_state_setup(@course, text, html: true)
      wait_for_new_page_load{f('form.edit-form button.submit').click}
      expect(f("#wiki_page_show")).to contain_css('table iframe')
    end

    describe "a11y checker plugin" do
      it "applys a fix" do
        text = "Some long string of text that probably shouldn't be a header, but rather should be paragraph text. I need to be shorter please"
        heading_html = "<h2>#{text}</h2>"
        wysiwyg_state_setup(@course, heading_html, html: true)
        f('[aria-label="Check Accessibility"] button').click
        wait_for_ajaximations
        fj('label:contains("Change heading tag to paragraph")').click
        fj('[aria-label="Accessibility Checker"] button:contains("Apply")').click
        expect(fj('[aria-label="Accessibility Checker"] p:contains("No accessibility issues were detected.")')).to be_displayed
        wait_for_new_page_load{f('form.edit-form button.submit').click}
        expect(f("#wiki_page_show")).not_to contain_css('h2')
        expect(f("#wiki_page_show p").text).to eq(text)
      end
    end
  end
end
