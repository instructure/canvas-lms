require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course statistics" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @student1 = student_in_course(:active_all => true, :name => "Sheldon Cooper").user
    @student2 = student_in_course(:active_all => true, :name => "Leonard Hofstadter").user
    @student3 = student_in_course(:active_all => true, :name => "Howard Wolowitz").user
  end

  it "should show most recent logged in users" do
    pseudonym(@student1) # no login info
    pseudonym(@student2).tap{|p| p.current_login_at = 1.days.ago; p.save!}
    pseudonym(@student3).tap{|p| p.current_login_at = 2.days.ago; p.save!}

    get "/courses/#{@course.id}/statistics"
    wait_for_ajaximations
    f('#students_stats_tab').click

    users = ff('.item_list li')
    users[0].should include_text @student2.name
    users[0].should_not include_text "unknown"
    users[1].should include_text @student3.name
    users[1].should_not include_text "unknown"
    users[2].should include_text @student1.name
    users[2].should include_text "unknown"

    links = ff('.item_list li a')
    links[0]['href'].end_with?("/courses/#{@course.id}/users/#{@student2.id}").should == true
    links[1]['href'].end_with?("/courses/#{@course.id}/users/#{@student3.id}").should == true
    links[2]['href'].end_with?("/courses/#{@course.id}/users/#{@student1.id}").should == true
  end
end
