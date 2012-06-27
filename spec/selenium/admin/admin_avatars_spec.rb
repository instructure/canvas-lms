require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "admin avatars" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_admin_logged_in
    Account.default.enable_service(:avatars)
    Account.default.settings[:avatars] = 'enabled_pending'
    Account.default.save!

  end

  def create_avatar_state(avatar_state="submitted", avatar_image_url="http://www.example.com")
    user = User.last
    user.avatar_image_url = avatar_image_url
    user.save!
    user.avatar_state = avatar_state
    user.save!
    get "/accounts/#{Account.default.id}/avatars"
    user
  end

  def verify_avatar_state(user, opts={})
    if (opts.empty?)
      f("#submitted_profile").should include_text "Submitted 1"
      f("#submitted_profile").click
    else
      f(opts.keys[0]).should include_text(opts.values[0])
      f(opts.keys[0]).click
    end
    f("#avatars .name").should include_text user.name
    f(".avatar img").attribute('src').should_not be_nil
  end

  def lock_avatar(user, element)
    element.click
    f(".links .lock_avatar_link").click
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    f(".links .unlock_avatar_link").should be_displayed
    user.reload
    user.avatar_state.should == :locked
    user
  end

  it "should verify that the profile pictures is submitted " do
    user = create_avatar_state
    verify_avatar_state(user)
  end

  it "should verify that the profile pictures is reported " do
    user = create_avatar_state("reported")
    opts = {"#reported_profile" => "Reported 1"}
    verify_avatar_state(user, opts)
  end

  it "should verify that the profile picture is approved, re-reported " do
    user = create_avatar_state("re_reported")
    opts = {"#re_reported_profile" => "Re-Reported 1"}
    verify_avatar_state(user, opts)
  end

  it "should verify that all profile pictures are displayed " do
    user = create_avatar_state
    opts = {"#any_profile" => "All 1"}
    verify_avatar_state(user, opts)
  end

  it "should lock the avatar state " do
    user = create_avatar_state
    lock_avatar(user, f("#any_profile"))
  end

  it "should unlock the avatar state " do
    user = create_avatar_state
    user = lock_avatar(user, f("#any_profile"))
    f(".links .unlock_avatar_link").click
    wait_for_ajax_requests
    user.reload
    user.avatar_state.should == :approved
    f(".links .lock_avatar_link").should be_displayed
  end

  it "should approve un-approved avatar" do
    user = create_avatar_state
    user.avatar_state.should == :submitted
    f(".links .approve_avatar_link").click
    wait_for_ajax_requests
    user.reload
    user.avatar_state.should == :approved
    f(".links .approve_avatar_link").should_not be_displayed
  end
  it "should delete the avatar" do
    user = create_avatar_state
    f("#any_profile").click
    f(".links .reject_avatar_link").click
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    user.reload
    user.avatar_state.should == :none
    user.avatar_image_url.should be_nil
  end
end