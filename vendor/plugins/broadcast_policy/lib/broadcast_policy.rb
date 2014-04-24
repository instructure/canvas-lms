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
#   whenever { |record| record.just_created? }
# end
#
# set_broadcast_policy do
#   dispatch :assignment_change
#   to { self.students }
#   whenever { |record|
#     record.prior_version != self.version and true
#     # ... some field-wise comparison
#   }
# end
#
# u = User.first
# a = Account.first
# a.check_policy(u)

module Instructure #:nodoc:
  module BroadcastPolicy #:nodoc:

    class PolicyList
      def initialize
        @notifications = []
      end

      def populate(&block)
        self.instance_eval(&block)
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
        self.current_notification.to = block
      end

      def whenever(&block)
        self.current_notification.whenever = block
      end

      def context(&block)
        self.current_notification.context = block
      end

      def data(&block)
        self.current_notification.data = block
      end

      def filter_asset_by_recipient(&block)
        self.current_notification.recipient_filter = block
      end

      def find_policy_for(notification)
        @notifications.detect{|policy| policy.dispatch == notification.name}
      end
    end

    class NotificationPolicy
      attr_accessor :dispatch, :to, :whenever, :context, :data, :recipient_filter

      def initialize(dispatch)
        self.dispatch = dispatch
        self.recipient_filter = lambda { |record, user| record }
      end

      # This should be called for an instance.  It can only be sent out if the
      # condition is met, if there is a notification that we can find, and if
      # there is someone to send this to.  At this point, a Message record is
      # created, which will be delayed, consolidated, dispatched to the right
      # server, and then finally sent through that server.
      #
      # This now sets a series of temporary flags while working for audit
      # reasons.
      def broadcast(record)
        if (record.skip_broadcasts rescue false)
          record.messages_failed[self.dispatch] = "Broadcasting explicitly skipped"
          return false
        end
        begin
          meets_condition = record.instance_eval &self.whenever
        rescue
          meets_condition = false
          record.messages_failed[self.dispatch] = "Error thrown attempting to meet condition."
          return false
        end

        unless meets_condition
          record.messages_failed[self.dispatch] = "Did not meet condition."
          return false
        end
        notification = Notification.by_name(self.dispatch)
        # logger.warn "Could not find notification for #{record.inspect}" unless notification
        unless notification
          record.messages_failed[self.dispatch] = "Could not find notification: #{self.dispatch}."
          return false
        end
        # self.consolidated_notifications[notification_name.to_s.titleize] rescue nil
        begin
          to_list = record.instance_eval &self.to
        rescue
          to_list = nil
          record.messages_failed[self.dispatch] = "Error thrown attempting to generate a recipient list."
          return false
        end
        unless to_list
          record.messages_failed[self.dispatch] = "Could not generate a recipient list."
          return false
        end
        to_list = Array[to_list].flatten

        begin
          asset_context = record.instance_eval &self.context if self.context
        rescue
          record.messages_failed[self.dispatch] = "Error thrown attempting to get asset_context."
          return false
        end

        begin
          data = record.instance_eval &self.data if self.data
        rescue
          record.messages_failed[self.dispatch] = "Error thrown attempting to get data."
          return false
        end

        NotificationPolicy.send_notification(record, self.dispatch, notification, to_list, asset_context, data)
      end

      def self.send_notification(record, dispatch, notification, to_list, asset_context=nil, data=nil)
        n = DelayedNotification.send_later_if_production_enqueue_args(
            :process,
            { :priority => Delayed::LOW_PRIORITY },
            record, notification, (to_list || []).compact.map(&:asset_string), asset_context, data)

        n ||= DelayedNotification.new(:asset => record, :notification => notification,
                                      :recipient_keys => (to_list || []).compact.map(&:asset_string),
                                      :asset_context => asset_context, :data => data)
        if Rails.env.test?
          record.messages_sent[dispatch] = n.is_a?(DelayedNotification) ? n.process : n
        end
        n
      end
    end # NotificationPolicy

    module ClassMethods #:nodoc:
      def has_a_broadcast_policy
        extend Instructure::BroadcastPolicy::SingletonMethods
        include Instructure::BroadcastPolicy::InstanceMethods
        after_save :broadcast_notifications # Must be defined locally...
        before_save :set_broadcast_flags
      end

      # Uses the 'context' relationship as the governing relationship.
      # Canonically, this probably will look something like:
      # course -> professor -> section -> department -> account.
      # So, this method recurses the list, keeping the nearer values.  So,
      # account can setup a series of default notifications, but a professor
      # can override these.

      # Removing for now, until we memoize this
      # def consolidated_notifications
      #   instance_notifications = Notification.find_all_by_context_type_and_context_id(self.class.to_s, self.id)
      #   class_notifications = Notification.find_all_by_context_type_and_context_id(self.class.to_s, nil)
      #   context_notifications = context.consolidated_notifications if
      #     defined?(context) and context.respond_to?(:consolidated_notifications)
      #   context_notifications ||= []
      #
      #   cn = hashify(*instance_notifications)
      #   cn.reverse_merge!(*class_notifications)
      #   cn.reverse_merge!(*context_notifications)
      #   cn
      # end
      #
      # def hashify(*list)
      #   list.inject({}) {|h, v| h[v.name] = v; h}
      # end
      # protected :hashify

    end

    # This is where the DSL is defined.
    module SingletonMethods

      def self.extended(klass)
        klass.send(:class_attribute, :broadcast_policy_list)
      end

      # This stores the policy for broadcasting changes on a class.  It works like a
      # macro.  The policy block will be stored in @broadcast_policy.
      def set_broadcast_policy(&block)
        self.broadcast_policy_list ||= PolicyList.new
        self.broadcast_policy_list.populate(&block)
      end

      def set_broadcast_policy!(&block)
        self.broadcast_policy_list = PolicyList.new
        self.broadcast_policy_list.populate(&block)
      end

    end # SingletonMethods

    module InstanceMethods

      # Some generic flags for inside the policy
      attr_accessor :just_created, :prior_version

      # Some flags for auditing policy matching
      def messages_sent
        @messages_sent ||= {}
      end

      def clear_broadcast_messages
        @messages_sent = {}
        @messages_failed = {}
      end

      # Whenever a requirement fails, this is stored here.
      def messages_failed
        @messages_failed ||= {}
      end

      # This is called before_save
      def set_broadcast_flags
        @broadcasted = false
        unless @skip_broadcasts
          self.just_created = self.new_record?
          self.prior_version = generate_prior_version
        end
      end

      def generate_prior_version
        obj = self.class.new
        self.attributes.each do |attr, value|
          obj.__send__("#{attr}=", value) rescue nil
        end
        self.changes.each do |attr, values|
          obj.__send__("#{attr}=", values[0]) rescue nil
        end
        obj.workflow_state = self.workflow_state_was if obj.respond_to?("workflow_state=") && self.respond_to?("workflow_state_was")
        obj
      end

      # This is called after_save
      def broadcast_notifications
        return if @broadcasted
        @broadcasted = true
        raise ArgumentError, "Broadcast Policy block not supplied for #{self.class.to_s}" unless self.class.broadcast_policy_list
        self.class.broadcast_policy_list.broadcast(self)
      end

      attr_accessor :skip_broadcasts

      def save_without_broadcasting
        begin
          @skip_broadcasts = true
          self.save
        ensure
          @skip_broadcasts = false
        end
      end

      def save_without_broadcasting!
        begin
          @skip_broadcasts = true
          self.save!
        ensure
          @skip_broadcasts = false
        end
      end

      # The rest of the methods here should just be helper methods to make
      # writing a condition that much easier.
      def changed_in_state(state, opts={})
        fields  = opts[:fields] || []
        fields = [fields] unless fields.is_a?(Array)

        begin
          fields.map {|field| self.prior_version.send(field) != self.send(field) }.include?(true) and
          self.workflow_state == state.to_s and
          self.prior_version.workflow_state == state.to_s
        rescue Exception => e
          logger.warn "Could not check if a change was made: #{e.inspect}"
          false
        end
      end

      def changed_in_states(states, opts={})
        !states.select{|s| changed_in_state(s, opts)}.empty?
      end

      def remained_in_state(state)
        begin
          self.workflow_state == state.to_s and
          self.prior_version.workflow_state == state.to_s
        rescue Exception => e
          logger.warn "Could not check if a record remained in the same state: #{e.inspect}"
          false
        end
      end

      def changed_state(new_state=nil, old_state=nil)
        begin
          if new_state and old_state
            self.workflow_state == new_state.to_s and
            self.prior_version.workflow_state == old_state.to_s
          elsif new_state
            self.workflow_state.to_s == new_state.to_s and
            self.prior_version.workflow_state != self.workflow_state
          else
            self.workflow_state != self.prior_version.workflow_state
          end
        rescue Exception => e
          ErrorReport.log_exception(:broadcast_policy, e, message: "Could not check if a record changed state")
          logger.warn "Could not check if a record changed state: #{e.inspect}"
          false
        end
      end
      alias :changed_state_to :changed_state

      def filter_asset_by_recipient(notification, recipient)
        policy = self.class.broadcast_policy_list.find_policy_for(notification)
        policy ? policy.recipient_filter.call(self, recipient) : self
      end

    end # InstanceMethods
  end # BroadcastPolicy
end # Instructure
