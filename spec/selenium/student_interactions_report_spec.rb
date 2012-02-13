require File.expand_path(File.dirname(__FILE__) + '/common')

describe "student interactions report" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    @e = course_with_teacher :active_course => true,
                             :user => u,
                             :active_enrollment => true
    @e.save!

    login_as(username, password)

    user_model
    @student1 = @user
    @e1 = @course.enroll_student(@student1)
    @e1.accept
    @e1.computed_current_score = 50
    @e1.computed_final_score = 75
    @e1.save!

    user_model
    @student2 = @user
    @student2.name = "zzzz student"
    @student2.save!
    @e2 = @course.enroll_student(@student2)
    @e2.accept
    @e2.computed_current_score = 100
    @e2.computed_final_score = 70
    @e2.save!

    get "/users/#{@teacher.id}/teacher_activity/course/#{@course.id}"
  end

  it "should have sortable columns, except the email header" do
    ths = driver.find_elements(:css, ".report th")
    ths[0].attribute('class').should match(/header/)
    ths[1].attribute('class').should match(/header/)
    ths[2].attribute('class').should match(/header/)
    ths[3].attribute('class').should match(/header/)
    ths[4].attribute('class').should match(/header/)
    ths[5].attribute('class').should_not match(/header/)
  end

  it "should allow sorting by columns" do
    ths = driver.find_elements(:css, ".report th")
    trs = driver.find_elements(:css, ".report tbody tr")
    ths[0].click
    ths[0].attribute('class').should match(/headerSortDown/)
    driver.find_elements(:css, ".report tbody tr").should == [trs[0], trs[1]]

    ths[0].click
    ths[0].attribute('class').should match(/headerSortUp/)
    driver.find_elements(:css, ".report tbody tr").should == [trs[1], trs[0]]

    ths[2].click
    ths[2].attribute('class').should match(/headerSortDown/)
    driver.find_elements(:css, ".report tbody tr").should == [trs[0], trs[1]]

    ths[2].click
    ths[2].attribute('class').should match(/headerSortUp/)
    driver.find_elements(:css, ".report tbody tr").should == [trs[1], trs[0]]

    ths[3].click
    ths[3].attribute('class').should match(/headerSortDown/)
    driver.find_elements(:css, ".report tbody tr").should == [trs[1], trs[0]]

    ths[3].click
    ths[3].attribute('class').should match(/headerSortUp/)
    driver.find_elements(:css, ".report tbody tr").should == [trs[0], trs[1]]

    ths[5].click
    ths[5].attribute('class').should_not match(/header/)
  end
end
