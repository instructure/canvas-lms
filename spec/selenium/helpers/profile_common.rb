require File.expand_path(File.dirname(__FILE__) + '/../common')

# ======================================================================================================================
# Shared Examples
# ======================================================================================================================

shared_examples 'profile_settings_page' do |context|
  it 'should give option to change profile pic', priority: "2", test_id: pick_test_id(context, 68936, 352617, 352618) do
    enable_avatars
    get "/profile/settings"
    driver.mouse.move_to f('.avatar.profile_pic_link.none')
    wait_for_ajaximations

    # We want to make sure the tooltip is displayed,
    # but are limited to assuming that with almost all popular browsers...
    # "The information is most often shown as a tooltip text when the mouse moves over the element."
    # ...as shown in HTML title attribute at http://www.w3schools.com/tags/att_global_title.asp
    expect(f('.avatar.profile_pic_link.none').attribute('title')).to eq 'Click to change profile pic'
  end
end


shared_examples 'profile_user_about_page' do |context|
  it 'should give option to change profile pic', priority: "2", test_id: pick_test_id(context, 358573, 358574, 358575) do
    enable_avatars
    get "/about/#{@user.id}"

    driver.mouse.move_to f('.avatar.profile-link')
    wait_for_ajaximations

    # We are checking the title in this tooltip like we do in the one above,
    # given the same limitation.
    expect(f('.avatar.profile-link').attribute('title')).to eq 'Click to change profile pic'
  end
end

shared_examples 'user settings page change pic window' do |context|
  it 'should allow user to click to change profile pic', priority: "1", test_id: pick_test_id(context, 68938, 368784, 368785) do
    enable_avatars
    get '/profile/settings'

    f('.avatar.profile_pic_link.none').click
    wait_for_ajaximations

    keep_trying_until(3) do
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
end



# ======================================================================================================================
# Helper Methods
# ======================================================================================================================

def enable_avatars
  a = Account.default
  a.enable_service('avatars')
  a.settings[:enable_profiles] = true
  a.save!
  a
end


def pick_test_id(context, id1, id2, id3)
  case context
  when 'student'
    id1
  when 'teacher'
    id2
  when 'admin'
    id3
  else
    raise('Error: Invalid context for "test id"')
  end
end

def pick_priority(context, p1, p2, p3)
  case context
  when 'student'
    p1
  when 'teacher'
    p2
  when 'admin'
    p3
  else
    raise('Error: Invalid context for "test priority"')
  end
end