require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

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
      link = f("div.links a.download_zip_link")
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

  def add_folders(name = 'new folder', number_to_add = 1)
    1..number_to_add.times do |number|
      keep_trying_until do
        f(".add_folder_link").click
        wait_for_animations
        f("#files_content .add_folder_form #folder_name").should be_displayed
      end
      new_folder = f("#files_content .add_folder_form #folder_name")
      new_folder.send_keys(name + "#{number}")
      new_folder.send_keys(:return)
      wait_for_ajax_requests
    end
  end

  before (:each) do
    @folder_name = "my folder"
    course_with_teacher_logged_in
    get "/dashboard/files"
    wait_for_ajaximations
    add_folders(@folder_name)
    Folder.last.name.should == @folder_name + '0'
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

  it "should allow dragging folders to re-arrange them" do
    pending('drag and drop not working')
    expected_folder_text = 'my folder'
    add_folders('new folder', 2)
    fj('.folder_item:visible:first').text.should == expected_folder_text
    make_folder_actions_visible
    driver.action.drag_and_drop(move_icons[0], move_icons[1]).perform
    wait_for_ajaximations
    fj('.folder_item:visible:last').text.should == expected_folder_text
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

    it "should allow you to edit html files" do
      link = keep_trying_until { f("li.editable_folder_item div.header a.download_url") }
      link.should be_displayed
      link.text.should == "html-editing-test.html"
      current_content = File.read(fixture_file_path("files/html-editing-test.html"))
      4.times do
        get "/courses/#{@course.id}/files"
        new_content = "<html>#{ActiveSupport::SecureRandom.hex(10)}</html>"
        link = keep_trying_until { f("li.editable_folder_item div.header a.edit_item_content_link") }
        link.should be_displayed
        link.text.should == "edit content"
        link.click
        keep_trying_until { fj("#edit_content_dialog").should be_displayed }
        keep_trying_until(120) { driver.execute_script("return $('#edit_content_textarea')[0].value;") == current_content }
        driver.execute_script("$('#edit_content_textarea')[0].value = '#{new_content}';")
        current_content = new_content
        f("#edit_content_dialog button.save_button").click
        keep_trying_until { !f("#edit_content_dialog").displayed? }
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
    prepend_before(:each) {
      Setting.set("file_storage_test_override", "s3")
    }
    prepend_before(:all) {
      Setting.set("file_storage_test_override", "s3")
    }
  end

  describe "collaborations folder in files menu" do
    it_should_behave_like "in-process server selenium tests"

    before (:each) do
      course_with_teacher_logged_in
      group_category = @course.group_categories.create(:name => "groupage")
      @group = Group.create!(:name => "group1", :group_category => group_category, :context => @course)
    end

    def load_collab_folder
      get "/groups/#{@group.id}/files"
      message_node = keep_trying_until do
        f("li.collaborations span.name").click
        f("ul.files_content li.message")
      end
      message_node.text
    end

    it "should not show 'add collaboration' paragraph to teacher not participating in group" do
      message = load_collab_folder
      message.should_not include_text("New collaboration")
    end

    it "should show 'add collaboration' paragraph to participating user" do
      @group.participating_users << @user
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
