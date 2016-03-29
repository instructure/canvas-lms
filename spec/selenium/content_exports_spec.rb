require File.expand_path(File.dirname(__FILE__) + '/common')

require 'nokogiri'

describe "content exports" do
  include_context "in-process server selenium tests"

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
    end

    def run_export
      get "/courses/#{@course.id}/content_exports"
      yield if block_given?
      submit_form('#exporter_form')
      @export = keep_trying_until { ContentExport.last }
      @export.export_without_send_later
      new_download_link = keep_trying_until { f("#export_files a") }
      url = new_download_link.attribute 'href'
      expect(url).to match(%r{/files/\d+/download\?verifier=})
    end

    it "should allow course export downloads", priority: "1", test_id: 126678 do
      run_export
      expect(@export.export_type).to eq 'common_cartridge'
    end

    it "should allow qti export downloads", priority: "1", test_id: 126680 do
      run_export do
        f("input[value=qti]").click
      end
      expect(@export.export_type).to eq 'qti'
    end

    it "should selectively create qti export" do
      q1 = @course.quizzes.create!(:title => 'quiz1')
      q2 = @course.quizzes.create!(:title => 'quiz2')

      run_export do
        f("input[value=qti]").click
        f(%{.quiz_item[name="copy[quizzes][#{CC::CCHelper.create_key(q2)}]"]}).click
      end

      expect(@export.export_type).to eq 'qti'

      file_handle = @export.attachment.open :need_local_file => true
      zip_file = Zip::File.open(file_handle.path)
      manifest_doc = Nokogiri::XML.parse(zip_file.read("imsmanifest.xml"))

      expect(manifest_doc.at_css("resource[identifier=#{CC::CCHelper.create_key(q1)}]")).not_to be_nil
      expect(manifest_doc.at_css("resource[identifier=#{CC::CCHelper.create_key(q2)}]")).to be_nil
    end
  end
end