#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module ConferencesCommon

  def conferences_index_page
    "/courses/#{@course.id}/conferences"
  end

  def new_conference_button
    f('.new-conference-btn')
  end

  def end_conference_button
    f('.close_conference_link', new_conference_list)
  end

  def end_first_conference_in_list
    end_conference_button.click
    close_modal_if_present
  end

  def delete_recording_button(recording)
    f('a.delete_recording_link', recording)
  end

  def delete_first_recording_in_first_conference_in_list
    conference = first_conference_in_list(new_conference_list)
    recording = first_recording_in_conference(conference)
    delete_recording_button(recording).click
    close_modal_if_present
  end

  def first_recording_in_conference(conference)
    f('li.recording', conference)
  end

  def first_conference_in_list(conference_list)
    f('li.conference', conference_list)
  end

  def show_recordings_in_first_conference_in_list
    conference = first_conference_in_list(new_conference_list)
    f('a.element_toggler', conference).click
  end

  def new_conference_list
    f('#new-conference-list')
  end

  def concluded_conference_list
    f('#concluded-conference-list')
  end

  def verify_conference_list_includes(conference_title)
    expect(new_conference_list).to include_text conference_title
  end

  def verify_conference_list_is_empty
    expect(new_conference_list).to include_text 'There are no new conferences'
  end

  def verify_concluded_conference_list_includes(conference_title)
    expect(concluded_conference_list).to include_text conference_title
  end

  def verify_concluded_conference_list_is_empty
    expect(concluded_conference_list).to include_text 'There are no concluded conferences'
  end

  def verify_conference_includes_recordings
    expect(first_conference_in_list(new_conference_list)).to include_text 'Recording'
  end

  def verify_conference_does_not_include_recordings
    expect(first_conference_in_list(new_conference_list)).not_to include_text 'Recording'
  end

  def verify_conference_includes_recordings_with_statistics
    expect(first_conference_in_list(new_conference_list)).to include_text 'statistics'
  end

  def verify_conference_does_not_include_recordings_with_statistics
    expect(first_conference_in_list(new_conference_list)).not_to include_text 'statistics'
  end

  def initialize_wimba_conference_plugin
    PluginSetting.create!(
      name: 'wimba',
      settings: {
        domain: 'wimba.instructure.com'
      }
    )
  end

  def create_wimba_conference(title = 'Wimba Conference', duration=60)
    WimbaConference.create!(
      title: title,
      user: @user,
      context: @course,
      duration: duration
    )
  end

  def initialize_big_blue_button_conference_plugin(domain = 'bbb.instructure.com', secret = 'secret')
    PluginSetting.create!(
      name: 'big_blue_button',
      settings: {
        domain: domain,
        secret: secret,
        recording_enabled: true
      }
    )
  end

  def create_big_blue_button_conference(conference_key = 'instructure_web_conference_defaultkey', title = 'BigBlueButton Conference', duration=60, record=true)
    BigBlueButtonConference.create!(
      conference_key: conference_key,
      title: title,
      user: @user,
      context: @course,
      duration: duration,
      conference_type: 'BigBlueButton',
      settings: {
        record: record
      }
    )
  end

  def delete_conference(opts={})
    cog_menu_item = opts.fetch(:cog_menu_item, f('.icon-settings'))
    cancel_transaction = opts.fetch(:cancel, false)

    cog_menu_item.click
    wait_for_ajaximations

    # click the trash icon to delete the conference
    f('.icon-trash.delete_conference_link.ui-corner-all').click

    if cancel_transaction
      driver.switch_to.alert.dismiss
    else
      driver.switch_to.alert.accept
    end

    wait_for_ajaximations
  end

  def edit_conference(opts={})
    cog_menu_item = opts.fetch(:cog_menu_item, f('.icon-settings'))
    cancel_transaction = opts.fetch(:cancel, false)

    cog_menu_item.click
    wait_for_ajaximations

    # click the pencil icon to delete the conference
    f('.icon-edit.edit_conference_link.ui-corner-all').click

    wait_for_ajaximations
  end

  def create_conference(opts={})
    title = opts.fetch(:title, 'Test Conference')
    cancel_transaction = opts.fetch(:cancel, false)
    invite_all_users = opts.fetch(:invite_all_users, false)

    add_conference(title)
    invite_all_but_one_user(opts) unless invite_all_users

    if cancel_transaction
      f('.ui-dialog button.cancel_button').click
    else
      f('.ui-dialog .btn-primary').click
    end

    wait_for_ajaximations
  end

  def add_conference(title)
    new_conference_button.click
    wait_for_ajaximations
    replace_content(f('#web_conference_title'), title)
  end

  def invite_all_but_one_user(opts={})
    undo_form_default_invite_all_users

    users_to_invite = opts.fetch(:users_to_invite, possible_conference_attendees)
    wait_for_ajaximations
    users_to_invite.each(&:click)

    # exclude one user
    users_to_invite.first.click
  end

  # This deselects the form default: "Invite All Course Users"
  def undo_form_default_invite_all_users
    f('.all_users_checkbox').click
  end

  def possible_conference_attendees
    ff('input[type=checkbox]', f('#members_list'))
  end

  def conclude_conference(conf)
    # closing will conclude the conference
    conf.close
    conf.save!
  end

  def big_blue_button_mock_response(request = '', response = '')
    filename = 'big_blue_button'
    filename += '_' + request unless request.empty?
    filename += '_' + response unless response.empty?
    filename += '.xml'
    File.read(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/files/conferences/' + filename))
  end

end
