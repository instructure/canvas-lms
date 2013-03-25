def item_lists
  ff('.item_list')
end

def validate_item_list(css, header_text)
  f(css).text.should include_text(header_text)
end

def should_validate_recently_created_courses_display
  get url
  validate_item_list(list_css[:created], @course.name)
end

def should_validate_recently_started_courses_display
  get url
  validate_item_list(list_css[:started], @course.name)
end

def should_validate_no_info_in_list_display
  get url
  validate_item_list(list_css[:ended], 'None to show')
end

def should_validate_link_works_in_list
  get url
  expect_new_page_load { f(list_css[:started]).find_element(:css, '.header').click }
  f('#section-tabs-header').should include_text(@course.name)
end

def should_validate_recently_ended_courses_display
  concluded_course = Course.create!(:name => 'concluded course', :account => account)
  concluded_course.update_attributes(:conclude_at => 1.day.ago)
  get url
  validate_item_list(list_css[:ended], concluded_course.name)
end

def should_validate_recently_logged_in_courses_display
  course = Course.create!(:name => 'new course', :account => account)
  course.offer!
  student = User.create!(:name => 'Example Student')
  student.register!
  pseudonym = student.pseudonyms.create!(:unique_id => 'student@example.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf')
  course.enroll_user(student, 'StudentEnrollment').accept!
  login_as(pseudonym.unique_id, 'asdfasdf')
  driver.navigate.to(app_host + '/logout')
  admin_logged_in
  get url
  validate_item_list(list_css[:logged_in], student.name)
end
