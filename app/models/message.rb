#
# Copyright (C) 2011-2013 Instructure, Inc.
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
  # Included modules
  include ActionController::UrlWriter
  include ERB::Util
  include SendToStream
  include TextHelper
  include Twitter
  include Workflow

  extend TextHelper

  # Associations
  belongs_to :asset_context, :polymorphic => true
  belongs_to :communication_channel
  belongs_to :context, :polymorphic => true
  belongs_to :notification
  belongs_to :user
  has_many   :attachments, :as => :context

  attr_accessible :to, :from, :subject, :body, :delay_for, :context, :path_type,
    :from_name, :sent_at, :notification, :user, :communication_channel,
    :notification_name, :asset_context, :data

  attr_writer :delayed_messages

  # Callbacks
  after_save  :stage_message
  before_save :infer_defaults
  before_save :move_dashboard_messages
  before_save :move_messages_for_deleted_users
  before_save :set_asset_context_code

  # Validations
  validates_length_of :body,                :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :transmission_errors, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true

  # Stream policy
  on_create_send_to_streams do
    if to == 'dashboard' && Notification.types_to_show_in_feed.include?(notification_name)
      user_id
    else
      []
    end
  end

  # State machine
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

  # Named scopes
  named_scope :for_asset_context_codes, lambda { |context_codes|
    { :conditions => { :asset_context_code => context_codes } }
  }

  named_scope :for, lambda { |context|
    { :conditions => ['messages.context_type = ? and messages.context_id = ?',
      context.class.base_ar_class.to_s, context.id] }
  }

  named_scope :after, lambda { |date|
    { :conditions => ['messages.created_at > ?', date] }
  }

  named_scope :to_dispatch, lambda {
    { :conditions => ["messages.workflow_state = ? and messages.dispatch_at <= ? and 'messages.to' != ?",
      'staged', Time.now.utc, 'dashboard'] }
  }

  named_scope :to_email, { :conditions =>
    ['messages.path_type = ? OR messages.path_type = ?', 'email', 'sms'] }

  named_scope :to_facebook, { :conditions =>
    ['messages.path_type = ? AND messages.workflow_state = ?',
     'facebook', 'sent'], :order => 'sent_at DESC', :limit => 25 }

  named_scope :not_to_email, { :conditions => 
    ['messages.path_type != ? AND messages.path_type != ?', 'email', 'sms'] }

  named_scope :by_name, lambda { |notification_name|
    { :conditions => ['messages.notification_name = ?', notification_name] }
  }

  named_scope :before, lambda { |date|
    { :conditions => ['messages.created_at < ?', date] }
  }

  named_scope :for_user, lambda { |user|
    { :conditions => {:user_id => user} }
  }

  # For finding a very particular message:
  # Message.for(context).by_name(name).directed_to(to).for_user(user), or
  # messages.for(context).by_name(name).directed_to(to).for_user(user)
  # Where user can be a User or id, name needs to be the Notification name.
  named_scope :staged, lambda {
    { :conditions => ['messages.workflow_state = ? and messages.dispatch_at > ?',
      'staged', DateTime.now.utc.to_s(:db) ]}
  }

  named_scope :in_state, lambda { |state|
    { :conditions => { :workflow_state => Array(state).map { |f| f.to_s } } }
  }

  # Public: Helper to generate a URI for the given subject. Overrides Rails'
  # built-in ActionController::PolymorphicRoutes#polymorphic_url method because
  # it forces option defaults for protocol and host.
  #
  # Differs from the built-in method in that it doesn't accept a hash as a
  # subject; only ActiveRecord objects and arrays.
  #
  # subject - An ActiveRecord object, or an array of ActiveRecord objects.
  # options - A hash of URI options (default: {}):
  #           :protocol - HTTP protocol string. Either 'http' or 'https'.
  #           :host - A host string (e.g. 'canvas.instructure.com').
  #
  # Returns a URL string.
  def polymorphic_url_with_context_host(subject, options = {})
    # Force options
    options[:protocol] = HostUrl.protocol
    options[:host]     = if subject.is_a?(Array)
                           HostUrl.context_host(subject.first)
                         else
                           HostUrl.context_host(subject)
                         end

    polymorphic_url_without_context_host(subject, options)
  end
  alias_method_chain :polymorphic_url, :context_host


  # Internal: Store any transmission errors in the database to help with later
  # debugging.
  #
  # val - An error string.
  #
  # Returns nothing.
  def transmission_errors=(val)
    write_attribute(:transmission_errors, val[0, self.class.maximum_text_length])
  end

  # Public: Custom getter that delegates and caches notification category to
  # associated notification 
  #
  # Returns a notification category string.
  def notification_category
    @cat ||= notification.try(:category)
  end

  # Public: Return associated notification's display category.
  #
  # Returns notification display category string.
  def notification_display_category
    notification.try(:display_category)
  end

  # Public: Skip message dispatch during stage transition. Used when batch
  # dispatching.
  #
  # Returns nothing.
  def stage_without_dispatch!
    @stage_without_dispatch = true
  end

  # Public: Stage the message during the dispatch process. Messages travel
  # from created -> staged -> sending -> sent.
  #
  # Returns nothing.
  def stage_message
    stage if state == :created

    if dashboard?
      messages = Message.in_state(:dashboard).scoped(:conditions => {
        :notification_id => notification_id,
        :context_id => context_id,
        :context_type => context_type,
        :user_id => user_id
      })

      (messages - [self]).each(&:close)
    end
  end

  # Public: Store content in a message_content_... instance variable.
  #
  # name  - The symbol name of the content.
  # block - ?
  #
  # Returns an empty string.
  def define_content(name, &block)
    old_output_buffer, @output_buffer = [@output_buffer, '']

    yield

    instance_variable_set(:"@message_content_#{name}",
      @output_buffer.to_s.strip)
    @output_buffer = old_output_buffer.sub(/\n\z/, '')

    ''
  end

  # Public: Get a message_content_... instance variable.
  #
  # name - The name of the message content variable as a symbol.
  #
  # Returns value of instance variable (should be a string?).
  def content(name)
    instance_variable_get(:"@message_content_#{name}")
  end

  # Public: Custom getter for @message_content_link.
  #
  # Returns string content from @message_content_link.
  def main_link
    content(:link)
  end

  # Public: Load a message template from app/messages. Also sets @i18n_scope.
  #
  # filename - The string path to the template (e.g. "/var/web/canvas/app/messages/template.email.erb")
  #
  # Returns a template string or false if it can't be found.
  def get_template(filename)
    path = Canvas::MessageHelper.find_message_path(filename)

    if !(File.exist?(path) rescue false)
      filename = self.notification.name.downcase.gsub(/\s/, '_') + ".email.erb"
      path = Canvas::MessageHelper.find_message_path(filename)
    end

    @i18n_scope = "messages." + filename.sub(/\.erb\z/, '')

    if (File.exist?(path) rescue false)
      File.read(path)
    else
      false
    end
  end

  # Public: Get the template name based on the path type.
  #
  # path_type - The path to send the message across, e.g, 'email'.
  #
  # Returns file name for erb template
  def template_filename(path_type=nil)
    self.notification.name.parameterize.underscore + "." + path_type + ".erb"
  end

  # Public: Load an HTML email template for this message.
  #
  # _binding - The binding to attach to the template.
  #
  # Returns a template string (or nil).
  def load_html_template(_binding)
    html_file   = template_filename('email.html')
    html_path   = Canvas::MessageHelper.find_message_path(html_file)

    if File.exist?(html_path)
      html_layout do
        Erubis::Eruby.new(File.read(html_path), :bufvar => '@output_buffer').result(_binding)
      end
    end
  end

  # Public: Return the layout for HTML emails. We need this because
  # Erubis::Eruby.new.result(binding) doesn't accept a block; by wrapping it
  # in a method we can pass it a block to handle the <%= yield %> call in the
  # layout.
  #
  # Returns an HTML string.
  def html_layout
    layout_path = Canvas::MessageHelper.find_message_path('_layout.email.html.erb')
    Erubis::Eruby.new(File.read(layout_path)).result(binding)
  end

  # Public: Assign the body, subject and url to the message.
  #
  # message_body_template - Raw template body
  # path_type             - Path to send the message across, e.g, 'email'.
  # _binding              - Message binding
  #
  # Returns message body
  def populate_body(message_body_template, path_type, _binding)
    # Build the body content based on the path type

    if path_type == 'facebook'
      # this will ensure we escape anything that's not already safe
      self.body = RailsXss::Erubis.new(message_body_template).result(_binding)
    else
      self.body = Erubis::Eruby.new(message_body_template,
        :bufvar => '@output_buffer').result(_binding)
      self.html_body = load_html_template(_binding) if path_type == 'email'
    end

    # Append a footer to the body if the path type is email
    if path_type == 'email'
      raw_footer_message = File.read(Canvas::MessageHelper.find_message_path('_email_footer.email.erb'))
      footer_message = Erubis::Eruby.new(raw_footer_message, :bufvar => "@output_buffer").result(b) rescue nil
      if footer_message.present?
        self.body = <<-END.strip_heredoc
          #{self.body}





          ________________________________________

          #{footer_message}
        END
      end
    end

    self.body
  end

  # Public: Prepare a message for delivery by setting body, subject, etc.
  #
  # path_type - The path to send the message across, e.g, 'email'.
  #
  # Returns nothing.
  def parse!(path_type=nil)
    raise StandardError, "Cannot parse without a context" unless self.context

    # Get the users timezone but maintain the original timezone in order to set it back at the end
    original_time_zone = Time.zone.name || "UTC"
    user_time_zone     = self.user.try(:time_zone) || original_time_zone
    Time.zone          = user_time_zone

    # Ensure we have a path_type
    path_type = 'dashboard' if to == 'summary'
    unless path_type
      path_type = communication_channel.try(:path_type) || 'email'
    end


    # Determine the message template file to be used in the message
    filename = template_filename(path_type)
    message_body_template = get_template(filename)

    context, asset, user, delayed_messages, asset_context, data = [self.context,
      self.context, @user, @delayed_messages, self.asset_context, @data]

    if message_body_template.present? && path_type.present?
      populate_body(message_body_template, path_type, binding)

      # Set the subject and url
      self.subject = @message_content_subject || t('#message.default_subject', 'Canvas Alert')
      self.url     = @message_content_link || nil
    else
      # Message doesn't exist so we flag the message as an error
      main_link    = Erubis::Eruby.new(self.notification.main_link || "").result(binding)
      self.subject = Erubis::Eruby.new(subject).result(binding)
      self.body    = Erubis::Eruby.new(body).result(binding)
      self.transmission_errors = "couldn't find #{Canvas::MessageHelper.find_message_path(filename)}"
    end

    self.body
  ensure
    # Set the timezone back to what it originally was
    Time.zone = original_time_zone if original_time_zone.present?

    @i18n_scope = nil
  end

  # Public: Construct a unique reply_to string for this message. This allows
  # us to associate any email responses to this message.
  #
  # Returns a secure ID string.
  def reply_to_secure_id
    Canvas::Security.hmac_sha1(global_id.to_s)
  end

  # Public: Construct a reply_to address for this message.
  #
  # Returns an email address string.
  def reply_to_address
    # Not sure this first line needs to be a thing.
    reply_address = (forced_reply_to || nil)  rescue nil
    reply_address = nil if path_type == 'sms' rescue false
    reply_address = from if context_type == 'ErrorReport'

    unless reply_address
      address, domain = HostUrl.outgoing_email_address.split('@')
      reply_address = "#{address}+#{reply_to_secure_id}-#{global_id}@#{domain}"
    end

    reply_address
  end

  # Public: Deliver this message.
  #
  # Returns nothing.
  def deliver
    # don't dispatch canceled or already-sent messages.
    return nil unless dispatch

    unless path_type.present?
      logger.warn "Could not find a path type for #{inspect}"
      return nil
    end

    delivery_method = "deliver_via_#{path_type}".to_sym

    if not delivery_method or not respond_to?(delivery_method)
      logger.warn("Could not set delivery_method from #{path_type}")
      return nil
    end

    send(delivery_method)
  end

  # Public: Fetch the dashboard messages for the given messages.
  #
  # messages - An array of message objects.
  #
  # Returns an array of dashboard messages.
  def self.dashboard_messages(messages)
    message_types = messages.inject({}) do |types, message|
      type = message.notification.category rescue 'Other'

      if type.present?
        types[type] ||= []
        types[type] << message
      end

      hash
    end

    # not sure what this is even doing?
    message_types.to_a.sort_by { |m| m[0] == 'Other' ? 'ZZZZ' : m[0] }
  end

  # Public: Format and return the body for this message.
  #
  # Returns a body string.
  def formatted_body
    # NOTE: I'm pretty sure this is only used for Facebook messages; confirm
    # that and maybe rename the method/do something different with it?
    case path_type
    when 'facebook'
      (body || '').
        gsub(/\n/, "<br />\n").
        gsub(/(\s\s+)/) { |str| str.gsub(/\s/, '&nbsp;') }
    when 'email'
      formatted_body = format_message(body).first
      formatted_body
    else
      body
    end
  end

  # Public: Get the root account of this message's context.
  #
  # Returns an account.
  def context_root_account
    unbounded_loop_paranoia_counter = 10
    current_context                 = context

    until current_context.respond_to?(:root_account) do
      current_context = current_context.context
      unbounded_loop_paranoia_counter -= 1

      return nil if unbounded_loop_paranoia_counter <= 0 || context.nil?
    end

    current_context.root_account
  end

  # Internal: Set default values before save.
  #
  # Returns true.
  def infer_defaults
    if notification
      self.notification_name     ||= notification.name
      self.notification_category ||= notification_category
    end

    self.path_type ||= communication_channel.try(:path_type)
    self.path_type = 'summary' if to == 'dashboard'
    self.path_type = 'email'   if context_type == 'ErrorReport'

    self.to_email  = true if %w[email sms].include?(path_type)

    self.from_name = context_root_account.settings[:outgoing_email_default_name] rescue nil
    self.from_name = HostUrl.outgoing_email_default_name if from_name.blank?
    self.from_name = asset_context.name if (asset_context &&
      !asset_context.is_a?(Account) && asset_context.name &&
      notification.dashboard? rescue false)
    self.from_name = from_name if respond_to?(:from_name)

    true
  end

  # Public: Convenience method for translation calls.
  #
  # key     - The translation key.
  # default - The English default of the key.
  # options - An options hash passed to translate (default: {}).
  #
  # Returns a translated string.
  def translate(key, default, options={})
    # Add scope if it's present in the model and missing from the key.
    if @i18n_scope && key !~ /\A#/
      key = "##{@i18n_scope}.#{key}"
    end

    super(key, default, options)
  end
  alias :t :translate

  # Public: Store data on the message for use at delivery-time.
  #
  # values_hash - A hash of values to store in the model's data attribute.
  #
  # Returns nothing.
  def data=(values_hash)
    @data = OpenStruct.new(values_hash)
  end

  # Public: Before save, close this message if it has no user or a deleted
  # user and isn't for an ErrorReport.
  #
  # Returns nothing.
  def move_messages_for_deleted_users
    if context_type != 'ErrorReport' && (!user || user.deleted?)
      self.workflow_state = 'closed'
    end
  end

  # Public: Before save, prepare dashboard messages for display on dashboard.
  #
  # Returns nothing.
  def move_dashboard_messages
    if to == 'dashboard' && !cancelled? && !closed?
      self.workflow_state = 'dashboard'
    end
  end

  # Public: Before save, set the proper asset_context_code for the model.
  #
  # Returns an asset_context_code string or nil.
  def set_asset_context_code
    self.asset_context_code = "#{context_type.underscore}_#{context_id}"
  rescue
    nil
  end

  protected
  # Internal: Deliver the message through email.
  #
  # Returns nothing.
  # Raises Net::SMTPServerBusy if the message cannot be sent.
  # Raises Timeout::Error if the remote server times out.
  def deliver_via_email
    res = nil
    logger.info "Delivering mail: #{self.inspect}"

    begin
      res = Mailer.deliver_message(self)
    rescue Net::SMTPServerBusy => e
      @exception = e
      logger.error "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
      cancel if e.message.try(:match, /Bad recipient/)
    rescue => e
      @exception = e
      logger.error "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
    end

    if res
      complete_dispatch
    elsif @exception
      raise_error = @exception.to_s !~ /^450/
      log_error = raise_error && !@exception.is_a?(Timeout::Error)
      if log_error
        ErrorReport.log_exception(:default, @exception, {
          :message => 'Message delivery failed',
          :to => to,
          :object => inspect.to_s })
      end

      self.errored_dispatch
      if raise_error
        raise @exception
      else
        return false
      end
    end

    true
  end

  # Internal: No-op included for compatibility.
  #
  # Returns nothing.
  def deliver_via_chat; end

  # Internal: Deliver the message through Twitter.
  #
  # Returns nothing.
  def deliver_via_twitter
    TwitterMessenger.new(self).deliver
    complete_dispatch
  end

  # Internal: Deliver the message through Facebook.
  #
  # Returns nothing.
  def deliver_via_facebook
    facebook_user_id = self.to.to_i.to_s
    service = self.user.user_services.for_service('facebook').find_by_service_user_id(facebook_user_id)
    Facebook.dashboard_increment_count(service) if service && service.token
    complete_dispatch
  end

  # Internal: Send the message through SMS. Right now this just calls
  # deliver_via_email because we're using email SMS gateways.
  #
  # Returns nothing.
  def deliver_via_sms
    deliver_via_email
  end
end
