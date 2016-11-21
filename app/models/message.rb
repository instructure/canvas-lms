#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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

require 'hey'

class Message < ActiveRecord::Base
  # Included modules
  include Rails.application.routes.url_helpers

  include ERB::Util
  include SendToStream
  include TextHelper
  include HtmlTextHelper
  include Workflow
  include Messages::PeerReviewsHelper

  extend TextHelper

  MAX_TWITTER_MESSAGE_LENGTH = 140


  # Associations
  belongs_to :asset_context, :polymorphic => true
  belongs_to :communication_channel
  belongs_to :context, :polymorphic => true
  include NotificationPreloader
  belongs_to :user
  belongs_to :root_account, :class_name => 'Account'
  has_many   :attachments, :as => :context

  attr_accessible :to, :from, :subject, :body, :delay_for, :context, :path_type,
    :from_name, :reply_to_name, :sent_at, :notification, :user, :communication_channel,
    :notification_name, :asset_context, :data, :root_account_id

  attr_writer :delayed_messages
  attr_accessor :output_buffer

  # Callbacks
  after_save  :stage_message
  before_save :infer_defaults
  before_save :move_dashboard_messages
  before_save :move_messages_for_deleted_users
  before_save :set_asset_context_code

  # Validations
  validates :body, length: {maximum: maximum_text_length}, allow_nil: true, allow_blank: true
  validates :html_body, length: {maximum: maximum_text_length}, allow_nil: true, allow_blank: true
  validates :transmission_errors, length: {maximum: maximum_text_length}, allow_nil: true, allow_blank: true
  validates :to, length: {maximum: maximum_text_length}, allow_nil: true, allow_blank: true
  validates :from, length: {maximum: maximum_text_length}, allow_nil: true, allow_blank: true
  validates :url, length: {maximum: maximum_text_length}, allow_nil: true, allow_blank: true
  validates :subject, length: {maximum: maximum_text_length}, allow_nil: true, allow_blank: true
  validates :from_name, length: {maximum: maximum_text_length}, allow_nil: true, allow_blank: true
  validates :reply_to_name, length: {maximum: maximum_string_length}, allow_nil: true, allow_blank: true

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
      event :set_transmission_error, :transitions_to => :transmission_error
      event :cancel, :transitions_to => :cancelled
      event :close, :transitions_to => :closed # needed for dashboard messages
    end

    state :staged do
      event :dispatch, :transitions_to => :sending
      event :set_transmission_error, :transitions_to => :transmission_error
      event :cancel, :transitions_to => :cancelled
      event :close, :transitions_to => :closed # needed for dashboard messages
    end

    state :sending do
      event :complete_dispatch, :transitions_to => :sent do
        self.sent_at ||= Time.now
      end
      event :set_transmission_error, :transitions_to => :transmission_error
      event :cancel, :transitions_to => :cancelled
      event :close, :transitions_to => :closed
      event :errored_dispatch, :transitions_to => :staged do
        # A little delay so we don't churn so much when the server is down.
        self.dispatch_at = Time.now.utc + 5.minutes
      end
    end

    state :sent do
      event :set_transmission_error, :transitions_to => :transmission_error
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
      event :set_transmission_error, :transitions_to => :transmission_error
      event :close, :transitions_to => :closed
      event :cancel, :transitions_to => :closed
    end

    state :cancelled

    state :transmission_error do
      event :close, :transitions_to => :closed
    end

    state :closed do
      event :set_transmission_error, :transitions_to => :transmission_error
      event :send_message, :transitions_to => :closed do
        self.sent_at ||= Time.now
      end
    end
  end

  # Named scopes
  scope :for_asset_context_codes, lambda { |context_codes| where(:asset_context_code => context_codes) }

  scope :for, lambda { |context| where(:context_type => context.class.base_class.to_s, :context_id => context) }

  scope :after, lambda { |date| where("messages.created_at>?", date) }

  scope :to_dispatch, -> {
    where("messages.workflow_state='staged' AND messages.dispatch_at<=? AND 'messages.to'<>'dashboard'", Time.now.utc)
  }

  scope :to_email, -> { where(:path_type => ['email', 'sms']) }

  scope :not_to_email, -> { where("messages.path_type NOT IN ('email', 'sms')") }

  scope :by_name, lambda { |notification_name| where(:notification_name => notification_name) }

  scope :before, lambda { |date| where("messages.created_at<?", date) }

  scope :for_user, lambda { |user| where(:user_id => user)}

  # messages that can be moved to the 'cancelled' state. dashboard messages
  # can be closed by calling 'cancel', but aren't included
  scope :cancellable, -> { where(:workflow_state => ['created', 'staged', 'sending']) }

  # For finding a very particular message:
  # Message.for(context).by_name(name).directed_to(to).for_user(user), or
  # messages.for(context).by_name(name).directed_to(to).for_user(user)
  # Where user can be a User or id, name needs to be the Notification name.
  scope :staged, -> { where("messages.workflow_state='staged' AND messages.dispatch_at>?", Time.now.utc) }

  scope :in_state, lambda { |state| where(:workflow_state => Array(state).map(&:to_s)) }

  #Public: Helper methods for grabbing a user via the "from" field and using it to
  #populate the avatar, name, and email in the conversation email notification

  def author
    @_author ||= begin
      if context.has_attribute?(:user_id)
        User.find(context.user_id)
      elsif context.has_attribute?(:author_id)
        User.find(context.author_id)
      else
        nil
      end
    end
  end

  def avatar_enabled?
    return false unless author_account.present?
    author_account.service_enabled?(:avatars)
  end

  def author_account
    # Root account is populated during save
    return nil unless author.present?
    root_account_id ? Account.find(root_account_id) : author.account
  end

  def author_avatar_url
    url = author.try(:avatar_url)
    URI.join("#{HostUrl.protocol}://#{HostUrl.context_host(author_account)}", url).to_s if url
  end

  def author_short_name
    author.try(:short_name)
  end

  def author_email_address
    if context_root_account.try(:author_email_in_notifications?)
      author.try(:email)
    end
  end

  # Public: Helper to generate a URI for the given subject. Overrides Rails'
  # built-in ActionController::PolymorphicRoutes#polymorphic_url method because
  # it forces option defaults for protocol and host.
  def default_url_options
    { protocol: HostUrl.protocol, host: HostUrl.context_host(link_root_account) }
  end

  # Public: Helper to generate JSON suitable for publishing via Amazon SNS
  #
  # Currently pulls data from email template contents
  #
  # Returns a JSON string
  def sns_json
    @sns_json ||= begin
      custom_data = {
        html_url: self.url,
        user_id: self.user.global_id
      }
      custom_data[:api_url] = content(:api_url) if content(:api_url) # no templates define this right now

      {
        default: self.subject,
        GCM: {
          data: {
            alert: self.subject,
          }.merge(custom_data)
        }.to_json,
        APNS_SANDBOX: {
          aps: {
            alert: self.subject
          }
        }.merge(custom_data).to_json,
        APNS: {
          aps: {
            alert: self.subject
          }
        }.merge(custom_data).to_json
      }.to_json
    end
  end

  # infer a root account associated with the context that the user can log in to
  def link_root_account
    @root_account ||= begin
      context = self.context
      context = self.asset_context if context.is_a?(CommunicationChannel) && self.asset_context

      context = context.assignment if context.respond_to?(:assignment) && context.assignment
      context = context.rubric_association.context if context.respond_to?(:rubric_association) && context.rubric_association
      context = context.appointment_group.contexts.first if context.respond_to?(:appointment_group) && context.appointment_group
      context = context.context if context.respond_to?(:context)
      context = context.account if context.respond_to?(:account)
      context = context.root_account if context.respond_to?(:root_account)
      if context
        p = SisPseudonym.for(user, context)
        p ||= user.find_pseudonym_for_account(context, true)
        context = p.account if p
      else
        # nothing? okay, just something the user can log in to
        context = user.pseudonym.try(:account)
        context ||= self.context
      end
      context
    end
  end

  # infer a root account time zone
  def root_account_time_zone
    link_root_account.time_zone if link_root_account.respond_to?(:time_zone)
  end

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
      messages = Message.in_state(:dashboard).where(
        :notification_id => notification_id,
        :context_id => context_id,
        :context_type => context_type,
        :user_id => user_id
      )

      (messages - [self]).each(&:close)
    end
  end

  class UnescapedBuffer < String # acts like safe buffer except for the actually being safe part
    alias :append= :<<
    alias :safe_concat :concat
    alias :safe_append= :concat
  end

  # Public: Store content in a message_content_... instance variable.
  #
  # name  - The symbol name of the content.
  # block - ?
  #
  # Returns an empty string.
  def define_content(name, &block)
    if name == :subject || name == :user_name
      old_output_buffer, @output_buffer = [@output_buffer, UnescapedBuffer.new]
    else
      old_output_buffer, @output_buffer = [@output_buffer, @output_buffer.dup.clear]
    end

    yield

    instance_variable_set(:"@message_content_#{name}",
      @output_buffer.to_s.strip)
    @output_buffer = old_output_buffer.sub(/\n\z/, '')

    if old_output_buffer.is_a?(ActiveSupport::SafeBuffer) && old_output_buffer.html_safe?
      @output_buffer = old_output_buffer.class.new(@output_buffer)
    end

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

  # Public: Apply an HTML email template to this message.
  #
  # _binding - The binding to attach to the template.
  #
  # Returns an HTML template (or nil).
  def apply_html_template(_binding)
    orig_i18n_scope = @i18n_scope
    @i18n_scope = "#{@i18n_scope}.html"
    return nil unless template = load_html_template

    # Add the attribute 'inner_html' with the value of inner_html into the _binding
    @output_buffer = nil
    inner_html = ActionView::Template::Handlers::Erubis.new(template, :bufvar => '@output_buffer').result(_binding)
    setter = eval "inner_html = nil; lambda { |v| inner_html = v }", _binding
    setter.call(inner_html)

    layout_path = Canvas::MessageHelper.find_message_path('_layout.email.html.erb')
    @output_buffer = nil
    ActionView::Template::Handlers::Erubis.new(File.read(layout_path)).result(_binding)
  ensure
    @i18n_scope = orig_i18n_scope
  end

  def load_html_template
    html_file = template_filename('email.html')
    html_path = Canvas::MessageHelper.find_message_path(html_file)
    File.read(html_path) if File.exist?(html_path)
  end

  # Public: Assign the body, subject and url to the message.
  #
  # message_body_template - Raw template body
  # path_type             - Path to send the message across, e.g, 'email'.
  # _binding              - Message binding
  #
  # Returns message body
  def populate_body(message_body_template, path_type, _binding, filename)
    # Build the body content based on the path type
    self.body = Erubis::Eruby.new(message_body_template,
      bufvar: '@output_buffer', filename: filename).result(_binding)
    self.html_body = apply_html_template(_binding) if path_type == 'email'

    # Append a footer to the body if the path type is email
    if path_type == 'email'
      raw_footer_message = File.read(Canvas::MessageHelper.find_message_path('_email_footer.email.erb'))
      footer_message = Erubis::Eruby.new(raw_footer_message, :bufvar => "@output_buffer").result(_binding)
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
    user_time_zone     = self.user.try(:time_zone) || root_account_time_zone || original_time_zone
    Time.zone          = user_time_zone

    # (temporarily) override course name with user's nickname for the course
    hacked_course = apply_course_nickname_to_asset(self.context, self.user)

    # Ensure we have a path_type
    path_type = 'dashboard' if to == 'summary'
    unless path_type
      path_type = communication_channel.try(:path_type) || 'email'
    end


    # Determine the message template file to be used in the message
    filename = template_filename(path_type)
    message_body_template = get_template(filename)

    context, asset, user, delayed_messages, asset_context, data = [self.context,
      self.context, self.user, @delayed_messages, self.asset_context, @data]

    link_root_account.shard.activate do
      if message_body_template.present? && path_type.present?
        populate_body(message_body_template, path_type, binding, filename)

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
    end

    self.body
  ensure
    # Set the timezone back to what it originally was
    Time.zone = original_time_zone if original_time_zone.present?

    hacked_course.apply_nickname_for!(nil) if hacked_course

    @i18n_scope = nil
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

    if not delivery_method or not respond_to?(delivery_method, true)
      logger.warn("Could not set delivery_method from #{path_type}")
      return nil
    end

    if user && user.account.feature_enabled?(:notification_service) && path_type != "yo"
      enqueue_to_sqs
    else
      send(delivery_method)
    end
  end

  # Public: Enqueues a message to the notification_service's sqs queue
  #
  # Returns nothing
  def enqueue_to_sqs
    notification_targets.each do |target|
      Services::NotificationService.process(
        global_id,
        notification_message,
        path_type,
        target
      )
      complete_dispatch
    end
  rescue Aws::SQS::Errors::ServiceError => e
    Canvas::Errors.capture(
      e,
      message: 'Message delivery failed',
      to: to,
      object: inspect.to_s
    )
    error_string = "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
    self.transmission_errors = error_string
    self.errored_dispatch
    raise
  end

  class RemoteConfigurationError < StandardError; end
  # Public: Determine the remote configuration for notification_service
  #
  # Returns string remote configuration (eventually a hash).
  def remote_configuration
    case path_type
    when "email"
      return "email.amazonaws.com"
    when "push"
      return "push.com"
    when "twitter"
      return 'twitter'
    when "sms"
      return if to =~ /^\+[0-9]+$/ ? "Twilio.com" : "email.amazonaws.com"
    else
      raise RemoteConfigurationError, "No matching path types for notification service"
    end
  end

  # Public: Determines the message body for a notification endpoint
  #
  # Returns target notification message body
  def notification_message
    case path_type
    when "email"
      Mailer.create_message(self).to_s
    when "push"
      sns_json
    when "twitter"
      url = self.main_link || self.url
      message_length = MAX_TWITTER_MESSAGE_LENGTH - url.length - 1
      truncated_body = HtmlTextHelper.strip_and_truncate(body, max_length: message_length)
      "#{truncated_body} #{url}"
    else
      if to =~ /^\+[0-9]+$/
        body
      else
        Mailer.create_message(self).to_s
      end
    end
  end

  # Public: Returns all notification_service targets to send to
  #
  # Returns the targets in which to send the notification to
  def notification_targets
    case path_type
    when "push"
      self.user.notification_endpoints.map(&:arn)
    when "twitter"
      twitter_service = user.user_services.where(service: 'twitter').first
      [
        "access_token"=> twitter_service.token,
        "access_token_secret"=> twitter_service.secret,
        "user_id"=> twitter_service.service_user_id
      ]
    else
      [to]
    end
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
    message_types.to_a.sort_by { |m| m[0] == 'Other' ? CanvasSort::Last : m[0] }
  end

  # Public: Get the root account of this message's context.
  #
  # Returns an account.
  def context_root_account
    unbounded_loop_paranoia_counter = 10
    current_context                 = context

    until current_context.respond_to?(:root_account)
      return nil if unbounded_loop_paranoia_counter <= 0 || current_context.nil?
      return nil unless current_context.respond_to?(:context)
      current_context = current_context.context
      unbounded_loop_paranoia_counter -= 1
    end

    current_context.root_account
  end

  def custom_logo
    context_root_account && context_root_account.settings[:email_logo]
  end

  # Internal: Set default values before save.
  #
  # Returns true.
  def infer_defaults
    if notification
      self.notification_name     ||= notification.name
    end

    self.path_type ||= communication_channel.try(:path_type)
    self.path_type = 'summary' if to == 'dashboard'
    self.path_type = 'email'   if context_type == 'ErrorReport'

    self.to_email  = true if %w[email sms].include?(path_type)

    root_account = context_root_account
    self.root_account_id ||= root_account.try(:id)

    self.from_name = infer_from_name
    self.reply_to_name = message_context.reply_to_name

    true
  end

  # Public: Convenience method for translation calls.
  #
  # key     - The translation key.
  # default - The English default of the key.
  # options - An options hash passed to translate (default: {}).
  #
  # Returns a translated string.
  def translate(*args)
    key, options = I18nliner::CallHelpers.infer_arguments(args)

    # Add scope if it's present in the model and missing from the key.
    if !options[:i18nliner_inferred_key] && @i18n_scope && key !~ /\A#/
      key = "##{@i18n_scope}.#{key}"
    end

    super(key, options)
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

  # Public: Return the message as JSON filtered to selected fields and
  # flattened appropriately.
  #
  # Returns json hash.
  def as_json(options = {})
    super(:only => [:id, :created_at, :sent_at, :workflow_state, :from, :to, :reply_to, :subject, :body, :html_body])['message']
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
      res = Mailer.create_message(self).deliver
    rescue Net::SMTPServerBusy => e
      @exception = e
      logger.error "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
      cancel if e.message.try(:match, /Bad recipient/)
    rescue StandardError, Timeout::Error => e
      @exception = e
      logger.error "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
    end
    if res
      complete_dispatch
    elsif @exception
      raise_error = @exception.to_s !~ /^450/
      log_error = raise_error && !@exception.is_a?(Timeout::Error)
      if log_error
        Canvas::Errors.capture(
          @exception,
          message: 'Message delivery failed',
          to: to,
          object: inspect.to_s
        )
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

  # Internal: Deliver the message through Twitter.
  #
  # The template should define the content for :link and not place into the body of the template itself
  #
  # Returns nothing.
  def deliver_via_twitter
    twitter_service = user.user_services.where(service: 'twitter').first
    host = HostUrl.short_host(self.asset_context)
    msg_id = AssetSignature.generate(self)
    Twitter::Messenger.new(self, twitter_service, host, msg_id).deliver
    complete_dispatch
  end

  # Internal: Deliver the message through Yo.
  #
  # Returns nothing.
  def deliver_via_yo
    plugin = Canvas::Plugin.find(:yo)
    if plugin && plugin.enabled? && plugin.setting(:api_token)
      service = self.user.user_services.where(service: 'yo').first
      Hey.api_token ||= plugin.setting(:api_token)
      Hey::Yo.user(service.service_user_id, link: self.url)
      complete_dispatch
    else
      cancel
    end
  end

  # Internal: Send the message through SMS. This currently sends it via Twilio if the recipient is a E.164 phone
  # number, or via email otherwise.
  #
  # Returns nothing.
  def deliver_via_sms
    if to =~ /^\+[0-9]+$/
      begin
        unless user.account.feature_enabled?(:international_sms)
          raise "International SMS is currently disabled for this user's account"
        end
        if Canvas::Twilio.enabled?
          Canvas::Twilio.deliver(
            to,
            body,
            from_recipient_country: true
          )
        end
      rescue StandardError => e
        logger.error "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
        Canvas::Errors.capture(
          e,
          message: 'SMS delivery failed',
          to: to,
          object: inspect.to_s,
          tags: {
            type: :sms_message
          }
        )
        cancel
      else
        complete_dispatch
      end
    else
      deliver_via_email
    end
  end

  # Internal: Deliver the message using AWS SNS.
  #
  # Returns nothing.
  def deliver_via_push
    begin
      self.user.notification_endpoints.each do |notification_endpoint|
        notification_endpoint.destroy unless notification_endpoint.push_json(sns_json)
      end
      complete_dispatch
    rescue StandardError => e
      @exception = e
      error_string = "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
      logger.error error_string
      transmission_errors = error_string
      cancel
      raise e
    end
  end

  private
  def infer_from_name
    if asset_context
      return message_context.from_name if message_context.from_name.present?
      return asset_context.name if can_use_asset_name_for_from?
    end

    if root_account && root_account.settings[:outgoing_email_default_name]
      return root_account.settings[:outgoing_email_default_name]
    end

    HostUrl.outgoing_email_default_name
  end

  def can_use_asset_name_for_from?
    !asset_context.is_a?(Account) && asset_context.name && notification.dashboard? rescue false
  end

  def message_context
    @_message_context ||= Messages::AssetContext.new(context, notification_name)
  end

  def apply_course_nickname_to_asset(asset, user)
    hacked_course = if asset.is_a?(Course)
      asset
    elsif asset.respond_to?(:context) && asset.context.is_a?(Course)
      asset.context
    elsif asset.respond_to?(:course) && asset.course.is_a?(Course)
      asset.course
    end
    hacked_course.apply_nickname_for!(user) if hacked_course
    hacked_course
  end

end
