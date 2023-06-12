# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::UpdateNotificationPreferences do
  before(:once) do
    @account = Account.default
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
    @student = @course.enroll_student(User.create!, enrollemnt_state: "active").user
    communication_channel(@teacher, { username: "two@example.com", active_cc: true })
    @notification = Notification.create!(name: "Assignment Created", subject: "Test", category: "Due Date")
  end

  def mutation_str(
    account_id: nil,
    course_id: nil,
    context_type: nil,
    enabled: nil,
    communication_channel_id: nil,
    notification_category: nil,
    frequency: nil,
    user_id: nil,
    send_scores_in_emails: nil,
    send_observed_names_in_notifications: nil,
    is_policy_override: nil,
    has_read_privacy_notice: nil
  )
    <<~GQL
      mutation {
        updateNotificationPreferences(input: {
          #{"accountId: #{account_id}" if account_id}
          #{"contextType: #{context_type}" if context_type}
          #{"courseId: #{course_id}" if course_id}
          #{"enabled: #{enabled}" unless enabled.nil?}
          #{"communicationChannelId: #{communication_channel_id}" if communication_channel_id}
          #{"notificationCategory: #{notification_category}" if notification_category}
          #{"frequency: #{frequency}" if frequency}
          #{"sendScoresInEmails: #{send_scores_in_emails}" unless send_scores_in_emails.nil?}
          #{"sendObservedNamesInNotifications: #{send_observed_names_in_notifications}" unless send_observed_names_in_notifications.nil?}
          #{"isPolicyOverride: #{is_policy_override}" unless is_policy_override.nil?}
          #{"hasReadPrivacyNotice: #{has_read_privacy_notice}" if has_read_privacy_notice}
        }) {
          user {
            #{notification_preferences_str(
              account_id:,
              course_id:,
              context_type:,
              user_id:
            )}
          }
          errors {
            message
          }
        }
      }
    GQL
  end

  def notification_preferences_str(
    account_id: nil,
    course_id: nil,
    context_type: nil,
    user_id: nil
  )
    <<~GQL
      #{if context_type && (course_id || account_id)
          "notificationPreferencesEnabled(
          contextType: #{context_type},
          #{"courseId: #{course_id}" if course_id}
          #{"accountId: #{account_id}" if account_id}
      )"
        end}
      notificationPreferences {
        sendScoresInEmails#{"(courseId: #{course_id})" if course_id}
        sendObservedNamesInNotifications
        readPrivacyNoticeDate
        channels {
          #{if context_type && (course_id || account_id)
              "notificationPolicyOverrides(
              contextType: #{context_type},
              #{"courseId: #{course_id}" if course_id}
              #{"accountId: #{account_id}" if account_id}
          ) {
              frequency
              notification {
                category
                categoryDisplayName
                name
              }
          }"
            end}
          notificationPolicies#{"(contextType: #{context_type})" if context_type} {
            frequency
            notification {
              category
              categoryDisplayName
              name
            }
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(mutation_str(**opts), context: {
                                    current_user:,
                                    request: ActionDispatch::TestRequest.create,
                                    domain_root_account: @account
                                  })
    result.to_h.with_indifferent_access
  end

  context "privacy notice" do
    it "sets the user preference" do
      result = run_mutation(
        user_id: @teacher.id,
        account_id: @account.id,
        context_type: "Account",
        has_read_privacy_notice: true
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(
               :data, :updateNotificationPreferences, :user, :notificationPreferences, :readPrivacyNoticeDate
             )).to eq @teacher.preferences[:read_notification_privacy_info]
    end
  end

  context "send observed names in notifications" do
    it "sets the user preference" do
      @course.enroll_user(@teacher, "ObserverEnrollment", associated_user_id: @student.id, enrollment_state: "active")
      result = run_mutation(
        user_id: @teacher.id,
        account_id: @account.id,
        context_type: "Account",
        send_observed_names_in_notifications: true
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(
               :data, :updateNotificationPreferences, :user, :notificationPreferences, :sendObservedNamesInNotifications
             )).to be true
      expect(@teacher.preferences[:send_observed_names_in_notifications]).to be true

      result = run_mutation(
        user_id: @teacher.id,
        account_id: @account.id,
        context_type: "Account",
        send_observed_names_in_notifications: false
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(
               :data, :updateNotificationPreferences, :user, :notificationPreferences, :sendObservedNamesInNotifications
             )).to be false
      expect(@teacher.preferences[:send_observed_names_in_notifications]).to be false
    end
  end

  context "send scores in emails" do
    it "sets the global setting" do
      result = run_mutation(
        user_id: @teacher.id,
        account_id: @account.id,
        context_type: "Account",
        send_scores_in_emails: true
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(
               :data, :updateNotificationPreferences, :user, :notificationPreferences, :sendScoresInEmails
             )).to be true

      result = run_mutation(
        user_id: @teacher.id,
        account_id: @account.id,
        context_type: "Account",
        send_scores_in_emails: false
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(
               :data, :updateNotificationPreferences, :user, :notificationPreferences, :sendScoresInEmails
             )).to be false
    end

    it "sets the course override setting" do
      result = run_mutation(
        user_id: @teacher.id,
        course_id: @course.id,
        context_type: "Course",
        send_scores_in_emails: true
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(
               :data, :updateNotificationPreferences, :user, :notificationPreferences, :sendScoresInEmails
             )).to be true

      result = run_mutation(
        user_id: @teacher.id,
        course_id: @course.id,
        context_type: "Course",
        send_scores_in_emails: false
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(
               :data, :updateNotificationPreferences, :user, :notificationPreferences, :sendScoresInEmails
             )).to be false
    end
  end

  context "course" do
    it "enables notifications" do
      NotificationPolicyOverride.enable_for_context(@teacher, @course, enable: false)
      result = run_mutation(
        context_type: "Course",
        course_id: @course.id,
        enabled: true
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferencesEnabled)).to be true
      expect(NotificationPolicyOverride.enabled_for(@teacher, @course)).to be true
    end

    it "disables notifications" do
      NotificationPolicyOverride.enable_for_context(@teacher, @course)
      result = run_mutation(
        context_type: "Course",
        course_id: @course.id,
        enabled: false
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferencesEnabled)).to be false
      expect(NotificationPolicyOverride.enabled_for(@teacher, @course)).to be false
    end

    it "creates notification policy overrides" do
      result = run_mutation(
        context_type: "Course",
        course_id: @course.id,
        communication_channel_id: @teacher.communication_channels.first.id,
        notification_category: "Due_Date",
        frequency: "daily",
        is_policy_override: true
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(
        result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferences, :channels, 0, :notificationPolicyOverrides, 0, :frequency)
      ).to eq("daily")
    end
  end

  context "account" do
    it "enables notifications" do
      NotificationPolicyOverride.enable_for_context(@teacher, @account, enable: false)
      result = run_mutation(
        context_type: "Account",
        account_id: @account.id,
        enabled: true
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferencesEnabled)).to be true
      expect(NotificationPolicyOverride.enabled_for(@teacher, @account)).to be true
    end

    it "disables notifications" do
      NotificationPolicyOverride.enable_for_context(@teacher, @account)
      result = run_mutation(
        context_type: "Account",
        account_id: @account.id,
        enabled: false
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferencesEnabled)).to be false
      expect(NotificationPolicyOverride.enabled_for(@teacher, @account)).to be false
    end

    it "creates notification policy overrides" do
      result = run_mutation(
        context_type: "Account",
        account_id: @account.id,
        communication_channel_id: @teacher.communication_channels.first.id,
        notification_category: "Due_Date",
        frequency: "immediately",
        is_policy_override: true
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(
        result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferences, :channels, 0, :notificationPolicyOverrides, 0, :frequency)
      ).to eq("immediately")
    end

    it "creates notification policies" do
      result = run_mutation(
        context_type: "Account",
        account_id: @account.id,
        communication_channel_id: @teacher.communication_channels.first.id,
        notification_category: "Due_Date",
        frequency: "immediately"
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(
        result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferences, :channels, 0, :notificationPolicies, 0, :frequency)
      ).to eq("immediately")
    end

    it "creates notification policies for newly created notification types" do
      Notification.create!(name: "Discussion Mention", subject: "Test", category: "DiscussionMention")
      result = run_mutation(
        context_type: "Account",
        account_id: @account.id,
        communication_channel_id: @teacher.communication_channels.first.id,
        notification_category: "DiscussionMention",
        frequency: "immediately"
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be_nil
      expect(
        result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferences, :channels, 0, :notificationPolicies, 0, :frequency)
      ).to eq("immediately")
    end

    it "throw not found when communication channel doesn't belong to current_user" do
      Notification.create!(name: "Discussion Mention", subject: "Test", category: "DiscussionMention")
      result = CanvasSchema.execute(mutation_str(context_type: "Account",
                                                 account_id: @account.id,
                                                 communication_channel_id: @teacher.communication_channels.first.id,
                                                 notification_category: "DiscussionMention",
                                                 frequency: "immediately"),
                                    context: {
                                      current_user: @student,
                                      request: ActionDispatch::TestRequest.create,
                                      domain_root_account: @account
                                    })
      result = result.to_h.with_indifferent_access

      expect(result[:errors][0][:message]).to be "not found"
    end
  end

  describe "invalid input" do
    it "errors when context_type is Account and is not given an account_id" do
      result = run_mutation(
        context_type: "Account",
        enabled: true
      )
      expect(
        result.dig(:data, :updateNotificationPreferences, :errors, 0, :message)
      ).to eq "Account level notification preferences require an account_id to update"
    end

    it "errors when context_type is Course and is not given a course_id" do
      result = run_mutation(
        context_type: "Course",
        enabled: true
      )
      expect(
        result.dig(:data, :updateNotificationPreferences, :errors, 0, :message)
      ).to eq "Course level notification preferences require a course_id to update"
    end

    it "errors when given an account_id for an account that does not exist" do
      result = run_mutation(
        context_type: "Account",
        account_id: 987_654_321,
        enabled: false
      )
      expect(result.dig(:errors, 0, :message)).to eq "not found"
    end

    it "errors when given a course_id for a course that does not exist" do
      result = run_mutation(
        context_type: "Course",
        course_id: 987_654_321,
        enabled: false
      )
      expect(result.dig(:errors, 0, :message)).to eq "not found"
    end

    it "errors when not provided all arguments required to update a policy" do
      result = run_mutation(
        context_type: "Account",
        account_id: @account.id,
        communication_channel_id: @teacher.communication_channels.first.id
      )
      expect(
        result.dig(:data, :updateNotificationPreferences, :errors, 0, :message)
      ).to eq "Notification policies requires the communication channel id, the notification category, and the frequency to update"
    end
  end
end
