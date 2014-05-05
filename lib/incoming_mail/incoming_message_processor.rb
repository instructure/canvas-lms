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
require 'iconv'

module IncomingMail

  class IncomingMessageProcessor

    extend HtmlTextHelper

    class SilentIgnoreError < StandardError; end
    class ReplyFromError < StandardError; end
    class UnknownAddressError < ReplyFromError; end
    class ReplyToLockedTopicError < ReplyFromError; end

    MailboxClasses = {
      :imap => IncomingMail::ImapMailbox,
      :directory => IncomingMail::DirectoryMailbox,
      :pop3 => IncomingMail::Pop3Mailbox,
    }.freeze

    ImportantHeaders = %w(To From Subject Content-Type)

    class << self
      attr_accessor :mailbox_accounts, :settings, :deprecated_settings
    end

    # See config/incoming_mail.yml.example for documentation on how to configure incoming mail
    def self.configure(config)
      configure_settings(config.except(*mailbox_keys))
      configure_accounts(config.slice(*mailbox_keys))
    end

    def self.run_periodically?
      if settings.run_periodically.nil?
        # check backwards compatibility settings
        deprecated_settings.poll_interval == 0 && deprecated_settings.ignore_stdin == true
      else
        !!settings.run_periodically
      end
    end

    def self.process
      self.mailbox_accounts.each do |account|
        mailbox = self.create_mailbox(account)
        process_mailbox(mailbox, account)
      end
    end

    def self.process_single(incoming_message, secure_id, message_id, account = IncomingMail::MailboxAccount.new)
      return if IncomingMessageProcessor.bounce_message?(incoming_message)

      if incoming_message.multipart? && part = incoming_message.parts.find { |p| p.content_type.try(:match, %r{^text/html(;|$)}) }
        html_body = utf8ify(part.body.decoded, part.charset)
      end
      html_body = utf8ify(incoming_message.body.decoded, incoming_message.charset) if !incoming_message.multipart? && incoming_message.content_type.try(:match, %r{^text/html(;|$)})
      if incoming_message.multipart? && part = incoming_message.parts.find { |p| p.content_type.try(:match, %r{^text/plain(;|$)}) }
        body = utf8ify(part.body.decoded, part.charset)
      end
      body ||= utf8ify(incoming_message.body.decoded, incoming_message.charset)
      if !html_body
        html_body = format_message(body).first
      end

      begin
        original_message = Message.find_by_id(message_id)
        # This prevents us from rebouncing users that have auto-replies setup -- only bounce something
        # that was sent out because of a notification.
        raise IncomingMessageProcessor::SilentIgnoreError unless original_message && original_message.notification_id
        raise IncomingMessageProcessor::SilentIgnoreError unless secure_id == ReplyToAddress.new(original_message).secure_id

        original_message.shard.activate do
          context = original_message.context
          user = original_message.user
          raise IncomingMessageProcessor::UnknownAddressError unless user && context && context.respond_to?(:reply_from)
          context.reply_from({
            :purpose => 'general',
            :user => user,
            :subject => utf8ify(incoming_message.subject, incoming_message.header[:subject].try(:charset)),
            :html => html_body,
            :text => body
          })
        end
      rescue IncomingMessageProcessor::ReplyFromError => error
        IncomingMessageProcessor.ndr(original_message, incoming_message, error, account)
      rescue IncomingMessageProcessor::SilentIgnoreError
        # ignore it
      end
    end

    private

    def self.mailbox_keys
      MailboxClasses.keys.map(&:to_s)
    end

    def self.get_mailbox_class(account)
      MailboxClasses.fetch(account.protocol)
    end

    def self.create_mailbox(account)
      mailbox_class = get_mailbox_class(account)
      mailbox = mailbox_class.new(account.config)
      mailbox.set_timeout_method(&method(:timeout_method))
      return mailbox
    end

    def self.timeout_method
      Canvas.timeout_protection("incoming_message_processor", raise_on_timeout: true) do
        yield
      end
    end

    def self.configure_settings(config)
      @settings = IncomingMail::Settings.new
      @deprecated_settings = IncomingMail::DeprecatedSettings.new

      config.symbolize_keys.each do |key, value|
        if IncomingMail::Settings.members.map(&:to_sym).include?(key)
          self.settings.send("#{key}=", value)
        elsif IncomingMail::DeprecatedSettings.members.map(&:to_sym).include?(key)
          Rails.logger.warn("deprecated setting sent to IncomingMessageProcessor: #{key}")
          self.deprecated_settings.send("#{key}=", value)
        else
          raise "unrecognized setting sent to IncomingMessageProcessor: #{key}"
        end
      end
    end

    def self.configure_accounts(account_configs)
      flat_account_configs = flatten_account_configs(account_configs)
      self.mailbox_accounts = flat_account_configs.map do |mailbox_protocol, mailbox_config|
        error_folder = mailbox_config.delete(:error_folder)
        address = mailbox_config[:username]
        IncomingMail::MailboxAccount.new({
          :protocol => mailbox_protocol.to_sym,
          :config => mailbox_config,
          :address => address,
          :error_folder => error_folder,
        })
      end
    end

    def self.flatten_account_configs(account_configs)
      account_configs.reduce([]) do |flat_account_configs, (mailbox_protocol, mailbox_config)|
        flat_mailbox_configs = flatten_mailbox_overrides(mailbox_config)
        flat_mailbox_configs.each do |single_mailbox_config|
          flat_account_configs << [mailbox_protocol, single_mailbox_config]
        end

        flat_account_configs
      end
    end

    def self.flatten_mailbox_overrides(mailbox_config)
      mailbox_defaults = mailbox_config.except('accounts')
      mailbox_overrides = mailbox_config['accounts'] || [{}]
      mailbox_overrides.map do |override_config|
        mailbox_defaults.merge(override_config).symbolize_keys
      end
    end

    def self.error_report_category
      "incoming_message_processor"
    end

    def self.bounce_message?(mail)
      mail.header.fields.any? do |field|
        case field.name

        # RFC-3834
        when 'Auto-Submitted' then field.value != 'no'

        # old klugey stuff uses this
        when 'Precedence' then ['bulk', 'list', 'junk'].include?(field.value)

        # Exchange sets this
        when 'X-Auto-Response-Suppress' then true

        # some other random headers I found that are easy to check
        when 'X-Autoreply', 'X-Autorespond', 'X-Autoresponder' then true

        # not a bounce header we care about
        else false
        end
      end

    end

    def self.utf8ify(string, encoding)
      encoding ||= 'UTF-8'
      encoding = encoding.upcase
      # change encoding; if it throws an exception (i.e. unrecognized encoding), just strip invalid UTF-8
      Iconv.conv('UTF-8//TRANSLIT//IGNORE', encoding, string) rescue Utf8Cleaner.strip_invalid_utf8(string)
    end


    def self.process_mailbox(mailbox, account)
      addr, domain = account.address.split(/@/)
      error_folder = account.error_folder
      mailbox.connect
      mailbox.each_message do |message_id, raw_contents|
        message, errors = parse_message(raw_contents)
        if message && !errors.present?
          process_message(message, account)
          mailbox.delete_message(message_id)
        else
          mailbox.move_message(message_id, error_folder)
          if message
            ErrorReport.log_error(error_report_category, {
              :message => "Error parsing email",
              :backtrace => message.errors.flatten.map(&:to_s).join("\n"),
              :from => message.from.try(:first),
              :to => message.to.to_s,
            })
          end
        end
      end
      mailbox.disconnect
    rescue => e
      # any exception that makes it here probably means the connection is broken
      # skip this account, but the rest of the accounts should still be tried
      ErrorReport.log_exception(error_report_category, e)
    end

    def self.parse_message(raw_contents)
      message = Mail.new(raw_contents)
      errors = select_relevant_errors(message)

      # access some of the fields to make sure they don't raise errors when accessed
      message.subject

      return message, errors
    rescue => e
      ErrorReport.log_exception(error_report_category, e)
      nil
    end

    def self.select_relevant_errors(message)
      # message.errors is an array of arrays containing header parsing errors:
      # [["header-name", "header-value", parser_exception], ...]
      message.errors.select do |error|
        IncomingMessageProcessor::ImportantHeaders.include?(error[0])
      end
    end

    def self.process_message(message, account)
      secure_id, outgoing_message_id = find_matching_to_address(message, account)
      # TODO: Add bounce processing and handling of other email to the default notification address.
      return unless secure_id && outgoing_message_id
      self.process_single(message, secure_id, outgoing_message_id, account)
    rescue => e
      ErrorReport.log_exception(error_report_category, e,
        :from => message.from.try(:first),
        :to => message.to.to_s)
    end

    def self.find_matching_to_address(message, account)
      addr, domain = account.address.split(/@/)
      regex = Regexp.new("#{Regexp.escape(addr)}\\+([0-9a-f]+)-(\\d+)@#{Regexp.escape(domain)}")
      message.to.each do |address|
        if match = regex.match(address)
          return [match[1], match[2].to_i]
        end
      end

      # if no match is found, return false secure_id and outgoing_message_id
      # so that self.process message stops processing.
      [false, false]
    end

    def self.ndr(original_message, incoming_message, error, account)
      incoming_from = incoming_message.from.try(:first)
      incoming_subject = incoming_message.subject
      return unless incoming_from

      ndr_subject, ndr_body = IncomingMessageProcessor.ndr_strings(incoming_subject, error)
      outgoing_message = Message.new({
        :to => incoming_from,
        :from => account.address,
        :subject => ndr_subject,
        :body => ndr_body,
        :delay_for => 0,
        :context => nil,
        :path_type => 'email',
        :from_name => "Instructure",
      })

      outgoing_message_delivered = false
      if original_message
        original_message.shard.activate do
          comch = CommunicationChannel.active.find_by_path_and_path_type(incoming_from, 'email')
          outgoing_message.communication_channel = comch
          outgoing_message.user = comch.try(:user)
          if outgoing_message.communication_channel && outgoing_message.user
            outgoing_message.save
            outgoing_message.deliver
            outgoing_message_delivered = true
          end
        end
      end

      unless outgoing_message_delivered
        # Can't use our usual mechanisms, so just try to send it once now
        begin
          res = Mailer.create_message(outgoing_message).deliver
        rescue => e
          # TODO: put some kind of error logging here?
        end
      end
    end

    def self.ndr_strings(subject, error)
      ndr_subject = ""
      ndr_body = ""
      case error
      when IncomingMessageProcessor::ReplyToLockedTopicError
        ndr_subject = I18n.t('lib.incoming_message_processor.locked_topic.subject', "Message Reply Failed: %{subject}", :subject => subject)
        ndr_body = I18n.t('lib.incoming_message_processor.locked_topic.body', <<-BODY, :subject => subject).strip_heredoc
          The message titled "%{subject}" could not be delivered because the discussion topic is locked. If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

          Thank you,
          Canvas Support
        BODY
      else # including IncomingMessageProcessor::UnknownAddressError
        ndr_subject = I18n.t('lib.incoming_message_processor.failure_message.subject', "Message Reply Failed: %{subject}", :subject => subject)
        ndr_body = I18n.t('lib.incoming_message_processor.failure_message.body', <<-BODY, :subject => subject).strip_heredoc
          The message titled "%{subject}" could not be delivered.  The message was sent to an unknown mailbox address.  If you are trying to contact someone through Canvas you can try logging in to your account and sending them a message using the Inbox tool.

          Thank you,
          Canvas Support
        BODY
      end

      [ndr_subject, ndr_body]
    end

  end

end
