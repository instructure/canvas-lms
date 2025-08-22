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

describe Mutations::DismissAccountNotification do
  before(:once) do
    @account = Account.default
    @admin = account_admin_user(account: @account)
    @student = student_in_course(account: @account, active_all: true).user
    @notification = AccountNotification.create!(
      account: @account,
      subject: "Test Notification",
      message: "<p>Test message</p>",
      start_at: 1.day.ago,
      end_at: 30.days.from_now,
      user: @admin
    )
  end

  def execute_mutation(notification_id, context_user = @student)
    mutation = <<~GQL
      mutation DismissNotification($notificationId: ID!) {
        dismissAccountNotification(input: {notificationId: $notificationId}) {
          errors {
            attribute
            message
          }
        }
      }
    GQL

    CanvasSchema.execute(
      mutation,
      context: { current_user: context_user, domain_root_account: @account },
      variables: { notificationId: notification_id.to_s }
    )
  end

  describe "dismissing notifications" do
    it "successfully dismisses a notification" do
      result = execute_mutation(@notification.id, @student)

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "dismissAccountNotification")).not_to be_nil

      closed_notifications = @student.get_preference(:closed_notifications)
      expect(closed_notifications).to include(@notification.id)
    end

    it "returns error when notification not found" do
      result = execute_mutation(99_999, @student)

      expect(result["errors"]).not_to be_nil
      expect(result["errors"].first["message"]).to include("Notification not found")
    end

    it "returns error when user not authenticated" do
      result = execute_mutation(@notification.id, nil)

      expect(result["errors"]).not_to be_nil
      expect(result["errors"].first["message"]).to include("Must be logged in")
    end

    it "does not duplicate notification id in closed_notifications" do
      # Dismiss once
      result1 = execute_mutation(@notification.id, @student)
      expect(result1["errors"]).to be_nil
      first_closed = @student.get_preference(:closed_notifications)

      # Dismiss again
      result2 = execute_mutation(@notification.id, @student)
      expect(result2["errors"]).to be_nil
      second_closed = @student.get_preference(:closed_notifications)

      expect(first_closed).to eq second_closed
      expect(second_closed.count(@notification.id)).to eq 1
    end

    it "preserves existing closed notifications when dismissing new ones" do
      other_notification = AccountNotification.create!(
        account: @account,
        subject: "Other Notification",
        message: "Other message",
        start_at: 1.day.ago,
        end_at: 30.days.from_now,
        user: @admin
      )
      @student.set_preference(:closed_notifications, [other_notification.id])

      result = execute_mutation(@notification.id, @student)
      expect(result["errors"]).to be_nil

      closed_notifications = @student.get_preference(:closed_notifications)
      expect(closed_notifications).to include(@notification.id)
      expect(closed_notifications).to include(other_notification.id)
      expect(closed_notifications.length).to eq 2
    end

    it "handles nil closed_notifications preference" do
      @student.set_preference(:closed_notifications, nil)

      result = execute_mutation(@notification.id, @student)
      expect(result["errors"]).to be_nil

      closed_notifications = @student.get_preference(:closed_notifications)
      expect(closed_notifications).to eq [@notification.id]
    end
  end

  describe "with GraphQL relay IDs" do
    it "accepts relay-style global IDs" do
      relay_id = GraphQLHelpers.relay_or_legacy_id_prepare_func("AccountNotification").call(@notification.id.to_s, {})

      result = execute_mutation(relay_id, @student)
      expect(result["errors"]).to be_nil

      closed_notifications = @student.get_preference(:closed_notifications)
      expect(closed_notifications).to include(@notification.id)
    end
  end

  describe "error handling" do
    it "handles invalid notification ID gracefully" do
      result = execute_mutation("invalid_id", @student)

      expect(result["errors"]).not_to be_nil
    end

    it "handles non-existent notification ID" do
      non_existent_id = @notification.id + 99_999
      result = execute_mutation(non_existent_id, @student)

      expect(result["errors"]).not_to be_nil
      expect(result["errors"].first["message"]).to include("Notification not found")
    end
  end
end
