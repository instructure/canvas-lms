# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/wiki_and_tiny_common"
require_relative "../helpers/quizzes_common"
require_relative '../helpers/wiki_and_tiny_common'
require_relative 'pages/rcs_sidebar_page'

describe "Wiki pages and Tiny WYSIWYG editor Images" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include WikiAndTinyCommon
  include RCSSidebarPage

  context "wiki and tiny images as a teacher" do

    before(:each) do
      stub_rcs_config
      course_with_teacher_logged_in
      @blank_page = @course.wiki_pages.create! :title => 'blank'
    end

    after(:each) do
      # wait for all images to be done loading, since they may be thumbnails which hit the rails stack
      keep_trying_until do
        driver.execute_script <<-SCRIPT
          var done = true;
          var images = $('img:visible');
          for(var idx in images) {
            if(images[idx].src && !images[idx].complete) {
              done = false;
              break;
            }
          }
          return done;
        SCRIPT
      end
    end

    it "should lazy load images" do
      wiki_page_tools_file_tree_setup(true, true)
      expect(sidebar_tabs).not_to have_class('initialized')
      expect(sidebar_tabs).not_to contain_css('img')

      click_images_tab
      wait_for_ajaximations
      expect(sidebar_images.count).to eq 2
    end

    it "should paginate images" do
      wiki_page_tools_file_tree_setup(true, true)
      150.times do |i|
        image = @root_folder.attachments.build(:context => @course)
        path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/graded.png')
        image.display_name = "image #{i}"
        image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
        image.save!
      end

      click_images_tab
      wait_for_ajaximations
      expect(sidebar_images.count).to eq 50

      # click the load more link; it should load another 50
      fj('button:contains("Load more results")').click
      wait_for_ajaximations
      expect(sidebar_images.count).to eq 100

      # click the very last load more link
      fj('button:contains("Load more results")').click
      wait_for_ajaximations
      expect(sidebar_images.count).to eq 150
    end

    it "should show images uploaded on the files tab in the image list" do
      skip('investigate in CCI-182')
      wiki_page_tools_file_tree_setup(true, true)
      click_files_tab
      wait_for_ajaximations

      expect(sidebar_files.length).to eq 4

      wait_for_tiny(f("form.edit-form .edit-content"))
      wiki_page_body = clear_wiki_rce

      upload_to_files_in_rce(true)
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.last
      expect(sidebar_files.length).to eq 5
      click_images_tab
      wait_for_ajaximations

      expect(fj("#right-side [role='button'] img:last").attribute('src')).to include "/thumbnails/#{@image.id}"
      switch_editor_views(wiki_page_body)
      expect(find_css_in_string(wiki_page_body[:value], '.instructure_file_link')).not_to be_empty
    end

    it "should add image via url" do
      get "/courses/#{@course.id}/pages/blank"
      wait_for_ajaximations
      f('a.edit-wiki').click
      wait_for_tiny(f("#tinymce-parent-of-wiki_page_body"))
      add_url_image(driver, 'https://via.placeholder.com/150.jpg', 'alt text')
      f('form.edit-form button.submit').click
      expect(f('#wiki_page_show')).to be_displayed
      check_element_attrs(f('#wiki_page_show img'), :src => 'https://via.placeholder.com/150.jpg', :alt => 'alt text')
    end

    describe "canvas images" do
      before do
        @course_root = Folder.root_folders(@course).first
        @course_attachment = @course_root.attachments.create! :uploaded_data => jpeg_data_frd,
                                                              :filename => 'course.jpg',
                                                              :display_name => 'course.jpg',
                                                              :context => @course
        get "/courses/#{@course.id}/pages/blank"
        wait_for_ajaximations
        f('a.edit-wiki').click
      end

      it "should add a course image" do
        add_canvas_image(driver, 'Course files', 'course.jpg')
        f('form.edit-form button.submit').click
        expect(f('#wiki_page_show')).to be_displayed
      end
    end
  end
end
