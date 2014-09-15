require File.expand_path(File.dirname(__FILE__) + '/common')

describe "content exports" do
  include_examples "in-process server selenium tests"

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
      url.should match(%r{/files/\d+/download\?verifier=})
    end

    it "should allow course export downloads" do
      run_export
      @export.export_type.should == 'common_cartridge'
    end

    it "should allow qti export downloads" do
      run_export do
        f("input[value=qti]").click
      end
      @export.export_type.should == 'qti'
    end

    it "should selectively create qti export" do
      q1 = @course.quizzes.create!(:title => 'quiz1')
      q2 = @course.quizzes.create!(:title => 'quiz2')

      run_export do
        f("input[value=qti]").click
        f(%{.quiz_item[name="copy[quizzes][#{CC::CCHelper.create_key(q2)}]"]}).click
      end

      @export.export_type.should == 'qti'

      file_handle = @export.attachment.open :need_local_file => true
      zip_file = Zip::File.open(file_handle.path)
      manifest_doc = Nokogiri::XML.parse(zip_file.read("imsmanifest.xml"))

      manifest_doc.at_css("resource[identifier=#{CC::CCHelper.create_key(q1)}]").should_not be_nil
      manifest_doc.at_css("resource[identifier=#{CC::CCHelper.create_key(q2)}]").should be_nil
    end
  end
end