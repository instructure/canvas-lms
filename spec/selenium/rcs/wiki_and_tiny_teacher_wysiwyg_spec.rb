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

describe "Wiki pages and Tiny WYSIWYG editor features" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage

  equation_button_selector = "div[aria-label='Insert Math Equation'] button"

  context "WYSIWYG generic as a teacher" do

    before(:once) do
      @teacher = user_with_pseudonym
      course_with_teacher({:user => @teacher, :active_course => true, :active_enrollment => true})
    end

    before :each do
      create_session(@pseudonym)
      stub_rcs_config
    end

    it 'should be able to click on things in the sidebar' do
      @course.wiki_pages.create!(title: 'Page1')
      get "/courses/#{@course.id}/pages/Page1/edit"
      f('#right-side button').click
      sleep 2
      expect(f('#right-side ul')).to include_text('Page1')
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
  end
end
