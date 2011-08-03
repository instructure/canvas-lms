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

describe "navigation" do
  it "should show enrollment terms when someone has multiple courses with the same name" do
    @account = Account.default
    user_with_pseudonym
    course_with_teacher(:course_name => "Course 1", :user => @user)
    course_with_teacher(:course_name => "Course 1", :user => @user)
    term1 = @account.enrollment_terms.create!(:name => "Spring Term")
    course_with_teacher(:course_name => "Course 2", :user => @user); @course.enrollment_term = term1; @course.save!
    course_with_teacher(:course_name => "Course 3", :user => @user); @course.enrollment_term = term1; @course.save!
    term2 = @account.enrollment_terms.create!(:name => "Summer Term")
    course_with_teacher(:course_name => "Course 3", :user => @user); @course.enrollment_term = term2; @course.save!
    
    user_session(@user, @pseudonym)
    
    get "/"
    page = Nokogiri::HTML(response.body)
    list = page.css(".menu-item-drop-column-list li")
    list[0].text.should match /Summer Term/m # course 3, Summer Term
    list[1].text.should match /Spring Term/m # course 3, Spring Term
    list[2].text.should_not match /Term/ # don't show term cause it doesn't have a name collision
    list[3].text.should_not match /Term/ # don't show term cause it's the default term
    list[4].text.should_not match /Term/ # "
  end
end


