require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

describe "shared files tests" do
  include_examples "in-process server selenium tests"

  def fixture_file_path(file)
    path = ActionController::TestCase.respond_to?(:fixture_path) ? ActionController::TestCase.send(:fixture_path) : nil
    return "#{path}#{file}"
  end

  def add_file(fixture, context, name)
    context.attachments.create! do |attachment|
      attachment.uploaded_data = fixture
      attachment.filename = name
      attachment.folder = Folder.root_folders(context).first
    end
  end

  def make_folder_actions_visible
    driver.execute_script("$('.folder_item').addClass('folder_item_hover')")
  end

  before do
    local_storage!
  end

  it "should make folders in the menu droppable local" do
    should_make_folders_in_the_menu_droppable
  end

  it "should show students link to download zip of folder local" do
    should_show_students_link_to_download_zip_of_folder
  end

  context "as a teacher" do

    before (:each) do
      local_storage!
      user_with_pseudonym :username => "nobody2@example.com",
                          :password => "asdfasdf2"
      course_with_teacher_logged_in :user => @user
      create_session(@pseudonym, false)
      add_file(fixture_file_upload('files/html-editing-test.html', 'text/html'),
               @course, "html-editing-test.html")
      get "/courses/#{@course.id}/files"
      keep_trying_until { expect(fj('.file')).to be_displayed }
      make_folder_actions_visible
    end

    it "should allow you to edit a file name" do
      edit_name = 'edited html file'
      fj('.file .rename_item_link:visible').click
      file_name = f('#rename_entry_field')
      wait_for_ajaximations
      replace_content(file_name, edit_name)
      wait_for_ajaximations
      file_name.send_keys(:return)
      wait_for_ajaximations
      last_file = Folder.last.attachments.last
      expect(f('#files_content')).to include_text(last_file.display_name)
    end

    it "should allow you to delete a file" do
      fj('.file .delete_item_link:visible').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      last_file = Folder.last.attachments.last
      last_file.file_state == 'deleted'
      expect(f('#files_content')).not_to include_text(last_file.display_name)
    end

    it "should allow you to lock a file" do
      fj('.file .lock_item_link:visible').click
      lock_form = f('#lock_attachment_form')
      expect(lock_form).to be_displayed
      wait_for_ajaximations
      submit_form(lock_form)
      wait_for_ajaximations
      expect(fj('.file .item_icon:visible')).to have_attribute('alt', 'Locked File')
      expect(Folder.last.attachments.last.locked).to be_truthy
    end

    context 'tinyMCE html editing' do

      before (:each) do
        link = keep_trying_until { f("li.editable_folder_item div.header a.download_url") }
        expect(link).to be_displayed
        expect(link.text).to eq "html-editing-test.html"
      end

      def click_edit_link(page_refresh = true)
        get "/courses/#{@course.id}/files" if page_refresh
        link = keep_trying_until { f("li.editable_folder_item div.header a.edit_item_content_link") }
        expect(link).to be_displayed
        expect(link.text).to eq "edit content"
        link.click
        wait_for_ajaximations
        keep_trying_until { expect(fj("#edit_content_dialog")).to be_displayed }
      end

      def switch_html_edit_views
        fj('.switch_views:visible').click
      end

      def save_html_content
        f(".ui-dialog .btn-primary").click
      end

      it "should allow you to edit html files" do
        current_content = File.read(fixture_file_path("files/html-editing-test.html"))
        4.times do
          new_content = "<html>#{SecureRandom.hex(10)}</html>"
          click_edit_link
          keep_trying_until(120) { driver.execute_script("return $('#edit_content_textarea')[0].value;") == current_content }
          driver.execute_script("$('#edit_content_textarea')[0].value = '#{new_content}';")
          current_content = new_content
          f(".ui-dialog .btn-primary").click
          expect(f("#edit_content_dialog")).not_to be_displayed
        end
      end

      it "should validate adding a bold line changes the html" do
        click_edit_link
        wait_for_ajaximations
        switch_html_edit_views
        f('.mce-i-bold').click
        type_in_tiny('#edit_content_textarea', 'this is bold')
        fj('.switch_views:visible').click
        expect(driver.execute_script("return $('#edit_content_textarea')[0].value;")).to match /<strong>this is bold<\/strong>/
        driver.execute_script("return $('#edit_content_textarea')[0].value = '<fake>lol</fake>';")
        fj('.switch_views:visible').click
        fj('.switch_views:visible').click
        expect(driver.execute_script("return $('#edit_content_textarea')[0].value;")).to match /<fake>lol<\/fake>/
      end

      it "should save changes from HTML view" do
        click_edit_link
        wait_for_ajaximations
        switch_html_edit_views
        type_in_tiny('#edit_content_textarea', 'I am typing')
        save_html_content
        wait_for_ajaximations
        click_edit_link
        keep_trying_until { expect(f('#edit_content_textarea')[:value]).to match /I am typing/ }
      end

      it "should save changes from code view" do
        click_edit_link
        wait_for_ajaximations
        driver.execute_script("$('#edit_content_textarea')[0].value = 'I am typing';")
        wait_for_ajaximations
        save_html_content
        wait_for_ajaximations
        click_edit_link
        wait_for_ajaximations
        keep_trying_until { expect(f('#edit_content_textarea')[:value]).to match /I am typing/ }
      end

      it "should allow you to open and close the dialog and switch views" do
        click_edit_link
        keep_trying_until { expect(driver.execute_script("return $('#edit_content_textarea').is(':visible');")).to eq true }
        switch_html_edit_views
        expect(driver.execute_script("return $('#edit_content_textarea').is(':hidden');")).to eq true
        close_visible_dialog
        click_edit_link(false)
        keep_trying_until { expect(driver.execute_script("return $('#edit_content_textarea').is(':visible');")).to eq true }
        switch_html_edit_views
        expect(driver.execute_script("return $('#edit_content_textarea').is(':hidden');")).to eq true
      end
    end
  end

  describe "files S3 tests" do
    before do
      s3_storage!
    end

    it "should make folders in the menu droppable s3" do
      should_make_folders_in_the_menu_droppable
    end

    it "should show students link to download zip of folder s3" do
      should_show_students_link_to_download_zip_of_folder
    end
  end
