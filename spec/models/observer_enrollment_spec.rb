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

describe ObserverEnrollment do
  before do
    course(:active_all => 1)
    @student = user
    @observer = user
    @student_enrollment = @course.enroll_student(@student)
    @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment')
    @observer_enrollment.update_attribute(:associated_user_id, @student.id)
  end
  describe 'observed_students' do
    it "should not fail if the observed has been deleted" do
      ObserverEnrollment.observed_students(@course, @observer).should == { @student => [@student_enrollment]}
      @student_enrollment.destroy
      ObserverEnrollment.observed_students(@course, @observer).should == {}
    end
  end
  describe 'observed_student_ids_by_observer_id' do
    it "should return a properly formatted hash" do
      @observer_two = user
      @observer_enrollment_two = @course.enroll_user(@observer_two, 'ObserverEnrollment')
      ObserverEnrollment.observed_student_ids_by_observer_id(@course, [@observer.id,@observer_two.id]).should == {@observer.id => [@student.id], @observer_two.id => []}
    end
  end
end
