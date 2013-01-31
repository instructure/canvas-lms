shared_examples_for "files selenium tests" do
  it_should_behave_like "forked server selenium tests"
  it_should_behave_like "files selenium shared"

  it "should make folders in the menu droppable" do
    course_with_teacher_logged_in
    get "/dashboard/files"
    wait_for_ajaximations

    keep_trying_until do
      f(".add_folder_link").click
      wait_for_ajaximations
      f("#files_content .add_folder_form #folder_name").should be_displayed
    end

    f("#files_content .add_folder_form #folder_name").send_keys("my folder\n")
    wait_for_ajaximations
    f(".node.folder span").should have_class('ui-droppable')

    # also make sure that it has a tooltip of the file name so that you can read really long names
    f(".node.folder .name[title='my folder']").should_not be_nil
  end

  it "should show students link to download zip of folder" do
    course_with_student_logged_in
    get "/courses/#{@course.id}/files"

    link = keep_trying_until do
      link = f(".links a.download_zip_link")
      wait_for_ajaximations
      link.should be_displayed
      link
    end
    link.attribute('href').should match(%r"/courses/#{@course.id}/folders/\d+/download")
  end
end

shared_examples_for "zip file uploads" do
  it_should_behave_like "in-process server selenium tests"

  it "should allow unzipping into a folder from the form" do
    pending('intermittently failing, take this out when shared examples refactor happens')
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
