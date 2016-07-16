module UsersCommon
  def add_user(opts={})
    f(".add_user_link").click
    name = opts[:name] ? opts[:name] : "user1"
    email = opts[:email] ? opts[:email] : "user1@test.com"
    sortable_name = opts[:sortable_name] ? opts[:sortable_name] : name
    confirmation = opts[:confirmation] ? opts[:confirmation] : 1
    short_name = opts[:short_name] ? opts[:short_name] : name

    replace_content f("#user_short_name"), short_name unless short_name.eql? name

    replace_content f("#user_sortable_name"), sortable_name unless sortable_name.eql? name

    expect(is_checked("#pseudonym_send_confirmation")).to be_truthy
    if confirmation == 0
      f("#pseudonym_send_confirmation").click
      expect(is_checked("#pseudonym_send_confirmation")).to be_falsey
    end
    f("#add_user_form #user_name").send_keys name
    f("#pseudonym_unique_id").send_keys email
    submit_dialog_form("#add_user_form")
    wait_for_ajax_requests
    user = User.where(:name => name).first
    expect(user).to be_present
    expect(user.sortable_name).to eq sortable_name
    expect(user.short_name).to eq short_name
    expect(user.email).to eq email
    user
  end
end