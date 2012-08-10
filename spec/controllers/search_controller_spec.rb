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

    it "should optionally show users who haven't finished registration" do
      course_with_student_logged_in(:active_all => true)
      @user.update_attribute(:name, 'billy')
      other = User.create(:name => 'bob')
      other.update_attribute(:workflow_state, 'creation_pending')
      @course.enroll_student(other).tap{ |e| e.workflow_state = 'invited'; e.save! }

      get 'recipients', {
        :search => 'b', :type => 'user', :skip_visibility_checks => true,
        :synthetic_contexts => true, :context => "course_#{@course.id}_students"
      }
      response.should be_success
      response.body.should include('bob')
      response.body.should include('billy')
    end

    context "with admin_context" do
      it "should return nothing if the user doesn't have rights" do
        user_session(user)
        course(:active_all => true).course_sections.create(:name => "other section")
        response.should be_success

        get 'recipients', {
          :type => 'section', :skip_visibility_checks => true,
          :synthetic_contexts => true, :context => "course_#{@course.id}_sections"
        }
        response.body.should =~ /\[\]\z/
      end

      it "should return sub-contexts" do
        account_admin_user()
        user_session(@user)
        course(:active_all => true).course_sections.create(:name => "other section")

        get 'recipients', {
          :type => 'section', :skip_visibility_checks => true,
          :synthetic_contexts => true, :context => "course_#{@course.id}_sections"
        }
        response.should be_success
        response.body.should include('other section')
      end

      it "should return sub-users" do
        account_admin_user
        user_session(@user)
        course(:active_all => true).course_sections.create(:name => "other section")
        course_with_student(:active_all => true)

        get 'recipients', {
          :type => 'user', :skip_visibility_checks => true,
          :synthetic_contexts => true, :context => "course_#{@course.id}_all"
        }
        response.body.should include(@teacher.name)
        response.body.should include(@student.name)
      end
    end
  end

end
