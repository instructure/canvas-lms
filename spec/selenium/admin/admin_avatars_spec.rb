require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "admin avatars" do
  include_context "in-process server selenium tests"

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
      expect(f("#submitted_profile")).to include_text "Submitted 1"
      f("#submitted_profile").click
    else
      expect(f(opts.keys[0])).to include_text(opts.values[0])
      f(opts.keys[0]).click
    end
    expect(f("#avatars .name")).to include_text user.name
    expect(f(".avatar").attribute('style')).to match(/http/)
  end

  def lock_avatar(user, element)
    element.click
    f(".links .lock_avatar_link").click
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    expect(f(".links .unlock_avatar_link")).to be_displayed
    user.reload
    expect(user.avatar_state).to eq :locked
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
    expect(user.avatar_state).to eq :approved
    expect(f(".links .lock_avatar_link")).to be_displayed
  end

  it "should approve un-approved avatar" do
    user = create_avatar_state
    expect(user.avatar_state).to eq :submitted
    f(".links .approve_avatar_link").click
    wait_for_ajax_requests
    user.reload
    expect(user.avatar_state).to eq :approved
    expect(f(".links .approve_avatar_link")).not_to be_displayed
  end
  it "should delete the avatar" do
    user = create_avatar_state
    f("#any_profile").click
    f(".links .reject_avatar_link").click
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    user.reload
    expect(user.avatar_state).to eq :none
    expect(user.avatar_image_url).to be_nil
  end
end