require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor Files" do
  include_examples "in-process server selenium tests"

  def add_file_to_rce
    wiki_page_tools_file_tree_setup
    wait_for_tiny(keep_trying_until { f("#new_wiki_page") })
    fj('.wiki_switch_views_link:visible').click
    wiki_page_body = clear_wiki_rce
    fj('.wiki_switch_views_link:visible').click
    f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
    root_folders = @tree1.find_elements(:css, 'li.folder')
    root_folders.first.find_element(:css, '.sign.plus').click
    wait_for_ajaximations
    root_folders.first.find_elements(:css, '.file.text').length.should == 1
    root_folders.first.find_elements(:css, '.file.text span').first.click

    in_frame "wiki_page_body_ifr" do
      f('#tinymce').should include_text('txt')
    end
    fj('.wiki_switch_views_link:visible').click
    find_css_in_string(wiki_page_body[:value], '.instructure_file_link').should_not be_empty
    submit_form('#new_wiki_page')
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests
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
      fj('a[title="text_file.txt"]').should be_displayed
      #check_file would be good to do here but the src on the file in the wiki body is messed up
    end
  end

  context "wiki sidebar files and locking/hiding" do
    before (:each) do
      course_with_teacher(:active_all => true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      user_session(@student)
      @root_folder = Folder.root_folders(@course).first
      @sub_folder = @root_folder.sub_folders.create!(:name => "visible subfolder", :context => @course)
    end

    it "should not show root folder in the sidebar if it is locked" do
      @root_folder.locked = true
      @root_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      ff('li.folder').count.should == 0
    end

    it "should not show root folder in the sidebar if it is hidden" do
      @root_folder.workflow_state = 'hidden'
      @root_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      ff('li.folder').count.should == 0
    end

    it "should not show root folder in the sidebar if the files navigation tab is hidden" do
      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      ff('li.folder').count.should == 0
    end

    it "should not show sub-folder in the sidebar if it is locked" do
      @root_folder.sub_folders.create!(:name => "subfolder", :context => @course, :locked => true)

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      f('li.folder').should_not be_nil
      f('li.folder span').click
      wait_for_ajaximations
      ff('li.folder li.folder').count.should == 1
      f('li.folder li.folder .name').text.should include_text("visible subfolder")
    end

    it "should not show sub-folder in the sidebar if it is hidden" do
      @root_folder.sub_folders.create!(:name => "subfolder", :context => @course, :workflow_state => 'hidden')

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      f('li.folder').should_not be_nil
      f('li.folder span').click
      wait_for_ajaximations
      ff('li.folder li.folder').count.should == 1
      f('li.folder li.folder .name').text.should include_text("visible subfolder")
    end

    it "should not show file in the sidebar if it is hidden" do
      visible_attachment = attachment_model(:uploaded_data => stub_file_data('foo.txt', nil, 'text/html'), :content_type => 'text/html')
      attachment = attachment_model(:uploaded_data => stub_file_data('foo2.txt', nil, 'text/html'), :content_type => 'text/html')

      attachment.file_state = 'hidden'
      attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      f('li.folder span').click
      wait_for_ajaximations
      ff('li.folder li.file').count.should == 1
      f('li.folder li.file .name').text.should include_text("foo.txt")
    end

    it "should not show file in the sidebar if it is locked" do
      visible_attachment = attachment_model(:uploaded_data => stub_file_data('foo.txt', nil, 'text/html'), :content_type => 'text/html')
      attachment = attachment_model(:uploaded_data => stub_file_data('foo2.txt', nil, 'text/html'), :content_type => 'text/html')

      attachment.locked = true
      attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
      keep_trying_until do
        f('li.folder span').click
        wait_for_ajaximations
        ff('li.folder li.file').count.should == 1
      end
      f('li.folder li.file .name').text.should include_text("foo.txt")
    end
  end

  context "wiki sidebar images and locking/hiding" do
    before (:each) do
      course_with_teacher(:active_all => true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      user_session(@student)
      @root_folder = Folder.root_folders(@course).first
      @sub_folder = @root_folder.sub_folders.create!(:name => "subfolder", :context => @course)

      @visible_attachment = @course.attachments.build(:filename => 'foo.png', :folder => @root_folder)
      @visible_attachment.content_type = 'image/png'
      @visible_attachment.save!

      @attachment = @course.attachments.build(:filename => 'foo2.png', :folder => @sub_folder)
      @attachment.content_type = 'image/png'
      @attachment.save!
    end

    it "should not show image files if their containing folder is locked" do
      @sub_folder.locked = true
      @sub_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      ff('.image_list img.img').count.should == 1
      f('.image_list img.img')['alt'].should == "foo.png"
    end

    it "should not show image files if their containing folder is hidden" do
      @sub_folder.workflow_state = 'hidden'
      @sub_folder.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      ff('.image_list img.img').count.should == 1
      f('.image_list img.img')['alt'].should == "foo.png"
    end

    it "should not show any image files if the files navigation tab is hidden" do

      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      ff('.image_list img.img').count.should == 0
    end

    it "should not show image files if they are hidden" do
      @attachment.file_state = 'hidden'
      @attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      ff('.image_list img.img').count.should == 1
      f('.image_list img.img')['alt'].should == "foo.png"
    end

    it "should not show image files if they are locked" do
      @attachment.locked = true
      @attachment.save!

      get "/courses/#{@course.id}/discussion_topics/new"
      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      ff('.image_list img.img').count.should == 1
      f('.image_list img.img')['alt'].should == "foo.png"
    end
  end
end
