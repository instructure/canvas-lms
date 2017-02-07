require File.expand_path(File.dirname(__FILE__) + '/common')

describe "conditional_release" do
  include_context "in-process server selenium tests"

  context "As a teacher" do
    before(:each) do
      Account.default.enable_feature!(:conditional_release)
      course_with_teacher_logged_in
      get course_settings_path @course.id
    end
  end
end
