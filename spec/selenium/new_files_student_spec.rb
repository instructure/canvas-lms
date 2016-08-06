require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

describe "better_file_browsing" do
  include_context "in-process server selenium tests"
  include FilesCommon

  context "as a student" do
    def student_goto_files
      user_session(@student)
      get "/courses/#{@course.id}/files"
      wait_for_ajaximations
    end

    def verify_hidden_item_not_searchable_as_student(search_text)
      refresh_page
      student_goto_files
      f("input[type='search']").send_keys "#{search_text}"
      driver.action.send_keys(:return).perform
      refresh_page
      expect(all_files_folders.count).to eq 0
    end

    context "in course with files" do
      before :each do
        course_with_teacher_logged_in
        @student = student_in_course(active_all: true).user
        txt_files = ["a_file.txt", "b_file.txt", "c_file.txt"]
        txt_files.map do |text_file|
          add_file(fixture_file_upload("files/#{text_file}", 'text/plain'), @course, text_file)
        end
      end

      it "should search for a file", priority: "1", test_id: 220355 do
        student_goto_files
        f("input[type='search']").send_keys "b_fi"
        driver.action.send_keys(:return).perform
        refresh_page
        expect(all_files_folders.count).to eq 1
      end

      it "should not return unpublished files in search results", priority: "1", test_id: 238870 do
        get "/courses/#{@course.id}/files"
        set_item_permissions(:unpublish)
        verify_hidden_item_not_searchable_as_student("a_fi")
      end

      it "should not return hidden files in search results", priority: "1", test_id: 238871 do
        get "/courses/#{@course.id}/files"
        set_item_permissions(:restricted_access, :available_with_link)
        verify_hidden_item_not_searchable_as_student("a_fi")
      end

      it "should not see upload file, add folder buttons and cloud icon", priority: "1", test_id: 327118 do
        student_goto_files
        content = f("#content")
        expect(content).not_to contain_css('.btn-upload')
        expect(content).not_to contain_css('.btn-add-folder')
        expect(content).not_to contain_css('.btn-link.published-status')
      end

      it "should only see Download option on cog icon", priority: "1", test_id: 133105 do
        student_goto_files
        content = f("#content")
        ff('.al-trigger-gray')[0].click
        expect(fln("Download")).to be_displayed
        expect(content).not_to contain_link("Rename")
        expect(content).not_to contain_link("Move")
        expect(content).not_to contain_link("Delete")
      end

      it "should only see View and Download options on toolbar menu", priority: "1", test_id: 133109 do
        student_goto_files
        content = f("#content")
        ff('.ef-item-row')[0].click
        expect(f('.btn-download')).to be_displayed
        expect(f('.btn-view')).to be_displayed
        expect(content).not_to contain_css('.btn-move')
        expect(content).not_to contain_css('.btn-restrict')
        expect(content).not_to contain_css('.btn-delete')
      end

      it "should see calendar icon on restricted files within a given timeframe", priority: "1", test_id: 133108 do
        get "/courses/#{@course.id}/files"
        set_item_permissions(:restricted_access, :available_with_timeline, :toolbar_menu)
        student_goto_files
        expect(f('.icon-calendar-day')).to be_displayed
        f('.icon-calendar-day').click
        wait_for_ajaximations
        expect(driver.find_elements(:name, 'permissions')[0]).not_to be_present
      end
    end

    context "in course with folders" do
      before :each do
        course_with_teacher_logged_in
        @student = student_in_course(active_all: true).user
        add_file(fixture_file_upload('files/example.pdf', 'application/pdf'),
                @course, "example.pdf")
        get "/courses/#{@course.id}/files"
        add_folder("restricted_folder")
        move("example.pdf", 0, :cog_icon)
        # without this refresh, the driver cannot find the permissions dialog for the folder
        refresh_page
      end

      it "should not return files from locked folders in search results", priority: "1", test_id: 171774 do
        set_item_permissions(:restricted_access, :available_with_link)
        verify_hidden_item_not_searchable_as_student("example")
      end

      it "should not return files from unpublished folders in search results", priority: "1", test_id: 171774 do
        set_item_permissions(:unpublish)
        verify_hidden_item_not_searchable_as_student("example")
      end

      it "should let student access files in restricted folder hidden by link", priority: "1", test_id: 134750 do
        set_item_permissions(:restricted_access, :available_with_link)
        f('.ef-name-col__text').click
        wait_for_ajaximations
        f('.ef-name-col__text').click
        wait_for_ajaximations
        file_preview_url = (driver.current_url).match(/\/files.*/)[0]
        student_goto_files
        expect(f("#content")).not_to contain_link("restricted_folder")
        get "/courses/#{@course.id}/files/folder/restricted_folder"
        expect(f("#content")).not_to contain_link("example.pdf")
        get "/courses/#{@course.id}"+file_preview_url
        refresh_page
        wait_for_ajaximations
        expect(f('.ef-file-preview-header')).to be_present
      end
    end
  end
end
