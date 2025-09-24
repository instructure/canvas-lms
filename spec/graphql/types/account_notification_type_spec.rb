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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Types::AccountNotificationType do
  let_once(:account) { Account.default }
  let_once(:admin) { account_admin_user(account:) }
  let_once(:student) { student_in_course(account:).user }

  let(:notification) do
    AccountNotification.create!(
      account:,
      subject: "Test Notification",
      message: "<p>Test message content</p>",
      start_at: 1.day.ago,
      end_at: 30.days.from_now,
      icon: "warning",
      user: admin
    )
  end

  let(:site_admin_notification) do
    AccountNotification.create!(
      account: Account.site_admin,
      subject: "Site Admin Notification",
      message: "<p>Site admin message</p>",
      start_at: 1.day.ago,
      end_at: 30.days.from_now,
      icon: "information",
      user: admin
    )
  end

  let(:notification_type) { GraphQLTypeTester.new(notification, current_user: student) }
  let(:site_admin_type) { GraphQLTypeTester.new(site_admin_notification, current_user: student) }

  it "works" do
    expect(notification_type.resolve("_id")).to eq notification.id.to_s
  end

  describe "fields" do
    it "returns the subject" do
      expect(notification_type.resolve("subject")).to eq "Test Notification"
    end

    it "returns the message" do
      expect(notification_type.resolve("message")).to eq "<p>Test message content</p>"
    end

    it "returns the start_at date" do
      expect(notification_type.resolve("startAt")).to eq notification.start_at.iso8601
    end

    it "returns the end_at date" do
      expect(notification_type.resolve("endAt")).to eq notification.end_at.iso8601
    end

    it "returns the account_id" do
      expect(notification_type.resolve("accountId")).to eq notification.account_id.to_s
    end

    it "returns the account name for non-site admin accounts" do
      expect(notification_type.resolve("accountName")).to eq account.name
    end

    it "returns nil account name for site admin accounts" do
      expect(site_admin_type.resolve("accountName")).to be_nil
    end

    it "returns false for is_site_admin on regular accounts" do
      expect(notification_type.resolve("siteAdmin")).to be false
    end

    it "returns true for is_site_admin on site admin accounts" do
      expect(site_admin_type.resolve("siteAdmin")).to be true
    end

    describe "notification_type mapping" do
      it "maps warning icon to warning type" do
        notification.update!(icon: "warning")
        expect(notification_type.resolve("notificationType")).to eq "warning"
      end

      it "maps error icon to error type" do
        notification.update!(icon: "error")
        expect(notification_type.resolve("notificationType")).to eq "error"
      end

      it "maps information icon to info type" do
        notification.update!(icon: "information")
        expect(notification_type.resolve("notificationType")).to eq "info"
      end

      it "maps question icon to question type" do
        notification.update!(icon: "question")
        expect(notification_type.resolve("notificationType")).to eq "question"
      end

      it "maps calendar icon to calendar type" do
        notification.update!(icon: "calendar")
        expect(notification_type.resolve("notificationType")).to eq "calendar"
      end

      it "defaults to info type for unknown icons" do
        notification.update!(icon: "unknown")
        expect(notification_type.resolve("notificationType")).to eq "info"
      end

      it "defaults to info type for nil icon" do
        notification.update!(icon: nil)
        expect(notification_type.resolve("notificationType")).to eq "info"
      end
    end
  end
end
