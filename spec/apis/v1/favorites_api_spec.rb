#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Favorites API", type: :request do
  before :once do
    @courses = []
    @courses << course_with_student(:active_all => true, :course_name => "Course 0").course
    5.times do |x|
      @courses << course_with_student(:course_name => "Course #{x + 1}", :user => @user, :active_all => true).course
    end
  end

  context "implicit favorites" do
    it "should list favorite courses" do
      json = api_call(:get, "/api/v1/users/self/favorites/courses", :controller=>"favorites", :action=>"list_favorite_courses", :format=>"json")
      expect(json.size).to eql(6)
      expect(json[0]['id']).to eql @courses[0].id
      expect(json[0]['name']).to eql @courses[0].name
      expect(json[0]['course_code']).to eql @courses[0].course_code
      expect(json[0]['enrollments'][0]['type']).to eql 'student'
      expect(json.collect {|row| row["id"]}.sort).to eql(@user.menu_courses.collect{|c| c[:id]}.sort)

      expect(@user.favorites.size).to be_zero
    end

    context "observed users" do
      before :once do
        @observer_enrollment = course_with_observer(active_all: true)
        @observer = @user
        @courses << @course
        @observer_course = @course
        @observed_student = create_users(1, return_type: :record).first
        @student_enrollment =
          @observer_course.enroll_student(@observed_student,
                                          :enrollment_state => 'active')
        @assigned_observer_enrollment =
          @observer_course.enroll_user(@observer, "ObserverEnrollment",
                                       :associated_user_id => @observed_student.id)
        @assigned_observer_enrollment.accept
      end

      it "includes observed users" do
        json = api_call_as_user(@observer, :get,
                                "/api/v1/users/self/favorites/courses?include[]=observed_users",
                                :controller=>"favorites", :include => [ "observed_users" ],
                                :action=>"list_favorite_courses", :format=>"json")

        expect(json[0]['enrollments']).to match_array [{
           "type" => "observer",
           "role" => @assigned_observer_enrollment.role.name,
           "role_id" => @assigned_observer_enrollment.role.id,
           "user_id" => @assigned_observer_enrollment.user_id,
           "enrollment_state" => "active",
           "associated_user_id" => @observed_student.id
         }, {
           "type" => "observer",
           "role" => @observer_enrollment.role.name,
           "role_id" => @observer_enrollment.role.id,
           "user_id" => @observer_enrollment.user_id,
           "enrollment_state" => "active"
         }, {
           "type" => "student",
           "role" => @student_enrollment.role.name,
           "role_id" => @student_enrollment.role.id,
           "user_id" => @student_enrollment.user_id,
           "enrollment_state" => "active"
         }]
      end
    end
  end

  context "explicit favorites" do
    before :once do
      @courses[0...2].each do |course|
        @user.favorites.build(:context => course) # these basically do nothing now
      end
      @user.save
    end

    it "should list favorite courses" do
      @courses[3...6].each do |course|
        Favorite.hide_context(@user, course)
      end
      json = api_call(:get, "/api/v1/users/self/favorites/courses", :controller=>"favorites", :action=>"list_favorite_courses", :format=>"json")
      expect(json.size).to eql(3)
      expect(json[0]['id']).to eql @courses[0].id
      expect(json[0]['name']).to eql @courses[0].name
      expect(json[0]['course_code']).to eql @courses[0].course_code
      expect(json[0]['enrollments'][0]['type']).to eql 'student'
      expect(json.collect {|row| row["id"]}).to match_array(@courses[0...3].map(&:id))
    end

    it "should add a course to favorites" do
      @user.favorites.by("Course").destroy_all

      # add some new courses, and fave one
      course6 = course_with_student(:course_name => "Course 6", :user => @user, :active_all => true).course
      course7 = course_with_student(:course_name => "Course 7", :user => @user, :active_all => true).course
      json = api_call(:post, "/api/v1/users/self/favorites/courses/#{course6.id}",
                      {:controller=>"favorites", :action=>"add_favorite_course", :format=>"json", :id=>"#{course6.id}"})
      expect(json["context_id"]).to eql(course6.id)

      # favorites should be empty still because now everything is already a favorite by default
      @user.reload
      expect(@user.favorites.size).to eql(0)
    end

    it "should remove a course from favorites" do
      expect(@user.favorites.size).to eql(2)

      # remove a course from favorites
      json = api_call(:delete, "/api/v1/users/self/favorites/courses/#{@courses[0].id}",
                      {:controller=>"favorites", :action=>"remove_favorite_course", :format=>"json", :id=>"#{@courses[0].id}"})
      expect(json["context_id"]).to eql(@courses[0].id)

      @user.reload

      # still shouldn't change the number of favorites
      expect(@user.favorites.size).to eql(2)
      hidden_fav = @user.favorites.detect{|f| f.context == @courses[0]}
      expect(hidden_fav).to be_hidden
    end

    it "should remove an implicitly favorited course from favorites" do
      @user.favorites.by("Course").destroy_all

      # remove a course from favorites
      json = api_call(:delete, "/api/v1/users/self/favorites/courses/#{@courses[0].id}",
        {:controller=>"favorites", :action=>"remove_favorite_course", :format=>"json", :id=>"#{@courses[0].id}"})
      expect(json["context_id"]).to eql(@courses[0].id)

      @user.reload

      # should create a hidden "favorite"
      expect(@user.favorites.size).to eql(1)
      hidden_fav = @user.favorites.detect{|f| f.context == @courses[0]}
      expect(hidden_fav).to be_hidden
    end

    it "should not create a duplicate by fav'ing an already faved course" do
      expect(@user.favorites.size).to eql(2)
      json = api_call(:post, "/api/v1/users/self/favorites/courses/#{@courses[0].id}",
                      {:controller=>"favorites", :action=>"add_favorite_course", :format=>"json", :id=>"#{@courses[0].id}"})
      expect(json["context_id"]).to eql(@courses[0].id)
      @user.reload
      expect(@user.favorites.size).to eql(2)
    end

    it "should return an empty hash when removing a non-faved course" do
      Favorite.hide_context(@user, @courses[5])
      json = api_call(:delete, "/api/v1/users/self/favorites/courses/#{@courses[5].id}",
                      {:controller=>"favorites", :action=>"remove_favorite_course", :format=>"json", :id=>"#{@courses[5].id}"})
      expect(json.size).to be_zero
    end

    it "should reset favorites" do
      expect(@user.favorites.size).not_to be_zero
      api_call(:delete, "/api/v1/users/self/favorites/courses",
               {:controller=>"favorites", :action=>"reset_course_favorites", :format=>"json"})
      @user.reload
      expect(@user.favorites.hidden.count).to be_zero
    end
  end

  context "group favorites" do
    before :each do
      @user = user_model
      @context = course_model
      @group_fave = Group.create!(:name=>"group1", :context=>@context)
      @group_not_fave = Group.create!(:name=>"group2", :context=>@context)
      @group_not_yet_fave= Group.create!(:name=>"group3", :context=>@context)
      @group_fave.add_user(@user)
      @group_not_fave.add_user(@user)
      @group_not_yet_fave.add_user(@user)
      @user.favorites.build(:context => @group_fave)
      @user.save
    end
    it "add favorite group" do
      api_call(:post, "/api/v1/users/self/favorites/groups/#{@group_not_yet_fave.id}",
               :controller=>"favorites", :action=>"add_favorite_group", :format=>"json", :id=>@group_not_yet_fave.id)
      expect(@user.favorites.size).to eql(1) # already implicitly favorited
    end

    it "lists favorite groups" do
      Favorite.hide_context(@user, @group_not_fave)
      Favorite.hide_context(@user, @group_not_yet_fave)
      json = api_call(:get, "/api/v1/users/self/favorites/groups",
                      :controller=>"favorites", :action=>"list_favorite_groups", :format=>"json")
      expect(json.size).to eq 1
      expect(json[0]['id']).to eql @group_fave.id
    end

    it "clears favorite groups" do
      group_fave_2 = Group.create!(:name=>"new_fave", :context=>@context)
      group_fave_2.add_user(@user)
      api_call(:delete, "/api/v1/users/self/favorites/groups/#{group_fave_2.id}",
               :controller=>"favorites", :action=>"remove_favorite_group", :format=>"json", :id=>group_fave_2.id)
      expect(@user.favorites.hidden.size).to eql(1)

      api_call(:delete, "/api/v1/users/self/favorites/groups",
               :controller=>"favorites", :action=>"reset_group_favorites", :format=>"json")
      expect(@user.favorites.hidden.size).to eql(0)
    end

    it "deletes one favorite group" do
      json = api_call(:delete, "/api/v1/users/self/favorites/groups/#{@group_fave.id}",
                      :controller=>"favorites", :action=>"remove_favorite_group", :format=>"json", :id=>@group_fave.id)
      expect(json['context_type']).to eql("Group")
    end
  end

end
