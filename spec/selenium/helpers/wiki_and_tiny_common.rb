require File.expand_path(File.dirname(__FILE__) + '/../common')

module WikiAndTinyCommon

  def wiki_page_body
    f('textarea.body')
  end

  def clear_wiki_rce
    element = wiki_page_body
    clear_tiny(element)
    element
  end

  def type_in_wiki_html(html)
    element = wiki_page_body
    switch_editor_views(element)
    element.send_keys(html)
    switch_editor_views(element)
  end

  def wiki_page_tools_upload_file(form, type)
    name, path, data = get_file({:text => 'testfile1.txt', :image => 'graded.png'}[type])

    f("#{form} .file_name").send_keys(path)
    wait_for_ajaximations
    f("#{form} button").click
    expect(f("body")).not_to contain_jqcss("#{form}:visible")
  end

  def wiki_page_tools_file_tree_setup
    @root_folder = Folder.root_folders(@course).first
    @sub_folder = @root_folder.sub_folders.create!(:name => 'subfolder', :context => @course)
    @sub_sub_folder = @sub_folder.sub_folders.create!(:name => 'subsubfolder', :context => @course)
    @text_file = @root_folder.attachments.create!(:filename => 'text_file.txt', :context => @course) { |a| a.content_type = 'text/plain' }
    @image1 = @root_folder.attachments.build(:context => @course)
    path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/email.png')
    @image1.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
    @image1.save!
    @image2 = @root_folder.attachments.build(:context => @course)
    path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/graded.png')
    @image2.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
    @image2.save!
    get "/courses/#{@course.id}/pages/front-page/edit"

    @tree1 = driver.find_element(:id, :tree1)
    @image_list = f('#editor_tabs_4 .image_list')
  end

  def add_text_to_tiny(text)
    clear_wiki_rce
    type_in_tiny('textarea.body', text)
    in_frame wiki_page_body_ifr_id do
      f('#tinymce').send_keys(:return)
      expect(f('#tinymce')).to include_text(text)
    end
  end

  def add_text_to_tiny_no_val(text)
    clear_wiki_rce
    type_in_tiny('textarea.body', text)
  end

  def add_html_to_tiny(html)
    clear_wiki_rce
    type_in_wiki_html(html)
  end

  def save_wiki
    f('form.edit-form button.submit').click
    wait_for_ajax_requests
    get "/courses/#{@course.id}/pages/front-page/edit"
  end

  def validate_link(text)
    in_frame wiki_page_body_ifr_id do
      link = f('#tinymce a')
      expect(link.attribute('href')).to eq text
    end
  end

  def create_wiki_page(title, unpublished, edit_roles)
    wiki_page = @course.wiki.wiki_pages.create(:title => title, :editing_roles => edit_roles, :notify_of_update => true)
    wiki_page.unpublish! if unpublished
    wiki_page
  end

  def manually_create_wiki_page(title,body)
    f('.new_page').click
    wait_for_ajaximations
    replace_content(f('#title'),title)
    add_text_to_tiny(body)
    expect_new_page_load { f('form.edit-form button.submit').click }
    expect(f('.page-title')).to include_text(title)
    expect(f('.show-content')).to include_text(body)
  end

  def select_all_wiki
    select_all_in_tiny(f("textarea.body"))
  end

  def validate_wiki_style_attrib_empty(selectors)
    in_frame wiki_page_body_ifr_id do
      expect(f("#tinymce #{selectors}").attribute('style')).to be_empty
    end
  end

  #only handles by #id's
  def validate_wiki_style_attrib(type, value, selectors)
    in_frame wiki_page_body_ifr_id do
      expect(f("#tinymce #{selectors}").attribute('style')).to match("#{type}: #{value}\;")
    end
  end

  def activate_editor_embed_image(el)
    el.find_element(:css, "div[aria-label='Embed Image'] button").click
    ff('.ui-dialog').reverse.detect(&:displayed?)
  end

  def add_canvas_image(el, folder, filename)
    dialog = activate_editor_embed_image(el)
    scroll_into_view('a[href="#tabUploaded"]')
    f('a[href="#tabUploaded"]', dialog).click
    expect(f('.treeLabel', dialog)).to be_displayed
    folder_el = ff('.treeLabel', dialog).detect { |e| e.text == folder }
    expect(folder_el).not_to be_nil
    folder_el.click unless folder_el['class'].split.include?('expanded')
    expect(f('.treeFile', dialog)).to be_displayed
    file_el = f(".treeFile[title=\"#{filename}\"]", dialog)
    expect(file_el).not_to be_nil
    file_el.click
    wait_for_ajaximations
    f('.ui-dialog-buttonset .btn-primary', dialog).click
    wait_for_ajaximations
  end

  def add_url_image(el, url, alt_text)
    dialog = activate_editor_embed_image(el)
    f('a[href="#tabUrl"]', dialog).click
    f('[name="image[src]"]', dialog).send_keys(url)
    f('[name="image[alt]"]', dialog).send_keys(alt_text)
    f('.ui-dialog-buttonset .btn-primary', dialog).click
    wait_for_ajaximations
  end

  def add_image_to_rce
    get "/courses/#{@course.id}/pages/front-page/edit"
    wait_for_tiny(f("form.edit-form .edit-content"))
    clear_wiki_rce
    f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
    f('.upload_new_image_link').click
    wait_for_animations
    wiki_page_tools_upload_file('#sidebar_upload_image_form', :image)
    in_frame wiki_page_body_ifr_id do
      expect(f('#tinymce img')).to be_displayed
    end

    f('form.edit-form button.submit').click
    wait_for_ajax_requests
  end

  def add_file_to_rce
    wiki_page_tools_file_tree_setup
    wait_for_tiny(f("form.edit-form .edit-content"))
    wiki_page_body = clear_wiki_rce
    f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
    root_folders = @tree1.find_elements(:css, 'li.folder')
    root_folders.first.find_element(:css, '.sign.plus').click
    wait_for_ajaximations
    expect(root_folders.first.find_elements(:css, '.file.text').length).to eq 1
    root_folders.first.find_elements(:css, '.file.text span').first.click

    in_frame wiki_page_body_ifr_id do
      expect(f('#tinymce')).to include_text('txt')
    end
    switch_editor_views(wiki_page_body)
    expect(find_css_in_string(wiki_page_body[:value], '.instructure_file_link')).not_to be_empty
    f('form.edit-form button.submit').click
    wait_for_ajax_requests
  end

  def wiki_page_body_ifr_id
    f('.mce-container iframe')['id']
  end

  def wiki_page_editor_id
    f('textarea.body')['id']
  end

  def expand_root_folder
    @tree1 = driver.find_element(:id, :tree1)
    root_folders = @tree1.find_elements(:css, 'li.folder')
    root_folders.first.find_element(:css, '.sign.plus').click
  end

  def shift_click_button(selector)
    el = f(selector)
    driver.action.key_down(:shift).click(el).key_up(:shift).perform
  end
end
