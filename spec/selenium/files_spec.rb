require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

def add_folders(name = 'new folder', number_to_add = 1)
  1..number_to_add.times do |number|
    keep_trying_until do
      f(".add_folder_link").click
      wait_for_animations
      f("#files_content .add_folder_form #folder_name").should be_displayed
    end
    new_folder = f("#files_content .add_folder_form #folder_name")
    new_folder.send_keys(name)
    new_folder.send_keys(:return)
    wait_for_ajax_requests
  end
end

def make_folder_actions_visible
  driver.execute_script("$('.folder_item').addClass('folder_item_hover')")
end

shared_examples_for "files selenium tests" do
  it_should_behave_like "forked server selenium tests"
  it_should_behave_like "files selenium shared"

  it "should show students link to download zip of folder" do
    user_with_pseudonym :username => "nobody3@example.com",
                        :password => "asdfasdf3"
    course_with_student_logged_in :user => @user
    login_as "nobody3@example.com", "asdfasdf3"
    get "/courses/#{@course.id}/files"

    link = keep_trying_until do
      link = f(".links a.download_zip_link")
      wait_for_ajaximations
      link.should be_displayed
      link
    end
    link.attribute('href').should match(%r"/courses/#{@course.id}/folders/\d+/download")
  end

  it "should make folders in the menu droppable" do
    course_with_teacher_logged_in
    get "/dashboard/files"
    wait_for_ajaximations

    keep_trying_until do
      f(".add_folder_link").click
      wait_for_animations
      f("#files_content .add_folder_form #folder_name").should be_displayed
    end

    f("#files_content .add_folder_form #folder_name").send_keys("my folder\n")
    wait_for_ajax_requests
    f(".node.folder span").should have_class('ui-droppable')

    # also make sure that it has a tooltip of the file name so that you can read really long names
    f(".node.folder .name[title='my folder']").should_not be_nil
  end
end


describe "files without s3 and forked tests" do
  it_should_behave_like "in-process server selenium tests"
  before (:each) do
    @folder_name = "my folder"
    course_with_teacher_logged_in
    get "/dashboard/files"
    wait_for_ajaximations
    add_folders(@folder_name)
    Folder.last.name.should == @folder_name
    @folder_css = ".folder_#{Folder.last.id}"
    make_folder_actions_visible
  end

  it "should allow renaming folders" do
    edit_folder_name = "my folder 2"
    entry_field = keep_trying_until do
      f("#files_content .folder_item .rename_item_link").click
      entry_field = f("#files_content #rename_entry_field")
      entry_field.should be_displayed
      entry_field
    end
    entry_field.send_keys(edit_folder_name)
    entry_field.send_keys(:return)
    wait_for_ajax_requests
    Folder.last.name.should == edit_folder_name
  end

  it "should allow deleting a folder" do
    f(@folder_css + ' .delete_item_link').click
    driver.switch_to.alert.accept
    wait_for_ajaximations
    Folder.last.workflow_state.should == 'deleted'
    f('#files_content').should_not include_text(@folder_name)
  end

  it "should allow locking a folder" do
    f(@folder_css + ' .lock_item_link').click
    lock_form = f('#lock_folder_form')
    lock_form.should be_displayed
    submit_form(lock_form)
    wait_for_ajaximations
    f(@folder_css + ' .header img').should have_attribute('alt', 'Locked Folder')
    Folder.last.locked.should be_true
  end

end

