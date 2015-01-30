require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

 describe "better_file_browsing" do
   include_examples "in-process server selenium tests"

   context "As a teacher", :priority => "1" do
      before (:each) do
        course_with_teacher_logged_in
        Account.default.enable_feature!(:better_file_browsing)
        get "/courses/#{@course.id}/files"
      end

        it "should display new files UI" do
          keep_trying_until { expect(f('.btn-upload')).to be_displayed }
        end
   end

   context "File Downloads", :priority => "2" do
      it "should download a file from top toolbar successfully" do
        skip("Skipped until issue with firefox on OSX is resolved")
        download_from_toolbar
      end

      it "should download a file from cog" do
        skip("Skipped until issue with firefox on OSX is resolved")
        download_from_cog
      end

      it "should download a file from file preview successfully" do
        skip("Skipped until issue with firefox on OSX is resolved")
        download_from_preview
      end
   end

end
