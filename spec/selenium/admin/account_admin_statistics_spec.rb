require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "account admin statistics" do
  it_should_behave_like "in-process server selenium tests"


  def item_lists
    ff('.item_list')
  end

  def validate_item_list(item_list, header_text)
    item_list.find_element(:css, '.header').text.should == header_text
  end

  context "with admin initially logged in" do

    before (:each) do
      @course = Course.create!(:name => 'stats', :account => Account.default)
      @course.offer!
      admin_logged_in
    end

    context 'created, started, none to show, and link validation' do
      before (:each) do
        get "/accounts/#{Account.default.id}/statistics"
      end

      ['created', 'started'].each_with_index do |action, i|
        it "should validate recently #{action} courses display" do
          validate_item_list(item_lists[i], @course.name)
        end
      end

      it "should validate no info in list display" do
        item_lists[2].text.should == 'None to show'
      end

      it "should validate link works in list" do
        expect_new_page_load { item_lists[0].find_element(:css, '.header').click }
        f('#section-tabs-header').should include_text(@course.name)
      end
    end

    it "should validate recently ended courses display" do
      concluded_course = Course.create!(:name => 'concluded course', :account => Account.default)
      concluded_course.update_attributes(:conclude_at => 1.day.ago)
      get "/accounts/#{Account.default.id}/statistics"
      validate_item_list(item_lists[2], concluded_course.name)
    end
  end

  it "should validate recently logged-in courses display" do
    course = Course.create!(:name => 'new course', :account => Account.default)
    course.offer!
    student = User.create!(:name => 'Example Student')
    student.register!
    pseudonym = student.pseudonyms.create!(:unique_id => 'student@example.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf')
    course.enroll_user(student, 'StudentEnrollment').accept!
    login_as(pseudonym.unique_id, 'asdfasdf')
    driver.navigate.to(app_host + '/logout')
    admin_logged_in
    get "/accounts/#{Account.default.id}/statistics"
    validate_item_list(item_lists[3], student.name)
  end
end
