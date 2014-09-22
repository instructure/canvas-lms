require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')


def enroll_many_students
  course_with_teacher_logged_in

  500.times do |i|
    @student= User.create!(:name => "STUDENT_NAME_#{i}")
    @student.register!
    @student.pseudonyms.create!(:unique_id => "nobody#{i}@example.com", :password => 'qwerty', :password_confirmation => 'qwerty')

    e = @course.enroll_student(@student)
    e.workflow_state = 'active'
    e.save!
    @course.reload
  end
end

describe "large enrollments", :priority => "2" do
  it_should_behave_like "in-process server selenium tests"

  context "page links" do

    before (:each) do
      enroll_many_students
    end

    it "should display course homepage" do
      get "/courses/#{@course.id}/"
      flash_message_present?(:error).should be_false
    end

  end
end