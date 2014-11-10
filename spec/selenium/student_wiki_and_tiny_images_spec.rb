require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor Images" do
  include_examples "in-process server selenium tests"

  context "wiki and tiny images as a student" do

    before (:each) do
      course(:active_all => true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @teacher = user_with_pseudonym(:active_user => true, :username => 'teacher@example.com', :name => 'teacher@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @course.enroll_teacher(@teacher).accept
    end

    it "should add an image to the page and validate a student can see it" do
      login_as(@teacher.name)
      get "/courses/#{@course.id}/wiki"
      add_image_to_rce

      login_as(@student.name)
      get "/courses/#{@course.id}/wiki"
      expect(fj("img[src='/courses/#{@course.id}/files/#{@course.attachments.last.id}/preview']")).to be_displayed
      #check_image would be good to do here but the src on the image in the wiki body is messed up
    end
  end
end
