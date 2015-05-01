#
# Copyright (C) 2012 - 2015 Instructure, Inc.
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
  let_once(:student) { user }

  it "should not allow a user to observe oneself" do
    expect { student.observers << student}.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "should enroll the observer in all pending/active courses" do
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
    expect(enrollments.size).to eql 2
    expect(enrollments.map(&:course_id)).to eql [c1.id, c2.id]
    expect(enrollments.map(&:workflow_state)).to eql ["invited", "active"]
  end

  it "should not enroll the observer in institutions where they lack a login" do
    a1 = account_model
    c1 = course(account: a1, active_all: true)
    e1 = student_in_course(course: c1, user: student, active_all: true)

    a2 = account_model
    c2 = course(account: a2, active_all: true)
    e2 = student_in_course(course: c2, user: student, active_all: true)

    observer = user_with_pseudonym(account: a2)
    Pseudonym.any_instance.stubs(:works_for_account?).returns(false)
    Pseudonym.any_instance.stubs(:works_for_account?).with(a2, true).returns(true)
    student.observers << observer

    enrollments = observer.observer_enrollments
    expect(enrollments.size).to eql 1
    expect(enrollments.map(&:course_id)).to eql [c2.id]
  end

  describe 'when adding a custom (second) student enrollment' do
    before(:once) do
      @custom_student_role = custom_student_role('CustomStudent', account: Account.default)
      @course = course active_all: true
      @student_enrollment = student_in_course(course: @course, user: student, active_all: true)
      @observer = user_with_pseudonym
      student.observers << @observer
      @observer_enrollment = @observer.enrollments.where(type: 'ObserverEnrollment', course_id: @course, associated_user_id: student).first
      expect(@observer_enrollment).not_to be_nil
    end

    it "should not attempt to add a duplicate observer enrollment" do
      expect {
        @course.enroll_student student, role: @custom_student_role
      }.not_to raise_error
    end

    it "should recycle an existing deleted observer enrollment" do
      @observer_enrollment.destroy
      expect {
        @course.enroll_student student, role: @custom_student_role
      }.not_to raise_error
      expect(@observer_enrollment.reload).to be_invited
    end
  end
end
