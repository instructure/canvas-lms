require File.expand_path(File.dirname(__FILE__) + '/common')

describe "student interactions report" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in(:active_all => true)
    @student1 = student_in_course(:active_all => true).user
    @student2 = student_in_course(:active_all => true, :name => "zzz student").user

    @assignment = @course.assignments.create(:name => "first assignment", :points_possible => 10)
    @sub1 = @assignment.submissions.create(:user => @student1)
    @sub2 = @assignment.submissions.create(:user => @student2)

    @sub1.update_attribute(:score, 10)
    @sub2.update_attribute(:score, 5)

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
    driver.find_elements(:css, ".report tbody tr").should == [trs[0], trs[1]]

    ths[3].click
    ths[3].attribute('class').should match(/headerSortUp/)
    driver.find_elements(:css, ".report tbody tr").should == [trs[1], trs[0]]

    ths[5].click
    ths[5].attribute('class').should_not match(/header/)
  end
end
