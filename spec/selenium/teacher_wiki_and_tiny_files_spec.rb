require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor Files" do
  include_examples "in-process server selenium tests"

  def add_file_to_rce
    wiki_page_tools_file_tree_setup
    wait_for_tiny(keep_trying_until { f("#new_wiki_page") })
    f('.wiki_switch_views_link').click
    wiki_page_body = clear_wiki_rce
    f('.wiki_switch_views_link').click
    f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
    root_folders = @tree1.find_elements(:css, 'li.folder')
    root_folders.first.find_element(:css, '.sign.plus').click
    wait_for_ajaximations
    root_folders.first.find_elements(:css, '.file.text').length.should == 1
    root_folders.first.find_elements(:css, '.file.text span').first.click

    in_frame "wiki_page_body_ifr" do
      f('#tinymce').should include_text('txt')
    end
    f('.wiki_switch_views_link').click
    find_css_in_string(wiki_page_body[:value], '.instructure_file_link').should_not be_empty
    submit_form('#new_wiki_page')
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests
  end


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

    it "should lazy load files" do
      wiki_page_tools_file_tree_setup
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click

      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.length.should == 1
      root_folders.first.find_element(:css, '.name').text.should == 'course files'

      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations

      sub_folders = root_folders.first.find_elements(:css, 'li.folder')
      sub_folders.length.should == 1
      sub_folders.first.find_element(:css, '.name').text.should == 'subfolder'

      text_file = root_folders.first.find_elements(:css, 'li.file.text')
      text_file.length.should == 1
      text_file.first.find_element(:css, '.name').text.should == 'text_file.txt'

      sub_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations

      sub_sub_folders = sub_folders.first.find_elements(:css, 'li.folder')
      sub_sub_folders.length.should == 1
      sub_sub_folders.first.find_element(:css, '.name').text.should == 'subsubfolder'

    end

    it "should lazy load directory structure for upload form" do
      wiki_page_tools_file_tree_setup
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click

      select = f('#attachment_folder_id')
      select.find_elements(:css, 'option').length.should == 1

      f('.upload_new_file_link').click
      keep_trying_until { select.find_elements(:css, 'option').length > 1 }
      select.find_elements(:css, 'option').length.should == 3
    end

    it "should be able to upload a file when nothing has been loaded" do
      wiki_page_tools_file_tree_setup
      keep_trying_until { f("#new_wiki_page").should be_displayed }
      f('.wiki_switch_views_link').click
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
      keep_trying_until { f('.file_list').should include_text('testfile') }
    end

    it "should show uploaded files in file tree and add them to the rce" do
      wiki_page_tools_file_tree_setup
      wait_for_tiny(keep_trying_until { f("#new_wiki_page") })
      f('.wiki_switch_views_link').click
      clear_wiki_rce
      f('.wiki_switch_views_link').click
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      f('.upload_new_file_link').click

      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations
      root_folders.first.find_elements(:css, '.file.text').length.should == 1

      wiki_page_tools_upload_file('#sidebar_upload_file_form', :text)

      root_folders.first.find_elements(:css, '.file.text').length.should == 2
      in_frame "wiki_page_body_ifr" do
        f('#tinymce').should include_text('txt')
      end

      submit_form('#new_wiki_page')
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      check_file(f('#wiki_body .instructure_file_link_holder a'))

    end

    it "should not show uploaded files in image list" do
      wiki_page_tools_file_tree_setup
      wait_for_tiny(keep_trying_until { f("#new_wiki_page") })
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      f('.upload_new_image_link').click
      f('.wiki_switch_views_link').click
      wiki_page_body = clear_wiki_rce
      wait_for_ajaximations
      keep_trying_until { @image_list.find_elements(:css, 'img.img').length.should == 2 }

      wiki_page_tools_upload_file('#sidebar_upload_image_form', :text)

      @image_list.find_elements(:css, 'img.img').length.should == 2
      wiki_page_body[:value].should be_empty
    end

    it "should be able to upload a file and add the file to the rce" do
      add_file_to_rce
      check_file(f('#wiki_body .instructure_file_link_holder a'))
    end

    it "should show files uploaded on the images tab in the file tree" do
      wiki_page_tools_file_tree_setup
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations
      root_folders.first.find_elements(:css, '.file.text').length.should == 1

      wait_for_tiny(keep_trying_until { f("#new_wiki_page") })
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      f('.upload_new_image_link').click
      f('.wiki_switch_views_link').click
      wiki_page_body = clear_wiki_rce
      wait_for_ajaximations
      keep_trying_until { @image_list.find_elements(:css, 'img.img').length.should == 2 }

      wiki_page_tools_upload_file('#sidebar_upload_image_form', :text)

      root_folders.first.find_elements(:css, '.file.text').length.should == 2
      @image_list.find_elements(:css, 'img.img').length.should == 2
      wiki_page_body[:value].should be_empty
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
      ff('li.folder').count.should == 1
    end

    it "should show root folder in the sidebar if it is hidden" do
      @root_folder.workflow_state = 'hidden'
      @root_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      ff('li.folder').count.should == 1
    end

    it "should show root folder in the sidebar if the files navigation tab is hidden" do
      pending('broken')
      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      ff('li.folder').count.should == 1
    end

    it "should show sub-folder in the sidebar if it is locked" do
      @root_folder.sub_folders.create!(:name => "subfolder", :context => @course, :locked => true)

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      f('li.folder').should_not be_nil
      f('li.folder span').click
      wait_for_ajaximations
      ff('li.folder li.folder').count.should == 2
      f('li.folder li.folder .name').text.should == "visible subfolder"
    end

    it "should show sub-folder in the sidebar if it is hidden" do
      @root_folder.sub_folders.create!(:name => "subfolder", :context => @course, :workflow_state => 'hidden')

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      f('li.folder').should_not be_nil
      f('li.folder span').click
      wait_for_ajaximations
      ff('li.folder li.folder').count.should == 2
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
        ff('li.folder li.file').count.should == 2
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
        ff('li.folder li.file').count.should == 2
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
      ff('.image_list img.img').count.should == 2
    end

    it "should show image files if their containing folder is hidden" do
      @sub_folder.workflow_state = 'hidden'
      @sub_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      ff('.image_list img.img').count.should == 2
    end

    it "should show image files if the files navigation tab is hidden" do
      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      ff('.image_list img.img').count.should == 2
    end

    it "should show image files if they are hidden" do
      @attachment.file_state = 'hidden'
      @attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      ff('.image_list img.img').count.should == 2
    end

    it "should show image files if they are locked" do
      @attachment.locked = true
      @attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      ff('.image_list img.img').count.should == 2
    end
  end
end
