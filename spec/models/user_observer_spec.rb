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

    observer = user
    student.observers << observer

    enrollments = observer.observer_enrollments.sort_by(&:course_id)
    enrollments.size.should eql 2
    enrollments.map(&:course_id).should eql [c1.id, c2.id]
    enrollments.map(&:workflow_state).should eql ["invited", "active"]
  end
end