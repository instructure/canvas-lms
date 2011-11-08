#
# Copyright (C) 2011 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FavoritesController do

  before do
    # we need > 12 courses to even get the menu in the UI, so all behavior assumes at least 13
    @first_course = course_with_teacher(:active_all => true).course
    user_session(@user)
    11.times do |int|
      course = course_with_teacher :course_name => "Course #{int}", :user => @user, :active_all => true
    end
    @last_course = course_with_teacher(:course_name => "z last Course", :user => @user, :active_all => true).course
  end

  it 'should set the courses in the menu as favorites on first add, and add the new one' do
    post 'create', :favorite => {:context_type => 'Course', :context_id => @last_course.id}
    @user.favorites.length.should == 13
  end

  it 'should set the courses in the menu as favorites on first destroy, and destroy one they may have clicked' do
    id = @user.menu_courses.last.id
    post 'destroy', :context_type => 'Course', :id => id
    @user.favorites.by('Course').length.should == 11
  end

  it 'should destroy all favorites of a context type with the context type as the id' do
    fav = @user.favorites.create(:context => @last_course)
    @user.favorites.length.should == 1
    post 'destroy', :id => 'Course'
    @user.favorites.length.should == 0
  end

end
