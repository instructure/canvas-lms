require_relative "common"

describe "new user tutorials" do
  include_context "in-process server selenium tests"

  before do
    @course = course_factory(active_all: true)
    course_with_teacher_logged_in(active_all: true)
    @course.account.enable_feature!(:new_user_tutorial)
  end

  it "should be collapsed if the page is set to collapsed on the server" do
    @user.new_user_tutorial_statuses['home'] = true
    @user.save!
    get "/courses/#{@course.id}/"
    expect(f('body')).not_to contain_css('.NewUserTutorialTray')
  end

  it "should be expanded if the page is set to not collapsed on the server" do
    @user.new_user_tutorial_statuses['home'] = false
    @user.save!
    get "/courses/#{@course.id}/"
    expect(f('body')).to contain_css('.NewUserTutorialTray')
  end
end
