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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe CourseSection, "moving to new course" do
  
  it "should transfer enrollments to the new root account" do
    account1 = Account.create!(:name => "1")
    account2 = Account.create!(:name => "2")
    course1 = account1.courses.create!
    course2 = account2.courses.create!
    cs = course1.course_sections.create!
    u = User.create!
    u.register!
    e = course1.enroll_user(u, 'StudentEnrollment', :section => cs)
    e.workflow_state = 'active'
    e.save!
    course1.reload
    
    course1.course_sections.find_by_id(cs.id).should_not be_nil
    course2.course_sections.find_by_id(cs.id).should be_nil
    e.root_account.should eql(account1)
    cs.last_course.should be_nil
    
    cs.move_to_course(course2)
    course1.reload
    course2.reload
    cs.reload
    e.reload
    
    course1.course_sections.find_by_id(cs.id).should be_nil
    course2.course_sections.find_by_id(cs.id).should_not be_nil
    e.root_account.should eql(account2)
    cs.last_course.should eql(course1)
    
    cs.move_to_course(course1)
    course1.reload
    course2.reload
    cs.reload
    e.reload
    
    course1.course_sections.find_by_id(cs.id).should_not be_nil
    course2.course_sections.find_by_id(cs.id).should be_nil
    e.root_account.should eql(account1)
    cs.last_course.should eql(course2)

    cs.move_to_course(course1)
    course1.reload
    course2.reload
    cs.reload
    e.reload
    
    course1.course_sections.find_by_id(cs.id).should_not be_nil
    course2.course_sections.find_by_id(cs.id).should be_nil
    e.root_account.should eql(account1)
    cs.last_course.should eql(course2)
  end
  
end
