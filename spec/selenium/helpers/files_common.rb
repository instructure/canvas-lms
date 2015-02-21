require File.expand_path(File.dirname(__FILE__) + '/../common')

# This method adds the specified file to the course
# Params:
# - fixture: location of the file to be uploaded
# - context: course in which file would be uploaded
# - name: file name
def add_file(fixture, context, name)
  context.attachments.create! do |attachment|
    attachment.uploaded_data = fixture
    attachment.filename = name
    attachment.folder = Folder.root_folders(context).first
  end
end

# This method downloads the file from top toolbar in New Files
def download_from_toolbar
  ff('.ef-item-row')[0].click
  f('.btn-download').click
end

# This method downloads the file using the Download option on Cog menu button
def download_from_cog
  ff('.al-trigger')[0].click
  ff('.al-options .ui-menu-item')[0].click
end

# This method downloads the file from the file preview
def download_from_preview
  fln("example.pdf").click
  f('.icon-download').click
end

def should_make_folders_in_the_menu_droppable
  course_with_teacher_logged_in
  get "/files"
  wait_for_ajaximations
  keep_trying_until do
    f(".add_folder_link").click
    wait_for_ajaximations
    expect(f("#files_content .add_folder_form #folder_name")).to be_displayed
  end
  f("#files_content .add_folder_form #folder_name").send_keys("my folder\n")
  wait_for_ajaximations
  expect(f(".node.folder span")).to have_class('ui-droppable')

  # also make sure that it has a tooltip of the file name so that you can read really long names
  expect(f(".node.folder .name[title='my folder']")).not_to be_nil
end

def should_show_students_link_to_download_zip_of_folder
  course_with_student_logged_in
  get "/courses/#{@course.id}/files"
  link = keep_trying_until do
    link = f(".links a.download_zip_link")
    wait_for_ajaximations
    expect(link).to be_displayed
    link
  end
  expect(link.attribute('href')).to match(%r"/courses/#{@course.id}/folders/\d+/download")
end

def unzip_from_form_to_folder()
    @folder = folder = Folder.root_folders(@context).first

    def upload_file(refresh)
      get @files_url
      if !refresh
        expect_new_page_load { f('a.upload_zip_link').click }
        expect(URI.parse(driver.current_url).path).to eq @files_import_url
      else
        refresh_page
      end
      filename, path, data, file = get_file('attachments.zip')
      expect(first_selected_option(f('#upload_to select'))).to have_value(@folder.id.to_s)
      f('input#zip_file').send_keys(path)
      submit_form('#zip_file_import_form')
      zfi = keep_trying_until { ZipFileImport.order(:id).last }
      expect(zfi.context).to eq @context
      expect(zfi.folder).to eq @folder
      expect(f('.ui-dialog-title')).to include_text('Uploading, Please Wait.') # verify it's visible
      job = Delayed::Job.order(:id).last
      expect(job.tag).to eq 'ZipFileImport#process_without_send_later'
      run_job(job)
      upload_file(true) if refresh != true && flash_message_present?(:error)
      zfi
    end
    zfi = upload_file(false)
    keep_trying_until { URI.parse(driver.current_url).path == @files_url }
    expect(zfi.reload.state).to eq :imported
    expect(@folder.attachments.active.map(&:display_name)).to eq ["first_entry.txt"]
    expect(@folder.sub_folders.active.count).to eq 1
    sub = folder.sub_folders.active.first
    expect(sub.name).to eq "adir"
    expect(sub.attachments.active.map(&:display_name)).to eq ["second_entry.txt"]
end

def unzip_into_folder_drag_and_drop
    # we can't actually drag a file into the browser from selenium, so we have
    # to mock some of the process
    folder = Folder.root_folders(@context).first
    keep_trying_until { expect(f('#files_content .message.no_content')).to be_nil }
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
    zfi = keep_trying_until { ZipFileImport.order(:id).last }
    expect(zfi.context).to eq @context
    expect(zfi.folder).to eq folder
    expect(f('.ui-dialog-title')).to include_text('Extracting Files into Folder') # verify it's visible
    job = Delayed::Job.order(:id).last
    expect(job.tag).to eq 'ZipFileImport#process_without_send_later'
    run_job(job)
    keep_trying_until { expect(f('#uploading_please_wait_dialog')).to be_nil } # wait until it's no longer visible
    expect(zfi.reload.state).to eq :imported
    expect(folder.attachments.active.map(&:display_name)).to eq ["first_entry.txt"]
    expect(folder.sub_folders.active.count).to eq 1
    sub = folder.sub_folders.active.first
    expect(sub.name).to eq "adir"
    expect(sub.attachments.active.map(&:display_name)).to eq ["second_entry.txt"]
end

def confirm_delete_on_dialog
    driver.switch_to.alert.accept
end

def cancel_delete_on_dialog
    driver.switch_to.alert.dismiss
end

def create_new_folder
  f('.btn-add-folder').click
  f('.ef-edit-name-form').submit
  wait_for_ajaximations
  get_all_folders.first
end

def get_all_folders
  new_folder = driver.find_elements(:class, 'ef-item-row')
end
