require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "Wiki pages and Tiny WYSIWYG editor Images" do
  include_examples "in-process server selenium tests"
  include_examples "quizzes selenium tests"

  context "wiki and tiny images as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
      @blank_page = @course.wiki.wiki_pages.create! :title => 'blank'
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
      expect(@image_list.find_elements(:css, '.img').length).to eq 0

      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(keep_trying_until { @image_list.find_elements(:css, '.img').length }).to eq 2
    end

    it "adds a tabindex to flickr search results" do
      skip "flickr outage"
      wiki_page_tools_file_tree_setup
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      f('.find_new_image_link').click
      f('#image_search_form input[type=text]').send_keys('dog')
      f('#image_search_form button[type=submit]').click
      wait_for_animations
      results = f('.results .image_link[tabindex="0"]')
      expect(results).not_to be_nil

    end

    it "inserts a flickr image when you hit enter" do
      skip "flickr outage"
      wiki_page_tools_file_tree_setup
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      f('.find_new_image_link').click
      f('#image_search_form input[type=text]').send_keys('dog')
      f('#image_search_form button[type=submit]').click
      wait_for_animations
      results = fj('.results .image_link[tabindex="0"]:first')
      results.send_keys(:return)
      in_frame "wiki_page_body_ifr" do
        expect(f('#tinymce img')).to be_displayed
      end
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
      expect(@image_list.find_elements(:css, '.img').length).to eq 0

      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      expect(keep_trying_until { @image_list.find_elements(:css, '.img').length }).to eq 30

      driver.execute_script('image_list = $(".image_list")')
      # scroll halfway down; it should load another 30
      driver.execute_script('image_list.scrollTop(100)')
      keep_trying_until { @image_list.find_elements(:css, '.img').length > 30 }
      expect(@image_list.find_elements(:css, '.img').length).to eq 60

      # scroll to the very bottom
      driver.execute_script('image_list.scrollTop(image_list[0].scrollHeight - image_list.height())')
      keep_trying_until { @image_list.find_elements(:css, '.img').length > 60 }
      expect(@image_list.find_elements(:css, '.img').length).to eq 90
    end

    it "should show images uploaded on the files tab in the image list" do
      wiki_page_tools_file_tree_setup
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations

      expect(root_folders.first.find_elements(:css, '.file.image').length).to eq 2

      wait_for_tiny(keep_trying_until { f("#new_wiki_page") })
      f('.upload_new_file_link').click
      fj('.wiki_switch_views_link:visible').click
      wiki_page_body = clear_wiki_rce

      expect(@image_list.find_elements(:css, '.img').length).to eq 2

      wiki_page_tools_upload_file('#sidebar_upload_file_form', :image)

      expect(root_folders.first.find_elements(:css, '.file.image').length).to eq 3
      expect(@image_list.find_elements(:css, '.img').length).to eq 3
      expect(find_css_in_string(wiki_page_body[:value], '.instructure_file_link')).not_to be_empty
    end

    it "should show uploaded images in image list and add the image to the rce" do
      skip "check image broken"
      wiki_page_tools_file_tree_setup
      wait_for_tiny(keep_trying_until { f("#new_wiki_page") })
      fj('.wiki_switch_views_link:visible').click
      clear_wiki_rce
      fj('.wiki_switch_views_link:visible').click
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajax_requests

      expect(@image_list.find_elements(:css, '.img').length).to eq 2
      keep_trying_until do
        ff('#editor_tabs_4 .image_list .img').first.click
        in_frame "wiki_page_body_ifr" do
          expect(f('#tinymce img')).to be_displayed
        end
        true
      end

      submit_form('#new_wiki_page')
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      check_image(f('#wiki_body img'))
    end

    it "should be able to upload an image and add the image to the rce" do
      skip "check_image broken"
      get "/courses/#{@course.id}/wiki"

      add_image_to_rce
      check_image(f('#wiki_body img'))
    end

    it "should add image via url" do
      get "/courses/#{@course.id}/wiki/blank"
      wait_for_ajaximations
      f('.edit_link').click
      add_url_image(driver, 'http://example.com/image.png', 'alt text')
      submit_form("#edit_wiki_page_#{@blank_page.id}")
      keep_trying_until { expect(f('#wiki_body')).to be_displayed }
      check_element_attrs(f('#wiki_body img'), :src => 'http://example.com/image.png', :alt => 'alt text')
    end
    
    describe "canvas images" do
      before do
        @course_root = Folder.root_folders(@course).first
        @course_attachment = @course_root.attachments.create! :uploaded_data => jpeg_data_frd, :filename => 'course.jpg', :display_name => 'course.jpg', :context => @course
        @teacher_root = Folder.root_folders(@teacher).first
        @teacher_attachment = @teacher_root.attachments.create! :uploaded_data => jpeg_data_frd, :filename => 'teacher.jpg', :display_name => 'teacher.jpg', :context => @teacher
        get "/courses/#{@course.id}/wiki/blank"
        wait_for_ajaximations
        f('.edit_link').click
      end
      
      it "should add a course image" do
        add_canvas_image(driver, 'Course files', 'course.jpg')
        submit_form("#edit_wiki_page_#{@blank_page.id}")
        keep_trying_until { expect(f('#wiki_body')).to be_displayed }
        check_element_attrs(f('#wiki_body img'), :src => /\/files\/#{@course_attachment.id}/, :alt => 'course.jpg')
      end
      
      it "should add a user image" do
        skip('testbot fragile')
        add_canvas_image(driver, 'My files', 'teacher.jpg')
        submit_form("#edit_wiki_page_#{@blank_page.id}")
        keep_trying_until { expect(f('#wiki_body')).to be_displayed }
        check_element_attrs(f('#wiki_body img'), :src => /\/files\/#{@teacher_attachment.id}/, :alt => 'teacher.jpg')
      end
    end

    it "should put images into the right editor" do
      @course_root = Folder.root_folders(@course).first
      @course_attachment = @course_root.attachments.create!(:context => @course, :uploaded_data => jpeg_data_frd, :filename => 'course.jpg', :display_name => 'course.jpg')
      @course_attachment2 = @course_root.attachments.create!(:context => @course, :uploaded_data => jpeg_data_frd, :filename => 'course2.jpg', :display_name => 'course2.jpg')
      get "/courses/#{@course.id}/quizzes"
      wait_for_ajaximations
      f(".new-quiz-link").click
      keep_trying_until { expect(f(".mce_instructure_image")).to be_displayed }
      add_canvas_image(driver, 'Course files', 'course2.jpg')

      click_questions_tab
      click_new_question_button
      wait_for_ajaximations
      add_canvas_image(f("#question_content_0_parent"), 'Course files', 'course.jpg')

      in_frame "question_content_0_ifr" do
        keep_trying_until {
          expect(f("#tinymce").find_elements(:css, "img").length).to eq 1
        }
        check_element_attrs(f('#tinymce img'), :src => /\/files\/#{@course_attachment.id}/, :alt => 'course.jpg')
      end

      click_settings_tab
      in_frame "quiz_description_ifr" do
        expect(f("#tinymce").find_elements(:css, "img").length).to eq 1
        check_element_attrs(f('#tinymce img'), :src => /\/files\/#{@course_attachment2.id}/, :alt => 'course2.jpg')
      end
    end
  end
end
