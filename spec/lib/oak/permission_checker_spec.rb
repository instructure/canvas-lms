# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe Oak::PermissionChecker do
  describe ".user_permitted?" do
    let_once(:account) { Account.default }

    context "when user is nil" do
      it "returns false" do
        expect(Oak::PermissionChecker.user_permitted?(nil, account)).to be false
      end
    end

    context "when root_account is nil" do
      let_once(:user) { user_model }

      it "returns false" do
        expect(Oak::PermissionChecker.user_permitted?(user, nil)).to be false
      end
    end

    context "with legacy ignite_agent_enabled feature flag" do
      before do
        account.enable_feature!(:ignite_agent_enabled)
      end

      context "when user has manage_account_settings permission" do
        let_once(:admin_user) { account_admin_user(account:) }

        it "returns true" do
          expect(Oak::PermissionChecker.user_permitted?(admin_user, account)).to be true
        end
      end

      context "when user has ignite_agent_enabled_for_user feature flag" do
        let_once(:user) { user_model }

        before do
          user.enable_feature!(:ignite_agent_enabled_for_user)
        end

        it "returns true" do
          expect(Oak::PermissionChecker.user_permitted?(user, account)).to be true
        end
      end

      context "when user has neither permission" do
        let_once(:user) { user_model }

        it "returns false" do
          expect(Oak::PermissionChecker.user_permitted?(user, account)).to be false
        end
      end
    end

    context "with oak_for_admins feature flag" do
      before do
        account.enable_feature!(:oak_for_admins)
      end

      context "when user has access_oak permission" do
        let_once(:admin_user) do
          account_admin_user_with_role_changes(
            role_changes: {
              manage_account_settings: false,
              access_oak: true
            },
            account:,
            role: Role.get_built_in_role("AccountMembership", root_account_id: account.id)
          )
        end

        it "returns true" do
          expect(Oak::PermissionChecker.user_permitted?(admin_user, account)).to be true
        end
      end

      context "when user does not have access_oak permission" do
        let_once(:admin_user) do
          account_admin_user_with_role_changes(
            role_changes: {
              manage_account_settings: false,
              access_oak: false
            },
            account:,
            role: Role.get_built_in_role("AccountMembership", root_account_id: account.id)
          )
        end

        it "returns false" do
          expect(Oak::PermissionChecker.user_permitted?(admin_user, account)).to be false
        end
      end

      context "when user is not an admin" do
        let_once(:user) { user_model }

        it "returns false" do
          expect(Oak::PermissionChecker.user_permitted?(user, account)).to be false
        end
      end
    end

    context "with oak_for_teachers feature flag" do
      let_once(:course) { course_factory(active_all: true, account:) }
      let_once(:teacher) { user_model }

      before do
        account.enable_feature!(:oak_for_teachers)
        course.enroll_teacher(teacher, enrollment_state: "active")
      end

      context "when user has access_oak_teacher permission" do
        before do
          teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: account.id)
          account.role_overrides.create!(permission: :access_oak_teacher, role: teacher_role, enabled: true)
        end

        it "returns true" do
          expect(Oak::PermissionChecker.user_permitted?(teacher, account)).to be true
        end
      end

      context "when user does not have access_oak_teacher permission" do
        it "returns false" do
          expect(Oak::PermissionChecker.user_permitted?(teacher, account)).to be false
        end
      end

      context "when user is not a teacher" do
        let_once(:student) { user_model }

        before do
          course.enroll_student(student, enrollment_state: "active")
        end

        it "returns false" do
          expect(Oak::PermissionChecker.user_permitted?(student, account)).to be false
        end
      end

      context "when user has no courses in the account" do
        let_once(:user_without_course) { user_model }

        it "returns false" do
          expect(Oak::PermissionChecker.user_permitted?(user_without_course, account)).to be false
        end
      end
    end

    context "when no feature flags are enabled" do
      let_once(:user) { user_model }

      it "returns false" do
        expect(Oak::PermissionChecker.user_permitted?(user, account)).to be false
      end
    end

    context "with multiple feature flags enabled" do
      let_once(:teacher) { user_model }
      let_once(:course) { course_factory(active_all: true, account:) }

      before do
        account.enable_feature!(:ignite_agent_enabled)
        account.enable_feature!(:oak_for_admins)
        account.enable_feature!(:oak_for_teachers)
        course.enroll_teacher(teacher, enrollment_state: "active")
      end

      context "when user qualifies through legacy feature" do
        before do
          teacher.enable_feature!(:ignite_agent_enabled_for_user)
        end

        it "returns true via legacy check" do
          expect(Oak::PermissionChecker.user_permitted?(teacher, account)).to be true
        end
      end

      context "when user qualifies through oak_for_teachers" do
        before do
          teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: account.id)
          account.role_overrides.create!(permission: :access_oak_teacher, role: teacher_role, enabled: true)
        end

        it "returns true via oak_for_teachers check" do
          expect(Oak::PermissionChecker.user_permitted?(teacher, account)).to be true
        end
      end
    end
  end
end
