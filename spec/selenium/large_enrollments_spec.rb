require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook_common')


describe "large enrollments", priority: "2" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  context "page links" do

    before(:each) do
      course_with_teacher_logged_in

      create_users_in_course @course, 500
    end

    it "should display course homepage" do
      get "/courses/#{@course.id}/"
      expect_no_flash_message :error
    end

  end
end
