#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/../common')

module WikiAndTinyCommon

  def wiki_page_body
    f('textarea.body')
  end

  def clear_wiki_rce
    element = wiki_page_body
    wait_for_tiny(element)
    clear_tiny(element)
    element
  end

  def type_in_wiki_html(html)
    element = wiki_page_body
    switch_editor_views(element)
    element.send_keys(html)
    switch_editor_views(element)
  end

  def wiki_page_tools_file_tree_setup(skip_tree=false, skip_image_list=false)
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

    if !skip_tree
      @tree1 = driver.find_element(:id, :tree1)
    end
    if !skip_image_list
      @image_list = f('#editor_tabs_4 .image_list')
    end
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
    wait_for_new_page_load { f('form.edit-form button.submit').click }
    get "/courses/#{@course.id}/pages/front-page/edit"
  end

  def validate_link(text)
    in_frame wiki_page_body_ifr_id do
      link = f('#tinymce a')
      expect(link.attribute('href')).to eq text
    end
  end

  def create_wiki_page(title, unpublished, edit_roles)
    wiki_page = @course.wiki_pages.create(:title => title, :editing_roles => edit_roles, :notify_of_update => true)
    wiki_page.unpublish! if unpublished
    wiki_page
  end

  def manually_create_wiki_page(title,body)
    f('.new_page').click
    wait_for_ajaximations
    wait_for_tiny(wiki_page_body)
    replace_content(f('#title'), title)
    type_in_tiny('textarea.body', body)
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
    fj('.ui-dialog:visible')
  end

  def add_canvas_image(el, folder, filename)
    dialog = activate_editor_embed_image(el)
    fj('a[href="#tabUploaded"]:visible').click
    folder_el = fj(".file-browser__tree button:contains('#{folder}')")
    folder_el.click unless folder_el['aria-expanded'] == 'true'
    expect(fj(".file-browser__tree li:contains('#{filename}') button", dialog)).to be_displayed
    file_el = fj(".file-browser__tree li:contains('#{filename}') button", dialog)
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
    fj('[role="presentation"]:contains("Images")').click
    fj('button:contains(" Upload a new image")').click
    alt_text = "image file"
    _name, path, _data = get_file({:image => 'graded.png'}[:image])
    f("input[type='file']").send_keys(path)
    f("input[name='alt_text']").send_keys(alt_text)
    f("button[type='submit']").click
    expect(f("body")).not_to contain_jqcss("input[type='file']:visible")
    in_frame wiki_page_body_ifr_id do
      expect(f('#tinymce img')).to be_displayed
    end

    force_click('form.edit-form button.submit')
    wait_for_ajax_requests
  end

  def upload_to_files_in_rce(image = false)
    fj('button:contains("Upload a new file")').click
    if image == true
      _name, path, _data = get_file({:image => 'graded.png'}[:image])
    else
      _name, path, _data = get_file({:text => 'foo.txt'}[:text])
    end
    f("input[type='file']").send_keys(path)
    button = f("button[type='submit']")
    keep_trying_until { button.displayed? }
    button.click
    wait_for_ajaximations
  end

  def add_file_to_rce
    title = "text_file.txt"
    @root_folder = Folder.root_folders(@course).first
    @text_file = @root_folder.attachments.create!(:filename => title,
                                                  :context => @course) { |a| a.content_type = 'text/plain' }
    get "/courses/#{@course.id}/pages/front-page/edit"
    wait_for_tiny(f("form.edit-form .edit-content"))
    fj('[role="presentation"]:contains("Files")').click
    fj("aside li:contains('#{title}')").click

    in_frame wiki_page_body_ifr_id do
      expect(f('#tinymce a').attribute('href')).to include course_file_id_path(@text_file)
    end

    switch_editor_views(wiki_page_body)
    expect(find_css_in_string(wiki_page_body[:value], '.instructure_file_link')).not_to be_empty
    force_click('form.edit-form button.submit')
    wait_for_ajax_requests
  end

  def add_file_to_rce_next
    title = "text_file.txt"
    @root_folder = Folder.root_folders(@course).first
    @text_file = @root_folder.attachments.create!(:filename => title,
                                                  :context => @course) { |a| a.content_type = 'text/plain' }
    get "/courses/#{@course.id}/pages/front-page/edit"
    wait_for_tiny(f("form.edit-form .edit-content"))
    selector = 'button[aria-label="Documents"]'
    button = driver.execute_script("return document.querySelector('#{selector}')")
    f('button[aria-label="More..."]').click unless button
    f(selector).click
    f('[role="menuitem"][title="Course Documents"]').click
    fj("[aria-label='Course Documents'] [role='button']:contains('#{title}')").click

    force_click('form.edit-form button.submit')
    wait_for_ajax_requests
  end

  def tiny_rce_ifr_id
    f('.tox-editor-container iframe')['id']
  end

  def wiki_page_body_ifr_id
    f('.mce-container iframe')['id']
  end

  def rce_page_body_ifr_id
    f('iframe.tox-edit-area__iframe')['id']
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

  def visit_front_page_edit(course)
    get "/courses/#{course.id}/pages/front-page/edit"
  end

  def visit_existing_wiki_edit(course, page_name)
    get "/courses/#{course.id}/pages/#{page_name}/edit"
  end

  def visit_new_announcement_page(course)
    get "/courses/#{course.id}/discussion_topics/new?is_announcement=true"
  end

  def visit_new_assignment_page(course)
    get "/courses/#{course.id}/assignments/new"
  end

  def visit_new_discussion_page(course)
    get "/courses/#{course.id}/discussion_topics/new"
  end

  def visit_new_quiz_page(course, quiz)
    get "/courses/#{course.id}/quizzes/#{quiz.id}/edit"
  end

  def visit_syllabus(course)
    get "/courses/#{course.id}/assignments/syllabus"
  end

  def click_edit_syllabus
    f('.edit_syllabus_link').click
  end

  def edit_wiki_css
    f("form.edit-form .edit-content")
  end

  def assignment_id_path(course, assignment)
    "/courses/#{course.id}/assignments/#{assignment.id}"
  end

  def quiz_id_path(course, quiz)
    "/courses/#{course.id}/quizzes/#{quiz.id}"
  end

  def announcement_id_path(course, announcement)
    "/courses/#{course.id}/discussion_topics/#{announcement.id}"
  end

  def discussion_id_path(course, discussion)
    "/courses/#{course.id}/discussion_topics/#{discussion.id}"
  end

  def module_id_path(course, module_obj)
    "/courses/#{course.id}/modules/#{module_obj.id}"
  end

  def course_file_path(course)
    "/courses/#{course.id}/files"
  end

  def course_file_id_path(file)
    "/files/#{file.id}"
  end

  def wysiwyg_state_setup(course, text = "1\n2\n3", val: false, html: false)
    visit_front_page_edit(course)
    wait_for_tiny(edit_wiki_css)

    if val == true
      add_text_to_tiny(text)
      validate_link(text)
    else
      if html
        add_html_to_tiny(text)
      else
        add_text_to_tiny_no_val(text)
      end
      select_all_wiki
    end
  end

  def rce_wysiwyg_state_setup(course, text = "1\n2\n3", html: false)
    visit_front_page_edit(course)
    wait_for_tiny(edit_wiki_css)

    if html
      f('button[title="Switch to raw html editor"]').click
      in_frame tiny_rce_ifr_id do
        tinyrce_element = f("body")
        tinyrce_element.send_keys(text)
      end
      f('button[title="Switch to rich text editor"]').click
    else
      in_frame tiny_rce_ifr_id do
        tinyrce_element = f("body")
        tinyrce_element.click
        tinyrce_element.send_keys(text)
      end
    end
    select_all_wiki
  end
end
