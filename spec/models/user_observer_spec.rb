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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe UserObserver do
  it "should enroll the observer in all pending/active courses" do
    student = user
    c1 = course(:active_all => true)
    e1 = student_in_course(:course => c1, :user => student)
    c2 = course(:active_all => true)
    e2 = student_in_course(:active_all => true, :course => c2, :user => student)
    c3 = course(:active_all => true)
    e3 = student_in_course(:active_all => true, :course => c3, :user => student)
    e3.complete!

    observer = user_with_pseudonym
    student.observers << observer

    enrollments = observer.observer_enrollments.sort_by(&:course_id)
    enrollments.size.should eql 2
    enrollments.map(&:course_id).should eql [c1.id, c2.id]
    enrollments.map(&:workflow_state).should eql ["invited", "active"]
  end

  it "should not enroll the observer in institutions where they lack a login" do
    student = user

    a1 = account_model
    c1 = course(account: a1, active_all: true)
    e1 = student_in_course(course: c1, user: student, active_all: true)

    a2 = account_model
    c2 = course(account: a2, active_all: true)
    e2 = student_in_course(course: c2, user: student, active_all: true)

    observer = user_with_pseudonym(account: a2)
    student.observers << observer

    enrollments = observer.observer_enrollments
    enrollments.size.should eql 1
    enrollments.map(&:course_id).should eql [c2.id]
  end
end