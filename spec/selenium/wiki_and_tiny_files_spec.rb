require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor Files" do
  it_should_behave_like "wiki and tiny selenium tests"

  def add_file_to_rce
    wiki_page_tools_file_tree_setup
    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    driver.find_element(:css, '.wiki_switch_views_link').click
    wiki_page_body = clear_wiki_rce
    driver.find_element(:css, '.wiki_switch_views_link').click
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
    root_folders = @tree1.find_elements(:css, 'li.folder')
    root_folders.first.find_element(:css, '.sign.plus').click
    wait_for_ajaximations
    root_folders.first.find_elements(:css, '.file.text').length.should == 1
    root_folders.first.find_elements(:css, '.file.text span').first.click

    in_frame "wiki_page_body_ifr" do
      driver.find_element(:id, 'tinymce').should include_text('txt')
    end
    driver.find_element(:css, '.wiki_switch_views_link').click
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
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click

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
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click

      select = driver.find_element(:css, '#sidebar_upload_file_form select#attachment_folder_id')
      select.find_elements(:css, 'option').length.should == 1

      driver.find_element(:css, '.upload_new_file_link').click
      keep_trying_until { select.find_elements(:css, 'option').length > 1 }
      select.find_elements(:css, 'option').length.should == 3
    end

    it "should be able to upload a file when nothing has been loaded" do
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      keep_trying_until { driver.find_element(:css, "form#new_wiki_page").should be_displayed }
      driver.find_element(:css, '.wiki_switch_views_link').click
      clear_wiki_rce
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      first_folder = @tree1.find_elements(:css, 'li.folder').first
      first_folder.find_element(:css, '.sign.plus').click
      wait_for_ajax_requests
      subfolder = first_folder.find_element(:css, '.folder')
      subfolder.find_element(:css, '.sign.plus').click
      wait_for_ajax_requests

      driver.find_element(:css, '.upload_new_file_link').click
      wait_for_ajax_requests
      #testing adding to a subfolder
      select_element = driver.find_element(:id, 'attachment_folder_id')
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
      keep_trying_until { driver.find_element(:css, '.file_list').should include_text('testfile') }
    end

    it "should show uploaded files in file tree and add them to the rce" do
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '.wiki_switch_views_link').click
      clear_wiki_rce
      driver.find_element(:css, '.wiki_switch_views_link').click
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      driver.find_element(:css, '.upload_new_file_link').click

      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations
      root_folders.first.find_elements(:css, '.file.text').length.should == 1

      wiki_page_tools_upload_file('#sidebar_upload_file_form', :text)

      root_folders.first.find_elements(:css, '.file.text').length.should == 2
      in_frame "wiki_page_body_ifr" do
        driver.find_element(:id, 'tinymce').should include_text('txt')
      end

      submit_form('#new_wiki_page')
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      check_file(driver.find_element(:css, '#wiki_body .instructure_file_link_holder a'))

    end

    it "should not show uploaded files in image list" do
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      driver.find_element(:css, '.upload_new_image_link').click
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_wiki_rce
      wait_for_ajaximations
      keep_trying_until { @image_list.find_elements(:css, 'img.img').length.should == 2 }

      wiki_page_tools_upload_file('#sidebar_upload_image_form', :text)

      @image_list.find_elements(:css, 'img.img').length.should == 2
      wiki_page_body[:value].should be_empty
    end

    it "should be able to upload a file and add the file to the rce" do
      add_file_to_rce
      check_file(driver.find_element(:css, '#wiki_body .instructure_file_link_holder a'))
    end

    it "should show files uploaded on the images tab in the file tree" do
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations
      root_folders.first.find_elements(:css, '.file.text').length.should == 1

      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      driver.find_element(:css, '.upload_new_image_link').click
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_wiki_rce
      wait_for_ajaximations
      keep_trying_until { @image_list.find_elements(:css, 'img.img').length.should == 2 }

      wiki_page_tools_upload_file('#sidebar_upload_image_form', :text)

      root_folders.first.find_elements(:css, '.file.text').length.should == 2
      @image_list.find_elements(:css, 'img.img').length.should == 2
      wiki_page_body[:value].should be_empty
    end
  end

  context "wiki and tiny files as a student" do
    before (:each) do
      course(:active_all => true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @teacher = user_with_pseudonym(:active_user => true, :username => 'teacher@example.com', :name => 'teacher@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @course.enroll_teacher(@teacher).accept
    end

    it "should add a file to the page and validate a student can see it" do
      login_as(@teacher.name)

      add_file_to_rce
      login_as(@student.name)
      get "/courses/#{@course.id}/wiki"
      find_with_jquery('a[title="text_file.txt"]').should be_displayed
      #check_file would be good to do here but the src on the file in the wiki body is messed up
    end
  end
end
