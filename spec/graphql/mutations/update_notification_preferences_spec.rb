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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative '../graphql_spec_helper'

RSpec.describe Mutations::UpdateNotificationPreferences do
  before(:once) do
    @account = Account.default
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: 'active').user
    @account.enable_feature!(:mute_notifications_by_course)
    @teacher.communication_channels.create!(path: 'two@example.com', path_type: 'email') { |cc| cc.workflow_state = 'active' }
    @notification = Notification.create!(:name => "Assignment Created", :subject => "Test", :category => 'Due Date')
  end

  def mutation_str(
    account_id: nil,
    course_id: nil,
    context_type: nil,
    enabled: nil,
    communication_channel_id: nil,
    notification_category: nil,
    frequency: nil
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
        }) {
          user {
            #{notification_preferences_str(account_id: account_id, course_id: course_id, context_type: context_type)}
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
    context_type: nil
  )
    <<~GQL
      #{"notificationPreferencesEnabled(
        contextType: #{context_type},
        #{"courseId: #{course_id}" if course_id}
        #{"accountId: #{account_id}" if account_id}
      )" if context_type && (course_id || account_id)}
      notificationPreferences {
        channels {
          #{"notificationPolicyOverrides(
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
          }" if context_type && (course_id || account_id)}
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
    result = CanvasSchema.execute(mutation_str(opts), context: {current_user: current_user, request: ActionDispatch::TestRequest.create})
    result.to_h.with_indifferent_access
  end

  context 'course' do
    it 'enables notifications' do
      NotificationPolicyOverride.enable_for_context(@teacher, @course, enable: false)
      result = run_mutation(
        context_type: 'Course',
        course_id: @course.id,
        enabled: true
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be nil
      expect(result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferencesEnabled)).to be true
      expect(NotificationPolicyOverride.enabled_for(@teacher, @course)).to be true
    end

    it 'disables notifications' do
      NotificationPolicyOverride.enable_for_context(@teacher, @course)
      result = run_mutation(
        context_type: 'Course',
        course_id: @course.id,
        enabled: false
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be nil
      expect(result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferencesEnabled)).to be false
      expect(NotificationPolicyOverride.enabled_for(@teacher, @course)).to be false
    end

    it 'creates notification policy overrides' do
      result = run_mutation(
        context_type: 'Course',
        course_id: @course.id,
        communication_channel_id: @teacher.communication_channels.first.id,
        notification_category: 'Due_Date',
        frequency: 'daily'
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be nil
      expect(
        result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferences, :channels, 0, :notificationPolicyOverrides, 0, :frequency)
      ).to eq('daily')
    end
  end

  context 'account' do
    it 'enables notifications' do
      NotificationPolicyOverride.enable_for_context(@teacher, @account, enable: false)
      result = run_mutation(
        context_type: 'Account',
        account_id: @account.id,
        enabled: true
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be nil
      expect(result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferencesEnabled)).to be true
      expect(NotificationPolicyOverride.enabled_for(@teacher, @account)).to be true
    end

    it 'disables notifications' do
      NotificationPolicyOverride.enable_for_context(@teacher, @account)
      result = run_mutation(
        context_type: 'Account',
        account_id: @account.id,
        enabled: false
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be nil
      expect(result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferencesEnabled)).to be false
      expect(NotificationPolicyOverride.enabled_for(@teacher, @account)).to be false
    end

    it 'creates notification policy overrides' do
      result = run_mutation(
        context_type: 'Account',
        account_id: @account.id,
        communication_channel_id: @teacher.communication_channels.first.id,
        notification_category: 'Due_Date',
        frequency: 'immediately'
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be nil
      expect(
        result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferences, :channels, 0, :notificationPolicyOverrides, 0, :frequency)
      ).to eq('immediately')
    end
  end

  context 'no context' do
    it 'does not update enabled if not provided a context' do
      result = run_mutation(enabled: false)
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be nil

      # Enabled defaults to true when not set which is why we expect true here
      expect(NotificationPolicyOverride.enabled_for(@teacher, @account)).to be true
      expect(NotificationPolicyOverride.enabled_for(@teacher, @course)).to be true
    end

    it 'updates notification policies when no context is provided' do
      result = run_mutation(
        communication_channel_id: @teacher.communication_channels.first.id,
        notification_category: 'Due_Date',
        frequency: 'immediately'
      )
      expect(result.dig(:data, :updateNotificationPreferences, :errors)).to be nil
      expect(
        result.dig(:data, :updateNotificationPreferences, :user, :notificationPreferences, :channels, 0, :notificationPolicies, 0, :frequency)
      ).to eq('immediately')
      expect(
        NotificationPolicy.find_or_update_for_category(
          @teacher.communication_channels.first,
          'Due Date'
        ).first.frequency
      ).to eq('immediately')
    end
  end

  describe 'invalid input' do
    it 'errors when context_type is Account and is not given an account_id' do
      result = run_mutation(
        context_type: 'Account',
        enabled: true
      )
      expect(
        result.dig(:data, :updateNotificationPreferences, :errors, 0, :message)
      ).to eq 'Account level notification preferences require an account_id to update'
    end

    it 'errors when context_type is Course and is not given a course_id' do
      result = run_mutation(
        context_type: 'Course',
        enabled: true
      )
      expect(
        result.dig(:data, :updateNotificationPreferences, :errors, 0, :message)
      ).to eq 'Course level notification preferences require a course_id to update'
    end

    it 'errors when given an account_id for an account that does not exist' do
      result = run_mutation(
        context_type: 'Account',
        account_id: 987654321,
        enabled: false
      )
      expect(result.dig(:errors, 0, :message)).to eq 'not found'
    end

    it 'errors when given a course_id for a course that does not exist' do
      result = run_mutation(
        context_type: 'Course',
        course_id: 987654321,
        enabled: false
      )
      expect(result.dig(:errors, 0, :message)).to eq 'not found'
    end
  end
end
