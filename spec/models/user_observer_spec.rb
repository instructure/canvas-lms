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

describe UserObservationLink do
  let_once(:student) { user_factory }

  it 'should fail when there is not observer or observee' do
    expect { UserObservationLink.create_or_restore(student: nil, observer: student, root_account: Account.default) }.
      to raise_error(ArgumentError, 'student, observer and root_account are required')
  end

  it "should not allow a user to observe oneself" do
    expect { student.linked_observers << student }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'should restore deleted observees instead of creating a new one' do
    observer = user_with_pseudonym
    student.linked_observers << observer
    observee = observer.as_observer_observation_links.first
    observee.destroy

    re_observee = UserObservationLink.create_or_restore(observer: observer, student: student, root_account: Account.default)
    expect(observee.id).to eq re_observee.id
    expect(re_observee.workflow_state).to eq 'active'
  end

  it 'should restore deleted observer enrollments on "restore" (even if nothing about the observee changed)' do
    # i'm like 66% sure someone will complain about this
    student_enroll = student_in_course(:user => student)

    observer = user_with_pseudonym
    student.linked_observers << observer
    observer_enroll = observer.observer_enrollments.first
    observer_enroll.destroy

    UserObservationLink.create_or_restore(observer: observer, student: student, root_account: Account.default)
    expect(observer_enroll.reload).to_not be_deleted
  end

  it 'should create an observees when one does not exist' do
    observer = user_with_pseudonym
    re_observee = UserObservationLink.create_or_restore(observer: observer, student: student, root_account: Account.default)
    expect(re_observee).to eq student.as_student_observation_links.first
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
    student.linked_observers << observer

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
    UserObservationLink.create_or_restore(observer: observer, student: student, root_account: Account.default)
    observer.reload
    expect(enrollments.reload.map(&:workflow_state)).to eql ["active", "active"]
  end

  it "should be able to preload observers" do
    c1 = course_factory(active_all: true)
    e1 = student_in_course(:course => c1, :user => student)

    observer = user_with_pseudonym
    student.linked_observers << observer

    preloaded_student = User.where(:id => student).preload(:linked_observers).first
    expect(preloaded_student.association(:linked_observers).loaded?).to be_truthy
    expect(preloaded_student.linked_observers).to eq [observer]

    UserObservationLink.where(:user_id => student).update_all(:workflow_state => "deleted")
    expect(User.where(:id => student).preload(:linked_observers).first.linked_observers).to eq []
  end

  it "should enroll the observer in courses when the student is inactive" do
    c1 = course_factory(active_all: true)
    enroll = student_in_course(:course => c1, :user => student)
    enroll.deactivate

    observer = user_with_pseudonym
    student.linked_observers << observer

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
    student.linked_observers << observer

    uo = student.as_student_observation_links.first
    uo.destroy!

    student.reload
    expect(student.linked_observers).to be_empty

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
    student.linked_observers << observer

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
      student.linked_observers << @observer
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
        UserObservationLink.create_or_restore(observer: parent, student: student, root_account: Account.default)
      end
      expect(parent.enrollments.shard(parent).first.course).to eq course
    end

    it "creates enrollments for trusted accounts" do
      @shard2.activate do
        @other_account = Account.create!
        @parent = user_with_pseudonym(account: @other_account, active_all: true)
        UserObservationLink.create_or_restore(observer: @parent, student: student, root_account: @other_account)
      end
      pseudonym(@parent, :account => Account.default)
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([@other_account.id])
      course_factory(active_all: true)
      student_in_course(course: @course, user: student, active_all: true)
      expect(@parent.enrollments.shard(@parent).first.course).to eq @course
    end
  end

  context "root account restrictions" do
    before :once do
      @a1 = account_model
      @c1 = course_factory(account: @a1, active_all: true)
      @a2 = account_model
      @c2 = course_factory(account: @a2, active_all: true)
      @observer = user_with_pseudonym(account: @a1)
      pseudonym(@observer, account: @a2)
    end

    it "should only add the observer in courses on the same root account as the link when created" do
      e1 = student_in_course(course: @c1, user: student, active_all: true)
      e2 = student_in_course(course: @c2, user: student, active_all: true)
      UserObservationLink.create_or_restore(observer: @observer, student: student, root_account: @a1)
      expect(@observer.enrollments.pluck(:course_id)).to eq [@c1.id]
    end

    it "should only add observers linked on the same root account to a new student enrollment" do
      @observer2 = user_with_pseudonym(account: @a2)
      UserObservationLink.create_or_restore(observer: @observer, student: student, root_account: @a1)
      UserObservationLink.create_or_restore(observer: @observer2, student: student, root_account: @a2)
      e1 = student_in_course(course: @c1, user: student, active_all: true)
      expect(@observer.enrollments.pluck(:course_id)).to eq [@c1.id]
      expect(@observer2.enrollments).to be_empty
    end

    it "should only remove the observer in courses on the same root account as the link" do
      e1 = student_in_course(course: @c1, user: student, active_all: true)
      e2 = student_in_course(course: @c2, user: student, active_all: true)
      link1 = UserObservationLink.create_or_restore(observer: @observer, student: student, root_account: @a1)
      link2 = UserObservationLink.create_or_restore(observer: @observer, student: student, root_account: @a2)
      expect(@observer.enrollments.active.pluck(:course_id)).to match_array([@c1.id, @c2.id])
      link1.destroy
      expect(@observer.enrollments.active.pluck(:course_id)).to eq [@c2.id]
    end

    it "should only update observer enrollments linked on the same root account" do
      UserObservationLink.create_or_restore(observer: @observer, student: student, root_account: @a1)
      UserObservationLink.create_or_restore(observer: @observer, student: student, root_account: @a2)
      e1 = student_in_course(course: @c1, user: student, active_all: true)
      e2 = student_in_course(course: @c2, user: student, active_all: true)
      e1.destroy
      expect(@observer.enrollments.active.pluck(:course_id)).to eq [@c2.id]
    end
  end
end
