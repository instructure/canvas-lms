require File.expand_path(File.dirname(__FILE__) + '/common')

describe "user lists Windows-Firefox-Tests" do
  it_should_behave_like "in-process server selenium tests"

  before(:each) do
    course_with_teacher_logged_in(:active_all => true)
  end
  
  def add_users_to_user_list
    @course.root_account.pseudonyms.create!(:unique_id => "A124123").assert_user{|u| u.name = "login_name user"}
    
    user_list = <<eolist
user1@example.com, "bob sagat" <bob@thesagatfamily.name>, A124123
eolist
    driver.find_element(:css, "textarea.user_list").send_keys(user_list)
    driver.find_element(:css, "button.verify_syntax_button").click
    driver.find_element(:css, "button.add_users_button").click
    wait_for_dom_ready
    keep_trying_until {driver.find_element(:css, "#enrollment_#{Enrollment.last.id}").text == "user, login_name"}
    
    unique_ids = ["user1@example.com", "bob@thesagatfamily.name", "A124123"]
    browser_text = ["user1@example.com\nuser1@example.com", "sagat, bob\nbob@thesagatfamily.name", "user, login_name"]
    Enrollment.all.last(3).each do |e|
      e.user.pseudonyms.first.unique_id.should == unique_ids.shift
      driver.find_element(:css, "#enrollment_#{e.id}").text.should == browser_text.shift
    end
  end

  it "should support both email addresses and user names on the course details page" do
    get "/courses/#{@course.id}/details"
    driver.find_element(:css, "a#tab-users-link").click
    driver.find_element(:css, "div#tab-users a.add_users_link").click
    add_users_to_user_list
  end

  it "should support both email addresses and user names on the getting started page" do
    get "/getting_started/students"
    add_users_to_user_list
  end

end
