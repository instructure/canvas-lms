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

module NotificationSpecHelpers
  class NotificationExpectation
    attr_reader :notification_name,
                :expected_recipients,
                :unexpected_recipients,
                :expected_data,
                :expected_from,
                :expected_subject_pattern,
                :expected_body_pattern,
                :channel_preferences

    def initialize(notification_name, &)
      @notification_name = notification_name.to_s.titleize
      @expected_recipients = []
      @unexpected_recipients = []
      @expected_data = {}
      @channel_preferences = {}
      @expected_count = nil
      @allow_others = false

      yield(self) if block_given?
    end

    # DSL Methods
    # Example: .to_be_sent_to(@student1, @student2)
    # Example: .sent_to(@course.students)
    # Example: .to(@student)
    def to_be_sent_to(*recipients)
      @expected_recipients.concat(recipients.flatten.compact)
      self
    end
    alias_method :sent_to, :to_be_sent_to
    alias_method :to, :to_be_sent_to

    # Example: .not_to_be_sent_to(@teacher, @ta)
    # Example: .not_sent_to(@other_student)
    # Example: .not_to(@admin)
    def not_to_be_sent_to(*recipients)
      @unexpected_recipients.concat(recipients.flatten.compact)
      self
    end
    alias_method :not_sent_to, :not_to_be_sent_to
    alias_method :not_to, :not_to_be_sent_to

    # Example: .with_data(course_id: @course.id, root_account_id: 1)
    def with_data(data = {})
      @expected_data.merge!(data)
      self
    end

    # Example: .from_name(@course.name)
    # Example: .from("Math 101")
    def from_name(name)
      @expected_from = name
      self
    end
    alias_method :from, :from_name

    # Example: .with_subject_matching(/New Assignment/)
    # Example: .subject_matching(/Due.*Tomorrow/)
    def with_subject_matching(pattern)
      @expected_subject_pattern = pattern
      self
    end
    alias_method :subject_matching, :with_subject_matching

    # Example: .with_body_matching(/100 points possible/)
    # Example: .body_matching(/due.*#{@assignment.due_at}/)
    def with_body_matching(pattern)
      @expected_body_pattern = pattern
      self
    end
    alias_method :body_matching, :with_body_matching

    # Example: .via_channel(:email, :immediately)
    # Example: .via_channel(:sms, :never)
    def via_channel(channel, frequency = nil)
      @channel_preferences[channel] = frequency
      self
    end

    # Example: .exactly(3)  # Expecting exactly 3 notifications
    def exactly(count)
      @expected_count = count
      self
    end

    # Example: .at_least(1)  # At least one notification
    def at_least(count)
      @min_count = count
      self
    end

    # Example: .at_most(5)  # No more than 5 notifications
    def at_most(count)
      @max_count = count
      self
    end

    # Example: .to(@student1).allowing_other_recipients  # Don't care about other recipients
    def allowing_other_recipients
      @allow_others = true
      self
    end

    # Trigger the expectation check
    # Example: .when { @assignment.save! }
    # Example: .during { @submission.grade! }
    def when(&)
      verify_notification(&)
    end
    alias_method :during, :when

    # Verify after the fact (without block)
    # Example: @assignment.save!; expect_notification(:assignment_created).on(@assignment)
    def on(model_instance)
      verify_on_model(model_instance)
    end

    private

    def verify_notification(&)
      # Capture initial state
      initial_messages = capture_current_messages

      # Execute the block that should trigger notifications
      result = yield

      # Get new messages
      new_messages = capture_current_messages - initial_messages
      notification_messages = filter_by_notification_name(new_messages)

      # Perform verifications
      verify_recipients(notification_messages)
      verify_data(notification_messages) if @expected_data.any?
      verify_from_name(notification_messages) if @expected_from
      verify_content(notification_messages)
      verify_count(notification_messages) if @expected_count || @min_count || @max_count
      verify_channels(notification_messages) if @channel_preferences.any?

      result
    end

    def verify_on_model(model)
      # Use the messages_sent hash for model-based verification
      messages = model.messages_sent[@notification_name] || []

      verify_recipients(messages)
      verify_data(messages) if @expected_data.any?
      verify_from_name(messages) if @expected_from
      verify_content(messages)
      verify_count(messages) if @expected_count || @min_count || @max_count
    end

    def capture_current_messages
      if defined?(Message)
        Message.all.to_a
      else
        []
      end
    end

    def filter_by_notification_name(messages)
      messages.select { |m| m.notification_name == @notification_name }
    end

    def verify_recipients(messages)
      actual_recipients = messages.map(&:user).uniq

      # Check expected recipients
      missing_recipients = @expected_recipients - actual_recipients
      if missing_recipients.any?
        recipient_names = missing_recipients.map { |r| identifier_for(r) }.join(", ")
        raise RSpec::Expectations::ExpectationNotMetError,
              "Expected notification '#{@notification_name}' to be sent to #{recipient_names}, but it wasn't.\n" \
              "Actual recipients: #{actual_recipients.map { |r| identifier_for(r) }.join(", ")}"
      end

      # Check unexpected recipients
      unwanted_recipients = @unexpected_recipients & actual_recipients
      if unwanted_recipients.any?
        recipient_names = unwanted_recipients.map { |r| identifier_for(r) }.join(", ")
        raise RSpec::Expectations::ExpectationNotMetError,
              "Expected notification '#{@notification_name}' NOT to be sent to #{recipient_names}, but it was."
      end

      # Check for unexpected recipients if not allowing others
      if !@allow_others && @expected_recipients.any?
        extra_recipients = actual_recipients - @expected_recipients
        if extra_recipients.any?
          recipient_names = extra_recipients.map { |r| identifier_for(r) }.join(", ")
          raise RSpec::Expectations::ExpectationNotMetError,
                "Notification '#{@notification_name}' was sent to unexpected recipients: #{recipient_names}.\n" \
                "Use .allowing_other_recipients if this is intentional."
        end
      end
    end

    def verify_data(messages)
      @expected_data.each do |key, expected_value|
        messages.each do |message|
          actual_value = message.context[key.to_s] || message.context[key.to_sym]
          next unless actual_value != expected_value

          raise RSpec::Expectations::ExpectationNotMetError,
                "Expected notification '#{@notification_name}' to have data #{key}: #{expected_value}, " \
                "but got #{actual_value} for recipient #{identifier_for(message.user)}"
        end
      end
    end

    def verify_from_name(messages)
      messages.each do |message|
        next unless message.from_name != @expected_from

        raise RSpec::Expectations::ExpectationNotMetError,
              "Expected notification '#{@notification_name}' to be from '#{@expected_from}', " \
              "but got '#{message.from_name}' for recipient #{identifier_for(message.user)}"
      end
    end

    def verify_content(messages)
      messages.each do |message|
        if @expected_subject_pattern && !message.subject.match?(@expected_subject_pattern)
          raise RSpec::Expectations::ExpectationNotMetError,
                "Expected notification subject to match #{@expected_subject_pattern.inspect}, " \
                "but got '#{message.subject}' for recipient #{identifier_for(message.user)}"
        end

        next unless @expected_body_pattern && !message.body.match?(@expected_body_pattern)

        raise RSpec::Expectations::ExpectationNotMetError,
              "Expected notification body to match #{@expected_body_pattern.inspect}, " \
              "but message body didn't match for recipient #{identifier_for(message.user)}"
      end
    end

    def verify_count(messages)
      actual_count = messages.size

      if @expected_count && actual_count != @expected_count
        raise RSpec::Expectations::ExpectationNotMetError,
              "Expected exactly #{@expected_count} '#{@notification_name}' notification(s), " \
              "but got #{actual_count}"
      end

      if @min_count && actual_count < @min_count
        raise RSpec::Expectations::ExpectationNotMetError,
              "Expected at least #{@min_count} '#{@notification_name}' notification(s), " \
              "but got #{actual_count}"
      end

      if @max_count && actual_count > @max_count
        raise RSpec::Expectations::ExpectationNotMetError,
              "Expected at most #{@max_count} '#{@notification_name}' notification(s), " \
              "but got #{actual_count}"
      end
    end

    def verify_channels(messages)
      @channel_preferences.each do |channel_type, frequency|
        messages_for_channel = messages.select { |m| m.communication_channel&.path_type == channel_type.to_s }

        if frequency == :never && messages_for_channel.any?
          raise RSpec::Expectations::ExpectationNotMetError,
                "Expected no '#{@notification_name}' notifications via #{channel_type}, " \
                "but found #{messages_for_channel.size}"
        elsif frequency != :never && messages_for_channel.empty?
          raise RSpec::Expectations::ExpectationNotMetError,
                "Expected '#{@notification_name}' notifications via #{channel_type}, but found none"
        end
      end
    end

    def identifier_for(user)
      return user.name if user.respond_to?(:name) && user.name.present?
      return user.email if user.respond_to?(:email) && user.email.present?
      return "User##{user.id}" if user.respond_to?(:id)

      user.to_s
    end
  end
end
