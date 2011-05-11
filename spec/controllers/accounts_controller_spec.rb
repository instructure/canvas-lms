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

describe AccountsController do
  def account
    @account = @course.account
  end

  def cross_listed_course
    course_with_teacher_logged_in(:active_all => true)
    @account1 = account
    @account1.add_user(@user)
    @course1 = @course
    @course1.account = @account1
    @course1.save!
    @account2 = account
    @course2 = course
    @course2.account = @account2
    @course2.save!
    @course2.course_sections.first.crosslist_to_course(@course1)
    @course1.update_account_associations
    @course2.update_account_associations
  end

  describe "GET 'index'" do
    it "shouldn't show duplicates of courses" do
      cross_listed_course
      get 'show', :id => @account1.id
      assigns[:courses].should == [@course1]
    end
  end

  describe "GET 'courses'" do
    it "shouldn't show duplicates of courses" do
      cross_listed_course
      get 'courses', :account_id => @account1.id, :query => @course1.name
      assigns[:courses].should == [@course1]
      response.should be_redirect
    end
  end
end
