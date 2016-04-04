require_relative 'common'
require_relative 'offline_contents_common'

describe "offline contents" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:epub_export)
    @course1 = course_model(name: 'First Course')
    @course1.offer!
    @course1.enable_feature!(:epub_export)
  end

  context "as a teacher" do
    before :each do
      @teacher1 = user_with_pseudonym(:username => 'teacher1@example.com', :active_all => 1)
      @course1.enroll_teacher(@teacher1).accept!
      user_session(@teacher1)
    end

    it_behaves_like 'show courses for ePub generation', :teacher
    it_behaves_like 'generate and download ePub', :teacher
  end

  context "as a student" do
    before :each do
      @student1 = user_with_pseudonym(:username => 'student1@example.com', :active_all => 1)
      @course1.enroll_student(@student1).accept!
      user_session(@student1)
    end

    it_behaves_like 'show courses for ePub generation', :student
    it_behaves_like 'generate and download ePub', :student
  end
end

