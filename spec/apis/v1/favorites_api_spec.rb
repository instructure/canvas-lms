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
      json.size.should eql(6)
      json[0]['id'].should eql @courses[0].id
      json[0]['name'].should eql @courses[0].name
      json[0]['course_code'].should eql @courses[0].course_code
      json[0]['enrollments'][0]['type'].should eql 'student'
      json.collect {|row| row["id"]}.sort.should eql(@user.menu_courses.collect{|c| c[:id]}.sort)

      @user.favorites.size.should be_zero
    end
  end

  context "explicit favorites" do
    before :once do
      @courses[0...3].each do |course|
        @user.favorites.build(:context => course)
      end
      @user.save
    end

    it "should list favorite courses" do
      json = api_call(:get, "/api/v1/users/self/favorites/courses", :controller=>"favorites", :action=>"list_favorite_courses", :format=>"json")
      json.size.should eql(3)
      json[0]['id'].should eql @courses[0].id
      json[0]['name'].should eql @courses[0].name
      json[0]['course_code'].should eql @courses[0].course_code
      json[0]['enrollments'][0]['type'].should eql 'student'
      json.collect {|row| row["id"]}.sort.should eql(@user.favorites.by('Course').collect{|c| c[:context_id]}.sort)
    end

    it "should add a course to favorites" do
      @user.favorites.by("Course").destroy_all

      # add some new courses, and fave one
      course6 = course_with_student(:course_name => "Course 6", :user => @user, :active_all => true).course
      course7 = course_with_student(:course_name => "Course 7", :user => @user, :active_all => true).course
      json = api_call(:post, "/api/v1/users/self/favorites/courses/#{course6.id}",
                      {:controller=>"favorites", :action=>"add_favorite_course", :format=>"json", :id=>"#{course6.id}"})
      json["context_id"].should eql(course6.id)

      # now favorites should include the implicit courses from before, plus the one we faved
      @user.reload
      @user.favorites.size.should eql(1)
    end

    it "should create favorites from implicit favorites when removing a course" do
      @user.favorites.by("Course").destroy_all

      # remove a course from favorites
      json = api_call(:delete, "/api/v1/users/self/favorites/courses/#{@courses[0].id}",
                      {:controller=>"favorites", :action=>"remove_favorite_course", :format=>"json", :id=>"#{@courses[0].id}"})
      json["context_id"].should eql(@courses[0].id)

      # now favorites should include the implicit courses from before, minus the one we removed
      @user.reload
      @user.favorites.size.should eql(5)
    end

    it "should remove a course from favorites" do
      @user.favorites.size.should eql(3)

      # remove a course from favorites
      json = api_call(:delete, "/api/v1/users/self/favorites/courses/#{@courses[0].id}",
                      {:controller=>"favorites", :action=>"remove_favorite_course", :format=>"json", :id=>"#{@courses[0].id}"})
      json["context_id"].should eql(@courses[0].id)

      # now favorites should include the implicit courses from before, minus the one we removed
      @user.reload
      @user.favorites.size.should eql(2)
    end

    it "should not create a duplicate by fav'ing an already faved course" do
      @user.favorites.size.should eql(3)
      json = api_call(:post, "/api/v1/users/self/favorites/courses/#{@courses[0].id}",
                      {:controller=>"favorites", :action=>"add_favorite_course", :format=>"json", :id=>"#{@courses[0].id}"})
      json["context_id"].should eql(@courses[0].id)
      @user.reload
      @user.favorites.size.should eql(3)
    end

    it "should return an empty hash when removing a non-faved course" do
      json = api_call(:delete, "/api/v1/users/self/favorites/courses/#{@courses[5].id}",
                      {:controller=>"favorites", :action=>"remove_favorite_course", :format=>"json", :id=>"#{@courses[5].id}"})
      json.size.should be_zero
    end

    it "should reset favorites" do
      @user.favorites.size.should_not be_zero
      api_call(:delete, "/api/v1/users/self/favorites/courses",
               {:controller=>"favorites", :action=>"reset_course_favorites", :format=>"json"})
      @user.reload
      @user.favorites.size.should be_zero
    end
  end

end
