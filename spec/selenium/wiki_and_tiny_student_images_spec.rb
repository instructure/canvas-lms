require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor Images" do
  include_context "in-process server selenium tests"

  context "wiki and tiny images as a student" do

    before (:each) do
      course(:active_all => true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @teacher = user_with_pseudonym(:active_user => true, :username => 'teacher@example.com', :name => 'teacher@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @course.enroll_teacher(@teacher).accept
    end

    it "should add an image to the page and validate a student can see it" do
      create_session(@teacher.pseudonym)
      add_image_to_rce

      @course.wiki.wiki_pages.first.publish!

      create_session(@student.pseudonym)
      get "/courses/#{@course.id}/pages/front-page"
      expect(fj("#wiki_page_show img")['src']).to include("/courses/#{@course.id}/files/#{@course.attachments.last.id}/preview")
    end
  end
end
