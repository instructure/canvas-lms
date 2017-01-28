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
    @course1 = course_factory(active_all: true)
    @student = user_factory
    @observer = user_factory
    @student_enrollment = @course1.enroll_student(@student)
    @observer_enrollment = @course1.enroll_user(@observer, 'ObserverEnrollment')
    @observer_enrollment.update_attribute(:associated_user_id, @student.id)

    @course2 = course_factory(active_all: true)
    @student_enrollment2 = @course2.enroll_student(@student)
    @observer_enrollment2 = @course2.enroll_user(@observer, 'ObserverEnrollment')
    @observer_enrollment2.update_attribute(:associated_user_id, @student.id)
  end

  describe 'observed_enrollments_for_courses' do
    it "retrieve observed enrollments for courses passed in" do
      expect(ObserverEnrollment.observed_enrollments_for_courses([@course1, @course2], @observer).sort)
        .to eq([@student_enrollment, @student_enrollment2].sort)
    end
  end

  describe 'observed_students' do
    it "should not fail if the observed has been deleted" do
      expect(ObserverEnrollment.observed_students(@course1, @observer)).to eq({ @student => [@student_enrollment]})
      @student_enrollment.destroy
      expect(ObserverEnrollment.observed_students(@course1, @observer)).to eq({})
    end
  end
  describe 'observed_student_ids_by_observer_id' do
    it "should return a properly formatted hash" do
      @observer_two = user_factory
      @observer_enrollment_two = @course1.enroll_user(@observer_two, 'ObserverEnrollment')
      expect(ObserverEnrollment
               .observed_student_ids_by_observer_id(@course1,
                                                    [@observer.id,@observer_two.id]))
        .to eq({@observer.id => [@student.id], @observer_two.id => []})
    end
  end

  context "notifications" do
    it "doesn't send enrollment notifications if already registered" do
      Notification.create!(:name => "Enrollment Notification")
      user_with_pseudonym(:active_all => true)
      e = @course1.enroll_user(@user, 'ObserverEnrollment')
      expect(e.messages_sent).to be_empty
    end

    it "does send enrollment notifications if not already registered" do
      Notification.create!(:name => "Enrollment Registration")
      user_with_pseudonym
      e = @course1.enroll_user(@user, 'ObserverEnrollment')
      expect(e.messages_sent).to_not be_empty
    end
  end
end