describe "files local tests" do
  it_should_behave_like "files selenium tests"

  prepend_before(:each) do
    Setting.set("file_storage_test_override", "local")
  end


  context "as a teacher" do

    before (:each) do
      user_with_pseudonym :username => "nobody2@example.com",
                          :password => "asdfasdf2"
      course_with_teacher_logged_in :user => @user
      login "nobody2@example.com", "asdfasdf2"
      add_file(fixture_file_upload('files/html-editing-test.html', 'text/html'),
               @course, "html-editing-test.html")
      get "/courses/#{@course.id}/files"
      keep_trying_until { fj('.file').should be_displayed }
      make_folder_actions_visible
    end

    context 'tinyMCE html editing' do

      def click_edit_link(page_refresh = true)
        get "/courses/#{@course.id}/files" if page_refresh
        link = keep_trying_until { f("li.editable_folder_item div.header a.edit_item_content_link") }
        link.should be_displayed
        link.text.should == "edit content"
        link.click
        keep_trying_until { fj("#edit_content_dialog").should be_displayed }
      end

      def switch_html_edit_views
        f('.switch_views').click
      end

      def save_html_content
        f(".ui-dialog .btn-primary").click
      end

      before (:each) do
        link = keep_trying_until { f("li.editable_folder_item div.header a.download_url") }
        link.should be_displayed
        link.text.should == "html-editing-test.html"
      end

      it "should allow you to edit html files" do
        current_content = File.read(fixture_file_path("files/html-editing-test.html"))
        4.times do
          new_content = "<html>#{ActiveSupport::SecureRandom.hex(10)}</html>"
          click_edit_link
          keep_trying_until(120) { driver.execute_script("return $('#edit_content_textarea')[0].value;") == current_content }
          driver.execute_script("$('#edit_content_textarea')[0].value = '#{new_content}';")
          current_content = new_content
          f(".ui-dialog .btn-primary").click
          f("#edit_content_dialog").should_not be_displayed
        end
      end

      it "should validate adding a bold line changes the html" do
        click_edit_link
        f('.switch_views').click
        f('.mce_bold').click
        type_in_tiny('#edit_content_textarea', 'this is bold')
        f('.switch_views').click
        driver.execute_script("return $('#edit_content_textarea')[0].value;").should =~ /<strong>this is bold<\/strong>/
        driver.execute_script("return $('#edit_content_textarea')[0].value = '<fake>lol</fake>';")
        f('.switch_views').click
        f('.switch_views').click
        driver.execute_script("return $('#edit_content_textarea')[0].value;").should =~ /<fake>lol<\/fake>/
      end

      it "should save changes from HTML view" do
        click_edit_link
        switch_html_edit_views
        type_in_tiny('#edit_content_textarea', 'I am typing')
        save_html_content
        wait_for_ajax_requests
        click_edit_link
        keep_trying_until { f('#edit_content_textarea')[:value].should =~ /I am typing/ }
      end

      it "should save changes from code view" do
        pending("intermittently fails")
        click_edit_link
        driver.execute_script("$('#edit_content_textarea')[0].value = 'I am typing';")
        save_html_content
        wait_for_ajax_requests
        click_edit_link
        keep_trying_until { f('#edit_content_textarea')[:value].should =~ /I am typing/ }
      end

      it "should allow you to open and close the dialog and switch views" do
        click_edit_link
        keep_trying_until { driver.execute_script("return $('#edit_content_textarea').is(':visible');").should == true }
        switch_html_edit_views
        driver.execute_script("return $('#edit_content_textarea').is(':hidden');").should == true
        close_visible_dialog
        click_edit_link(false)
        keep_trying_until { driver.execute_script("return $('#edit_content_textarea').is(':visible');").should == true }
        switch_html_edit_views
        driver.execute_script("return $('#edit_content_textarea').is(':hidden');").should == true
      end
    end

    it "should allow you to edit a file name" do
      edit_name = 'edited html file'
      fj('.file .rename_item_link:visible').click
      file_name = f('#rename_entry_field')
      replace_content(file_name, edit_name)
      file_name.send_keys(:return)
      wait_for_ajax_requests
      last_file = Folder.last.attachments.last
      f('#files_content').should include_text(last_file.display_name)
    end

    it "should allow you to delete a file" do
      fj('.file .delete_item_link:visible').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      last_file = Folder.last.attachments.last
      last_file.file_state == 'deleted'
      f('#files_content').should_not include_text(last_file.display_name)
    end

    it "should allow you to lock a file" do
      fj('.file .lock_item_link:visible').click
      lock_form = f('#lock_attachment_form')
      lock_form.should be_displayed
      submit_form(lock_form)
      wait_for_ajaximations
      fj('.file .item_icon:visible').should have_attribute('alt', 'Locked File')
      Folder.last.attachments.last.locked.should be_true
    end

  end


  describe "files S3 tests" do
    it_should_behave_like "files selenium tests"
    prepend_before(:each) { Setting.set("file_storage_test_override", "s3") }
    prepend_before(:all) { Setting.set("file_storage_test_override", "s3") }
  end

  describe "collaborations folder in files menu" do
    it_should_behave_like "in-process server selenium tests"

    before (:each) do
      user_with_pseudonym(:active_user => true)
      course_with_teacher(:user => @user, :active_course => true, :active_enrollment => true)
      group_category = @course.group_categories.create(:name => "groupage")
      @group = group_category.groups.create!(:name => "group1", :context => @course)
    end

    def load_collab_folder
      get "/groups/#{@group.id}/files"
      message_node = keep_trying_until do
        f("li.collaborations span.name").click
        f("ul.files_content li.message")
      end
      message_node.text
    end

    it "should show 'add collaboration' paragraph to teacher of a course group" do
      create_session(@pseudonym, false)
      message = load_collab_folder
      message.should include_text("New collaboration")
    end

    it "should show 'add collaboration' paragraph to participating user" do
      user_with_pseudonym(:active_user => true)
      student_in_course(:user => @user, :active_enrollment => true)
      create_session(@pseudonym, false)
      @group.add_user(@user, 'accepted')
      message = load_collab_folder
      message.should include_text("New collaboration")
    end
  end
