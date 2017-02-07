require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

describe "better_file_browsing" do
  include_context "in-process server selenium tests"
  include FilesCommon

  context "as a student" do
    before :once do
      @student = course_with_student(active_all: true).user
    end

    before :each do
      user_session(@student)
    end

    def verify_hidden_item_not_searchable_as_student(search_text)
      f("input[type='search']").send_keys "#{search_text}", :return
      expect(f("body")).not_to contain_css(".ef-item-row")
    end

    context "in course with files" do
      before :once do
        txt_files = ["a_file.txt", "b_file.txt", "c_file.txt"]
        @files = txt_files.map do |text_file|
          add_file(fixture_file_upload("files/#{text_file}", 'text/plain'), @course, text_file)
        end
      end

      it "should search for a file", priority: "1", test_id: 220355 do
        get "/courses/#{@course.id}/files"
        f("input[type='search']").send_keys "b_fi", :return
        expect(all_files_folders).to have_size 1
      end

      it "should not return unpublished files in search results", priority: "1", test_id: 238870 do
        @files[0].update_attribute(:locked, true)
        get "/courses/#{@course.id}/files"
        verify_hidden_item_not_searchable_as_student("a_fi")
      end

      it "should not return hidden files in search results", priority: "1", test_id: 238871 do
        @files[0].update_attribute(:hidden, true)
        get "/courses/#{@course.id}/files"
        verify_hidden_item_not_searchable_as_student("a_fi")
      end

      it "should not see upload file, add folder buttons and cloud icon", priority: "1", test_id: 327118 do
        get "/courses/#{@course.id}/files"
        content = f("#content")
        expect(content).not_to contain_css('.btn-upload')
        expect(content).not_to contain_css('.btn-add-folder')
        expect(content).not_to contain_css('.btn-link.published-status')
      end

      it "should only see Download option on cog icon", priority: "1", test_id: 133105 do
        get "/courses/#{@course.id}/files"
        content = f("#content")
        f('.al-trigger-gray').click
        expect(fln("Download")).to be_displayed
        expect(content).not_to contain_link("Rename")
        expect(content).not_to contain_link("Move")
        expect(content).not_to contain_link("Delete")
      end

      it "should only see View and Download options on toolbar menu", priority: "1", test_id: 133109 do
        get "/courses/#{@course.id}/files"
        content = f("#content")
        f('.ef-item-row').click
        expect(f('.btn-download')).to be_displayed
        expect(f('.btn-view')).to be_displayed
        expect(content).not_to contain_css('.btn-move')
        expect(content).not_to contain_css('.btn-restrict')
        expect(content).not_to contain_css('.btn-delete')
      end

      it "should see calendar icon on restricted files within a given timeframe", priority: "1", test_id: 133108 do
        @files[0].update_attributes unlock_at: Time.zone.now - 1.week,
                                    lock_at: Time.zone.now + 1.week
        get "/courses/#{@course.id}/files"
        expect(f('.icon-calendar-day')).to be_displayed
        f('.icon-calendar-day').click
        wait_for_ajaximations
        expect(f("body")).not_to contain_css("[name=permissions]")
      end
    end

    context "in course with folders" do
      before :once do
        @folder = folder_model(name: "restricted_folder", context: @course)
        @file = add_file(fixture_file_upload('files/example.pdf', 'application/pdf'),
                         @course, "example.pdf", @folder)
      end

      it "should not return files from hidden folders in search results", priority: "1", test_id: 171774 do
        @folder.update_attribute :hidden, true
        get "/courses/#{@course.id}/files"
        verify_hidden_item_not_searchable_as_student("example")
      end

      it "should not return files from unpublished folders in search results", priority: "1", test_id: 171774 do
        @folder.update_attribute :locked, true
        get "/courses/#{@course.id}/files"
        verify_hidden_item_not_searchable_as_student("example")
      end

      it "should let student access files in restricted folder hidden by link", priority: "1", test_id: 134750 do
        @folder.update_attribute :hidden, true

        get "/courses/#{@course.id}/files/folder/restricted_folder?preview=#{@file.id}"
        refresh_page # the header seriously doesn't show up until you refres ¯\_(ツ)_/¯
        expect(f('.ef-file-preview-header')).to be_present
      end
    end
  end
end
