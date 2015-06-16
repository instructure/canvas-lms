require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/announcements_common')

describe "announcements public course" do
  include_examples "in-process server selenium tests"

  context "replies on announcements" do
    before :each do
      course_with_teacher(active_all: true, is_public: true) # sets @teacher and @course
      expect(@course.is_public).to be_truthy
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user

      @context = @course
      @announcement = announcement_model(user: @teacher) # sets @a

      s1e = @announcement.discussion_entries.create!(:user => @student1, :message => "Hello I'm student 1!")
      @announcement.discussion_entries.create!(:user => @student2, :parent_entry => s1e, :message => "Hello I'm student 2!")
    end

    it "does not display replies on announcements to unauthenticated users" do
      get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
      wait_for_ajaximations
      expect(f('#discussion_subentries span').text).to match(/must log in/i)
    end

    it "does not display replies on announcements to users not enrolled in the course" do
      user_session(user)

      get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
      wait_for_ajaximations
      expect(f('#discussion_subentries span').text).to match(/must log in/i)
    end
  end
end
