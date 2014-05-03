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

    it "should sort alphabetically" do
      course_with_student_logged_in(:active_all => true)
      @user.update_attribute(:name, 'bob')
      other = User.create(:name => 'billy')
      @course.enroll_student(other).tap{ |e| e.workflow_state = 'active'; e.save! }

      group = @course.groups.create(:name => 'group')
      group.users << other

      get 'recipients', :context => @course.asset_string, :per_page => '1', :type => 'user'
      response.should be_success
      response.body.should include('billy')
      response.body.should_not include('bob')
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

    it "should allow filtering out non-messageable courses" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:name, "course1")
      @course2 = course(:active_all => 1)
      @course2.enroll_student(@user).accept
      @course2.update_attribute(:name, "course2")
      term = @course2.root_account.enrollment_terms.create! :name => "Fall", :end_at => 1.day.ago
      @course2.update_attributes! :enrollment_term => term
      get 'recipients', {search: 'course', :messageable_only => true}
      response.body.should include('course1')
      response.body.should_not include('course2')
    end

    it "should return an empty list when searching in a non-messageable context" do
      course_with_student_logged_in(:active_all => true)
      @enrollment.update_attributes(workflow_state: 'deleted')
      get 'recipients', {search: 'foo', :context => @course.asset_string}
      response.body.should =~ /\[\]\z/
    end

    it "should handle groups in courses without messageable enrollments" do
      course_with_student_logged_in
      group = @course.groups.create(:name => 'this_is_a_test_group')
      group.users = [@user]
      get 'recipients', {:search => '', :type => 'context'}
      response.should be_success
      # This is questionable legacy behavior.
      response.body.should include(group.name)
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

    context "with section privilege limitations" do
      before do
        course_with_teacher_logged_in(:active_all => true)
        @section = @course.course_sections.create!(:name => 'Section1')
        @section2 = @course.course_sections.create!(:name => 'Section2')
        @enrollment.update_attribute(:course_section, @section)
        @enrollment.update_attribute(:limit_privileges_to_course_section, true)
        @student1 = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
        @section.enroll_user(@student1, 'StudentEnrollment', 'active')
        @student2 = user_with_pseudonym(:active_all => true, :name => 'Student2', :username => 'student2@instructure.com')
        @section2.enroll_user(@student2, 'StudentEnrollment', 'active')
      end

      it "should exclude non-messageable contexts" do
        get 'recipients', {
          :context => "course_#{@course.id}",
          :synthetic_contexts => true
        }
        response.body.should include('"name":"Course Sections"')
        get 'recipients', {
          :context => "course_#{@course.id}_sections",
          :synthetic_contexts => true
        }
        response.body.should include('Section1')
        response.body.should_not include('Section2')
      end

      it "should exclude non-messageable users" do
        get 'recipients', {
          :context => "course_#{@course.id}_students"
        }
        response.body.should include('Student1')
        response.body.should_not include('Student2')
      end
    end
  end

end
