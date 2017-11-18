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

require_relative "common"
require_relative "helpers/wiki_and_tiny_common"
require_relative "helpers/quizzes_common"

describe "Wiki pages and Tiny WYSIWYG editor Images" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include WikiAndTinyCommon

  context "wiki and tiny images as a teacher" do

    before(:each) do
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
      wiki_page_tools_file_tree_setup
      expect(@image_list).not_to have_class('initialized')
      expect(@image_list).not_to contain_css('.img')

      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.img', @image_list)).to have_size(2)
    end

    it "should infini-scroll images" do
      wiki_page_tools_file_tree_setup
      90.times do |i|
        image = @root_folder.attachments.build(:context => @course)
        path = File.expand_path(File.dirname(__FILE__) + '/../../public/images/graded.png')
        image.display_name = "image #{i}"
        image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
        image.save!
      end
      expect(@image_list).not_to have_class('initialized')
      expect(@image_list).not_to contain_css('.img')

      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.img', @image_list)).to have_size(30)

      # scroll halfway down; it should load another 30
      scroll_element '.image_list', 100
      expect(ff('.img', @image_list)).to have_size(60)

      # scroll to the very bottom
      scroll_element '.image_list', 'max'
      expect(ff('.img', @image_list)).to have_size(90)
    end

    it "should show images uploaded on the files tab in the image list" do
      wiki_page_tools_file_tree_setup
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations

      expect(root_folders.first.find_elements(:css, '.file.image').length).to eq 2

      wait_for_tiny(f("form.edit-form .edit-content"))
      f('.upload_new_file_link').click
      wiki_page_body = clear_wiki_rce

      expect(@image_list.find_elements(:css, '.img').length).to eq 2

      wiki_page_tools_upload_file('#sidebar_upload_file_form', :image)
      wait_for_ajaximations
      expect(root_folders.first.find_elements(:css, '.file.image').length).to eq 3
      expect(@image_list.find_elements(:css, '.img').length).to eq 3
      switch_editor_views(wiki_page_body)
      expect(find_css_in_string(wiki_page_body[:value], '.instructure_file_link')).not_to be_empty
    end

    it "should add image via url" do
      get "/courses/#{@course.id}/pages/blank"
      wait_for_ajaximations
      f('a.edit-wiki').click
      add_url_image(driver, 'http://example.com/image.png', 'alt text')
      f('form.edit-form button.submit').click
      expect(f('#wiki_page_show')).to be_displayed
      check_element_attrs(f('#wiki_page_show img'), :src => 'http://example.com/image.png', :alt => 'alt text')
    end

    describe "canvas images" do
      before do
        @course_root = Folder.root_folders(@course).first
        @course_attachment = @course_root.attachments.create! :uploaded_data => jpeg_data_frd, :filename => 'course.jpg', :display_name => 'course.jpg', :context => @course
        @teacher_root = Folder.root_folders(@teacher).first
        @teacher_attachment = @teacher_root.attachments.create! :uploaded_data => jpeg_data_frd, :filename => 'teacher.jpg', :display_name => 'teacher.jpg', :context => @teacher
        get "/courses/#{@course.id}/pages/blank"
        wait_for_ajaximations
        f('a.edit-wiki').click
      end

      it "should add a course image" do
        add_canvas_image(driver, 'Course files', 'course.jpg')
        f('form.edit-form button.submit').click
        expect(f('#wiki_page_show')).to be_displayed
        check_element_attrs(f('#wiki_page_show img'), :src => /\/files\/#{@course_attachment.id}/, :alt => 'course.jpg')
      end
    end

    it "should put images into the right editor" do
      skip('fragile, see CNVS-39901')
      @course_root = Folder.root_folders(@course).first
      @course_attachment = @course_root.attachments.create!(:context => @course, :uploaded_data => jpeg_data_frd, :filename => 'course.jpg', :display_name => 'course.jpg')
      @course_attachment2 = @course_root.attachments.create!(:context => @course, :uploaded_data => jpeg_data_frd, :filename => 'course2.jpg', :display_name => 'course2.jpg')
      get "/courses/#{@course.id}/quizzes"
      wait_for_ajaximations
      f(".new-quiz-link").click
      expect(f("div[aria-label='Embed Image']")).to be_displayed
      add_canvas_image(driver, 'Course files', 'course2.jpg')

      click_questions_tab
      click_new_question_button
      wait_for_ajaximations

      container = ff(".mce-container").detect(&:displayed?)
      add_canvas_image(container, 'Course files', 'course.jpg')

      in_frame "question_content_0_ifr" do
        expect(ff("#tinymce img")).to have_size 1
        check_element_attrs(f('#tinymce img'), :src => /\/files\/#{@course_attachment.id}/, :alt => 'course.jpg')
      end

      click_settings_tab
      in_frame "quiz_description_ifr" do
        expect(ff("#tinymce img")).to have_size 1
        check_element_attrs(f('#tinymce img'), :src => /\/files\/#{@course_attachment2.id}/, :alt => 'course2.jpg')
      end
    end
  end
end
