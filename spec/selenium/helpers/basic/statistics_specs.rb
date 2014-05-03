shared_examples_for "statistics basic tests" do
  include_examples "in-process server selenium tests"

  def item_lists
    ff('.item_list')
  end

  def validate_item_list(css, header_text)
    f(css).text.should include_text(header_text)
  end

  context "with admin initially logged in" do

    before (:each) do
      @course = Course.create!(:name => 'stats', :account => account)
      @course.offer!
      admin_logged_in
    end

    it "should validate recently started courses display" do
      pending('list is not available on sub account level') if account != Account.default
      get url
      validate_item_list(list_css[:created], @course.name)
    end

    it "should validate recently started courses display" do
      pending('spec is broken on sub account level') if account != Account.default
      get url
      validate_item_list(list_css[:started], @course.name)
    end

    it "should validate no info in list display" do
      get url
      validate_item_list(list_css[:ended], 'None to show')
    end

    it "should validate link works in list" do
      pending('spec is broken on sub account level') if account != Account.default
      get url
      expect_new_page_load { f(list_css[:started]).find_element(:css, '.header').click }
      f('#section-tabs-header').should include_text(@course.name)
    end

    it "should validate recently ended courses display" do
      pending('spec is broken on sub account level') if account != Account.default
      concluded_course = Course.create!(:name => 'concluded course', :account => account)
      concluded_course.update_attributes(:conclude_at => 1.day.ago)
      get url
      validate_item_list(list_css[:ended], concluded_course.name)
    end
  end

  it "should validate recently logged-in courses display" do
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
end