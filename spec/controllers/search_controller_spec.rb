require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchController do

  describe "GET 'recipients'" do
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:name, "this_is_a_test_course")

      other = User.create(:name => 'this_is_a_test_user')
      enrollment = @course.enroll_student(other)
      enrollment.workflow_state = 'active'
      enrollment.save

      group = @course.groups.create(:name => 'this_is_a_test_group')
      group.users = [@user, other]

      get 'recipients', :search => 'this_is_a_test_'
      response.should be_success
      response.body.should include(@course.name)
      response.body.should include(group.name)
      response.body.should include(other.name)
    end

    it "should not sort by rank if a search term is not used" do
      course_with_student_logged_in(:active_all => true)
      @user.update_attribute(:name, 'billy')
      other = User.create(:name => 'bob')
      @course.enroll_student(other).tap{ |e| e.workflow_state = 'active'; e.save! }

      group = @course.groups.create(:name => 'group')
      group.users << other

      get 'recipients', :context => @course.asset_string, :per_page => '1', :type => 'user'
      response.should be_success
      response.body.should include('billy')
      response.body.should_not include('bob')
    end

    it "should sort by rank if a search term is used" do
      course_with_student_logged_in(:active_all => true)
      @user.update_attribute(:name, 'billy')
      other = User.create(:name => 'bob')
      @course.enroll_student(other).tap{ |e| e.workflow_state = 'active'; e.save! }

      group = @course.groups.create(:name => 'group')
      group.users << other

      get 'recipients', :search => 'b', :per_page => '1', :type => 'user'
      response.should be_success
      response.body.should include('bob')
      response.body.should_not include('billy')
    end
  end

end
