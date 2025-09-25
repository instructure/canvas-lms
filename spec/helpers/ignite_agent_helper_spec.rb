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

require "spec_helper"

describe IgniteAgentHelper do
  include IgniteAgentHelper

  let_once(:user) { user_factory(active_all: true) }
  let_once(:account) { Account.default }
  let_once(:course) { course_factory(account:) }

  before do
    @domain_root_account = account
    @current_user = user
    allow(Services::IgniteAgent).to receive_messages(
      launch_url: "https://ignite.example.com/launch",
      backend_url: "https://ignite.example.com/api"
    )
  end

  describe "#add_ignite_agent_bundle" do
    context "when no user is logged in" do
      before do
        @current_user = nil
      end

      it "does not add the ignite agent bundle" do
        expect(self).not_to receive(:js_bundle)
        expect(self).not_to receive(:remote_env)

        add_ignite_agent_bundle
      end
    end

    context "when ignite_agent_enabled feature is disabled" do
      before do
        account.disable_feature!(:ignite_agent_enabled)
      end

      it "does not add the ignite agent bundle" do
        expect(self).not_to receive(:js_bundle)
        expect(self).not_to receive(:remote_env)

        add_ignite_agent_bundle
      end
    end

    context "when ignite_agent_enabled feature is enabled" do
      before do
        account.enable_feature!(:ignite_agent_enabled)
      end

      context "when user has only student enrollments" do
        before do
          course.enroll_student(user, enrollment_state: "active")
          allow(self).to receive(:user_has_only_student_enrollments?).with(user).and_return(true)
        end

        it "does not add the ignite agent bundle" do
          expect(self).not_to receive(:js_bundle)
          expect(self).not_to receive(:remote_env)

          add_ignite_agent_bundle
        end
      end

      context "when user does not have only student enrollments" do
        before do
          allow(self).to receive(:user_has_only_student_enrollments?).with(user).and_return(false)
        end

        it "adds the ignite agent bundle and remote env" do
          expect(self).to receive(:js_bundle).with(:ignite_agent)
          expect(self).to receive(:remote_env).with(
            ignite_agent: {
              launch_url: "https://ignite.example.com/launch",
              backend_url: "https://ignite.example.com/api"
            }
          )

          add_ignite_agent_bundle
        end
      end
    end
  end

  describe "#user_has_only_student_enrollments?" do
    context "when user has admin roles" do
      before do
        account.account_users.create!(user:, role: admin_role)
      end

      it "returns false" do
        expect(user_has_only_student_enrollments?(user)).to be false
      end
    end

    context "when user has no enrollments" do
      it "returns false" do
        expect(user_has_only_student_enrollments?(user)).to be false
      end
    end

    context "when user has only student enrollments" do
      before do
        course.enroll_student(user, enrollment_state: "active")
      end

      it "returns true" do
        expect(user_has_only_student_enrollments?(user)).to be true
      end
    end

    context "when user has mixed enrollment types" do
      before do
        course.enroll_student(user, enrollment_state: "active")
        course.enroll_teacher(user, enrollment_state: "active")
      end

      it "returns false" do
        expect(user_has_only_student_enrollments?(user)).to be false
      end
    end

    context "when user has only teacher enrollments" do
      before do
        course.enroll_teacher(user, enrollment_state: "active")
      end

      it "returns false" do
        expect(user_has_only_student_enrollments?(user)).to be false
      end
    end

    context "when user has only observer enrollments" do
      before do
        course.enroll_user(user, "ObserverEnrollment", enrollment_state: "active")
      end

      it "returns false" do
        expect(user_has_only_student_enrollments?(user)).to be false
      end
    end

    context "when user has inactive student enrollment" do
      before do
        course.enroll_student(user, enrollment_state: "deleted")
      end

      it "returns false (no active enrollments)" do
        expect(user_has_only_student_enrollments?(user)).to be false
      end
    end

    context "when user has both active and inactive enrollments" do
      before do
        course.enroll_student(user, enrollment_state: "active")
        course.enroll_student(user, enrollment_state: "deleted")
      end

      it "returns true (only considers active enrollments)" do
        expect(user_has_only_student_enrollments?(user)).to be true
      end
    end

    context "when user has student enrollments across multiple accounts" do
      let(:other_account) { account_model }
      let(:other_course) { course_factory(account: other_account) }

      before do
        course.enroll_student(user, enrollment_state: "active")
        other_course.enroll_student(user, enrollment_state: "active")
      end

      it "returns true when all enrollments are student type" do
        expect(user_has_only_student_enrollments?(user)).to be true
      end
    end
  end
end
