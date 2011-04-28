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
    a.add_user(user(:active_all => true))
    user_session(@user)
    t1 = a.default_enrollment_term
    t2 = a.enrollment_terms.create!(:name => 'Term 2')
    c1 = course_with_student(:active_all => true).course
    c1.update_attributes!(:enrollment_term => t1)
    c2 = course_with_student(:active_all => true).course
    c2.update_attributes!(:enrollment_term => t2)
    User.update_account_associations(User.all.map(&:id))

    get 'index', :account_id => a.id
    assigns[:users].size.should == 4 # 2 students, 2 teachers

    get 'index', :account_id => a.id, :enrollment_term_id => t1.id
    assigns[:users].size.should == 2 # 1 students, 1 teachers
    get 'index', :account_id => a.id, :enrollment_term_id => t2.id
    assigns[:users].size.should == 2 # 1 students, 1 teachers
  end

end
