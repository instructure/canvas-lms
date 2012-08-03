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

class NotificationPolicy < ActiveRecord::Base
  
  belongs_to :notification
  belongs_to :communication_channel
  
  before_save :infer_frequency

  attr_accessible :notification, :communication_channel, :frequency, :notification_id, :communication_channel_id

  validates_presence_of :communication_channel_id
  
  # This is for choosing a policy for another context, so:
  # NotificationPolicy.for(notification) or
  # communication_channel.notification_policies.for(notification)
  named_scope :for, lambda { |context| 
    case context
    when User
      { :joins => :communication_channel, :conditions => { 'communication_channels.user_id' => context.id } }
    when Notification
      { :conditions => ['notification_policies.notification_id = ?', context.id] }
    else
      {}
    end
  }
  
  # TODO: the named_scope name should be self-explanatory... change
  # this to by_frequency or something
  # This is for choosing a policy by frequency
  named_scope :by, lambda { |freq| 
    case freq
    when Array
      { :conditions => { :frequency => freq.map{|f| f.to_s} } }
    else
      { :conditions => ['notification_policies.frequency = ?', freq.to_s] }
    end
  }
  
  named_scope :where, lambda { |where| { :include => [:communication_channel], :conditions => where } }
  named_scope :in_state, lambda { |state| { :conditions => ["notification_policies.workflow_state = ?", state.to_s] } }

  def infer_frequency
    self.frequency ||= "immediately"
  end
  protected :infer_frequency
  
  def communication_preference
    return nil unless broadcast
    communication_channel || user.communication_channel
  end
  
  def self.spam_blocked_by(user)
    NotificationPolicy.delete_all({:communication_channel_id => user.communication_channels.map(&:id)})
    cc = user.communication_channel
    cc.confirm
    Notification.all.each do |notification|
      if notification.category == "Message"
        NotificationPolicy.create(:notification => notification, :communication_channel => cc, :frequency => 'immediately')
      else
        NotificationPolicy.create(:notification => notification, :communication_channel => cc, :frequency => 'never')
      end
    end
    true
  rescue => e
    puts e.to_s
    false
  end

  def self.setup_for(user, params)
    # Check for user preference settings first. Some communication related options are available on the page.
    # Handle those if given.
    user_prefs = params[:user]
    # If have user preference settings and this is a root account, check further to see if settings can be changed
    if user_prefs && params[:root_account]
      user_prefs.each_pair do |key, value|
        bool_val = (value == 'true')
        # save the preference as a symbol (convert from string)
        case key.to_sym
          when :send_scores_in_emails
            # Only set if a root account and the root account allows the setting.
            if params[:root_account].settings[:allow_sending_scores_in_emails] != false
              user.preferences[:send_scores_in_emails] = bool_val
            end
          when :no_submission_comments_inbox
            user.preferences[:no_submission_comments_inbox] = bool_val
        end
      end
      user.save!
    else
      # User preference change not being made. Make a notification policy change.

      # Using the category name, fetch all Notifications for the category. Will set the desired value on them.
      notifications = Notification.scoped(:select => :id, :conditions => {:category => params[:category]}).all.map(&:id)
      # Look for frequency settings and only recognize a valid value.
      frequency = case params[:frequency]
        when Notification::FREQ_IMMEDIATELY, Notification::FREQ_DAILY, Notification::FREQ_WEEKLY, Notification::FREQ_NEVER
          params[:frequency]
        else
          Notification::FREQ_NEVER
      end

      # Find any existing NotificationPolicies for the category and the channel. If frequency is 'never', delete the
      # entry. If other than than, create or update the entry.
      NotificationPolicy.transaction do
        notifications.each do |notification_id|
          p = NotificationPolicy.scoped(:include => :communication_channel,
                                        :conditions => ['communication_channels.user_id = ?', user.id] ).
            find_or_initialize_by_communication_channel_id_and_notification_id(params[:channel_id], notification_id)
          # Set the frequency and save
          p.frequency = frequency
          p.save!
        end
      end # transaction
    end #if..else
    nil
  end

  # Fetch the user's NotificationPolicies but whenever a category is not represented, create a NotificationPolicy on the primary
  # CommunicationChannel with a default frequency set.
  # Returns the full list of policies for the user
  #
  # ===== Arguments
  # * <tt>user</tt> - The User instance to load the values for.
  # * <tt>full_category_list</tt> - An array of Notification models that represent the unique list of categories that should be displayed for the user.
  #
  # ===== Returns
  # A list of NotificationPolicy entries for the user. May include newly created entries if defaults were needed.
  def self.setup_with_default_policies(user, full_category_list)
    categories = {}
    # Get the list of notification categories and its default. Like this: {"Announcement" => 'immediately'}
    full_category_list.each {|c| categories[c.category] = c.default_frequency}
    default_channel_id = user.communication_channel.try(:id)
    # Load unique list of categories that the user currently has settings for.
    user_categories = NotificationPolicy.for(user).scoped(:joins => :notification,
                                                          :select => 'DISTINCT notifications.category').all.map{|c| c.category}
    missing_categories = (categories.keys - user_categories)
    missing_categories.each do |need_category|
      # Create the settings for a completely unrepresented category. Use default communication_channel (primary email)
      self.setup_for(user, {:category => need_category,
                            :channel_id => default_channel_id,
                            :frequency => categories[need_category]})
    end
    # Load and return user's policies after defaults may or may not have been set.
    NotificationPolicy.scoped(:include => :notification).for(user)
  end
end
