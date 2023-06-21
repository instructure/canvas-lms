# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module BroadcastPolicy
  class PolicyList
    attr_reader :notifications

    def initialize
      @notifications = []
    end

    def populate(&)
      instance_eval(&)
      @current_notification = nil
    end

    def broadcast(record)
      @notifications.each { |notification| notification.broadcast(record) }
    end

    def dispatch(notification_name)
      titleized = notification_name.to_s.titleize.gsub(/sms/i, "SMS")
      @current_notification = @notifications.find { |notification| notification.dispatch == titleized }
      return if @current_notification

      @current_notification = NotificationPolicy.new(titleized)
      @notifications << @current_notification
    end

    def current_notification
      raise "Must call dispatch in the policy block first" unless @current_notification

      @current_notification
    end
    protected :current_notification

    def to(&block)
      current_notification.to = block
    end

    def whenever(&block)
      current_notification.whenever = block
    end

    def data(&block)
      current_notification.data = block
    end

    # filter_asset_by_recipient is a way for the asset (ie assignment, announcement)
    # to filter users out that do not apply to the notification like when a due
    # date is different for a specific user when using variable due dates.
    def filter_asset_by_recipient(&block)
      current_notification.recipient_filter = block
    end

    def find_policy_for(notification)
      @notifications.detect { |policy| policy.dispatch == notification }
    end
  end
end
