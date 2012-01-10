require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Wiki pages and Tiny WYSIWYG editor" do
  # it_should_behave_like "forked server selenium tests"
  it_should_behave_like "in-process server selenium tests"

  def clear_rce
    wiki_page_body = driver.find_element(:id, :wiki_page_body)
    wiki_page_body.clear
    wiki_page_body[:value].should be_empty
    wiki_page_body
  end

  def file_tree_setup
    course_with_teacher_logged_in
    @root_folder = Folder.root_folders(@course).first
    @sub_folder = @root_folder.sub_folders.create!(:name => 'subfolder', :context => @course);
    @sub_sub_folder = @sub_folder.sub_folders.create!(:name => 'subsubfolder', :context => @course);
    @text_file = @root_folder.attachments.create!(:filename => 'text_file.txt', :context => @course) { |a| a.content_type = 'text/plain' }
    @image1 = @root_folder.attachments.build(:context => @course)
    path = File.expand_path(File.dirname(__FILE__) + '/../../public/images/email.png')
    @image1.uploaded_data = ActionController::TestUploadedFile.new(path, Attachment.mimetype(path))
    @image1.save!
    @image2 = @root_folder.attachments.build(:context => @course)
    path = File.expand_path(File.dirname(__FILE__) + '/../../public/images/graded.png')
    @image2.uploaded_data = ActionController::TestUploadedFile.new(path, Attachment.mimetype(path))
    @image2.save!
    get "/courses/#{@course.id}/wiki"

    @tree1 = driver.find_element(:id, :tree1)
    @image_list = driver.find_element(:css, '#editor_tabs_3 .image_list')
  end

  context "files and images" do

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
      file_tree_setup
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

    it "should lazy load images" do
      file_tree_setup
      @image_list.attribute('class').should_not match(/initialized/)
      @image_list.find_elements(:css, 'img.img').length.should == 0

      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      keep_trying_until { @image_list.find_elements(:css, 'img.img').length }.should == 2
    end

    it "should properly clone images, including thumbnails, and display" do
      file_tree_setup
      old_course = @course
      new_course = old_course.clone_for(old_course.account)
      new_course.merge_into_course(old_course, :everything => true)
      new_course.enroll_teacher(@user)

      get "/courses/#{new_course.id}/wiki"
      @tree1 = driver.find_element(:id, :tree1)
      @image_list = driver.find_element(:css, '#editor_tabs_3 .image_list')
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      keep_trying_until {
        images = @image_list.find_elements(:css, 'img.img')
        images.length.should == 2
        images.each { |i| i.attribute('complete').should == 'true' }
      }
    end

    it "should infini-scroll images" do
      file_tree_setup
      90.times do |i|
        image = @root_folder.attachments.build(:context => @course)
        path = File.expand_path(File.dirname(__FILE__) + '/../../public/images/graded.png')
        image.display_name = "image #{i}"
        image.uploaded_data = ActionController::TestUploadedFile.new(path, Attachment.mimetype(path))
        image.save!
      end
      @image_list.attribute('class').should_not match(/initialized/)
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

    it "should lazy load directory structure for upload form" do
      file_tree_setup
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click

      select = driver.find_element(:css, '#sidebar_upload_file_form select#attachment_folder_id')
      select.find_elements(:css, 'option').length.should == 1

      driver.find_element(:css, '.upload_new_file_link').click
      keep_trying_until { select.find_elements(:css, 'option').length > 1 }
      select.find_elements(:css, 'option').length.should == 3
    end

    def upload_file(form, type)
      name, path, data = get_file({ :text => 'testfile1.txt', :image => 'graded.png' }[type])

      driver.find_element(:css, "#{form} .file_name").send_keys(path)
      driver.find_element(:css, "#{form} button").click
      keep_trying_until { find_all_with_jquery("#{form}:visible").empty? }
    end

    it "should be able to upload a file when nothing has been loaded" do
      file_tree_setup
      keep_trying_until { driver.find_element(:css, "form#new_wiki_page").should be_displayed }
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_rce
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
      upload_file('#sidebar_upload_file_form', :text)
      wait_for_ajax_requests


      subfolder.find_elements(:css, '.file.text').length.should == 1
    end

    it "should show uploaded files in file tree and add them to the rce" do
      file_tree_setup
      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_rce
      driver.find_element(:css, '.wiki_switch_views_link').click
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      driver.find_element(:css, '.upload_new_file_link').click

      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations
      root_folders.first.find_elements(:css, '.file.text').length.should == 1

      upload_file('#sidebar_upload_file_form', :text)

      root_folders.first.find_elements(:css, '.file.text').length.should == 2
      in_frame "wiki_page_body_ifr" do
        driver.find_element(:id, 'tinymce').should include_text('txt')
      end

      driver.find_element(:id, 'wiki_page_submit').click
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki"#can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      check_file( driver.find_element(:css, '#wiki_body .instructure_file_link_holder a') )

    end

    it "should not show uploaded files in image list" do
      file_tree_setup
      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      driver.find_element(:css, '.upload_new_image_link').click
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_rce
      wait_for_ajaximations
      keep_trying_until{ @image_list.find_elements(:css, 'img.img').length.should == 2 }

      upload_file('#sidebar_upload_image_form', :text)

      @image_list.find_elements(:css, 'img.img').length.should == 2
      wiki_page_body[:value].should be_empty
    end

    it "should be able to upload a file and add the file to the rce" do
      file_tree_setup
      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_rce
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
      wiki_page_body.attribute('value').should match(/class="instructure_file_link/)

      driver.find_element(:id, 'wiki_page_submit').click
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki"#can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      check_file( driver.find_element(:css, '#wiki_body .instructure_file_link_holder a') )
    end

    it "should show files uploaded on the images tab in the file tree" do
      file_tree_setup
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations
      root_folders.first.find_elements(:css, '.file.text').length.should == 1

      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      driver.find_element(:css, '.upload_new_image_link').click
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_rce
      wait_for_ajaximations
      keep_trying_until{ @image_list.find_elements(:css, 'img.img').length.should == 2 }

      upload_file('#sidebar_upload_image_form', :text)

      root_folders.first.find_elements(:css, '.file.text').length.should == 2
      @image_list.find_elements(:css, 'img.img').length.should == 2
      wiki_page_body[:value].should be_empty
    end

    it "should show images uploaded on the files tab in the image list" do
      file_tree_setup
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      root_folders = @tree1.find_elements(:css, 'li.folder')
      root_folders.first.find_element(:css, '.sign.plus').click
      wait_for_ajaximations

      root_folders.first.find_elements(:css, '.file.image').length.should == 2

      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '.upload_new_file_link').click
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_rce

      @image_list.find_elements(:css, 'img.img').length.should == 2

      upload_file('#sidebar_upload_file_form', :image)

      root_folders.first.find_elements(:css, '.file.image').length.should == 3
      @image_list.find_elements(:css, 'img.img').length.should == 3
      wiki_page_body[:value].should match(/a class="instructure_file_link/)
    end

    it "should show uploaded images in image list and add the image to the rce" do
      file_tree_setup
      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_rce
      driver.find_element(:css, '.wiki_switch_views_link').click
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajax_requests

      @image_list.find_elements(:css, 'img.img').length.should == 2
      keep_trying_until do
        driver.find_elements(:css, '#editor_tabs_3 .image_list img.img').first.click
        in_frame "wiki_page_body_ifr" do
          driver.find_element(:css, '#tinymce img').should be_displayed
        end
        true
      end

      driver.find_element(:id, 'wiki_page_submit').click
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki"#can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      check_image( driver.find_element(:css, '#wiki_body img') )
    end

    it "should be able to upload an image and add the image to the rce" do
      course_with_teacher_logged_in
      get "/courses/#{@course.id}/wiki"

      wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
      driver.find_element(:css, '.wiki_switch_views_link').click
      wiki_page_body = clear_rce
      driver.find_element(:css, '.wiki_switch_views_link').click
      driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      driver.find_element(:css, '.upload_new_image_link').click
      upload_file('#sidebar_upload_image_form', :image)
      in_frame "wiki_page_body_ifr" do
        driver.find_element(:css, '#tinymce img').should be_displayed
      end

      driver.find_element(:id, 'wiki_page_submit').click
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki"#can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      check_image( driver.find_element(:css, '#wiki_body img') )
    end
    
  end


  it "should add bold and italic text to the rce" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/wiki"

    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    driver.find_element(:css, '.mceIcon.mce_bold').click
    driver.find_element(:css, '.mceIcon.mce_italic').click
    first_text = 'This is my text.'

    type_in_tiny('#wiki_page_body', first_text)
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:id, 'tinymce').text.include?(first_text).should be_true
    end
    #make sure each view uses the proper format
    driver.find_element(:css, '.wiki_switch_views_link').click
    driver.execute_script("return $('#wiki_page_body').val()").should include '<p><em><strong>'
    driver.find_element(:css, '.wiki_switch_views_link').click
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:id, 'tinymce').text.include?('<p>').should be_false
    end

    driver.find_element(:id, 'wiki_page_submit').click
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki"#can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests

    driver.page_source.should match(/<p><em><strong>This is my text\./)
  end

  it "should add a quiz to the rce" do
    course_with_teacher_logged_in
    #create test quiz
    @context = @course
    quiz = quiz_model
    quiz.generate_quiz_data
    quiz.save!

    get "/courses/#{@course.id}/wiki"
    # add quiz to rce
    accordion = driver.find_element(:css, '#editor_tabs #pages_accordion')
    accordion.find_element(:link, I18n.t('links_to.quizzes','Quizzes')).click
    keep_trying_until{ accordion.find_element(:link, quiz.title).should be_displayed }
    accordion.find_element(:link, quiz.title).click
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:id, 'tinymce').should include_text(quiz.title)
    end

    driver.find_element(:id, 'wiki_page_submit').click
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki"#can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests

    driver.find_element(:css, '#wiki_body').find_element(:link, quiz.title).should be_displayed
  end

  it "should add an assignment to the rce" do
    course_with_teacher_logged_in
    assignment_name = 'first assignment'
    @assignment = @course.assignments.create(:name => assignment_name)
    get "/courses/#{@course.id}/wiki"

    driver.find_element(:css, '.wiki_switch_views_link').click
    clear_rce
    driver.find_element(:css, '.wiki_switch_views_link').click
    #check assigment accordion
    accordion = driver.find_element(:css, '#editor_tabs #pages_accordion')
    accordion.find_element(:link, I18n.t('links_to.assignments','Assignments')).click
    keep_trying_until{ accordion.find_element(:link, assignment_name).should be_displayed }
    accordion.find_element(:link, assignment_name).click
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:id, 'tinymce').should include_text(assignment_name)
    end

    driver.find_element(:id, 'wiki_page_submit').click
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki"#can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests

    driver.find_element(:css, '#wiki_body').find_element(:link, assignment_name).should be_displayed
  end

  it "should add an equation to the rce" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/wiki"

    driver.find_element(:css, '.mce_instructure_equation').click
    wait_for_animations
    equation_dialog = driver.find_element(:id, 'instructure_equation_prompt')
    misc_tab = driver.find_element(:css, '.mathquill-tab-bar > li:last-child a')
    driver.action.move_to(misc_tab).perform
    driver.find_element(:css, '#Misc_tab li:nth-child(35) a').click
    basic_tab = driver.find_element(:css, '.mathquill-tab-bar > li:first-child a')
    driver.action.move_to(basic_tab).perform
    driver.find_element(:css, '#Basic_tab li:nth-child(27) a').click
    driver.find_element(:id, 'instructure_equation_prompt_form').submit
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:css, '#tinymce img').should be_displayed
    end

    driver.find_element(:id, 'wiki_page_submit').click
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki"#can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests

    check_image( driver.find_element(:css, '#wiki_body img') )
  end

  def add_flickr_image(el)
    el.find_element(:css, '.mce_instructure_embed').click
    driver.find_element(:css, '.flickr_search_link').click
    driver.find_element(:css, '#image_search_form > input').send_keys('angel')
    driver.find_element(:id, 'image_search_form').submit
    wait_for_ajax_requests
    keep_trying_until{ driver.find_element(:css, '.image_link').should be_displayed }
    driver.find_element(:css, '.image_link').click
  end

  it "should add image from flickr" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/wiki"

    #add image from flickr to rce
    driver.find_element(:css, '.wiki_switch_views_link').click
    clear_rce
    driver.find_element(:css, '.wiki_switch_views_link').click
    add_flickr_image(driver)
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:css, '#tinymce img').should be_displayed
    end

    driver.find_element(:id, 'wiki_page_submit').click
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki"#can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests

    check_image( driver.find_element(:css, '#wiki_body img') )
  end

  it "should put flickr images into the right editor" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/quizzes"
    driver.find_element(:css, ".new-quiz-link").click
    keep_trying_until { driver.find_element(:css, ".mce_instructure_embed").displayed? }
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

  it "should display record video dialog" do
    stub_kaltura
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/wiki"

    driver.find_element(:css, '.mce_instructure_record').click
    keep_trying_until{ driver.find_element(:id, 'record_media_tab').should be_displayed }
    driver.find_element(:css, '#media_comment_dialog a[href="#upload_media_tab"]').click
    driver.find_element(:css, '#media_comment_dialog #audio_upload').should be_displayed
    find_with_jquery('.ui-icon-closethick:visible').click
    driver.find_element(:id, 'media_comment_dialog').should_not be_displayed
  end

  it "should resize the WYSIWYG editor height gracefully" do
    file_tree_setup
    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    make_full_screen
    resizer = driver.find_element(:class, 'editor_box_resizer')
    # TODO: there's an issue where we can drag the box smaller than it's supposed to be on the first resize.
    # Until we can track that down, first we do a fake drag to make sure the rest of the resizing machinery
    # works.
    driver.action.drag_and_drop_by(resizer, 0, -1).perform
    resizer_to = 1 - resizer.location.y
    # drag the resizer way up to the top of the screen (to make the wysiwyg the shortest it will go)
    driver.action.drag_and_drop_by(resizer, 0, resizer_to).perform
    keep_trying_until { driver.execute_script("return $('#wiki_page_body_ifr').height()").should eql(200) }
    resizer.attribute('style').should be_blank

    # now move it down 30px from 200px high
    resizer = driver.find_element(:class, 'editor_box_resizer')
    keep_trying_until { driver.action.drag_and_drop_by(resizer, 0, 30).perform; true }
    driver.execute_script("return $('#wiki_page_body_ifr').height()").should be_close(230, 5)
    resizer.attribute('style').should be_blank
  end

  it "should handle table borders correctly" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/wiki"

    def check_table(attributes = {})
      # clear out whatever is in the editor
      driver.execute_script("$('#wiki_page_body_ifr')[0].contentDocument.body.innerHTML =''")

      # this is the only way I know to actually trigger the insert table dialog to open
      # listening to the click events on the button in the menu did not work
      driver.execute_script("$('#wiki_page_body').editorBox('execute', 'mceInsertTable')")

      # the iframe will be created with an id of mce_<some number>_ifr
      table_iframe_id = keep_trying_until{ driver.find_elements(:css, 'iframe').map { |f| f['id'] }.detect { |w| w =~ /mce_\d+_ifr/ } }
      table_iframe_id.should_not be_nil
      in_frame(table_iframe_id) do
        attributes.each do |attribute, value|
          tab_to_show = attribute == :bordercolor ? 'advanced' : 'general'
          keep_trying_until do
            driver.execute_script "mcTabs.displayTab('#{tab_to_show}_tab', '#{tab_to_show}_panel')"
            set_value(driver.find_element(:id, attribute), value)
            true
          end
        end
        driver.find_element(:id, 'insert').click
      end
      in_frame "wiki_page_body_ifr" do
        table = driver.find_element(:css, 'table')
        attributes.each do |attribute, value|
          (table[attribute].should == value.to_s) if (value && (attribute != :bordercolor))
        end
        [:width, :color].each do |part|
          [:top, :right, :bottom, :left].each do |side|
            expected_value = attributes[{:width => :border, :color => :bordercolor}[part]] || {:width => 1,  :color => '#888888'}[part]
            if expected_value.is_a?(Numeric)
              expected_value = 1 if expected_value == 0
              expected_value = "#{expected_value}px"
            end
            table.style("border-#{side}-#{part}").should == expected_value
          end
        end
      end
      # TODO: test how it looks after page is saved.
      # driver.find_element(:id, :wiki_page_submit).click

    end

    # check with default settings
    check_table()

    check_table(
      :align => 'center',
      :cellpadding => 5,
      :cellspacing => 6,
      :border => 7,
      :bordercolor => '#ff0000'
    )
    check_table(
      :align => 'center',
      :cellpadding => 0,
      :cellspacing => 0,
      :border => 0
    )
  end

end
