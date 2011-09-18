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

describe UsersController do

  it "should filter account users by term" do
    a = Account.default
    u = user(:active_all => true)
    a.add_user(u)
    user_session(@user)
    t1 = a.default_enrollment_term
    t2 = a.enrollment_terms.create!(:name => 'Term 2')

    e1 = course_with_student(:active_all => true)
    c1 = e1.course
    c1.update_attributes!(:enrollment_term => t1)
    e2 = course_with_student(:active_all => true)
    c2 = e2.course
    c2.update_attributes!(:enrollment_term => t2)
    c3 = course_with_student(:active_all => true, :user => e1.user).course
    c3.update_attributes!(:enrollment_term => t1)

    User.update_account_associations(User.all.map(&:id))

    get 'index', :account_id => a.id
    assigns[:users].map(&:id).sort.should == [u, e1.user, c1.teachers.first, e2.user, c2.teachers.first, c3.teachers.first].map(&:id).sort

    get 'index', :account_id => a.id, :enrollment_term_id => t1.id
    assigns[:users].map(&:id).sort.should == [e1.user, c1.teachers.first, c3.teachers.first].map(&:id).sort # 1 student, enrolled twice, and 2 teachers

    get 'index', :account_id => a.id, :enrollment_term_id => t2.id
    assigns[:users].map(&:id).sort.should == [e2.user, c2.teachers.first].map(&:id).sort
  end

  it "should not include deleted courses in manageable courses" do
    course_with_teacher_logged_in(:course_name => "MyCourse1", :active_all => 1)
    course1 = @course
    course1.destroy!
    course_with_teacher(:course_name => "MyCourse2", :user => @teacher, :active_all => 1)
    course2 = @course

    get 'manageable_courses', :user_id => @teacher.id, :query => "MyCourse"
    response.should be_success

    courses = ActiveSupport::JSON.decode(response.body)
    courses['data'].map { |c| c['course']['id'] }.should == [course2.id]
  end

end
