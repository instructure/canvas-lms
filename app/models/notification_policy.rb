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

  def self.refresh_for(user)
    categories = Notification.dashboard_categories
    policies = NotificationPolicy.for(user).to_a
    params = {}
    categories.each do |category|
      ps = policies.select{|p| p.notification_id == category.id }
      params["category_#{category.category_slug}".to_sym] = {}
      ps.each do |p|
        params["category_#{category.category_slug}".to_sym]["channel_#{p.communication_channel_id}"] = p.frequency
      end
    end
    setup_for(user, params)
  end
  
  def self.setup_for(user, params)
    @user = user
    user.preferences[:send_scores_in_emails] = params[:root_account] && 
        params[:root_account].settings[:allow_sending_scores_in_emails] != false && 
        params[:user] && params[:user][:send_scores_in_emails] == '1'
    params[:user].try(:delete, :send_scores_in_emails)
    @user.update_attributes(params[:user])
    @channels = @user.communication_channels
    categories = Notification.dashboard_categories
    prefs_to_save = []
    categories.each do |category|
      category_data = params["category_#{category.category_slug}".to_sym]
      channels = []
      if category_data
        category_data.each do |key, value|
          tag, id = key.split("_", 2)
          channels << @channels.find(id) if tag == "channel" rescue nil
        end
        channels.compact!
        notifications = Notification.find_all_by_category(category.category)
        notifications.each do |notification|
          if channels.empty?
            channels << @user.communication_channel
          end
          if category.category == 'Message'
            found_immediately = channels.any?{|c| category_data["channel_#{c.id}".to_sym] == 'immediately' }
            unless found_immediately
              channels << @user.communication_channel
              category_data["channel_#{@user.communication_channel.id}".to_sym] = 'immediately'
            end
          end
          channels.uniq.each do |channel|
            frequency = category_data["channel_#{channel.id}".to_sym] || 'never'
            pref = channel.notification_policies.new
            pref.notification_id = notification.id
            pref.frequency = frequency
            prefs_to_save << pref
          end
        end
      end
    end
    NotificationPolicy.transaction do
      NotificationPolicy.delete_all({:communication_channel_id => user.communication_channels.map(&:id)})
      prefs_to_save.each{|p| p.save! }
    end
    categories = Notification.dashboard_categories
    @user.reload
    @policies = NotificationPolicy.for(@user).scoped(:conditions => { :notification_id => categories.map(&:id)})
    @policies
  end
end
