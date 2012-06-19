shared_examples_for "wiki and tiny selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  def clear_wiki_rce
    wiki_page_body = driver.find_element(:id, :wiki_page_body)
    wiki_page_body.clear
    wiki_page_body[:value].should be_empty
    wiki_page_body
  end

  def wiki_page_tools_upload_file(form, type)
    name, path, data = get_file({:text => 'testfile1.txt', :image => 'graded.png'}[type])

    driver.find_element(:css, "#{form} .file_name").send_keys(path)
    driver.find_element(:css, "#{form} button").click
    keep_trying_until { find_all_with_jquery("#{form}:visible").empty? }
  end

  def wiki_page_tools_file_tree_setup
    @root_folder = Folder.root_folders(@course).first
    @sub_folder = @root_folder.sub_folders.create!(:name => 'subfolder', :context => @course);
    @sub_sub_folder = @sub_folder.sub_folders.create!(:name => 'subsubfolder', :context => @course);
    @text_file = @root_folder.attachments.create!(:filename => 'text_file.txt', :context => @course) { |a| a.content_type = 'text/plain' }
    @image1 = @root_folder.attachments.build(:context => @course)
    path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/email.png')
    @image1.uploaded_data = ActionController::TestUploadedFile.new(path, Attachment.mimetype(path))
    @image1.save!
    @image2 = @root_folder.attachments.build(:context => @course)
    path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/graded.png')
    @image2.uploaded_data = ActionController::TestUploadedFile.new(path, Attachment.mimetype(path))
    @image2.save!
    get "/courses/#{@course.id}/wiki"

    @tree1 = driver.find_element(:id, :tree1)
    @image_list = driver.find_element(:css, '#editor_tabs_4 .image_list')
  end
end
