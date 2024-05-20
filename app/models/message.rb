# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  include Rails.application.routes.url_helpers

  include ERB::Util
  include SendToStream
  include TextHelper
  include HtmlTextHelper
  include Workflow
  include RruleHelper
  include Messages::PeerReviewsHelper
  include Messages::SendStudentNamesHelper

  include CanvasPartman::Concerns::Partitioned
  self.partitioning_strategy = :by_date
  self.partitioning_interval = :weeks

  extend TextHelper

  MAX_TWITTER_MESSAGE_LENGTH = 140

  class QueuedNotFound < StandardError; end

  class Queued
    # use this to queue messages for delivery so we find them using the created_at in the scope
    # instead of using id alone when reconstituting the AR object
    attr_accessor :id, :created_at

    def initialize(id, created_at)
      @id, @created_at = id, created_at
    end

    delegate :dispatch_at, to: :message

    def deliver
      message.deliver
    rescue QueuedNotFound
      raise Delayed::RetriableError, "Message does not (yet?) exist"
    end

    def message
      return @message if @message.present?

      @message = Message.in_partition("id" => id, "created_at" => @created_at).where(id: @id, created_at: @created_at).first || Message.where(id: @id).first
      raise QueuedNotFound if @message.nil?

      @message
    end
  end

  def for_queue
    Queued.new(id, created_at)
  end

  # Associations
  belongs_to :communication_channel
  belongs_to :context, polymorphic: [], exhaustive: false
  include NotificationPreloader
  belongs_to :user
  belongs_to :root_account, class_name: "Account"
  has_many   :attachments, as: :context, inverse_of: :context

  attr_writer :delayed_messages
  attr_accessor :output_buffer

  # Callbacks
  after_save  :stage_message
  before_save :infer_defaults
  before_save :move_dashboard_messages
  before_save :move_messages_for_deleted_users
  before_validation :truncate_invalid_message

  # Validations
  validate :prevent_updates
  validates :body, length: { maximum: maximum_text_length }, allow_blank: true
  validates :html_body, length: { maximum: maximum_text_length }, allow_blank: true
  validates :transmission_errors, length: { maximum: maximum_text_length }, allow_blank: true
  validates :to, length: { maximum: maximum_text_length }, allow_blank: true
  validates :from, length: { maximum: maximum_text_length }, allow_blank: true
  validates :url, length: { maximum: maximum_text_length }, allow_blank: true
  validates :subject, length: { maximum: maximum_text_length }, allow_blank: true
  validates :from_name, length: { maximum: maximum_text_length }, allow_blank: true
  validates :reply_to_name, length: { maximum: maximum_string_length }, allow_blank: true

  def prevent_updates
    unless new_record?
      # e.g. Message.where(:id => self.id, :created_at => self.created_at).update_all(...)
      errors.add(:base, "Regular saving on messages is disabled - use save_using_update_all")
    end
  end

  # Stream policy
  on_create_send_to_streams do
    if to == "dashboard" && Notification.types_to_show_in_feed.include?(notification_name)
      user_id
    else
      []
    end
  end

  # State machine
  workflow do
    state :created do
      event :stage, transitions_to: :staged do
        self.dispatch_at = Time.now.utc + delay_for
        if to != "dashboard"
          MessageDispatcher.dispatch(self)
        end
      end
      event :set_transmission_error, transitions_to: :transmission_error
      event :cancel, transitions_to: :cancelled
      event :close, transitions_to: :closed # needed for dashboard messages
    end

    state :staged do
      event :dispatch, transitions_to: :sending
      event :set_transmission_error, transitions_to: :transmission_error
      event :cancel, transitions_to: :cancelled
      event :close, transitions_to: :closed # needed for dashboard messages
    end

    state :sending do
      event :complete_dispatch, transitions_to: :sent do
        self.sent_at ||= Time.now
      end
      event :set_transmission_error, transitions_to: :transmission_error
      event :cancel, transitions_to: :cancelled
      event :close, transitions_to: :closed
      event :errored_dispatch, transitions_to: :staged do
        # A little delay so we don't churn so much when the server is down.
        self.dispatch_at = Time.now.utc + 5.minutes
      end
    end

    state :sent do
      event :set_transmission_error, transitions_to: :transmission_error
      event :close, transitions_to: :closed
      event :bounce, transitions_to: :bounced do
        # Permenant reminder that this bounced.
        communication_channel.bounce_count += 1
        communication_channel.save!
        self.is_bounced = true
      end
      event :recycle, transitions_to: :staged
    end

    state :bounced do
      event :close, transitions_to: :closed
    end

    state :dashboard do
      event :set_transmission_error, transitions_to: :transmission_error
      event :close, transitions_to: :closed
      event :cancel, transitions_to: :closed
    end

    state :cancelled

    state :transmission_error do
      event :close, transitions_to: :closed
    end

    state :closed do
      event :set_transmission_error, transitions_to: :transmission_error
      event :send_message, transitions_to: :closed do
        self.sent_at ||= Time.now
      end
    end
  end

  # turns out we can override this method inside the workflow gem to get a custom save for workflow transitions
  def persist_workflow_state(new_state)
    self.workflow_state = new_state
    save_using_update_all
  end

  def save_using_update_all
    shard.activate do
      self.updated_at = Time.now.utc
      updates = changes_to_save.transform_values(&:last)
      self.class.in_partition(attributes).where(id:, created_at:).update_all(updates)
      clear_changes_information
    end
  end

  # Named scopes
  scope :for, ->(context) { where(context:) }

  scope :after, ->(date) { where("messages.created_at>?", date) }
  scope :more_recent_than, ->(date) { where("messages.created_at>? AND messages.dispatch_at>?", date, date) }

  scope :to_dispatch, lambda {
    where("messages.workflow_state='staged' AND messages.dispatch_at<=? AND 'messages.to'<>'dashboard'", Time.now.utc)
  }

  scope :to_email, -> { where(path_type: ["email", "sms"]) }

  scope :not_to_email, -> { where("messages.path_type NOT IN ('email', 'sms')") }

  scope :by_name, ->(notification_name) { where(notification_name:) }

  scope :before, ->(date) { where("messages.created_at<?", date) }

  scope :for_user, ->(user) { where(user_id: user) }

  # messages that can be moved to the 'cancelled' state. dashboard messages
  # can be closed by calling 'cancel', but aren't included
  scope :cancellable, -> { where(workflow_state: %w[created staged sending]) }

  # For finding a very particular message:
  # Message.for(context).by_name(name).directed_to(to).for_user(user), or
  # messages.for(context).by_name(name).directed_to(to).for_user(user)
  # Where user can be a User or id, name needs to be the Notification name.
  scope :staged, -> { where("messages.workflow_state='staged' AND messages.dispatch_at>?", Time.now.utc) }

  scope :in_state, ->(state) { where(workflow_state: Array(state).map(&:to_s)) }

  scope :at_timestamp, ->(timestamp) { where("created_at >= ? AND created_at < ?", Time.at(timestamp.to_i), Time.at(timestamp.to_i + 1)) }

  # an optimization for queries that would otherwise target the main table to
  # make them target the specific partition table. Naturally this only works if
  # the records all reside within the same partition!!!
  #
  # for example, this takes us from:
  #
  #     Message.where(id: 3)
  #     => SELECT "messages".* FROM "messages" WHERE "messages"."id" = 3
  # to:
  #
  #     Message.in_partition(Message.last.attributes).where(id: 3)
  #     => SELECT "messages_2020_35".* FROM "messages_2020_35" WHERE "messages_2020_35"."id" = 3
  #
  scope :in_partition, lambda { |attrs|
    dup.instance_eval do
      tap do
        @table = klass.arel_table_from_key_values(attrs)
        @predicate_builder = predicate_builder.dup
        @predicate_builder.instance_variable_set(:@table, ActiveRecord::TableMetadata.new(klass, @table))
      end
    end
  }

  # Public: Helper methods for grabbing a user via the "from" field and using it to
  # populate the avatar, name, and email in the conversation email notification

  def author
    @_author ||= if author_context.has_attribute?(:user_id)
                   User.find(context.user_id)
                 elsif author_context.has_attribute?(:author_id)
                   User.find(context.author_id)
                 else
                   nil
                 end
  end

  def author_context
    # the user_id on a mention is the user that was mentioned instead of the
    # author of the message.
    context.is_a?(Mention) ? context.discussion_entry : context
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
    if context.is_a?(DiscussionEntry) && context.discussion_topic.anonymous?
      return "https://canvas.instructure.com/images/messages/avatar-50.png"
    end

    url = author.try(:avatar_url)
    # The User model currently supports storing either a path or full
    # URL for an avatar. Because of this, alternatives to URI::DEFAULT_PARSER.escape
    # such as CGI.escape end up escaping too much for full URLs. In
    # order to escape just the path, we'd need to utilize URI.parse
    # which can't handle URLs with spaces. As that is the root cause
    # of this change, we'll just use the deprecated URI::DEFAULT_PARSER.escape method.
    #
    # rubocop:disable Lint/UriEscapeUnescape
    URI.join("#{HostUrl.protocol}://#{HostUrl.context_host(author_account)}", URI::DEFAULT_PARSER.escape(url)).to_s if url
    # rubocop:enable Lint/UriEscapeUnescape
  end

  def author_short_name
    if context.is_a?(DiscussionEntry) && context.discussion_topic.anonymous?
      return context.author_name
    end

    author.try(:short_name)
  end

  def author_email_address
    if context.is_a?(DiscussionEntry) && context.discussion_topic.anonymous?
      return nil
    end

    if context_root_account.try(:author_email_in_notifications?)
      author.try(:email)
    end
  end

  # Public: Helper to generate a URI for the given subject. Overrides Rails'
  # built-in ActionController::PolymorphicRoutes#polymorphic_url method because
  # it forces option defaults for protocol and host.
  def default_url_options
    { protocol: HostUrl.protocol, host: HostUrl.context_host(link_root_account, ApplicationController.test_cluster_name) }
  end

  # Public: Helper to generate JSON suitable for publishing via Amazon SNS
  #
  # Currently pulls data from email template contents
  #
  # Returns a JSON string
  def sns_json
    @sns_json ||= begin
      custom_data = {
        html_url: url,
        user_id: user.global_id
      }
      custom_data[:api_url] = content(:api_url) if content(:api_url) # no templates define this right now

      {
        default: subject,
        GCM: {
          data: {
            alert: subject,
          }.merge(custom_data)
        }.to_json,
        APNS_SANDBOX: {
          aps: {
            alert: subject
          }
        }.merge(custom_data).to_json,
        APNS: {
          aps: {
            alert: subject
          }
        }.merge(custom_data).to_json
      }.to_json
    end
  end

  # overwrite existing html_to_text so that messages with links can have the ids
  # translated to be shard aware while preserving the link_root_account for the
  # host.
  def html_to_text(html, *opts)
    super(transpose_url_ids(html), *opts)
  end

  # overwrite existing html_to_simple_html so that messages with links can have
  # the ids translated to be shard aware while preserving the link_root_account
  # for the host.
  def html_to_simple_html(html, *opts)
    super(transpose_url_ids(html), *opts)
  end

  def transpose_url_ids(html)
    url_helper = Api::Html::UrlProxy.new(self,
                                         context,
                                         HostUrl.context_host(link_root_account),
                                         HostUrl.protocol,
                                         target_shard: link_root_account.shard)
    Api::Html::Content.rewrite_outgoing(html, link_root_account, url_helper)
  end

  # infer a root account associated with the context that the user can log in to
  def link_root_account(pre_loaded_account: nil)
    context = pre_loaded_account
    @root_account ||= begin
      context ||= self.context
      if context.is_a?(CommunicationChannel) && @data&.root_account_id
        root_account = Account.where(id: @data.root_account_id).first
        context = root_account if root_account
      end

      # root_account is on lots of objects, use it when we can.
      context = context.root_account if context.respond_to?(:root_account)
      # some of these `context =` may not be relevant now that we have
      # root_account on many classes, but root_account doesn't respond to them
      # and so it's fast, and there are a lot of ways to generate a message.
      context = context.assignment.root_account if context.respond_to?(:assignment) && context.assignment
      context = context.rubric_association.context if context.respond_to?(:rubric_association) && context.rubric_association
      context = context.appointment_group.contexts.first if context.respond_to?(:appointment_group) && context.appointment_group
      context = context.master_template.course if context.respond_to?(:master_template) && context.master_template
      context = context.context if context.respond_to?(:context)
      context = context.account if context.respond_to?(:account)
      context = context.root_account if context.respond_to?(:root_account)

      # Going through SisPseudonym.for is important since the account could change
      if context.respond_to?(:root_account)
        p = SisPseudonym.for(user, context, type: :implicit, require_sis: false)
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
    return if state == :bounced

    self.dispatch_at = Time.now.utc + delay_for
    self.workflow_state = "staged"
  end

  # Public: Stage the message during the dispatch process. Messages travel
  # from created -> staged -> sending -> sent.
  #
  # Returns nothing.
  def stage_message
    stage if state == :created

    if dashboard?
      messages = Message.in_state(:dashboard).where(
        notification_id:,
        context_id:,
        context_type:,
        user_id:
      )

      (messages - [self]).each(&:close)
    end
  end

  # acts like safe buffer except for the actually being safe part
  class UnescapedBuffer
    def initialize(buffer = "")
      @raw_buffer = String.new(buffer)
      @raw_buffer.encode!
    end

    delegate :concat, :<<, :length, :empty?, :blank?, :encoding, :encode!, :force_encoding, to: :@raw_buffer

    def to_s
      @raw_buffer.dup
    end
    alias_method :html_safe, :to_s
    alias_method :to_str, :to_s

    def html_safe?
      true
    end

    alias_method :append=, :<<
    alias_method :safe_concat, :concat
    alias_method :safe_append=, :concat
  end

  module OutputBufferDeleteSuffix
    def delete_suffix(str)
      self.class.new(@raw_buffer.delete_suffix(str))
    end
  end
  UnescapedBuffer.include(OutputBufferDeleteSuffix)
  ActionView::OutputBuffer.include(OutputBufferDeleteSuffix) if $canvas_rails == "7.1"

  # Public: Store content in a message_content_... instance variable.
  #
  # name  - The symbol name of the content.
  #
  # Returns an empty string.
  def define_content(name)
    if name == :subject || name == :user_name
      old_output_buffer, @output_buffer = [@output_buffer, UnescapedBuffer.new]
    else
      old_output_buffer, @output_buffer = [@output_buffer, @output_buffer.class.new]
    end

    yield

    instance_variable_set(:"@message_content_#{name}",
                          @output_buffer.to_s.strip)
    @output_buffer = old_output_buffer.delete_suffix("\n")

    if old_output_buffer.is_a?(ActiveSupport::SafeBuffer) && old_output_buffer.html_safe?
      @output_buffer = old_output_buffer.class.new(@output_buffer)
    end

    ""
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

    unless (File.exist?(path) rescue false)
      return false if filename.include?("slack")

      filename = notification.name.downcase.gsub(/\s/, "_") + ".email.erb"
      path = Canvas::MessageHelper.find_message_path(filename)
    end

    @i18n_scope = "messages." + filename.delete_suffix(".erb")

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
  def template_filename(path_type = nil)
    notification.name.parameterize.underscore + "." + path_type + ".erb"
  end

  # rubocop:disable Security/Eval ERB rendering
  # Public: Apply an HTML email template to this message.
  #
  # Returns an HTML template (or nil).
  def apply_html_template(binding)
    orig_i18n_scope = @i18n_scope
    @i18n_scope = "#{@i18n_scope}.html"
    template, template_path = load_html_template
    return nil unless template

    # Add the attribute 'inner_html' with the value of inner_html into the _binding
    @output_buffer = ActionView::OutputBuffer.new
    inner_html = eval(ActionView::Template::Handlers::ERB::Erubi.new(template, bufvar: "@output_buffer").src, binding, template_path)
    setter = eval "inner_html = nil; lambda { |v| inner_html = v }", binding, __FILE__, __LINE__
    setter.call(inner_html)

    layout_path = Canvas::MessageHelper.find_message_path("_layout.email.html.erb")
    @output_buffer = ActionView::OutputBuffer.new
    eval(ActionView::Template::Handlers::ERB::Erubi.new(File.read(layout_path)).src, binding, layout_path)
  ensure
    @i18n_scope = orig_i18n_scope
  end

  def load_html_template
    html_file = template_filename("email.html")
    html_path = Canvas::MessageHelper.find_message_path(html_file)
    [File.read(html_path), html_path] if File.exist?(html_path)
  end

  # Public: Assign the body, subject and url to the message.
  #
  # message_body_template - Raw template body
  # path_type             - Path to send the message across, e.g, 'email'.
  #
  # Returns message body
  def populate_body(message_body_template, path_type, binding, filename)
    # Build the body content based on the path type
    self.body = eval(Erubi::Engine.new(message_body_template, bufvar: "@output_buffer").src, binding, filename)
    self.html_body = apply_html_template(binding) if path_type == "email"

    # Append a footer to the body if the path type is email
    if path_type == "email"
      footer_path = Canvas::MessageHelper.find_message_path("_email_footer.email.erb")
      raw_footer_message = File.read(footer_path)
      footer_message = eval(Erubi::Engine.new(raw_footer_message, bufvar: "@output_buffer").src, nil, footer_path)
      # currently, _email_footer.email.erb only contains a way for users to change notification prefs
      # they can only change it if they are registered in the first place
      # do not show this for emails telling users to register
      if footer_message.present? && !notification&.registration?
        self.body = <<~TEXT
          #{body}





          ________________________________________

          #{footer_message}
        TEXT
      end
    end

    body
  end

  # Public: Prepare a message for delivery by setting body, subject, etc.
  #
  # path_type - The path to send the message across, e.g, 'email'.
  #
  # Returns nothing.
  def parse!(path_type = nil, root_account: nil)
    raise StandardError, "Cannot parse without a context" unless context

    # set @root_account using our pre_loaded_account, because link_root_account
    # is called many times.
    link_root_account(pre_loaded_account: root_account)
    # Get the users timezone but maintain the original timezone in order to set it back at the end
    original_time_zone = Time.zone.name || "UTC"
    user_time_zone     = user.try(:time_zone) || root_account_time_zone || original_time_zone
    Time.zone          = user_time_zone

    # (temporarily) override course name with user's nickname for the course
    hacked_course = apply_course_nickname_to_asset(context, user)

    path_type ||= communication_channel.try(:path_type) || "email"

    # Determine the message template file to be used in the message
    filename = template_filename(path_type)
    message_body_template = get_template(filename)
    if !message_body_template && path_type == "slack"
      filename = template_filename("sms")
      message_body_template = get_template(filename)
    end

    context, asset, user, delayed_messages, data = [self.context,
      self.context,
self.user,
@delayed_messages,
@data]

    link_root_account.shard.activate do
      if message_body_template.present?
        populate_body(message_body_template, path_type, binding, filename)

        # Set the subject and url
        self.subject = @message_content_subject || t("#message.default_subject", "Canvas Alert")
        self.url     = @message_content_link || nil
      else
        # Message doesn't exist so we flag the message as an error
        self.subject = eval(Erubi::Engine.new(subject).src)
        self.body    = eval(Erubi::Engine.new(body).src)
        self.transmission_errors = "couldn't find #{Canvas::MessageHelper.find_message_path(filename)}"
      end
    end

    body
  ensure
    # Set the timezone back to what it originally was
    Time.zone = original_time_zone if original_time_zone.present?

    hacked_course&.apply_nickname_for!(nil)

    @i18n_scope = nil
  end
  # rubocop:enable Security/Eval

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

    if path_type == "slack" && !context_root_account.settings[:encrypted_slack_key]
      logger.warn("Could not send slack message without configured key")
      return nil
    end

    check_acct = infer_feature_account

    return skip_and_cancel if path_type == "sms"

    if path_type == "push" &&
       (Notification.types_to_send_in_push.exclude?(notification_name) || !check_acct.enable_push_notifications?)
      return skip_and_cancel
    end

    InstStatsd::Statsd.increment("message.deliver.#{path_type}.#{notification_name}",
                                 short_stat: "message.deliver",
                                 tags: { path_type:, notification_name: })

    global_account_id = Shard.global_id_for(root_account_id, shard)
    InstStatsd::Statsd.increment("message.deliver.#{path_type}.#{global_account_id}",
                                 short_stat: "message.deliver_per_account",
                                 tags: { path_type:, root_account_id: global_account_id })

    if check_acct.feature_enabled?(:notification_service)
      enqueue_to_sqs
    else
      delivery_method = :"deliver_via_#{path_type}"
      if !delivery_method || !respond_to?(delivery_method, true)
        logger.warn("Could not set delivery_method from #{path_type}")
        return nil
      end
      send(delivery_method)
    end
  end

  def skip_and_cancel
    InstStatsd::Statsd.increment("message.skip.#{path_type}.#{notification_name}",
                                 short_stat: "message.skip",
                                 tags: { path_type:, notification_name: })
    cancel
  end

  # Public: Enqueues a message to the notification_service's sqs queue
  #
  # Returns nothing
  def enqueue_to_sqs
    targets = notification_targets
    if targets.empty?
      # Log no_targets_specified error to DataDog
      InstStatsd::Statsd.increment("message.no_targets_specified",
                                   short_stat: "message.no_targets_specified",
                                   tags: { path_type: })

      self.transmission_errors = "No notification targets specified"
      set_transmission_error
    else
      targets.each do |target|
        Services::NotificationService.process(
          notification_service_id,
          notification_message,
          path_type,
          target,
          notification&.priority?
        )
      end
      complete_dispatch
    end
  rescue => e
    Canvas::Errors.capture(
      e,
      message: "Message delivery failed",
      to:,
      object: inspect.to_s
    )
    error_string = "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
    self.transmission_errors = error_string
    errored_dispatch
    raise
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
      url = main_link || self.url
      message_length = MAX_TWITTER_MESSAGE_LENGTH - url.length - 1
      truncated_body = HtmlTextHelper.strip_and_truncate(body, max_length: message_length)
      "#{truncated_body} #{url}"
    else
      if to =~ /^\+[0-9]+$/ || path_type == "slack"
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
      user.notification_endpoints.pluck(:arn)
    when "twitter"
      twitter_service = user.user_services.where(service: "twitter").first
      return [] unless twitter_service

      [
        "access_token" => twitter_service.token,
        "access_token_secret" => twitter_service.secret,
        "user_id" => twitter_service.service_user_id
      ]
    when "slack"
      [
        "recipient" => to,
        "access_token" => Canvas::Security.decrypt_password(context_root_account.settings[:encrypted_slack_key],
                                                            context_root_account.settings[:encrypted_slack_key_salt],
                                                            "instructure_slack_encrypted_key")
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
      type = message.notification.category rescue "Other"

      if type.present?
        types[type] ||= []
        types[type] << message
      end

      hash
    end

    # not sure what this is even doing?
    message_types.to_a.sort_by { |m| (m[0] == "Other") ? CanvasSort::Last : m[0] }
  end

  # Public: Message to use if the message is unavailable to send.
  #
  # Returns a string
  def self.unavailable_message
    I18n.t("message preview unavailable")
  end

  # Public: Get the root account of this message's context.
  #
  # Returns an account.
  def context_root_account
    if context.is_a?(AccountNotification)
      return context.account.root_account
    end

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

  # This is a dumb name, but it's the context (course/group/account/user) of
  # the message.context (which should really be message.asset)
  def context_context
    @context_context ||= begin
      unbounded_loop_paranoia_counter = 10
      current_context = context

      loop do
        break if unbounded_loop_paranoia_counter.zero? ||
                 current_context.nil? ||
                 current_context.is_a_context?

        current_context = current_context.try(:context)
        unbounded_loop_paranoia_counter -= 1
      end

      current_context
    end
  end

  def media_context
    context = self.context
    context = context.context if context.respond_to?(:context)
    return context if context.is_a?(Course)

    (context.respond_to?(:course) && context.course) ? context.course : link_root_account
  end

  def notification_service_id
    "#{global_id}+#{created_at.to_i}"
  end

  def self.parse_notification_service_id(service_id)
    if service_id.to_s.include?("+")
      service_id.split("+")
    else
      [service_id, nil]
    end
  end

  def custom_logo
    context_root_account && context_root_account.settings[:email_logo]
  end

  # Internal: Set default values before save.
  #
  # Returns true.
  def infer_defaults
    if notification
      self.notification_name ||= notification.name
    end

    self.path_type ||= communication_channel.try(:path_type)
    self.path_type = "summary" if to == "dashboard"
    self.path_type = "email"   if context_type == "ErrorReport"

    self.to_email  = true if %w[email sms].include?(path_type)

    root_account = context_root_account
    self.root_account_id ||= root_account.try(:id)

    self.from_name = infer_from_name
    self.reply_to_name = name_helper.reply_to_name

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
  alias_method :t, :translate

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
    if context_type != "ErrorReport" && (!user || user.deleted?)
      self.workflow_state = "closed"
    end
  end

  # Public: Truncate the message if it exceeds 64kb
  #
  # Returns nothing.
  def truncate_invalid_message
    [:body, :html_body].each do |attr|
      if send(attr) && send(attr).bytesize > self.class.maximum_text_length
        send(:"#{attr}=", Message.unavailable_message)
      end
    end
  end

  # Public: Before save, prepare dashboard messages for display on dashboard.
  #
  # Returns nothing.
  def move_dashboard_messages
    if to == "dashboard" && !cancelled? && !closed?
      self.workflow_state = "dashboard"
    end
  end

  # Public: Return the message as JSON filtered to selected fields and
  # flattened appropriately.
  #
  # Returns json hash.
  def as_json(*)
    super(only: %i[id created_at sent_at workflow_state from from_name to reply_to subject body html_body])["message"]
  end

  protected

  # Internal: Choose account to check feature flags on.
  #
  # used to choose which account to trust for inspecting
  # feature state to decide how to send messages.  In general
  # the root account is a good choice, but for a user-context
  # message (which would intentionally have a dummy root account),
  # we want to make sure we aren't inspecting
  # features on the dummy account
  def infer_feature_account
    root_account&.unless_dummy || user&.account || Account.site_admin
  end

  # Internal: Deliver the message through email.
  #
  # Returns nothing.
  # Raises Net::SMTPServerBusy if the message cannot be sent.
  # Raises Timeout::Error if the remote server times out.
  def deliver_via_email
    res = nil
    logger.info "Delivering mail: #{inspect}"
    begin
      res = Mailer.create_message(self).deliver_now
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
        Canvas::Errors.capture(
          @exception,
          message: "Message delivery failed",
          to:,
          object: inspect.to_s
        )
      end

      errored_dispatch
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
    twitter_service = user.user_services.where(service: "twitter").first
    host = HostUrl.context_host(link_root_account)
    msg_id = AssetSignature.generate(self)
    Twitter::Messenger.new(self, twitter_service, host, msg_id).deliver
    complete_dispatch
  end

  # Internal: Send the message through SMS. This currently sends it via Twilio if the recipient is a E.164 phone
  # number, or via email otherwise.
  #
  # Returns nothing.
  def deliver_via_sms
    if /^\+[0-9]+$/.match?(to)
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
      rescue => e
        logger.error "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
        Canvas::Errors.capture(
          e,
          message: "SMS delivery failed",
          to:,
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
    user.notification_endpoints.each do |notification_endpoint|
      notification_endpoint.destroy unless notification_endpoint.push_json(sns_json)
    end
    complete_dispatch
  rescue => e
    @exception = e
    error_string = "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
    logger.error error_string
    cancel
    raise e
  end

  private

  def outgoing_email_default_name_for_messages
    if root_account && root_account.settings[:outgoing_email_default_name]
      root_account.settings[:outgoing_email_default_name]
    else
      HostUrl.outgoing_email_default_name
    end
  end

  def infer_from_name
    if notification_category == "Summaries"
      return outgoing_email_default_name_for_messages
    end

    if context.is_a?(DiscussionEntry) && context.discussion_topic.anonymous?
      return context.author_name
    end

    return name_helper.from_name if name_helper.from_name.present?

    if name_helper.asset.is_a?(AppointmentGroup) && !(names = name_helper.asset.contexts_for_user(user)).nil?
      names = names.map(&:name).join(", ")
      if names == ""
        return name_helper.asset.context.name
      else
        return names
      end
    end
    return context_context.nickname_for(user) if can_use_name_for_from?(context_context)

    outgoing_email_default_name_for_messages
  end

  def can_use_name_for_from?(c)
    c && !c.is_a?(Account) && notification&.dashboard? &&
      c.respond_to?(:name) && c.name.present?
  end

  def name_helper
    @name_helper ||= Messages::NameHelper.new(
      asset: context,
      message_recipient: user,
      notification_name:
    )
  end

  def apply_course_nickname_to_asset(asset, user)
    hacked_course = if asset.is_a?(Course)
                      asset
                    elsif asset.respond_to?(:context) && asset.context.is_a?(Course)
                      asset.context
                    elsif asset.respond_to?(:course) && asset.course.is_a?(Course)
                      asset.course
                    end
    hacked_course&.apply_nickname_for!(user)
    hacked_course
  end
end
