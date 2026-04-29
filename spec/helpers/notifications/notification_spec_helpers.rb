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

require_relative "expectations/notification_expectation"
require_relative "expectations/no_notification_expectation"
require_relative "notification_spy"
require_relative "policy_verifier"

# Comprehensive RSpec helpers for testing broadcast-policy notifications
#
# Usage:
#   include NotificationSpecHelpers
#
#   it "sends assignment created notification to students" do
#     expect_notification(:assignment_created)
#       .to_be_sent_to(@student1, @student2)
#       .when { @assignment.save! }
#
#     # or with block syntax
#     expect_notification(:assignment_created) do
#       sent_to @student1, @student2
#       not_sent_to @teacher, @ta
#       with_data course_id: @course.id
#       from_name @course.name
#     end.when { @assignment.save! }
#   end

module NotificationSpecHelpers
  extend RSpec::Matchers::DSL

  # Main DSL entry point
  # Example:
  #   expect_notification(:assignment_created) do |n|
  #     n.sent_to @student1, @student2
  #   end.when { @assignment.save! }
  def expect_notification(notification_name, &)
    NotificationExpectation.new(notification_name, &)
  end

  # Aliased methods for better readability
  alias_method :expect_notifications, :expect_notification
  alias_method :expect_to_send_notification, :expect_notification

  # Expect no notifications to be sent
  # Example:
  #   expect_no_notifications.when {
  #     @assignment.save_without_broadcasting
  #   }
  def expect_no_notifications(&)
    NoNotificationExpectation.new(&)
  end

  # Clear all notifications (useful in before blocks)
  # Example:
  #   before(:each) do
  #     clear_all_notifications
  #   end
  def clear_all_notifications
    Message.delete_all if defined?(Message)
    DelayedMessage.delete_all if defined?(DelayedMessage)
    @notification_spy&.clear
  end

  # Enable notification spying for more detailed inspection
  # Example:
  #   spy = spy_on_notifications
  #   @assignment.save!
  #   expect(spy.for_notification(:assignment_created)).to have(1).item
  #   expect(spy.for_user(@student)).to have(2).items
  def spy_on_notifications
    @notification_spy = NotificationSpy.new
    allow(BroadcastPolicy.notifier).to receive(:send_notification) do |args|
      @notification_spy.record(args)
      BroadcastPolicy.notifier.send_notification(args) # Call original
    end
    @notification_spy
  end

  # Get all notifications sent in a block
  # Example:
  #   messages = notifications_sent_during do
  #     @assignment.save!
  #   end
  #   expect(messages.map(&:notification_name)).to include("Assignment Created")
  def notifications_sent_during(&)
    initial_messages = Message.all.to_a
    yield
    Message.all.to_a - initial_messages
  end

  # Custom RSpec matcher for better integration
  # Example:
  #   expect { @assignment.save! }.to send_notification(:assignment_created).to(@student1, @student2)
  RSpec::Matchers.define :send_notification do |notification_name|
    match do |actual|
      @notification_name = notification_name.to_s.titleize
      @actual_block = actual

      initial_messages = capture_messages
      @actual_block.call
      new_messages = capture_messages - initial_messages

      @sent_notifications = new_messages.select { |m| m.notification_name == @notification_name }

      if @expected_recipients
        actual_recipients = @sent_notifications.map(&:user).uniq
        missing = @expected_recipients - actual_recipients
        @failure_message = "Expected to send '#{@notification_name}' to #{missing.map(&:name).join(", ")}" if missing.any?
        missing.empty?
      else
        @sent_notifications.any?
      end
    end

    chain :to do |*recipients|
      @expected_recipients = recipients.flatten
    end

    failure_message do
      @failure_message || "Expected to send '#{@notification_name}' notification, but didn't"
    end

    failure_message_when_negated do
      "Expected not to send '#{@notification_name}' notification, but did"
    end

    def capture_messages
      defined?(Message) ? Message.all.to_a : []
    end
  end

  # Simplified matchers for common cases
  # Example:
  #   @assignment.save!
  #   expect(@assignment).to have_sent_notification(:assignment_created).to(@student1, @student2)
  RSpec::Matchers.define :have_sent_notification do |notification_name|
    match do |model|
      @notification_name = notification_name.to_s.titleize
      messages = model.messages_sent[@notification_name] || []

      if @to_users
        actual_recipients = messages.map(&:user)
        (@to_users - actual_recipients).empty?
      else
        messages.any?
      end
    end

    chain :to do |*users|
      @to_users = users.flatten
    end

    failure_message do
      if @to_users
        "expected #{@notification_name} to be sent to #{@to_users.map(&:name).join(", ")}"
      else
        "expected #{@notification_name} to be sent"
      end
    end
  end

  # Helper to verify notification policies
  # Example:
  #   verify_notification_policy(@assignment) do
  #     should_send(:assignment_created).to(@course.students)
  #     should_not_send(:assignment_graded)  # Not graded yet
  #   end
  def verify_notification_policy(model, &)
    policy_verifier = PolicyVerifier.new(model)
    policy_verifier.instance_eval(&)
    policy_verifier.verify!
  end
end

# Shared examples for common notification scenarios
# Example usage:
#   describe Assignment do
#     it_behaves_like "sends creation notification", :assignment_created, :participating_students
#   end
RSpec.shared_examples "sends creation notification" do |notification_name, recipients_method|
  it "sends #{notification_name} to #{recipients_method}" do
    recipients = subject.send(recipients_method)

    expect_notification(notification_name)
      .to_be_sent_to(recipients)
      .when { subject.save! }
  end
end

# Example usage:
#   describe Assignment do
#     let(:new_value) { 5.days.from_now }
#     it_behaves_like "sends update notification", :assignment_due_date_changed, :due_at, :participating_students
#   end
RSpec.shared_examples "sends update notification" do |notification_name, field, recipients_method|
  it "sends #{notification_name} when #{field} changes" do
    recipients = subject.send(recipients_method)
    subject.save!

    expect_notification(notification_name)
      .to_be_sent_to(recipients)
      .when { subject.update!(field => new_value) }
  end
end

# Example usage:
#   describe Assignment do
#     let(:user) { @student }
#     let(:trigger_notification) { @assignment.save! }
#     it_behaves_like "respects notification preferences", :assignment_created
#   end
RSpec.shared_examples "respects notification preferences" do |notification_name|
  it "respects user notification preferences for #{notification_name}" do
    user.notification_preferences.create!(
      notification: Notification.find_by(name: notification_name),
      frequency: "never"
    )

    expect_no_notifications.when { trigger_notification }
  end
end
