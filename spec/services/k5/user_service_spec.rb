# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../helpers/k5_common"

describe K5::UserService do
  include K5Common

  before :once do
    @k5_account = Account.create!(parent_account_id: Account.default)
    course_with_teacher(active_all: true, account: @k5_account)
    @teacher1 = @teacher
    @student1 = student_in_course(context: @course).user
    toggle_k5_setting(@k5_account)
    @root_account = @course.root_account
  end

  describe "k5_user?" do
    it "caches the result after computing" do
      enable_cache do
        service = K5::UserService.new(@student1, @root_account, nil)
        expect(service).to receive(:user_has_association?).once
        service.send(:k5_user?)
        service.send(:k5_user?)
      end
    end

    it "does not use cached value if enrollments have been invalidated" do
      enable_cache(:redis_cache_store) do
        service = K5::UserService.new(@student1, @root_account, nil)
        expect(service).to receive(:user_has_association?).twice
        service.send(:k5_user?)
        @student1.clear_cache_key(:enrollments)
        service.send(:k5_user?)
      end
    end

    it "does not use cached value if account_users have been invalidated" do
      enable_cache(:redis_cache_store) do
        service = K5::UserService.new(@student1, @root_account, nil)
        expect(service).to receive(:user_has_association?).twice
        service.send(:k5_user?)
        @student1.clear_cache_key(:account_users)
        service.send(:k5_user?)
      end
    end

    it "caches the eligibility computation at the request level" do
      RequestCache.enable do
        service = K5::UserService.new(@student1, @root_account, nil)
        expect(service).to receive(:k5_disabled?).once
        expect(service.send(:k5_user?)).to be true
        expect(service.send(:k5_user?)).to be true
      end
    end

    it "returns true if associated with a k5 account" do
      service = K5::UserService.new(@student1, @root_account, nil)
      expect(service.send(:k5_user?)).to be_truthy
    end

    it "returns true if enrolled in a subaccount of a k5 account" do
      sub = Account.create!(parent_account_id: @k5_account)
      course_factory(account: sub)
      student_in_course(active_all: true)
      service = K5::UserService.new(@student, @root_account, nil)
      expect(service.send(:k5_user?)).to be true
    end

    it "returns false if all k5 enrollments are concluded" do
      @student1.enrollments.where(course_id: @course.id).take.complete
      service = K5::UserService.new(@student1, @root_account, nil)
      expect(service.send(:k5_user?)).to be false
    end

    it "returns false if not associated with a k5 account" do
      toggle_k5_setting(@k5_account, false)
      service = K5::UserService.new(@student1, @root_account, nil)
      expect(service.send(:k5_user?)).to be_falsey
    end

    it "returns false if a teacher or admin has opted-out of the k5 dashboard" do
      @teacher.preferences[:elementary_dashboard_disabled] = true
      @teacher.save!
      service = K5::UserService.new(@teacher, @root_account, nil)
      expect(service.send(:k5_user?)).to be_falsey
    end

    it "returns true for an admin without enrollments" do
      account_admin_user(account: @k5_account)
      service = K5::UserService.new(@admin, @root_account, nil)
      expect(service.send(:k5_user?)).to be true
    end

    it "ignores the disabled preference if check_disabled = false" do
      @teacher.preferences[:elementary_dashboard_disabled] = true
      @teacher.save!
      service = K5::UserService.new(@teacher, @root_account, nil)
      expect(service.send(:k5_user?, check_disabled: false)).to be_truthy
    end

    it "returns true even if a student has opted-out of the k5 dashboard" do
      @student1.preferences[:elementary_dashboard_disabled] = true
      @student1.save!
      service = K5::UserService.new(@student1, @root_account, nil)
      expect(service.send(:k5_user?)).to be_truthy
    end

    it "returns false if no current user" do
      service = K5::UserService.new(nil, @root_account, nil)
      expect(service).not_to receive(:user_has_association?)
      expect(service.send(:k5_user?)).to be_falsey
    end

    context "as an observer" do
      before :once do
        @observer = @teacher1
        @student = course_with_student(active_all: true).user
        @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: :active, associated_user_id: @student)
      end

      it "returns false for a k5 observer actively observing a non-k5 student" do
        service = K5::UserService.new(@observer, @root_account, @student)
        expect(service.send(:k5_user?)).to be_falsey
      end

      it "returns true for a k5 observer observing a non-k5 student if observer is selected" do
        service = K5::UserService.new(@observer, @root_account, nil)
        expect(service.send(:k5_user?)).to be_truthy
      end

      it "only considers courses where user is observing student" do
        k5_course = course_factory(account: @k5_account, active_all: true)
        k5_course.enroll_student(@student, enrollment_state: :active)
        service = K5::UserService.new(@observer, @root_account, @student)
        expect(service.send(:k5_user?)).to be_falsey
      end

      it "ignores a user's linked ObserverEnrollments when determining k5_user? for themself" do
        @observer.enrollments.not_of_observer_type.destroy_all
        classic_course = course_factory(active_all: true)
        classic_course.enroll_teacher(@observer, enrollment_state: :active)
        k5_course = course_factory(account: @k5_account, active_all: true)
        k5_course.enroll_student(@student, enrollment_state: :active)
        k5_course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: :active, associated_user_id: @student)

        service = K5::UserService.new(@observer, @root_account, nil)
        expect(service.send(:k5_user?)).to be_falsey
      end

      it "considers a user's unlinked ObserverEnrollments when determining k5_user? for themself" do
        @observer.enrollments.not_of_observer_type.destroy_all
        classic_course = course_factory(active_all: true)
        classic_course.enroll_teacher(@observer, enrollment_state: :active)
        k5_course = course_factory(account: @k5_account, active_all: true)
        k5_course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: :active)

        service = K5::UserService.new(@observer, @root_account, nil)
        expect(service.send(:k5_user?)).to be_truthy
      end

      it "returns true when a k5 student is selected, even if observer has disabled k5 dashboard" do
        toggle_k5_setting(@course.account)
        @observer.preferences[:elementary_dashboard_disabled] = true
        @observer.save!
        service = K5::UserService.new(@observer, @root_account, @student)
        expect(service.send(:k5_user?)).to be_truthy
      end

      context "with sharding" do
        specs_require_sharding

        before :once do
          @shard2.activate do
            @s2_k5_account = Account.create!
            toggle_k5_setting(@s2_k5_account)
          end
        end

        it "considers courses across shards where user is observing student" do
          @k5_course = course_factory(active_all: true, account: @s2_k5_account)
          @k5_course.enroll_student(@student, enrollment_state: :active)
          service = K5::UserService.new(@observer, @root_account, @student)
          expect(service.send(:k5_user?)).to be_falsey

          @k5_course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: :active, associated_user_id: @student)
          expect(service.send(:k5_user?)).to be_truthy
        end
      end
    end

    context "with sharding" do
      specs_require_sharding

      before :once do
        @shard2.activate do
          @student2 = User.create!
        end
        @course.enroll_student(@student2)
      end

      it "returns true for user from another shard if associated with a k5 account on current shard" do
        service = K5::UserService.new(@student2, @root_account, nil)
        expect(service.send(:k5_user?)).to be_truthy
      end

      it "returns true for a user with k5 enrollments on another shard" do
        @shard2.activate do
          service = K5::UserService.new(@student2, @root_account, nil)
          expect(service.send(:k5_user?)).to be_truthy
        end
      end

      it "returns true for a user with k5 enrollments on a subaccount of another shard" do
        toggle_k5_setting(@k5_account, false)
        @shard2.activate do
          subaccount = Account.default.sub_accounts.create!
          toggle_k5_setting(subaccount)
          @course2 = course_factory(account: subaccount)
          @course2.enroll_student(@student1)
          service = K5::UserService.new(@student1, @root_account, nil)
          expect(service.send(:k5_user?)).to be true
        end
      end

      it "returns true for an admin with an AccountUser on another shard" do
        admin = User.create!
        @shard2.activate do
          account_admin_user(user: admin, account: @k5_account)
          service = K5::UserService.new(admin, @root_account, nil)
          expect(service.send(:k5_user?)).to be true
        end
      end

      it "returns false for users on multiple shards with no k5 enrollments" do
        toggle_k5_setting(@k5_account, false)
        @shard2.activate do
          service = K5::UserService.new(@student2, @root_account, nil)
          expect(service.send(:k5_user?)).to be_falsey
        end
      end
    end
  end

  describe "use_classic_font?" do
    it "caches the result after computing" do
      enable_cache do
        service = K5::UserService.new(@student1, @root_account, nil)
        expect(service).to receive(:user_has_association?).once
        service.send(:use_classic_font?)
        service.send(:use_classic_font?)
      end
    end

    it "caches the eligibility computation at the request level" do
      RequestCache.enable do
        service = K5::UserService.new(@student1, @root_account, nil)
        expect(service).to receive(:currently_observing?).twice # once for use_classic_font?; once for k5_user?
        service.send(:use_classic_font?)
        service.send(:use_classic_font?)
      end
    end

    it "returns false if no user is provided" do
      toggle_k5_setting(@root_account)
      toggle_classic_font_setting(@root_account)
      service = K5::UserService.new(nil, @root_account, nil)
      expect(service.send(:use_classic_font?)).to be false
    end

    it "returns false if not a k5_user" do
      toggle_classic_font_setting(@k5_account)
      service = K5::UserService.new(@student1, @root_account, nil)
      allow(service).to receive(:k5_user?).and_return(false)
      expect(service.send(:use_classic_font?)).to be false
    end

    it "returns false if the user is not associated with a classic font k5 account" do
      service = K5::UserService.new(@student1, @root_account, nil)
      expect(service.send(:use_classic_font?)).to be false
    end

    it "returns true if the user is enrolled in a course in a classic font account" do
      toggle_classic_font_setting(@k5_account)
      service = K5::UserService.new(@student1, @root_account, nil)
      expect(service.send(:use_classic_font?)).to be true
    end

    it "returns true if the user is enrolled in a course that's in a subaccount of a classic font account" do
      toggle_k5_setting(@root_account)
      toggle_classic_font_setting(@root_account)
      service = K5::UserService.new(@student1, @root_account, nil)
      expect(service.send(:use_classic_font?)).to be true
    end

    it "returns false if an account is marked as a classic font account but its not a k5 account" do
      toggle_classic_font_setting(@root_account)
      service = K5::UserService.new(@student1, @root_account, nil)
      expect(service.send(:use_classic_font?)).to be false
    end

    describe "as an observer" do
      before :once do
        @observer = @teacher1
        @student = course_with_student(active_all: true).user
        @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: :active, associated_user_id: @student)
        toggle_classic_font_setting(@k5_account)
      end

      it "returns false for a k5 observer actively observing a non-k5 student" do
        service = K5::UserService.new(@observer, @root_account, @student)
        expect(service.send(:use_classic_font?)).to be_falsey
      end

      it "returns true for a k5 observer observing a non-k5 student if observer is selected" do
        service = K5::UserService.new(@observer, @root_account, nil)
        expect(service.send(:use_classic_font?)).to be_truthy
      end

      it "only considers courses where user is observing student" do
        k5_course = course_factory(account: @k5_account, active_all: true)
        k5_course.enroll_student(@student, enrollment_state: :active)
        service = K5::UserService.new(@observer, @root_account, @student)
        expect(service.send(:use_classic_font?)).to be_falsey
      end
    end
  end
end
