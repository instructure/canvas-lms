# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe ConversationsHelper do
  include ConversationsHelper

  let(:account) { Account.default }
  let(:account_admin) { account_admin_user(account:) }
  let(:site_admin) { site_admin_user(account:) }
  let(:course) { course_factory(account:, active_all: true) }
  let(:user) { user_factory }
  let(:user_student) { course.enroll_student(user_factory, enrollment_state: "active").user }
  let(:user_teacher) { course.enroll_teacher(user_factory, enrollment_state: "active").user }
  let(:user_ta) { course.enroll_ta(user_factory, enrollment_state: "active").user }
  let(:user_designer) { course.enroll_designer(user_factory, enrollment_state: "active").user }
  let(:user_observer) do
    observer = user_factory
    observer_enrollment = course.enroll_user(observer, "ObserverEnrollment")
    observer_enrollment.update_attribute(:associated_user_id, user_student.id)
    observer
  end
  let(:account_admin_student) { course.enroll_student(account_admin_user(account:), enrollment_state: "active").user }
  let(:account_admin_teacher) { course.enroll_teacher(account_admin_user(account:), enrollment_state: "active").user }
  let(:account_admin_ta) { course.enroll_ta(account_admin_user(account:), enrollment_state: "active").user }
  let(:account_admin_designer) { course.enroll_designer(account_admin_user(account:), enrollment_state: "active").user }
  let(:account_admin_observer) do
    admin_observer = account_admin_user(account:)
    observer_enrollment = course.enroll_user(admin_observer, "ObserverEnrollment")
    observer_enrollment.update_attribute(:associated_user_id, user_student.id)
    admin_observer
  end
  let(:site_admin_student) { course.enroll_student(site_admin_user(account:), enrollment_state: "active").user }
  let(:site_admin_teacher) { course.enroll_teacher(site_admin_user(account:), enrollment_state: "active").user }
  let(:site_admin_ta) { course.enroll_ta(site_admin_user(account:), enrollment_state: "active").user }
  let(:site_admin_designer) { course.enroll_designer(site_admin_user(account:), enrollment_state: "active").user }
  let(:site_admin_observer) do
    siteadmin_observer = site_admin_user(account:)
    observer_enrollment = course.enroll_user(siteadmin_observer, "ObserverEnrollment")
    observer_enrollment.update_attribute(:associated_user_id, user_student.id)
    siteadmin_observer
  end

  describe "inbox_settings_student?" do
    context "returns false for users considered non-students for inbox settings" do
      it "user who is active teacher" do
        expect(inbox_settings_student?(user: user_teacher, account:)).to be false
      end

      it "user who is active teaching assistant" do
        expect(inbox_settings_student?(user: user_ta, account:)).to be false
      end

      it "user who is active designer" do
        expect(inbox_settings_student?(user: user_designer, account:)).to be false
      end

      it "account admin who is active teacher" do
        expect(inbox_settings_student?(user: account_admin_teacher, account:)).to be false
      end

      it "account admin who is active teaching assistant" do
        expect(inbox_settings_student?(user: account_admin_ta, account:)).to be false
      end

      it "account admin who is active designer" do
        expect(inbox_settings_student?(user: account_admin_designer, account:)).to be false
      end

      it "site admin who is active teacher" do
        expect(inbox_settings_student?(user: site_admin_teacher, account:)).to be false
      end

      it "site admin who is active teaching assistant" do
        expect(inbox_settings_student?(user: site_admin_ta, account:)).to be false
      end

      it "site admin who is active designer" do
        expect(inbox_settings_student?(user: site_admin_designer, account:)).to be false
      end
    end

    context "returns true for users considered students for inbox settings" do
      it "user who is not enrolled" do
        expect(inbox_settings_student?(user:, account:)).to be true
      end

      it "user who is active student" do
        expect(inbox_settings_student?(user: user_student, account:)).to be true
      end

      it "user who is active observer" do
        expect(inbox_settings_student?(user: user_observer, account:)).to be true
      end

      it "account admin who is active student" do
        expect(inbox_settings_student?(user: account_admin_student, account:)).to be true
      end

      it "account admin who is active observer" do
        expect(inbox_settings_student?(user: account_admin_observer, account:)).to be true
      end

      it "site admin who is active student" do
        expect(inbox_settings_student?(user: site_admin_student, account:)).to be true
      end

      it "site admin who is active observer" do
        expect(inbox_settings_student?(user: site_admin_observer, account:)).to be true
      end
    end
  end

  describe "trigger_out_of_office_auto_responses" do
    before do
      Account.site_admin.enable_feature!(:inbox_settings)
    end

    let(:participant_ids) { [user.id] }
    let(:date) { Time.zone.now }
    let(:author) { user_student }
    let(:context) { account }
    let(:root_account_id) { account.id }
    let(:root_account_ids) { [account.id] } # This is a method in the ConversationHelper module, I just mock it here

    context "when user is out of office" do
      before do
        inbox_settings_factory(user_id: user.id)
      end

      it "sends out of office auto response once" do
        expect do
          trigger_out_of_office_auto_responses(participant_ids, date, author, context.id, context.class.name, root_account_id)
          trigger_out_of_office_auto_responses(participant_ids, date, author, context.id, context.class.name, root_account_id)
        end.to change { Conversation.count }.by(1)
      end

      it "sends auto response to each author" do
        expect do
          trigger_out_of_office_auto_responses(participant_ids, date, author, context.id, context.class.name, root_account_id)
          author = user_teacher
          trigger_out_of_office_auto_responses(participant_ids, date, author, context.id, context.class.name, root_account_id)
        end.to change { Conversation.count }.by(2)
      end

      it "sends auto response again if settings changed" do
        expect do
          trigger_out_of_office_auto_responses(participant_ids, date, author, context.id, context.class.name, root_account_id)
          settings = Inbox::Repositories::InboxSettingsRepository::InboxSettingsRecord.find_by(user_id: user.id)
          settings.update_attribute(:out_of_office_message, "New message")
          trigger_out_of_office_auto_responses(participant_ids, date, author, context.id, context.class.name, root_account_id)
        end.to change { Conversation.count }.by(2)
      end
    end
  end
end