end

describe "zip file uploads" do
  it_should_behave_like "in-process server selenium tests"

  shared_examples_for "zip file uploads" do
    it "should allow unzipping into a folder from the form" do
      @folder = folder = Folder.root_folders(@context).first

      def upload_file(refresh)
        get @files_url

        if !refresh
          expect_new_page_load { f('a.upload_zip_link').click }

          URI.parse(driver.current_url).path.should == @files_import_url
        else
          refresh_page
        end
        filename, path, data, file = get_file('attachments.zip')
        first_selected_option(f('#upload_to select')).should have_value(@folder.id.to_s)
        f('input#zip_file').send_keys(path)
        submit_form('#zip_file_import_form')

        zfi = keep_trying_until { ZipFileImport.last(:order => :id) }
        zfi.context.should == @context
        zfi.folder.should == @folder

        f('.ui-dialog-title').should include_text('Uploading, Please Wait.') # verify it's visible

        job = Delayed::Job.last(:order => :id)
        job.tag.should == 'ZipFileImport#process_without_send_later'
        run_job(job)
        upload_file(true) if refresh != true && f("#flash_message_holder .ui-state-error").present?
        zfi
      end

      zfi = upload_file(false)

      keep_trying_until { URI.parse(driver.current_url).path == @files_url }

      zfi.reload.state.should == :imported

      @folder.attachments.active.map(&:display_name).should == ["first_entry.txt"]
      @folder.sub_folders.active.count.should == 1
      sub = folder.sub_folders.active.first
      sub.name.should == "adir"
      sub.attachments.active.map(&:display_name).should == ["second_entry.txt"]
    end

    it "should allow unzipping into a folder from drag-and-drop" do
      # we can't actually drag a file into the browser from selenium, so we have
      # to mock some of the process
      get @files_url

      next unless driver.execute_script("return $.handlesHTML5Files;") == true

      folder = Folder.root_folders(@context).first
      keep_trying_until { f('#files_content .message.no_content').should be_nil }

      filename, path, data, file = get_file('attachments.zip')

      # the drop event that we're mocking requires an actual JS File object,
      # which can't be created through javascript. so we add a file input field
      # to the page so we can enter the file path, and then pull the data from
      # that.
      driver.execute_script(%{$("<input/>").attr({type:'file',id:'mock-file-data'}).appendTo('body');})
      f('#mock-file-data').send_keys(path)

      driver.execute_script(%{$("#files_content").trigger($.Event("drop", { originalEvent: { dataTransfer: { files: $('#mock-file-data')[0].files } } }));})
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajax_requests

      zfi = keep_trying_until { ZipFileImport.last(:order => :id) }
      zfi.context.should == @context
      zfi.folder.should == folder

      f('.ui-dialog-title').should include_text('Extracting Files into Folder') # verify it's visible

      job = Delayed::Job.last(:order => :id)
      job.tag.should == 'ZipFileImport#process_without_send_later'
      run_job(job)

      keep_trying_until { f('#uploading_please_wait_dialog').should be_nil } # wait until it's no longer visible

      zfi.reload.state.should == :imported

      folder.attachments.active.map(&:display_name).should == ["first_entry.txt"]
      folder.sub_folders.active.count.should == 1
      sub = folder.sub_folders.active.first
      sub.name.should == "adir"
      sub.attachments.active.map(&:display_name).should == ["second_entry.txt"]
    end
  end

  context "courses" do
    it_should_behave_like "zip file uploads"
    before do
      course_with_teacher_logged_in
      @files_url = "/courses/#{@course.id}/files"
      @files_import_url = "/courses/#{@course.id}/imports/files"
      @context = @course
    end
  end

  context "groups" do
    it_should_behave_like "zip file uploads"
    before do
      group_with_user_logged_in(:group_context => course)
      @files_url = "/groups/#{@group.id}/files"
      @files_import_url = "/groups/#{@group.id}/imports/files"
      @context = @group
    end
  end

  context "profile" do
    it_should_behave_like "zip file uploads"
    before do
      course_with_student_logged_in
      @files_url = "/dashboard/files"
      @files_import_url = "/users/#{@user.id}/imports/files"
      @context = @user
    end
  end
