#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe UserObserver do
  let_once(:student) { user_factory }

  it 'should fail when there is not observer or observee' do
    expect { UserObserver.create_or_restore(observee: nil, observer: student) }.
      to raise_error(ArgumentError, 'observee and observer are required')
  end

  it "should not allow a user to observe oneself" do
    expect { student.observers << student }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'should restore deleted observees instead of creating a new one' do
    observer = user_with_pseudonym
    student.observers << observer
    observee = observer.user_observees.first
    observee.destroy

    re_observee = UserObserver.create_or_restore(observer: observer, observee: student)
    expect(observee.id).to eq re_observee.id
    expect(re_observee.workflow_state).to eq 'active'
  end

  it 'should restore deleted observer enrollments on "restore" (even if nothing about the observee changed)' do
    # i'm like 66% sure someone will complain about this
    student_enroll = student_in_course(:user => student)

    observer = user_with_pseudonym
    student.observers << observer
    observer_enroll = observer.observer_enrollments.first
    observer_enroll.destroy

    UserObserver.create_or_restore(observer: observer, observee: student)
    expect(observer_enroll.reload).to_not be_deleted
  end

  it 'should create an observees when one does not exist' do
    observer = user_with_pseudonym
    re_observee = UserObserver.create_or_restore(observer: observer, observee: student)
    expect(re_observee).to eq student.user_observers.first
  end

  it "should enroll the observer in all pending/active courses and restore them after destroy" do
    c1 = course_factory(active_all: true)
    e1 = student_in_course(:course => c1, :user => student)
    c2 = course_factory(active_all: true)
    e2 = student_in_course(:active_all => true, :course => c2, :user => student)
    c3 = course_factory(active_all: true)
    e3 = student_in_course(:active_all => true, :course => c3, :user => student)
    e3.complete!

    observer = user_with_pseudonym
    student.observers << observer

    enrollments = observer.observer_enrollments.order(:course_id)
    expect(enrollments.size).to eql 2
    expect(enrollments.map(&:course_id)).to eql [c1.id, c2.id]
    expect(enrollments.map(&:workflow_state)).to eql ["active", "active"]
    observer.destroy
    expect(enrollments.reload.map(&:workflow_state)).to eql ["deleted", "deleted"]
    observer.workflow_state = 'registered'
    observer.save!
    p = observer.pseudonyms.first
    p.workflow_state = 'active'
    p.save!
    UserObserver.create_or_restore(observer: observer, observee: student)
    observer.reload
    expect(enrollments.reload.map(&:workflow_state)).to eql ["active", "active"]
  end

  it "should be able to preload observers" do
    c1 = course_factory(active_all: true)
    e1 = student_in_course(:course => c1, :user => student)

    observer = user_with_pseudonym
    student.observers << observer

    preloaded_student = User.where(:id => student).preload(:observers).first
    expect(preloaded_student.association(:observers).loaded?).to be_truthy
    expect(preloaded_student.observers).to eq [observer]

    UserObserver.where(:user_id => student).update_all(:workflow_state => "deleted")
    expect(User.where(:id => student).preload(:observers).first.observers).to eq []
  end

  it "should enroll the observer in courses when the student is inactive" do
    c1 = course_factory(active_all: true)
    enroll = student_in_course(:course => c1, :user => student)
    enroll.deactivate

    observer = user_with_pseudonym
    student.observers << observer

    o_enroll = observer.observer_enrollments.first
    expect(o_enroll).to be_inactive

    o_enroll.destroy_permanently!
    enroll.reactivate # it should recreate it

    new_o_enroll = observer.observer_enrollments.first
    expect(new_o_enroll).to be_active
  end

  it "should not enroll the observer if the user_observer record is deleted" do
    c1 = course_factory(active_all: true)

    observer = user_with_pseudonym
    student.observers << observer

    uo = student.user_observers.first
    uo.destroy!

    student.reload
    expect(student.observers).to be_empty

    enroll = student_in_course(:course => c1, :user => student)

    expect(observer.observer_enrollments.first).to be_nil
  end

  it "should not enroll the observer in institutions where they lack a login" do
    unless has_sharding?
      skip 'Sharding specs fail without additional support from a multi-tenancy plugin'
    end

    a1 = account_model
    c1 = course_factory(account: a1, active_all: true)
    e1 = student_in_course(course: c1, user: student, active_all: true)

    a2 = account_model
    c2 = course_factory(account: a2, active_all: true)
    e2 = student_in_course(course: c2, user: student, active_all: true)

    observer = user_with_pseudonym(account: a2)
    allow(@pseudonym).to receive(:works_for_account?).and_return(false)
    allow(@pseudonym).to receive(:works_for_account?).with(a2, true).and_return(true)
    student.observers << observer

    enrollments = observer.observer_enrollments
    expect(enrollments.size).to eql 1
    expect(enrollments.map(&:course_id)).to eql [c2.id]
  end

  describe 'when adding a custom (second) student enrollment' do
    before(:once) do
      @custom_student_role = custom_student_role('CustomStudent', account: Account.default)
      @course = course_factory active_all: true
      @student_enrollment = student_in_course(course: @course, user: student, active_all: true)
      @observer = user_with_pseudonym
      student.observers << @observer
      @observer_enrollment = @observer.enrollments.where(type: 'ObserverEnrollment', course_id: @course, associated_user_id: student).first
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
      expect(@observer_enrollment.reload).to be_active
    end
  end

  context "sharding" do
    specs_require_sharding

    it "creates enrollments for cross-shard users" do
      course = course_factory(active_all: true)
      student_in_course(course: @course, user: student, active_all: true)

      parent = nil
      @shard2.activate do
        parent = user_with_pseudonym(account: course.account, active_all: true)
        UserObserver.create_or_restore(observer: parent, observee: student)
      end
      expect(parent.enrollments.shard(parent).first.course).to eq course
    end
  end
end
