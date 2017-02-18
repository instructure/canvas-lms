require_relative 'common'
require_relative 'helpers/shared_examples_common'

# ======================================================================================================================
# Shared Examples
# ======================================================================================================================

shared_examples 'profile_settings_page' do |context|
  include SharedExamplesCommon

  it 'should give option to change profile pic', priority: "2", test_id: pick_test_id(context, student: 68936, teacher: 352617, admin: 352618) do
    enable_avatars
    get "/profile/settings"
    driver.mouse.move_to f('.avatar.profile_pic_link.none')
    wait_for_ajaximations

    # We want to make sure the tooltip is displayed,
    # but are limited to assuming that with almost all popular browsers...
    # "The information is most often shown as a tooltip text when the mouse moves over the element."
    # ...as shown in HTML title attribute at http://www.w3schools.com/tags/att_global_title.asp
    expect(f('.avatar.profile_pic_link.none')).to have_attribute('title', 'Click to change profile pic')
  end
end


shared_examples 'profile_user_about_page' do |context|
  include SharedExamplesCommon

  it 'should give option to change profile pic', priority: "2", test_id: pick_test_id(context, student: 358573, teacher: 358574, admin: 358575) do
    enable_avatars
    get "/about/#{@user.id}"

    driver.mouse.move_to f('.avatar.profile-link')
    wait_for_ajaximations

    # We are checking the title in this tooltip like we do in the one above,
    # given the same limitation.
    expect(f('.avatar.profile-link')).to have_attribute('title', 'Click to change profile pic')
  end
end

shared_examples 'user settings page change pic window' do |context|
  include SharedExamplesCommon

  it 'should allow user to click to change profile pic', priority: "1", test_id: pick_test_id(context, student: 68938, teacher: 368784, admin: 368785) do
    enable_avatars
    get '/profile/settings'

    f('.avatar.profile_pic_link.none').click
    wait_for_ajaximations

    # There is a window with title "Select Profile Picture"
    expect(f('.ui-dialog.ui-widget.ui-widget-content.ui-corner-all.ui-draggable.ui-dialog-buttons')).to be_truthy
    expect(f('.ui-dialog-title')).to be_truthy
    expect(f('.ui-dialog-titlebar.ui-widget-header.ui-corner-all.ui-helper-clearfix')).to include_text('Select Profile Picture')

    # There is a default gray image placeholder for picture
    expect(f('.avatar-content .active .select-photo-link')).to include_text('choose a picture')

    # There are 'Upload Picture' and 'From Gravatar' buttons
    expect(f('.nav.nav-pills .active')).to include_text('Upload a Picture')
    expect(fj('.nav.nav-pills li :contains("From Gravatar")')).to include_text('From Gravatar')
    # Firefox and Chrome: There is a 'Take a Picture' button
    expect(fj('.nav.nav-pills li :contains("Take a Picture")')).to include_text('Take a Picture')

    # There are 'X', Save, and Cancel buttons
    expect(f('.ui-icon.ui-icon-closethick')).to be_truthy
    expect(fj('.ui-button :contains("Cancel")')).to be_truthy
    expect(fj('.ui-button :contains("Save")')).to be_truthy
  end
end

shared_examples 'user settings change pic cancel' do |context|
  include SharedExamplesCommon

  it 'closes window when cancel button is pressed', priority: "1", test_id: pick_test_id(context, student: 68939, teacher: 372132, admin: 372133) do
    enable_avatars
    get '/profile/settings'

    f('.avatar.profile_pic_link.none').click
    wait_for_ajaximations
    expect(f('.ui-dialog.ui-widget.ui-widget-content.ui-corner-all.ui-draggable.ui-dialog-buttons')).to be_truthy
    expect(f('.ui-widget-overlay')).to be_truthy

    fj('.ui-button.ui-widget.ui-state-default.ui-corner-all.ui-button-text-only :contains("Cancel")').click
    wait_for_ajaximations
    expect(f("body")).not_to contain_css('.ui-widget-overlay')
  end
end

# ======================================================================================================================
# Helper Methods
# ======================================================================================================================
shared_context 'profile common' do
  def enable_avatars
    a = Account.default.reload
    a.enable_service('avatars')
    a.settings[:enable_profiles] = true
    a.save!
    a
  end
end

