#
# Copyright (C) 2011 Instructure, Inc.
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

# This should work like this:
#
# class Account < ActiveRecord::Base
#   has_a_broadcast_policy
#
#   set_broadcast_policy do
#     dispatch(:name)
#     to { some_list }
#     whenever { |obj| obj.something == condition }
#   end
# end
#
# Some useful examples:
#
# set_broadcast_policy do
#   dispatch :new_assignment
#   to { self.students }
#   whenever { |record| record.just_created }
# end
#
# set_broadcast_policy do
#   dispatch :assignment_change
#   to { self.students }
#   whenever { |record|
#     record.workflow_state_changed?
#     # ... some field-wise comparison
#   }
# end
#
# u = User.first
# a = Account.first
# a.check_policy(u)

module BroadcastPolicy #:nodoc:
 
  def self.notifier
    @notifier ||= @notifier_proc.call if @notifier_proc
    @notifier
  end

  def self.notifier=(notifier_or_proc)
    if notifier_or_proc.respond_to?(:call)
      @notifier = nil
      @notifier_proc = notifier_or_proc
    else
      @notifier = notifier_or_proc
    end
  end

  def self.notification_finder
    @notification_finder ||= @notification_finder_proc.call if @notification_finder_proc
    @notification_finder
  end

  def self.notification_finder=(notification_finder_or_proc)
    if notification_finder_or_proc.respond_to?(:call)
      @notification_finder = nil
      @notification_finder_proc = notification_finder_or_proc
    else
      @notification_finder = notification_finder_or_proc
    end
  end

  def self.reset_notifiers!
    @notifier = nil if @notifier_proc
    @notification_finder = nil if @notification_finder_proc
  end

  require 'active_support/core_ext/class/attribute'
  require 'active_support/core_ext/string/inflections'
  require 'broadcast_policy/policy_list'
  require 'broadcast_policy/notification_policy'
  require 'broadcast_policy/class_methods'
  require 'broadcast_policy/singleton_methods'
  require 'broadcast_policy/instance_methods'
end
