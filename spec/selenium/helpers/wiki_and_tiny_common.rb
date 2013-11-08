require File.expand_path(File.dirname(__FILE__) + '/../common')

  def clear_wiki_rce
    wiki_page_body = driver.find_element(:id, :wiki_page_body)
    wiki_page_body.clear
    wiki_page_body[:value].should be_empty
    wiki_page_body
  end

  def wiki_page_tools_upload_file(form, type)
    name, path, data = get_file({:text => 'testfile1.txt', :image => 'graded.png'}[type])

    f("#{form} .file_name").send_keys(path)
    f("#{form} button").click
    keep_trying_until { ffj("#{form}:visible").empty? }
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
    @image_list = f('#editor_tabs_4 .image_list')
  end

  def add_text_to_tiny(text)
    f('.wiki_switch_views_link').click
    clear_wiki_rce
    f('.wiki_switch_views_link').click
    type_in_tiny('#wiki_page_body', text)
    in_frame "wiki_page_body_ifr" do
      f('#tinymce').send_keys(:return)
      f('#tinymce').should include_text(text)
    end
  end

  def add_text_to_tiny_no_val(text)
    f('.wiki_switch_views_link').click
    clear_wiki_rce
    f('.wiki_switch_views_link').click
    type_in_tiny('#wiki_page_body', text)
  end

  def save_wiki
    submit_form('#new_wiki_page')
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests
  end

  def validate_link(text)
    in_frame "wiki_page_body_ifr" do
      link = keep_trying_until { f('#tinymce a') }
      link.attribute('href').should == text
    end
  end

  def create_wiki_page(title, hfs, edit_roles)
    @course.wiki.wiki_pages.create(:title => title, :hide_from_students => hfs, :editing_roles => edit_roles, :notify_of_update => true)
  end

  def select_all_wiki
    tiny_controlling_element = "#wiki_page_body"
    scr = "$(#{tiny_controlling_element.to_s.to_json}).editorBox('execute', 'selectAll')"
    driver.execute_script(scr)
  end

  def validate_wiki_style_attrib_empty(selectors)
    in_frame "wiki_page_body_ifr" do
      f("#tinymce #{selectors}").attribute('style').should be_empty
    end
  end

  #only handles by #id's
  def validate_wiki_style_attrib(type, value, selectors)
    in_frame "wiki_page_body_ifr" do
      f("#tinymce #{selectors}").attribute('style').should == "#{type}: #{value}\;"
    end
  end

  def add_canvas_image(el, folder, filename)
    el.find_element(:css, '.mce_instructure_image').click
    dialog = ff('.ui-dialog').reverse.detect(&:displayed?)
    f('a[href="#tabUploaded"]', dialog).click
    keep_trying_until { f('.folderLabel', dialog).should be_displayed }
    folder_el = ff('.folderLabel', dialog).detect { |el| el.text == folder }
    folder_el.should_not be_nil
    folder_el.click unless folder_el['class'].split.include?('expanded')
    keep_trying_until { f('.treeFile', dialog).should be_displayed }
    file_el = f(".treeFile[title=\"#{filename}\"]", dialog)
    file_el.should_not be_nil
    file_el.click
    wait_for_ajaximations
    f('.ui-dialog-buttonset .btn-primary', dialog).click
    wait_for_ajaximations
  end

  def add_url_image(el, url, alt_text)
    el.find_element(:css, '.mce_instructure_image').click
    dialog = ff('.ui-dialog').reverse.detect(&:displayed?)
    f('a[href="#tabUrl"]', dialog).click
    f('[name="image[src]"]', dialog).send_keys(url)
    f('[name="image[alt]"]', dialog).send_keys(alt_text)
    f('.ui-dialog-buttonset .btn-primary', dialog).click
    wait_for_ajaximations
  end

  def add_image_to_rce
    wait_for_tiny(keep_trying_until { f("#new_wiki_page") })
    f('.wiki_switch_views_link').click
    clear_wiki_rce
    f('.wiki_switch_views_link').click
    f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
    f('.upload_new_image_link').click
    wiki_page_tools_upload_file('#sidebar_upload_image_form', :image)
    in_frame "wiki_page_body_ifr" do
      f('#tinymce img').should be_displayed
    end

    submit_form('#new_wiki_page')
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests
  end
