require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')

describe "discussion assignments" do
  it_should_behave_like "in-process server selenium tests"


  before (:each) do
    course_with_teacher_logged_in
  end

  context "created on the index page" do
    it "should create a discussion topic when created" do
      get "/courses/#{@course.id}/assignments"
      build_assignment_with_type("Discussion", :submit => true)
      expect_new_page_load { f("#left-side .discussions").click }
      wait_for_ajaximations
      ffj('.discussion-list li.discussion:visible').should_not be_empty
    end

    it "should redirect to the discussion topic" do
      get "/courses/#{@course.id}/assignments"
      build_assignment_with_type("Discussion", :submit => true)
      expect_new_page_load { f(".assignment_list .group_assignment .assignment_title a").click }
      driver.current_url.should match %r{/courses/\d+/discussion_topics/\d+}
    end
  end

  context "created with 'more options'" do
    it "should redirect to the discussion new page and maintain parameters" do
      get "/courses/#{@course.id}/assignments"
      build_assignment_with_type("Discussion", :name => "Discuss!", :points => "5")
      expect_new_page_load { f('.more_options_link').click }
      wait_for_ajaximations
      f('#discussion-title').attribute(:value).should == "Discuss!"
      f('#discussion_topic_assignment_points_possible').attribute(:value).should == "5"
    end
  end

  context "edited from the index page" do
    it "should update discussion when updated" do
      assign = @course.assignments.create!(:name => "Discuss!", :points_possible => "5", :submission_types => "discussion_topic")
      get "/courses/#{@course.id}/assignments"
      driver.execute_script %{$('#assignment_#{assign.id} .edit_assignment_link:first').addClass('focus');}
      f("#assignment_#{assign.id} .edit_assignment_link").click
      edit_assignment(:name => "Rediscuss!", :submit => true)
      assign.reload.discussion_topic.title.should == "Rediscuss!"
    end
  end

  context "edited with 'more options'" do
    it "should redirect to the discussion edit page and maintain parameters" do
      assign = @course.assignments.create!(:name => "Discuss!", :points_possible => "5", :submission_types => "discussion_topic")
      get "/courses/#{@course.id}/assignments"
      driver.execute_script %{$('#assignment_#{assign.id} .edit_assignment_link:first').addClass('focus');}
      f("#assignment_#{assign.id} .edit_assignment_link").click
      edit_assignment(:name => "Rediscuss!", :points => 10)
      expect_new_page_load { f('.more_options_link').click }
      wait_for_ajaximations
      f('#discussion-title').attribute(:value).should == "Rediscuss!"
      f('#discussion_topic_assignment_points_possible').attribute(:value).should == "10"
    end
  end
end
