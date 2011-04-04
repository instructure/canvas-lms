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

class Message < ActiveRecord::Base
  include Workflow
  include SendToStream

  has_many :attachments, :as => :context
  belongs_to :notification
  belongs_to :context, :polymorphic => true
  belongs_to :communication_channel
  belongs_to :user
  belongs_to :asset_context, :polymorphic => true

  after_save :stage_message
  before_save :move_messages_for_deleted_users
  before_save :infer_defaults
  before_save :move_dashboard_messages
  before_save :set_asset_context_code
  validates_length_of :body, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :transmission_errors, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
    
  def move_messages_for_deleted_users
    self.workflow_state = 'closed' if self.context_type != "ErrorReport" && (!self.user || self.user.deleted?)
  end
    
  def transmission_errors=(val)
    if !val || val.length < self.class.maximum_text_length
      write_attribute(:transmission_errors, val)
    else
      write_attribute(:transmission_errors, val[0,self.class.maximum_text_length])
    end
  end
  
  on_create_send_to_streams do
    if self.to == "dashboard" && Notification.types_to_show_in_feed.include?(self.notification_name)
      self.user_id
    else
      []
    end
  end
  
  def move_dashboard_messages
    self.workflow_state = 'dashboard' if self.to == 'dashboard' && !self.cancelled? && !self.closed?
  end
  
  def set_asset_context_code
    self.asset_context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  named_scope :for_asset_context_codes, lambda { |context_codes| { 
    :conditions => {:asset_context_code => context_codes} } 
  }

  # TODO: DOES ANYTHING USE THIS?  IT IS DEPRECATED BY THE asset_context_code COLUMN
  def context_code
    self.asset_context_code
  end
  
  def notification_category
    @cat ||= self.notification.category
  end
  
  named_scope :for, lambda { |context| 
    { :conditions => ['messages.context_type = ? and messages.context_id = ?', context.class.base_ar_class.to_s, context.id]}
  }
  named_scope :after, lambda{ |date|
    { :conditions => ['messages.created_at > ?', date] }
  }

  named_scope :to_dispatch, lambda { 
    { :conditions => ["messages.workflow_state = ? and messages.dispatch_at <= ? and 'messages.to' != ?", 'staged', Time.now.utc, 'dashboard' ]}
  }
  named_scope :to_email, lambda{
    { :conditions => ['messages.path_type = ? OR messages.path_type = ?', 'email', 'sms'] }
  }
  named_scope :to_facebook, lambda{
    { :conditions => ['messages.path_type = ? AND messages.workflow_state = ?', 'facebook', 'sent'], :order => 'sent_at DESC', :limit => 25 }
  }
  named_scope :not_to_email, lambda{
    { :conditions => ['messages.path_type != ? AND messages.path_type != ?', 'email', 'sms'] }
  }

  named_scope :by_name, lambda { |notification_name|
    { :conditions => ['messages.notification_name = ?', notification_name]}
  }
  
  named_scope :directed_to, lambda { |to|
    if to == "dashboard"
      { :conditions => ['messages.to = ?', to]}
    else
      { :conditions => ['messages.communication_channel_id = ?', CommunicationChannel.find_by_path(to)]}
    end
  }
  
  named_scope :before, lambda { |date|
    {:conditions => ['messages.created_at < ?', date] }
  }
  
  def self.old_dashboard
    res = []
    Notification.find_all_by_category("Course Content").each do |notification|
      res += Message.in_state(:dashboard).by_name(notification.name).before(2.weeks.ago)[0..10]
    end
    res
  end
  
  named_scope :for_user, lambda { |user|
    { :conditions => {:user_id => user}}
  }
  
  # For finding a very particular message:
  # Message.for(context).by_name(name).directed_to(to).for_user(user), or
  # messages.for(context).by_name(name).directed_to(to).for_user(user)
  # Where user can be a User or id, name needs to be the Notification name.
  named_scope :staged, lambda {
    { :conditions => ['messages.workflow_state = ? and messages.dispatch_at > ?', 'staged', DateTime.now.utc.to_s(:db) ]}
  }
  
  named_scope :in_state, lambda { |state| 
    case state
    when Array
      { :conditions => { :workflow_state => state.map{|f| f.to_s} } }
    else
      { :conditions => {:workflow_state => state.to_s } } 
    end
  }

  workflow do
    state :created do
      event :stage, :transitions_to => :staged do
        self.dispatch_at = Time.now.utc + self.delay_for
        if self.to != 'dashboard' && !@stage_without_dispatch
          MessageDispatcher.dispatch(self)
        end
      end
      event :cancel, :transitions_to => :cancelled
      event :close, :transitions_to => :closed # needed for dashboard messages
    end

    state :staged do
      event :dispatch, :transitions_to => :sending
      event :cancel, :transitions_to => :cancelled
      event :close, :transitions_to => :closed # needed for dashboard messages
    end

    state :sending do
      event :complete_dispatch, :transitions_to => :sent do
        self.sent_at ||= Time.now
      end
      event :cancel, :transitions_to => :cancelled
      event :close, :transitions_to => :closed
      event :errored_dispatch, :transitions_to => :staged do
        # A little delay so we don't churn so much when the server is down.
        self.dispatch_at = Time.now.utc + 5.minutes
      end
    end

    state :sent do
      event :close, :transitions_to => :closed
      event :bounce, :transitions_to => :bounced do
        # Permenant reminder that this bounced.
        self.communication_channel.bounce_count += 1
        self.communication_channel.save!
        self.is_bounced = true
      end
      event :recycle, :transitions_to => :staged
    end
    
    state :bounced do
      event :close, :transitions_to => :closed
    end
    
    state :dashboard do
      event :close, :transitions_to => :closed
      event :cancel, :transitions_to => :closed
    end
    state :cancelled

    state :closed do
      event :send_message, :transitions_to => :closed do
        self.sent_at ||= Time.now
      end
    end

  end

  # skip dispatching the message during the stage transition, useful when batch
  # dispatching.
  def stage_without_dispatch!
    @stage_without_dispatch = true
  end
  
  # Sets a few defaults and gets it on its way to be dispatched.  
  # The path: created -> staged -> sending -> sent 
  def stage_message
    self.stage if self.state == :created
    if self.dashboard?
      messages = Message.in_state(:dashboard).find_all_by_notification_id_and_context_id_and_context_type_and_user_id(self.notification_id, self.context_id, self.context_type, self.user_id)
      (messages - [self]).each{|m| m.close }
    end
  end
  
  def define_content(name, &block)
    old_output, @output = @output, ''
    yield
    self.instance_variable_set("@message_content_#{name.to_s}".to_sym, @output.to_s.strip)
    old_output.sub!(/\n\z/, '')
    @output = old_output
    ""
  end
  
  attr_writer :delayed_messages
  
  def content(name)
    self.instance_variable_get("@message_content_#{name.to_s}".to_sym)
  end
  
  def main_link
    content(:link)
  end
  
  def parse!(path_type=nil)
    raise StandardError, "Cannot parse without a context" unless self.context
    @user = self.user
    old_time_zone = Time.zone.name || "UTC"
    Time.zone = (@user && @user.time_zone) || old_time_zone
    # This makes me sad every time I see it.  What we call context on a 
    # message is different than what we call context anywhere else in the
    # app.  In message templates you should use "asset" instead of "context"
    # to prevent confusion.
    @context = self.context
    @asset = @context
    context, asset, user, delayed_messages = [@context, @asset, @user, @delayed_messages]
    @time_zone = Time.zone
    time_zone = Time.zone
    path_type ||= self.communication_channel.path_type rescue path_type
    path_type = "summary" if self.to == 'dashboard'
    path_type ||= "email"
    filename = self.notification.name.downcase.gsub(/\s/, '_') + "." + path_type + ".erb" #rescue "not.found"
    path = Canvas::MessageHelper.find_message_path(filename)
    if !(File.exist?(path) rescue false)
      filename = self.notification.name.downcase.gsub(/\s/, '_') + ".email.erb" #rescue "not.found"
      path = Canvas::MessageHelper.find_message_path(filename)
    end
    if (File.exist?(path) rescue false)
      message = File.read(path)
      @message_content_link = nil; @message_content_subject = nil
      self.extend TextHelper
      b = binding
      
      self.body = ERB.new(message, nil, "%<>", "@output").result(b).strip
      if path_type == 'email'
        message = File.read(Canvas::MessageHelper.find_message_path('_email_footer.email.erb'))
        comm_message = ERB.new(message, nil, "%<>", "@output").result(b).strip rescue nil
        self.body = self.body + "\n\n\n\n\n\n________________________________________\n" + comm_message if comm_message
      end
      self.subject = @message_content_subject || "Canvas Alert"
      self.url = @message_content_link || nil
      self.body
    else
      self.extend TextHelper
      b = binding
      main_link = ERB.new(self.notification.main_link || "", nil, "%<>").result(b)
      b = binding
      self.subject = ERB.new(self.subject, nil, "%<>").result(b)
      self.body = ERB.new(self.body, nil, "%<>").result(b)
      self.transmission_errors = "couldn't find #{path}"
    end
    Time.zone = old_time_zone
    self.body
  end
  
  def reply_to_address
    res = (self.forced_reply_to || nil) rescue nil
    res = nil if self.path_type == 'sms' rescue false
    res = self.from if self.context_type == 'ErrorReport'
    res ||= HostUrl.outgoing_email_address
    res
  end
  
  def deliver
    self.dispatch
    
    if not self.path_type
      logger.warn("Could not find a path type for #{self.inspect}")
      return
    end

    delivery_method = "deliver_via_#{self.path_type}".to_sym
    if not delivery_method or not self.respond_to?(delivery_method)
      logger.warn("Could not set delivery_method from #{self.path_type}")
      return
    end
    
    self.send(delivery_method)
  end
  
  def self.dashboard_messages(messages)
    message_types = {}
    messages.each do |m|
      type = m.notification.category rescue "Other"
      if type
        message_types[type] ||= []
        message_types[type] << m
      end
    end
    message_types.to_a.sort_by{|m| m[0] == "Other" ? "ZZZZ" : m[0]}
  end

  def formatted_body
    if path_type == 'facebook'
      res = (body || "").gsub(/\n/, "<br/>\n").gsub(/(\s\s+)/) {|str| str.gsub(/\s/, "&nbsp;") }
    elsif path == 'email'
      self.extend TextHelper
      res = format_message(body).first
      res
    else
      body
    end
  end
    
  def infer_defaults
    self.notification_name ||= self.notification.name if self.notification
    self.notification_category ||= self.notification.category if self.notification
    self.path_type ||= self.communication_channel.path_type rescue nil
    self.path_type = 'summary' if self.to == 'dashboard'
    self.path_type = 'email' if self.context_type == 'ErrorReport'
    self.to_email = true if self.path_type == 'email' || self.path_type == 'sms'
    self.from_name = "Instructure Canvas"
    self.from_name = self.asset_context.name if (self.asset_context && self.asset_context.name && self.notification.dashboard? rescue false)
    self.from_name = self.from_name if self.respond_to?(:from_name)
    true
  end
    
  protected
  
    def deliver_via_email
      logger.info "Delivering mail: #{self.inspect}"
      res = nil
      begin
        res = Mailman.deliver_message(self)
      rescue Net::SMTPServerBusy => e
        @exception = e
        logger.error "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
        if e.message && e.message.match(/Bad recipient/)
          self.cancel
        end
      rescue Timeout::Error => e
        @exception = e
        logger.error "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
      rescue => e
        @exception = e
        logger.error "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
      end
      if res
        complete_dispatch
      elsif @exception 
        if !@exception.is_a?(Timeout::Error)
          ErrorLogging.log_error(:default, {
            :message => "Message delivery failed",
            :to => self.to,
            :object => self.inspect.to_s,
            :error_type => (@exception.inspect rescue ''),
            :exception_message => (@exception.message rescue ''),
            :failure_status => (@exception.to_s rescue ''),
            :backtrace => (@exception.backtrace rescue '')
          })
        end
        self.errored_dispatch
        raise @exception
      end
      true
    end
  
    def deliver_via_chat
      # record_delivered
    end
    
    def deliver_via_facebook
      @@facebooker_session ||= Facebooker::Session.create
      user = Facebooker::User.new((self.to.to_i.to_s rescue "0"), @@facebooker_session)
      res = user.dashboard_increment_count rescue nil
      # TODO: now that we're just incrementing the dashboard count, check
      # the possible return values...
      # Forcing skip of this code until I can find out what happens when you're
      # throttled.  We shouldn't delete facebook membership data just because of
      # throttling...
      if false #&& (!res || res == "")
        logger.info("cannot send notification to facebook user #{self.to}, deleting policies")
        # If nothing returned, this is not a subscribed user id, so the channel should probably
        # be disabled.  I'm sure Facebook will get mad if we keep sending notifications to
        # users who have uninstalled the app.
        ErrorLogging.log_error(:default, {
          :message => "Failure response from Facebook, deleting policies and channel",
          :to => self.to,
          :object => self.inspect.to_s
        })
        self.errored_dispatch
        cc = CommunicationChannel.find_by_path_and_path_type(self.to, 'facebook')
        cc.destroy if cc
        UserService.find_by_user_id_and_service(cc.user_id, 'facebook').destroy rescue nil
        policies = NotificationPolicy.find_all_by_communication_channel_id_and_notification_id(self.communication_channel_id, self.notification_id)
        policies.each{|p| p.destroy }
      else
        complete_dispatch
        true
      end
    end
    
    def deliver_via_sms
      # for now, this is good.
      deliver_via_email
    end
    
end
