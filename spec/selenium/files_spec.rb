require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')
#require File.expand_path(File.dirname(__FILE__) + '/helpers/files_specs')


def add_folders(name = 'new folder', number_to_add = 1)
  1..number_to_add.times do |number|
    keep_trying_until do
      f(".add_folder_link").click
      wait_for_ajaximations
      f("#files_content .add_folder_form #folder_name").should be_displayed
    end
    new_folder = f("#files_content .add_folder_form #folder_name")
    wait_for_ajaximations
    new_folder.send_keys(name)
    wait_for_ajaximations
    new_folder.send_keys(:return)
    wait_for_ajaximations
  end
end

def make_folder_actions_visible
  driver.execute_script("$('.folder_item').addClass('folder_item_hover')")
end

def add_file(file_fullpath)
  attachment_field = keep_trying_until do
    driver.execute_script "$('.add_file_link').click()"
    wait_for_ajaximations
    attachment_field = fj('#attachment_uploaded_data')
    attachment_field.should be_displayed
    attachment_field
  end
  attachment_field.send_keys(file_fullpath)
  wait_for_ajaximations
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

def file_setup
  sleep 5
  @a_filename, a_fullpath, _, @a_tempfile = get_file("a_file.txt")
  @b_filename, b_fullpath, _, @b_tempfile = get_file("b_file.txt")
  @c_filename, c_fullpath, _, @c_tempfile = get_file("c_file.txt")

  add_file(a_fullpath)
  add_file(c_fullpath)
  add_file(b_fullpath)
end

describe "common file behaviors" do
  it_should_behave_like "in-process server selenium tests"

  def add_file(file_fullpath)
    attachment_field = keep_trying_until do
      driver.execute_script "$('.add_file_link').click()"
      wait_for_ajaximations
      attachment_field = fj('#attachment_uploaded_data')
      attachment_field.should be_displayed
      attachment_field
    end
    attachment_field.send_keys(file_fullpath)
    wait_for_ajaximations
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

    it "should order file structure files alphabetically" do
      file_setup
      file_elements = get_file_elements

      file_elements[0].text.should == @a_filename
      file_elements[1].text.should == @b_filename
      file_elements[2].text.should == @c_filename
    end
  end

  context "letter casing" do

    def add_multiple_folders(folder_names)
      folder_names.each { |name| add_folders(name) }
      ff('#files_content .folder')
    end

    it "should ignore file name case when alphabetizing" do
      sleep 5 # page does a weird load twice which is causing selenium failures so we sleep and wait for the page
      amazing_filename, amazing_fullpath, _, amazing_tempfile = get_file("amazing_file.txt")
      dog_filename, dog_fullpath, _, dog_tempfile = get_file("Dog_file.txt")
      file_paths = [dog_fullpath, amazing_fullpath]
      file_paths.each do
        |name| add_file(name)
        wait_for_ajaximations
      end
      files = ff('#files_content .file')
      files.first.should include_text('amazing')
      files.last.should include_text('Dog')
    end

    it "should ignore folder name case when alphabetizing" do
      folder_names = %w(amazing Dog)
      folders = add_multiple_folders(folder_names)
      folders.first.should include_text(folder_names[0])
      folders.last.should include_text(folder_names[1])
    end

    it "should ignore mixed-casing when adding new folders" do
      folder_names = %w(ZeEDeE CoOlEst)
      folders = add_multiple_folders(folder_names)
      folders.first.should include_text(folder_names[1])
      folders.last.should include_text(folder_names[0])
    end
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
    wait_for_ajaximations
    Folder.last.name.should == @folder_name
    @folder_css = ".folder_#{Folder.last.id}"
    make_folder_actions_visible
  end

  it "should allow renaming folders" do
    edit_folder_name = "my folder 2"
    entry_field = keep_trying_until do
      f("#files_content .folder_item .rename_item_link").click
      wait_for_ajaximations
      entry_field = f("#files_content #rename_entry_field")
      entry_field.should be_displayed
      entry_field
    end
    wait_for_ajaximations
    entry_field.send_keys(edit_folder_name)
    wait_for_ajaximations
    entry_field.send_keys(:return)
    wait_for_ajaximations
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

describe "course files" do
  it_should_behave_like "in-process server selenium tests"

  it "should not show root folder files in the collaborations folder when there is a collaboration" do
    course_with_teacher_logged_in

    f = Folder.root_folders(@course).first
    a = f.active_file_attachments.build
    a.context = @course
    a.uploaded_data = default_uploaded_data
    a.save!

    PluginSetting.create!(:name => 'etherpad', :settings => {})

    @collaboration = Collaboration.typed_collaboration_instance('EtherPad')
    @collaboration.context = @course
    @collaboration.attributes = { :title => 'My collaboration',
                                  :user  => @teacher }
    @collaboration.save!

    get "/courses/#{@course.id}/files"
    wait_for_ajaximations

    file_elements = keep_trying_until do
      file_elements = ffj('#files_structure_list > .context > ul > .file > .name')
      file_elements.count.should == 1
      file_elements
    end

    file_elements.first.text.should == a.name
  end
end

describe "scribd re-rendering" do
  it_should_behave_like "in-process server selenium tests"

  before do
    ScribdAPI.stubs(:config).returns({ :key => "key", :secret => "what" })
  end

  context "with missing scribd_doc" do
    before do
      course_with_student_logged_in :active_all => true
      @attachment = scribdable_attachment_model :context => @course, :workflow_state => 'deleted', :display_name => 'scribd-test-file.pdf'
      @attachment.folder = Folder.root_folders(@course).first
      @attachment.save!
    end

    context "with google previews enabled" do
      it "should kick off a scribd render when the file is previewed" do
        get "/courses/#{@course.id}/files"
        wait_for_ajaximations
        file_item = nil
        keep_trying_until { file_item = f("#files_structure span[title='#{@attachment.display_name}']") }
        file_item.click
        wait_for_ajax_requests
        f('#doc_preview_holder iframe').should_not be_nil
        keep_trying_until { Delayed::Job.find_by_tag('Attachment#submit_to_scribd!') }
        @attachment.reload.last_inline_view.should > 1.minute.ago
      end
    end

    context "with google previews disabled" do
      before do
        @account = @course.account
        @account.allowed_services = "-google_docs_previews"
        @account.save!
      end

      it "should re-render a deleted scribd document" do
        get "/courses/#{@course.id}/files"
        wait_for_ajaximations
        file_item = nil
        keep_trying_until { file_item = f("#files_structure span[title='#{@attachment.display_name}']") }
        file_item.click
        wait_for_ajax_requests
        f('#doc_preview_holder').text.should be_include "try again later"
        keep_trying_until { Delayed::Job.find_by_tag('Attachment#submit_to_scribd!') }
      end

      it "should display a message if the scribd document is processing" do
        @attachment.workflow_state = 'processing'
        @attachment.save!
        get "/courses/#{@course.id}/files"
        wait_for_ajaximations
        file_item = nil
        keep_trying_until { file_item = f("#files_structure span[title='#{@attachment.display_name}']") }
        file_item.click
        wait_for_ajax_requests
        f('#doc_preview_holder').text.should be_include "being processed"
        Delayed::Job.find_by_tag('Attachment#submit_to_scribd!').should be_nil
      end
    end
  end
end
