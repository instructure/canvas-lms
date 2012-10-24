require File.expand_path(File.dirname(__FILE__) + '/common')

describe "courses" do
  it_should_behave_like "in-process server selenium tests"

  before do
    course_with_student_logged_in(:active_all => true)
    course_with_teacher(:active_all => true, :course => @course)

    @course_discussion = @course.discussion_topics.create!(:user => @teacher, :title => "hi", :message => "a")
    @course_announcement = @course.announcements.create!(:user => @teacher, :title => "to read", :message => "a")

    @group_category = @course.group_categories.create!(:name => "course groups")
    @group = @group_category.groups.create!(:context => @course, :name => "course groups 1")
    @group.add_user(@student, 'accepted')

    @group.discussion_topics.create!(:user => @teacher, :title => "hi", :message => "a")
    @group.announcements.create!(:user => @teacher, :title => "to read", :message => "a")
  end

  it "should show badges in the left nav of a course" do
    get "/courses/#{@course.id}"

    f("#section-tabs .discussions .nav-badge").text.should == "1"
    f("#section-tabs .announcements .nav-badge").text.should == "1"
  end

  it "should show badges in the left nav of a group" do
    get "/groups/#{@group.id}"

    f("#section-tabs .discussions .nav-badge").text.should == "1"
    f("#section-tabs .announcements .nav-badge").text.should == "1"
  end

  it "should derement the badge when a conversation is read" do
    # visiting the page will decrement the count on the next page load
    get "/courses/#{@course.id}/discussion_topics/#{@course_discussion.id}"
    get "/courses/#{@course.id}/announcements/#{@course_announcement.id}"

    f("#section-tabs .discussions .nav-badge").should be_nil
    f("#section-tabs .announcements .nav-badge").text.should == "1"

    get "/courses/#{@course.id}"

    f("#section-tabs .discussions .nav-badge").should be_nil
    f("#section-tabs .announcements .nav-badge").should be_nil
  end
end