end

describe "common file behaviors" do
  it_should_behave_like "forked server selenium tests"

  before(:each) do
    course_with_teacher_logged_in
    get "/dashboard/files"
  end

  context "when creating new folders" do
    let(:folder_a_name) { "a_folder" }
    let(:folder_b_name) { "b_folder" }
    let(:folder_c_name) { "c_folder" }

    before(:each) do
      add_folders(folder_b_name)
      add_folders(folder_a_name)
      add_folders(folder_c_name)
    end

    it "orders file structure folders alphabetically" do
      folder_elements = ff('#files_structure_list > .context > ul > .node.folder > .name')

      folder_elements[0].text.should == folder_a_name
      folder_elements[1].text.should == folder_b_name
      folder_elements[2].text.should == folder_c_name
    end

    it "orders file content folders alphabetically" do
      folder_elements = ff('#files_content > .folder_item.folder > .header > .name')

      folder_elements[0].text.should == folder_a_name
      folder_elements[1].text.should == folder_b_name
      folder_elements[2].text.should == folder_c_name
    end
  end

  context "when creating new files" do

    def add_file(file_fullpath)
      attachment_field = keep_trying_until do
        fj('#add_file_link').click # fj to avoid selenium caching
        attachment_field = fj('#attachment_uploaded_data')
        attachment_field.should be_displayed
        attachment_field
      end
      attachment_field.send_keys(file_fullpath)
      f('.add_file_form').submit
      wait_for_ajaximations
      wait_for_js
    end

    def get_file_elements
      file_elements = keep_trying_until do
        file_elements = ffj('#files_structure_list > .context > ul > .file > .name')
        file_elements.count.should == 3
        file_elements
      end
      file_elements
    end

    before(:each) do
      @a_filename, a_fullpath, a_data = get_file("a_file.txt")
      @b_filename, b_fullpath, b_data = get_file("b_file.txt")
      @c_filename, c_fullpath, c_data = get_file("c_file.txt")

      add_file(c_fullpath)
      add_file(a_fullpath)
      add_file(b_fullpath)
    end

    it "orders file structure files alphabetically" do
      file_elements = get_file_elements

      file_elements[0].text.should == @a_filename
      file_elements[1].text.should == @b_filename
      file_elements[2].text.should == @c_filename
    end

    it "orders file content files alphabetically" do
      file_elements = get_file_elements

      file_elements[0].text.should == @a_filename
      file_elements[1].text.should == @b_filename
      file_elements[2].text.should == @c_filename
    end
  end
end
