def add_user (opts={})
  f(".add_user_link").click
  name = opts[:name] ? opts[:name] : "user1"
  email = opts[:email] ? opts[:email] : "user1@test.com"
  sortable_name = opts[:sortable_name] ? opts[:sortable_name] : name
  confirmation = opts[:confirmation] ? opts[:confirmation] : 1
  short_name = opts[:short_name] ? opts[:short_name] : name
  if (!short_name.eql? name)
    replace_content f("#user_short_name"), short_name
  end

  if (!sortable_name.eql? name)
    replace_content f("#user_sortable_name"), sortable_name
  end
  is_checked("#pseudonym_send_confirmation").should be_true
  if (confirmation == 0)
    f("#pseudonym_send_confirmation").click
    is_checked("#pseudonym_send_confirmation").should be_false
  end
  f("#add_user_form #user_name").send_keys name
  f("#pseudonym_unique_id").send_keys email
  submit_form("#add_user_form")
  wait_for_ajax_requests
  user = User.first(:conditions => {:name => name})
  user.should be_present
  user.sortable_name.should eql sortable_name
  user.short_name.should eql short_name
  user.email.should eql email
  user
end
