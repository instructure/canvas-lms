require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor Files" do
  include_context "in-process server selenium tests"

  context "wiki and tiny files as a teacher" do

    before (:each) do
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
          wiki_page_tools_file_tree_setup
          f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
          driver.execute_script('$("#editor_tabs .ui-tabs-nav li:nth-child(2) a").focus()')
        end

        it "sets the first root folder with aria-selected=true when initialized" do
          root_folder = @tree1.find_elements(:css, '[role="treeitem"]').first
          expect(root_folder.attribute('aria-selected')).to eq "true"
        end

        it "expands a folder when you press the right allow key" do
          root_folder = @tree1.find_elements(:css, '[role="treeitem"]').first
          @tree1.send_keys :arrow_right
          wait_for_ajaximations
          expect(root_folder.attribute('aria-expanded')).to eq "true"
        end

        it "goes to the first child when pressing the right arrow on an expanded folder" do
          root_folder = @tree1.find_elements(:css, '[role="treeitem"]').first
          @tree1.send_keys :arrow_right
          wait_for_ajaximations
          @tree1.send_keys :arrow_right
          wait_for_ajaximations
          selected = @tree1.find_elements(:css, '[aria-selected="true"]').first
          expect(selected.attribute('id')).to eq root_folder.find_elements(:css, '[role="treeitem"]').first.attribute('id')
        end

        it "collapes folders when pressing the left arrow" do
          root_folder = @tree1.find_elements(:css, '[role="treeitem"]').first
          @tree1.send_keys :arrow_right
          wait_for_ajaximations
          expect(root_folder.attribute('aria-expanded')).to eq "true"

          @tree1.send_keys :arrow_left
          wait_for_ajaximations
          expect(root_folder.attribute('aria-expanded')).to eq "false"
        end

        it "goes to the next file avalible when pressing down" do 
          root_folder = @tree1.find_elements(:css, '[role="treeitem"]').first
          @tree1.send_keys :arrow_right
          wait_for_ajaximations
          @tree1.send_keys :arrow_down
          wait_for_ajaximations
          selected = @tree1.find_elements(:css, '[aria-selected="true"]').first
          expect(selected.attribute('id')).to eq root_folder.find_elements(:css, '[role="treeitem"]').first.attribute('id')
        end

        it "goes to the prevous file avalible when pressing up" do 
          root_folder = @tree1.find_elements(:css, '[role="treeitem"]').first
          @tree1.send_keys :arrow_right
          wait_for_ajaximations
          @tree1.send_keys :arrow_down
          wait_for_ajaximations
          @tree1.send_keys :arrow_up
          wait_for_ajaximations

          selected = @tree1.find_elements(:css, '[aria-selected="true"]').first
          expect(selected.attribute('id')).to eq root_folder.attribute('id')

        end

        it "doesn't change aria-selected when pressing enter" do
          root_folder = @tree1.find_elements(:css, '[role="treeitem"]').first
          @tree1.send_keys :arrow_right
          wait_for_ajaximations
          @tree1.send_keys :arrow_down
          wait_for_ajaximations
          @tree1.send_keys :arrow_down
          wait_for_ajaximations
          @tree1.send_keys :arrow_down
          wait_for_ajaximations
          @tree1.send_keys(:return)
          selected = @tree1.find_elements(:css, '[aria-selected="true"]').first
          expect(selected.attribute('id')).to eq root_folder.find_elements(:css, '[role="treeitem"]')[2].attribute('id')
        end
      end

    end
    it "should lazy load files" do
      wiki_page_tools_file_tree_setup
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click

      root_folders = @tree1.find_elements(:css, 'li.folder')
      expect(root_folders.length).to eq 1
      expect(root_folders.first.find_element(:css, '.name').text).to include_text('course files')

      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations

      sub_folders = root_folders.first.find_elements(:css, 'li.folder')
      expect(sub_folders.length).to eq 1
      expect(sub_folders.first.find_element(:css, '.name').text).to include_text('subfolder')

      text_file = root_folders.first.find_elements(:css, 'li.file.text')
      expect(text_file.length).to eq 1
      expect(text_file.first.find_element(:css, '.name').text).to include_text('text_file.txt')

      sub_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations

      sub_sub_folders = sub_folders.first.find_elements(:css, 'li.folder')
      expect(sub_sub_folders.length).to eq 1
      expect(sub_sub_folders.first.find_element(:css, '.name').text).to include_text('subsubfolder')

    end

    it "should lazy load directory structure for upload form" do
      wiki_page_tools_file_tree_setup
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click

      select = f('#attachment_folder_id')
      expect(select.find_elements(:css, 'option').length).to eq 1

      f('.upload_new_file_link').click
      keep_trying_until { select.find_elements(:css, 'option').length > 1 }
      expect(select.find_elements(:css, 'option').length).to eq 3
    end

    it "should be able to upload a file when nothing has been loaded" do
      wiki_page_tools_file_tree_setup
      keep_trying_until { expect(f("form.edit-form .edit-content")).to be_displayed }

      fj('a.switch_views:visible').click
      clear_wiki_rce
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      first_folder = @tree1.find_elements(:css, 'li.folder').first
      first_folder.find_element(:css, '.sign.plus').click
      wait_for_ajax_requests
      subfolder = first_folder.find_element(:css, '.folder')
      subfolder.find_element(:css, '.sign.plus').click
      wait_for_ajax_requests

      f('.upload_new_file_link').click
      wait_for_ajax_requests
      #testing adding to a subfolder
      select_element = f('#attachment_folder_id')
      select_element.click
      options = select_element.find_elements(:css, 'option')
      for option in options
        if option.text.include?('subfolder')
          option.click
          break
        end
      end
      wiki_page_tools_upload_file('#sidebar_upload_file_form', :text)
      wait_for_ajaximations
      keep_trying_until { expect(f('.file_list')).to include_text('testfile') }
    end

    it "should show uploaded files in file tree and add them to the rce" do
      wiki_page_tools_file_tree_setup
      wait_for_tiny(keep_trying_until { f("form.edit-form .edit-content") })
      fj('a.switch_views:visible').click
      clear_wiki_rce
      fj('a.switch_views:visible').click
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      f('.upload_new_file_link').click

      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations
      expect(root_folders.first.find_elements(:css, '.file.text').length).to eq 1

      wiki_page_tools_upload_file('#sidebar_upload_file_form', :text)

      expect(root_folders.first.find_elements(:css, '.file.text').length).to eq 2
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce')).to include_text('txt')
      end

      f('form.edit-form button.submit').click
      wait_for_ajax_requests

      check_file(f('#wiki_page_show .instructure_file_link_holder a'))
    end

    it "should not show uploaded files in image list" do
      wiki_page_tools_file_tree_setup
      wait_for_tiny(keep_trying_until { f("form.edit-form .edit-content") })
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      f('.upload_new_image_link').click
      fj('a.switch_views:visible').click
      wiki_page_body = clear_wiki_rce
      wait_for_ajaximations
      keep_trying_until { expect(@image_list.find_elements(:css, 'img.img').length).to eq 2 }

      wiki_page_tools_upload_file('#sidebar_upload_image_form', :text)

      expect(@image_list.find_elements(:css, 'img.img').length).to eq 2
      expect(wiki_page_body[:value]).to be_empty
    end

    it "should be able to upload a file and add the file to the rce" do
      add_file_to_rce
      check_file(f('#wiki_page_show .instructure_file_link_holder a'))
    end

    it "should show files uploaded on the images tab in the file tree" do
      wiki_page_tools_file_tree_setup
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations
      expect(root_folders.first.find_elements(:css, '.file.text').length).to eq 1

      wait_for_tiny(keep_trying_until { f("form.edit-form .edit-content") })
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      f('.upload_new_image_link').click
      fj('a.switch_views:visible').click
      wiki_page_body = clear_wiki_rce
      wait_for_ajaximations
      keep_trying_until { expect(@image_list.find_elements(:css, 'img.img').length).to eq 2 }

      wiki_page_tools_upload_file('#sidebar_upload_image_form', :text)

      expect(root_folders.first.find_elements(:css, '.file.text').length).to eq 2
      expect(@image_list.find_elements(:css, 'img.img').length).to eq 2
      expect(wiki_page_body[:value]).to be_empty
    end
  end

  context "wiki sidebar files and locking/hiding" do
    before (:each) do
      course_with_teacher_logged_in(:active_all => true, :name => 'wiki course')
      @root_folder = Folder.root_folders(@course).first
      @sub_folder = @root_folder.sub_folders.create!(:name => "visible subfolder", :context => @course)
    end

    it "should show root folder in the sidebar if it is locked" do
      @root_folder.locked = true
      @root_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      expect(ff('li.folder').count).to eq 1
    end

    it "should show root folder in the sidebar if it is hidden" do
      @root_folder.workflow_state = 'hidden'
      @root_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      expect(ff('li.folder').count).to eq 1
    end

    it "should show root folder in the sidebar if the files navigation tab is hidden" do
      skip('broken')
      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      expect(ff('li.folder').count).to eq 1
    end

    it "should show sub-folder in the sidebar if it is locked" do
      @root_folder.sub_folders.create!(:name => "subfolder", :context => @course, :locked => true)

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      expect(f('li.folder')).not_to be_nil
      f('li.folder span').click
      wait_for_ajaximations
      expect(ff('li.folder li.folder').count).to eq 2
      expect(f('li.folder li.folder .name').text).to include_text("visible subfolder")
    end

    it "should show sub-folder in the sidebar if it is hidden" do
      @root_folder.sub_folders.create!(:name => "subfolder", :context => @course, :workflow_state => 'hidden')

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      expect(f('li.folder')).not_to be_nil
      f('li.folder span').click
      wait_for_ajaximations
      expect(ff('li.folder li.folder').count).to eq 2
    end

    it "should show file in the sidebar if it is hidden" do
      visible_attachment = attachment_model(:uploaded_data => stub_file_data('foo.txt', nil, 'text/html'), :content_type => 'text/html')
      attachment = attachment_model(:uploaded_data => stub_file_data('foo2.txt', nil, 'text/html'), :content_type => 'text/html')

      attachment.file_state = 'hidden'
      attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      fj('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      wait_for_ajaximations
      keep_trying_until do
        fj('li.folder span').click
        wait_for_ajaximations
        expect(ff('li.folder li.file').count).to eq 2
      end
    end

    it "should show file in the sidebar if it is locked" do
      visible_attachment = attachment_model(:uploaded_data => stub_file_data('foo.txt', nil, 'text/html'), :content_type => 'text/html')
      attachment = attachment_model(:uploaded_data => stub_file_data('foo2.txt', nil, 'text/html'), :content_type => 'text/html')

      attachment.locked = true
      attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      fj('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      wait_for_ajaximations
      keep_trying_until do
        fj('li.folder span').click
        wait_for_ajaximations
        expect(ff('li.folder li.file').count).to eq 2
      end
    end
  end

  context "wiki sidebar images and locking/hiding" do
    before (:each) do
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
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.image_list img.img').count).to eq 2
    end

    it "should show image files if their containing folder is hidden" do
      @sub_folder.workflow_state = 'hidden'
      @sub_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.image_list img.img').count).to eq 2
    end

    it "should show image files if the files navigation tab is hidden" do
      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.image_list img.img').count).to eq 2
    end

    it "should show image files if they are hidden" do
      @attachment.file_state = 'hidden'
      @attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.image_list img.img').count).to eq 2
    end

    it "should show image files if they are locked" do
      @attachment.locked = true
      @attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(ff('.image_list img.img').count).to eq 2
    end
  end
end
