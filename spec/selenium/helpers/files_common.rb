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

module FilesCommon
  # This method adds the specified file to the course
  # Params:
  # - fixture: location of the file to be uploaded
  # - context: course in which file would be uploaded
  # - name: file name
  # - folder: course folder it should go under (defaults to root folder)
  def add_file(fixture, context, name, folder = Folder.root_folders(context).first)
    context.attachments.create! do |attachment|
      attachment.uploaded_data = fixture
      attachment.filename = name
      attachment.folder = folder
    end
  end

  def edit_name_from_cog_icon(file_name_new, row_selected = 0)
    ff('.al-trigger-gray')[row_selected].click
    fln("Rename").click
    expect(f(".ef-edit-name-cancel")).to be_displayed
    file_name_textbox_el = f('.ef-edit-name-form__input')
    replace_content(file_name_textbox_el, file_name_new)
    file_name_textbox_el.send_keys(:return)
  end

  def delete(row_selected = 0, delete_using = :cog_icon)
    if delete_using == :cog_icon
      ff('.al-trigger')[row_selected].click
      fln("Delete").click
    elsif delete_using == :toolbar_menu
      ff('.ef-item-row')[row_selected].click
      f('.btn-delete').click
    end
    confirm_delete_on_dialog
  end

  def move(file_name, row_selected = 0, move_using = :cog_icon, destination = nil)
    if move_using == :cog_icon
      ff('.al-trigger')[row_selected].click
      fln("Move").click
    elsif move_using == :toolbar_menu
      ff('.ef-item-row')[row_selected].click
      f('.btn-move').click
    end
    expect(f(".ReactModal__Header-Title h4")).to include_text "Where would you like to move #{file_name}?"
    if destination.present?
      folders = destination.split('/')
      folders.each do |folder|
        fj(".ReactModal__Body .treeLabel span:contains('#{folder}')").click
      end
    else
      ff(".treeLabel span")[3].click
    end
    driver.action.send_keys(:return).perform
    wait_for_ajaximations
    ff(".btn-primary")[1].click
  end

  def move_multiple_using_toolbar(files = [])
    files.each do |file_name|
      file = driver.find_element(xpath: "//span[contains(text(), '#{file_name}') and @class='ef-name-col__text']")
                   .find_element(xpath: "../..")
      driver.action.key_down(:command).click(file).key_up(:command).perform
    end
    wait_for_ajaximations
    f('.btn-move').click
    wait_for_ajaximations
    expect(f(".ReactModal__Header-Title h4").text).to eq "Where would you like to move these #{files.count} items?"
    ff(".treeLabel span")[3].click
    driver.action.send_keys(:return).perform
    wait_for_ajaximations
    ff(".btn-primary")[1].click
  end

  # This method sets permissions on files/folders
  def set_item_permissions(permission_type = :publish, restricted_access_option = nil, set_permissions_from = :cloud_icon)
    if set_permissions_from == :cloud_icon
      f('.btn-link.published-status').click
    elsif set_permissions_from == :toolbar_menu
      ff('.ef-item-row')[0].click
      f('.btn-restrict').click
    end
    wait_for_ajaximations
    if permission_type == :publish
      driver.find_elements(:name, 'permissions')[0].click
    elsif permission_type == :unpublish
      driver.find_elements(:name, 'permissions')[1].click
    else
      if restricted_access_option == :available_with_link
        driver.find_elements(:name, 'permissions')[2].click
      else
        driver.find_elements(:name, 'permissions')[3].click
        ff('.ui-datepicker-trigger.btn')[0].click
        fln("15").click
        ff('.ui-datepicker-trigger.btn')[0].send_keys(:enter) # close the calendar
        wait_for_ajaximations
        ff('.ui-datepicker-trigger.btn')[1].click
        fln("25").click
        ff('.ui-datepicker-trigger.btn')[1].send_keys(:enter) # close the calendar
      end
    end
    ff('.btn.btn-primary')[1].click
    wait_for_ajaximations
  end

  def should_make_folders_in_the_menu_droppable
    course_with_teacher_logged_in
    get "/files"
    wait_for_ajaximations
    f(".add_folder_link").click
    wait_for_ajaximations
    expect(f("#files_content .add_folder_form #folder_name")).to be_displayed
    f("#files_content .add_folder_form #folder_name").send_keys("my folder\n")
    wait_for_ajaximations
    expect(f(".node.folder span")).to have_class('ui-droppable')

    # also make sure that it has a tooltip of the file name so that you can read really long names
    expect(f(".node.folder .name[title='my folder']")).not_to be_nil
  end

  def should_show_students_link_to_download_zip_of_folder
    course_with_student_logged_in
    get "/courses/#{@course.id}/files"
    link = f(".links a.download_zip_link")
    wait_for_ajaximations
    expect(link).to be_displayed
    expect(link).to have_attribute('href', %r"/courses/#{@course.id}/folders/\d+/download")
  end

  def confirm_delete_on_dialog
    driver.switch_to.alert.accept
    wait_for_ajaximations
  end

  def cancel_delete_on_dialog
    driver.switch_to.alert.dismiss
    wait_for_ajaximations
  end

  def add_folder(name = 'new folder')
    click_new_folder_button
    new_folder = f("input[aria-label='Folder Name']")
    new_folder.click # sometimes send_keys won't send all keys unless click first
    new_folder.send_keys(name)
    f('.ef-edit-name-accept').click
    wait_for_ajaximations
  end

  def click_new_folder_button
    f("button[aria-label='Add Folder']").click
    wait_for_ajaximations
  end

  def create_new_folder
    f('.btn-add-folder').click
    f("input[aria-label='Folder Name']").send_keys(:return)
    wait_for_ajaximations
    all_files_folders.first
  end

  def all_files_folders
    # TODO: switch to ff once specs stop using this to find non-existence of stuff
    driver.find_elements(:class, 'ef-item-row')
  end

  def insert_file_from_rce(insert_into = nil, filename = nil)
    fj('[role=tablist] [role=presentation]:not([aria-disabled]):contains("Files")').click
    fj('[role=tabpanel] button:contains("unfiled")').click
    fj('[role=tabpanel] button:contains("some test file")').click
    if insert_into == :quiz
      fj("[role=tabpanel] button:contains('#{filename}')").click
      f(".save_quiz_button").click
    elsif insert_into == :discussion
      f("#edit_discussion_form_buttons .btn-primary").click
    else
      f(".btn-primary").click
    end
    expect(fln("some test file")).to be_displayed
  end
end
