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

describe "RCE Next toolbar features" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage
  include CustomSeleniumActions
  include RCENextPage

  context "WYSIWYG generic as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
      stub_rcs_config
    end

    it "should add bullet lists", priority: "1", test_id: 307623 do
      skip('Unskip in CORE-2636')
      wysiwyg_state_setup(@course)

      click_bullet_list_button

      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce li').length).to eq 3
      end
    end

    it "should remove bullet lists", priority: "1", test_id: 535894 do
      skip('Unskip in CORE-2636')
      text = "<ul><li>1</li><li>2</li><li>3</li></ul>"
      wysiwyg_state_setup(@course, text, html: true)

      # editor window needs focus in chrome to enable bullet list button
      click_editor_window if driver.browser == :chrome
      click_bullet_list_button

      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('li')
      end
    end

    it "should add numbered lists", priority: "1", test_id: 307625 do
      skip('Unskip in CORE-2636')
      wysiwyg_state_setup(@course)

      click_list_toggle_button
      click_numbered_list_button

      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce li').length).to eq 3
      end
    end

    it "should remove numbered lists", priority: "1", test_id: 537619 do
      skip('Unskip in CORE-2636')
      text = "<ol><li>1</li><li>2</li><li>3</li></ol>"
      wysiwyg_state_setup(@course, text, html: true)

      # editor window needs focus in chrome to enable number list button
      click_editor_window if driver.browser == :chrome
      click_list_toggle_button
      click_numbered_list_button

      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('li')
      end
    end

    it "should indent and remove indentation for embedded images" do
      skip('Unskip in CORE-2637')
      title = "email.png"
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.build(:context => @course)
      path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/email.png')
      @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      @image.save!

      visit_front_page_edit(@course)
      click_images_toolbar_button
      click_course_images
      click_image_link(title)

      select_all_wiki
      force_click(indent_button)
      validate_wiki_style_attrib("padding-left", "40px", "p")

      force_click(indent_toggle_button)
      force_click(outdent_button)

      validate_wiki_style_attrib_empty("p")
    end

    it "should indent and remove indentation for text" do
      skip('Unskip in CORE-2637')
      wysiwyg_state_setup(@course, "test")

      click_indent_button
      validate_wiki_style_attrib("padding-left", "40px", "p")

      click_indent_toggle_button
      click_outdent_button
      
      validate_wiki_style_attrib_empty("p")
    end
  end
end
