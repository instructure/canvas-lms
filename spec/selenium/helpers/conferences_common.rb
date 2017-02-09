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
end
