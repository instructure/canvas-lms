#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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

      get 'recipients', params: {:search => 'this_is_a_test_'}
      expect(response).to be_successful
      expect(response.body).to include(@course.name)
      expect(response.body).to include(group.name)
      expect(response.body).to include(other.name)
    end

    it "should sort alphabetically" do
      course_with_student_logged_in(:active_all => true)
      @user.update_attribute(:name, 'bob')
      other = User.create(:name => 'billy')
      @course.enroll_student(other).tap{ |e| e.workflow_state = 'active'; e.save! }

      group = @course.groups.create(:name => 'group')
      group.users << other

      get 'recipients', params: {:context => @course.asset_string, :per_page => '1', :type => 'user'}
      expect(response).to be_successful
      expect(response.body).to include('billy')
      expect(response.body).not_to include('bob')
    end

    it "should optionally show users who haven't finished registration" do
      course_with_student_logged_in(:active_all => true)
      @user.update_attribute(:name, 'billy')
      other = User.create(:name => 'bob')
      other.update_attribute(:workflow_state, 'creation_pending')
      @course.enroll_student(other).tap{ |e| e.workflow_state = 'invited'; e.save! }

      get 'recipients', params: {
        :search => 'b', :type => 'user', :skip_visibility_checks => true,
        :synthetic_contexts => true, :context => "course_#{@course.id}_students"
      }
      expect(response).to be_successful
      expect(response.body).to include('bob')
      expect(response.body).to include('billy')
    end

    it "should allow filtering out non-messageable courses" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:name, "course1")
      @course2 = course_factory(active_all: true)
      @course2.enroll_student(@user).accept
      @course2.update_attribute(:name, "course2")
      term = @course2.root_account.enrollment_terms.create! :name => "Fall", :end_at => 1.day.ago
      @course2.update_attributes! :enrollment_term => term
      get 'recipients', params: {search: 'course', :messageable_only => true}
      expect(response.body).to include('course1')
      expect(response.body).not_to include('course2')
    end

    it "should return an empty list when searching in a non-messageable context" do
      course_with_student_logged_in(:active_all => true)
      @enrollment.update_attributes(workflow_state: 'deleted')
      get 'recipients', params: {search: 'foo', :context => @course.asset_string}
      expect(response.body).to match /\[\]\z/
    end

    it "should handle groups in courses without messageable enrollments" do
      course_with_student_logged_in
      group = @course.groups.create(:name => 'this_is_a_test_group')
      group.users = [@user]
      get 'recipients', params: {:search => '', :type => 'context'}
      expect(response).to be_successful
      # This is questionable legacy behavior.
      expect(response.body).to include(group.name)
    end

    context "with admin_context" do
      it "should return nothing if the user doesn't have rights" do
        user_session(user_factory)
        course_factory(active_all: true).course_sections.create(:name => "other section")
        expect(response).to be_successful

        get 'recipients', params: {
          :type => 'section', :skip_visibility_checks => true,
          :synthetic_contexts => true, :context => "course_#{@course.id}_sections"
        }
        expect(response.body).to match /\[\]\z/
      end

      it "should return sub-contexts" do
        account_admin_user()
        user_session(@user)
        course_factory(active_all: true).course_sections.create(:name => "other section")

        get 'recipients', params: {
          :type => 'section', :skip_visibility_checks => true,
          :synthetic_contexts => true, :context => "course_#{@course.id}_sections"
        }
        expect(response).to be_successful
        expect(response.body).to include('other section')
      end

      it "should return sub-users" do
        account_admin_user
        user_session(@user)
        course_factory(active_all: true).course_sections.create(:name => "other section")
        course_with_student(:active_all => true)

        get 'recipients', params: {
          :type => 'user', :skip_visibility_checks => true,
          :synthetic_contexts => true, :context => "course_#{@course.id}_all"
        }
        expect(response.body).to include(@teacher.name)
        expect(response.body).to include(@student.name)
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
        get 'recipients', params: {
          :context => "course_#{@course.id}",
          :synthetic_contexts => true
        }
        expect(response.body).to include('"name":"Course Sections"')
        get 'recipients', params: {
          :context => "course_#{@course.id}_sections",
          :synthetic_contexts => true
        }
        expect(response.body).to include('Section1')
        expect(response.body).not_to include('Section2')
      end

      it "should exclude non-messageable users" do
        get 'recipients', params: {
          :context => "course_#{@course.id}_students"
        }
        expect(response.body).to include('Student1')
        expect(response.body).not_to include('Student2')
      end
    end
  end

  describe "GET 'all_courses'" do
    before(:once) do
      @c1 = course_factory(course_name: 'foo', active_course: true)
      @c2 = course_factory(course_name: 'bar', active_course: true)
      @c2.update_attribute(:indexed, true)
    end

    it "returns indexed courses" do
      get 'all_courses'
      expect(assigns[:courses].map(&:id)).to eq [@c2.id]
    end

    it "searches" do
      @c1.update_attribute(:indexed, true)
      get 'all_courses', params: {search: 'foo'}
      expect(assigns[:courses].map(&:id)).to eq [@c1.id]
    end

    it "doesn't explode with non-string searches" do
      get 'all_courses', params: {search: {'foo' => 'bar'}}
      expect(assigns[:courses].map(&:id)).to eq []
    end

    it "does not cache XHR requests" do
      get 'all_courses', xhr: true
      expect(response.headers["Pragma"]).to eq "no-cache"
    end
  end

end
