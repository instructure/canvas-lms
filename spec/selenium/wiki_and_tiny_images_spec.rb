require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor Images" do
  it_should_behave_like "wiki and tiny selenium tests"

  def add_flickr_image(el)
    el.find_element(:css, '.mce_instructure_embed').click
    driver.find_element(:css, '.flickr_search_link').click
    driver.find_element(:css, '#image_search_form > input').send_keys('angel')
    submit_form('#image_search_form')
    wait_for_ajax_requests
    keep_trying_until { driver.find_element(:css, '.image_link').should be_displayed }
    driver.find_element(:css, '.image_link').click
  end

  def add_image_to_rce
    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    driver.find_element(:css, '.wiki_switch_views_link').click
    clear_wiki_rce
    driver.find_element(:css, '.wiki_switch_views_link').click
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
    driver.find_element(:css, '.upload_new_image_link').click
    wiki_page_tools_upload_file('#sidebar_upload_image_form', :image)
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:css, '#tinymce img').should be_displayed
    end

    submit_form('#new_wiki_page')
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests
  end

  context "wiki and tiny images as a teacher" do

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

    it "should lazy load images" do
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      @image_list.should_not have_class('initialized')
      @image_list.find_elements(:css, 'img.img').length.should == 0

      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      keep_trying_until { @image_list.find_elements(:css, 'img.img').length }.should == 2
    end


    it "should properly clone images, including thumbnails, and display" do
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      old_course = @course
      new_course = old_course.clone_for(old_course.account)
      new_course.merge_into_course(old_course, :everything => true)
      new_course.enroll_teacher(@user)

      get "/courses/#{new_course.id}/wiki"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      keep_trying_until do
        images = ffj('#editor_tabs_4 .image_list img.img')
        images.length.should == 2
        #images.each { |i| i.attribute('complete').should == 'true' } - commented out because it is breaking with
        #webdriver 2.22 and firefox 12
      end
    end

    it "should infini-scroll images" do
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      90.times do |i|
        image = @root_folder.attachments.build(:context => @course)
        path = File.expand_path(File.dirname(__FILE__) + '/../../public/images/graded.png')
        image.display_name = "image #{i}"
        image.uploaded_data = ActionController::TestUploadedFile.new(path, Attachment.mimetype(path))
        image.save!
      end
      @image_list.should_not have_class('initialized')
      @image_list.find_elements(:css, 'img.img').length.should == 0

      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      keep_trying_until { @image_list.find_elements(:css, 'img.img').length }.should == 30

      driver.execute_script('image_list = $(".image_list")')
      # scroll halfway down; it should load another 30
      driver.execute_script('image_list.scrollTop(100)')
      keep_trying_until { @image_list.find_elements(:css, 'img.img').length > 30 }
      @image_list.find_elements(:css, 'img.img').length.should == 60

      # scroll to the very bottom
      driver.execute_script('image_list.scrollTop(image_list[0].scrollHeight - image_list.height())')
      keep_trying_until { @image_list.find_elements(:css, 'img.img').length > 60 }
      @image_list.find_elements(:css, 'img.img').length.should == 90
    end

    it "should show images uploaded on the files tab in the image list" do
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations

      root_folders.first.find_elements(:css, '.file.image').length.should == 2

      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '.upload_new_file_link').click
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_wiki_rce

      @image_list.find_elements(:css, 'img.img').length.should == 2

      wiki_page_tools_upload_file('#sidebar_upload_file_form', :image)

      root_folders.first.find_elements(:css, '.file.image').length.should == 3
      @image_list.find_elements(:css, 'img.img').length.should == 3
      find_css_in_string(wiki_page_body[:value], '.instructure_file_link').should_not be_empty
    end

    it "should show uploaded images in image list and add the image to the rce" do
      skip_if_ie('Out of memory')
      wiki_page_tools_file_tree_setup
      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '.wiki_switch_views_link').click
      clear_wiki_rce
      driver.find_element(:css, '.wiki_switch_views_link').click
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajax_requests

      @image_list.find_elements(:css, 'img.img').length.should == 2
      keep_trying_until do
        driver.find_elements(:css, '#editor_tabs_4 .image_list img.img').first.click
        in_frame "wiki_page_body_ifr" do
          driver.find_element(:css, '#tinymce img').should be_displayed
        end
        true
      end

      submit_form('#new_wiki_page')
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      check_image(driver.find_element(:css, '#wiki_body img'))
    end

    it "should be able to upload an image and add the image to the rce" do
      get "/courses/#{@course.id}/wiki"

      add_image_to_rce
      check_image(driver.find_element(:css, '#wiki_body img'))
    end

    it "should add image from flickr" do
      skip_if_ie('Out of memory')
      get "/courses/#{@course.id}/wiki"

      #add image from flickr to rce
      driver.find_element(:css, '.wiki_switch_views_link').click
      clear_wiki_rce
      driver.find_element(:css, '.wiki_switch_views_link').click
      add_flickr_image(driver)
      in_frame "wiki_page_body_ifr" do
        driver.find_element(:css, '#tinymce img').should be_displayed
      end

      submit_form('#new_wiki_page')
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      check_image(driver.find_element(:css, '#wiki_body img'))
    end


    it "should put flickr images into the right editor" do
      skip_if_ie('Out of memory')
      get "/courses/#{@course.id}/quizzes"
      driver.find_element(:css, ".new-quiz-link").click
      keep_trying_until { driver.find_element(:css, ".mce_instructure_embed").should be_displayed }
      add_flickr_image(driver)
      driver.find_element(:css, ".add_question_link").click
      wait_for_animations
      add_flickr_image(driver.find_element(:id, "question_content_0_parent"))
      in_frame "quiz_description_ifr" do
        driver.find_element(:id, "tinymce").find_elements(:css, "a").length.should == 1
      end
      in_frame "question_content_0_ifr" do
        driver.find_element(:id, "tinymce").find_elements(:css, "a").length.should == 1
      end
    end
  end

  context "wiki and tiny images as a student" do
    before (:each) do
      course(:active_all => true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @teacher = user_with_pseudonym(:active_user => true, :username => 'teacher@example.com', :name => 'teacher@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @course.enroll_teacher(@teacher).accept
    end

    it "should add an image to the page and validate a student can see it" do
      login_as(@teacher.name)
      get "/courses/#{@course.id}/wiki"
      add_image_to_rce

      login_as(@student.name)
      get "/courses/#{@course.id}/wiki"
      find_with_jquery("img[src='/courses/#{@course.id}/files/#{@course.attachments.last.id}/preview']").should be_displayed
      #check_image would be good to do here but the src on the image in the wiki body is messed up
    end
  end
end
