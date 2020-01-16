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

require_relative '../helpers/wiki_and_tiny_common'
require_relative 'pages/rcs_sidebar_page'

describe "Wiki pages and Tiny WYSIWYG editor Files" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage

  context "wiki and tiny files as a teacher" do

    before(:each) do
      stub_rcs_config
      course_with_teacher_logged_in
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

    describe "keyboard navigation and accessiblity" do
      context "when on the Files tab" do
        before do
          wiki_page_tools_file_tree_setup(true, true)
          click_files_tab
          driver.execute_script('$("#right-side li a").focus()')
        end

        it "sets the first root folder with aria-expanded=true when initialized" do
          root_folder = fj('#right-side button:contains("course files")')
          expect(root_folder).to have_attribute('aria-expanded', "true")
        end

        it "collapses a folder when you press the spacebar" do
          root_folder = fj('#right-side button:contains("course files")')
          root_folder.send_keys :space
          expect(root_folder).to have_attribute('aria-expanded', "false")
        end

        it "expands a collapsed folder when you press the spacebar" do
          sub_folder = fj('#right-side button:contains("subfolder")')
          sub_folder.send_keys :space
          expect(sub_folder).to have_attribute('aria-expanded', "true")
        end

        it "goes to the next item when pressing down" do
          first_file = fj('#right-side button:contains("email.png")')
          second_file = fj('#right-side button:contains("graded.png")')
          first_file.send_keys :arrow_down
          check_element_has_focus(second_file)
        end

        it "goes to the previous item when pressing up" do
          first_file = fj('#right-side button:contains("email.png")')
          second_file = fj('#right-side button:contains("graded.png")')
          second_file.send_keys :arrow_up
          check_element_has_focus(first_file)
        end
      end
    end

    it "should show uploaded files in file tree and add them to the rce" do
      wiki_page_tools_file_tree_setup(true, true)
      click_files_tab
      expect(sidebar_files.count).to eq 4

      upload_to_files_in_rce

      expect(sidebar_files.count).to eq 5

      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce')).to include_text('txt')
      end

      f('form.edit-form button.submit').click
      wait_for_ajax_requests
      check_file(f('#wiki_page_show a.instructure_file_link'))
    end

    it "should not show uploaded files in image list" do
      wiki_page_tools_file_tree_setup(true, true)
      wait_for_tiny(f("form.edit-form .edit-content"))
      click_images_tab
      upload_new_image.click
      wiki_page_body = clear_wiki_rce
      expect(sidebar_images.count).to eq 2

      alt_text = "foo text"
      _name, path, _data = get_file({:text => 'foo.txt'}[:text])
      f("input[type='file']").send_keys(path)
      f("input[name='alt_text']").send_keys(alt_text)
      f("button[type='submit']").click
      wait_for_ajaximations

      expect(sidebar_images.count).to eq 2
      expect(wiki_page_body[:value]).to be_empty
    end

    it "should be able to upload a file and add the file to the rce" do
      skip('investigate in CCI-182')
      add_file_to_rce
      check_file(f('#wiki_page_show a.instructure_file_link'))
    end

    it "should show files uploaded on the images tab in the file tree" do
      wiki_page_tools_file_tree_setup(true, true)
      click_files_tab
      expect(sidebar_files.count).to eq 4

      click_images_tab
      upload_new_image.click
      wiki_page_body = clear_wiki_rce
      expect(sidebar_images.count).to eq 2
      alt_text = "foo text"
      _name, path, _data = get_file({:text => 'foo.txt'}[:text])
      f("input[type='file']").send_keys(path)
      f("input[name='alt_text']").send_keys(alt_text)
      f("button[type='submit']").click
      wait_for_ajaximations

      expect(sidebar_images.count).to eq 2
      click_files_tab
      expect(sidebar_files.count).to eq 5
      expect(wiki_page_body[:value]).to be_empty
    end
  end

  context "wiki sidebar files and locking/hiding" do
    before(:each) do
      stub_rcs_config
      course_with_teacher_logged_in(:active_all => true, :name => 'wiki course')
      @root_folder = Folder.root_folders(@course).first
      @sub_folder = @root_folder.sub_folders.create!(:name => "visible subfolder", :context => @course)
    end

    it "should show root folder in the sidebar if it is locked" do
      @root_folder.locked = true
      @root_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_files_tab
      expect(fj("button:contains('course files')")).to be_displayed
    end

    it "should show root folder in the sidebar if it is hidden" do
      @root_folder.workflow_state = 'hidden'
      @root_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_files_tab
      expect(fj("button:contains('course files')")).to be_displayed
    end

    it "should show sub-folder in the sidebar if it is locked" do
      @root_folder.sub_folders.create!(:name => "subfolder", :context => @course, :locked => true)

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_files_tab
      expect(sidebar_files.count).to eq 2
      expect(ff('#right-side li')[1]).to include_text("visible subfolder")
    end

    it "should show sub-folder in the sidebar if it is hidden" do
      @root_folder.sub_folders.create!(:name => "subfolder", :context => @course, :workflow_state => 'hidden')

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_files_tab
      expect(sidebar_files.count).to eq 2
    end

    it "should show file in the sidebar if it is hidden" do
      _visible_attachment = attachment_model(:uploaded_data => stub_file_data('foo.txt', nil, 'text/html'), :content_type => 'text/html')
      attachment = attachment_model(:uploaded_data => stub_file_data('foo2.txt', nil, 'text/html'), :content_type => 'text/html')

      attachment.file_state = 'hidden'
      attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_files_tab
      expect(sidebar_files.count).to eq 3
    end

    it "should show file in the sidebar if it is locked" do
      _visible_attachment = attachment_model(:uploaded_data => stub_file_data('foo.txt', nil, 'text/html'), :content_type => 'text/html')
      attachment = attachment_model(:uploaded_data => stub_file_data('foo2.txt', nil, 'text/html'), :content_type => 'text/html')

      attachment.locked = true
      attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_files_tab
      expect(sidebar_files.count).to eq 3
    end
  end

  context "wiki sidebar images and locking/hiding" do
    before(:each) do
      stub_rcs_config
      course_with_teacher_logged_in(:active_all => true, :name => 'wiki course')
      @root_folder = Folder.root_folders(@course).first
      @sub_folder = @root_folder.sub_folders.create!(:name => "subfolder", :context => @course)

      @visible_attachment = @course.attachments.build(:filename => 'foo.png', :folder => @root_folder)
      @visible_attachment.content_type = 'image/png'
      @visible_attachment.save!

      @attachment = @course.attachments.build(:filename => 'foo2.png', :folder => @sub_folder)
      @attachment.content_type = 'image/png'
      @attachment.save!
    end

    it "should show image files if their containing folder is locked" do
      @sub_folder.locked = true
      @sub_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_images_tab
      wait_for_ajaximations
      expect(sidebar_images.count).to eq 2
    end

    it "should show image files if their containing folder is hidden" do
      @sub_folder.workflow_state = 'hidden'
      @sub_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_images_tab
      wait_for_ajaximations
      expect(sidebar_images.count).to eq 2
    end

    it "should show image files if the files navigation tab is hidden" do
      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_images_tab
      wait_for_ajaximations
      expect(sidebar_images.count).to eq 2
    end

    it "should show image files if they are hidden" do
      @attachment.file_state = 'hidden'
      @attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_images_tab
      wait_for_ajaximations
      expect(sidebar_images.count).to eq 2
    end

    it "should show image files if they are locked" do
      @attachment.locked = true
      @attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      expect(f('#editor_tabs')).to be_displayed
      click_images_tab
      wait_for_ajaximations
      expect(sidebar_images.count).to eq 2
    end
  end
end

