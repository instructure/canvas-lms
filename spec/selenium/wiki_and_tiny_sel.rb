require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Wiki pages and Tiny WYSIWYG editor" do
  # it_should_behave_like "forked server selenium tests"
  it_should_behave_like "in-process server selenium tests"

  before(:each) do
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
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click

    root_folders = @tree1.find_elements(:css, 'li.folder')
    root_folders.length.should == 1
    root_folders.first.find_element(:css, '.name').text.should == 'course files'

    root_folders.first.find_element(:css, '.sign.plus').click

    keep_trying_until { root_folders.first.find_elements(:css, 'li.folder').length }
    sub_folders = root_folders.first.find_elements(:css, 'li.folder')
    sub_folders.length.should == 1
    sub_folders.first.find_element(:css, '.name').text.should == 'subfolder'

    text_file = root_folders.first.find_elements(:css, 'li.file.text')
    text_file.length.should == 1
    text_file.first.find_element(:css, '.name').text.should == 'text_file.txt'

    sub_folders.first.find_element(:css, '.sign.plus').click

    keep_trying_until { sub_folders.first.find_elements(:css, 'li.folder').length }
    sub_sub_folders = sub_folders.first.find_elements(:css, 'li.folder')
    sub_sub_folders.length.should == 1
    sub_sub_folders.first.find_element(:css, '.name').text.should == 'subsubfolder'

  end

  it "should lazy load images" do
    @image_list.attribute('class').should_not match(/initialized/)
    @image_list.find_elements(:css, 'img.img').length.should == 0

    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
    keep_trying_until { @image_list.find_elements(:css, 'img.img').length }.should == 2
  end

  it "should properly clone images, including thumbnails, and display" do
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
    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
    driver.find_element(:css, '.upload_new_file_link').click
    driver.find_element(:css, '.wiki_switch_views_link').click
    wiki_page_body = driver.find_element(:id, :wiki_page_body)
    wiki_page_body.clear
    wiki_page_body[:value].should be_empty

    upload_file('#sidebar_upload_file_form', :text)

    wiki_page_body[:value].should match(/a class="instructure_file_link/)
  end

  it "should show uploaded files in file tree" do
    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
    driver.find_element(:css, '.upload_new_file_link').click
    driver.find_element(:css, '.wiki_switch_views_link').click
    wiki_page_body = driver.find_element(:id, :wiki_page_body)
    wiki_page_body.clear
    wiki_page_body[:value].should be_empty

    root_folders = @tree1.find_elements(:css, 'li.folder')
    root_folders.first.find_element(:css, '.sign.plus').click
    root_folders.first.find_elements(:css, '.file.text').length.should == 1

    upload_file('#sidebar_upload_file_form', :text)

    root_folders.first.find_elements(:css, '.file.text').length.should == 2
    wiki_page_body[:value].should match(/a class="instructure_file_link/)
  end

  it "should not show uploaded files in image list" do
    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
    driver.find_element(:css, '.upload_new_image_link').click
    driver.find_element(:css, '.wiki_switch_views_link').click
    wiki_page_body = driver.find_element(:id, :wiki_page_body)
    wiki_page_body.clear
    wiki_page_body[:value].should be_empty

    @image_list.find_elements(:css, 'img.img').length.should == 2

    upload_file('#sidebar_upload_image_form', :text)

    @image_list.find_elements(:css, 'img.img').length.should == 2
    wiki_page_body[:value].should be_empty
  end

  it "should show uploaded images in image list" do
    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
    driver.find_element(:css, '.upload_new_image_link').click
    driver.find_element(:css, '.wiki_switch_views_link').click
    wiki_page_body = driver.find_element(:id, :wiki_page_body)
    wiki_page_body.clear
    wiki_page_body[:value].should be_empty

    @image_list.find_elements(:css, 'img.img').length.should == 2

    upload_file('#sidebar_upload_image_form', :image)

    @image_list.find_elements(:css, 'img.img').length.should == 3
    wiki_page_body[:value].should match(/img/)
  end

  it "should show files uploaded on the images tab in the file tree" do
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
    root_folders = @tree1.find_elements(:css, 'li.folder')
    root_folders.first.find_element(:css, '.sign.plus').click
    root_folders.first.find_elements(:css, '.file.text').length.should == 1

    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
    driver.find_element(:css, '.upload_new_image_link').click
    driver.find_element(:css, '.wiki_switch_views_link').click
    wiki_page_body = driver.find_element(:id, :wiki_page_body)
    wiki_page_body.clear
    wiki_page_body[:value].should be_empty

    @image_list.find_elements(:css, 'img.img').length.should == 2

    upload_file('#sidebar_upload_image_form', :text)

    root_folders.first.find_elements(:css, '.file.text').length.should == 2
    @image_list.find_elements(:css, 'img.img').length.should == 2
    wiki_page_body[:value].should be_empty
  end

  it "should show images uploaded on the files tab in the image list" do
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
    root_folders = @tree1.find_elements(:css, 'li.folder')
    root_folders.first.find_element(:css, '.sign.plus').click
    root_folders.first.find_elements(:css, '.file.image').length.should == 2

    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    driver.find_element(:css, '.upload_new_file_link').click
    driver.find_element(:css, '.wiki_switch_views_link').click
    wiki_page_body = driver.find_element(:id, :wiki_page_body)
    wiki_page_body.clear
    wiki_page_body[:value].should be_empty

    @image_list.find_elements(:css, 'img.img').length.should == 2

    upload_file('#sidebar_upload_file_form', :image)

    root_folders.first.find_elements(:css, '.file.image').length.should == 3
    @image_list.find_elements(:css, 'img.img').length.should == 3
    wiki_page_body[:value].should match(/a class="instructure_file_link/)
  end

  it "should resize the WYSIWYG editor height gracefully" do
    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    make_full_screen
    resizer = driver.find_element(:class, 'editor_box_resizer')
    # TODO: there's an issue where we can drag the box smaller than it's supposed to be on the first resize.
    # Until we can track that down, first we do a fake drag to make sure the rest of the resizing machinery
    # works.
    driver.action.drag_and_drop_by(resizer, 0, -1).perform
    # drag the resizer way up to the top of the screen (to make the wysiwyg the shortest it will go)
    driver.action.drag_and_drop_by(resizer, 0, -1500).perform
    keep_trying_until { driver.execute_script("return $('#wiki_page_body_ifr').height()").should eql(200) }
    resizer.attribute('style').should be_blank

    # now move it down 30px from 200px high
    resizer = driver.find_element(:class, 'editor_box_resizer')
    keep_trying_until { driver.action.drag_and_drop_by(resizer, 0, 30).perform; true }
    driver.execute_script("return $('#wiki_page_body_ifr').height()").should eql(230)
    resizer.attribute('style').should be_blank
  end
  
end