end


describe "zip file uploads" do
  include_examples "in-process server selenium tests"

  context "courses" do
    before do
      course_with_teacher_logged_in
      @files_url = "/courses/#{@course.id}/files"
      @files_import_url = "/courses/#{@course.id}/imports/files"
      @context = @course
    end

    it "should allow unzipping into a folder from the form courses" do
      unzip_from_form_to_folder
    end

    it "should allow unzipping into a folder from drag-and-drop courses" do
      skip("drag and drop issues")
      get @files_url
      next unless driver.execute_script("return $.handlesHTML5Files;") == true
      unzip_into_folder_drag_and_drop
    end
  end


  context "groups" do
    before do
      group_with_user_logged_in(:group_context => course)
      @files_url = "/groups/#{@group.id}/files"
      @files_import_url = "/groups/#{@group.id}/imports/files"
      @context = @group
    end

    it "should allow unzipping into a folder from the form groups" do
      unzip_from_form_to_folder
    end

    it "should allow unzipping into a folder from drag-and-drop groups" do
      get @files_url
      next unless driver.execute_script("return $.handlesHTML5Files;") == true
      unzip_into_folder_drag_and_drop
    end
  end

  context "user" do
    before do
      course_with_student_logged_in
      @files_url = "/files"
      @files_import_url = "/users/#{@user.id}/imports/files"
      @context = @user
    end

    it "should allow unzipping into a folder from the form profile" do
      unzip_from_form_to_folder
    end

    it "should allow unzipping into a folder from drag-and-drop profile" do
      get @files_url
      next unless driver.execute_script("return $.handlesHTML5Files;") == true
      unzip_into_folder_drag_and_drop
    end
  end
end
