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

module IncomingMailProcessor

  class IncomingMessageProcessor

    extend HtmlTextHelper

    MailboxClasses = {
      :imap => IncomingMailProcessor::ImapMailbox,
      :directory => IncomingMailProcessor::DirectoryMailbox,
      :pop3 => IncomingMailProcessor::Pop3Mailbox,
    }.freeze

    ImportantHeaders = %w(To From Subject Content-Type)

    class << self
      attr_accessor :mailbox_accounts, :settings, :deprecated_settings, :logger
    end

    def initialize(message_handler, error_reporter)
      @message_handler = message_handler
      @error_reporter = error_reporter
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

    def process
      self.class.mailbox_accounts.each do |account|
        mailbox = self.class.create_mailbox(account)
        process_mailbox(mailbox, account)
      end
    end

    def process_single(incoming_message, tag, mailbox_account = IncomingMailProcessor::MailboxAccount.new)
      return if self.class.bounce_message?(incoming_message)

      body, html_body = extract_body(incoming_message)

      @message_handler.handle(mailbox_account.address, body, html_body, incoming_message, tag)
    end

    private

    def extract_body(incoming_message)

      if incoming_message.multipart?
        html_part = incoming_message.html_part
        text_part =  incoming_message.text_part

        html_body = self.class.utf8ify(html_part.body.decoded, html_part.charset)
        body = self.class.utf8ify(text_part.body.decoded, text_part.charset)
      else
        body = self.class.utf8ify(incoming_message.body.decoded, incoming_message.charset)
      end

      if !html_body
        html_body = self.class.format_message(body).first
      end

      return body, html_body
    end

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
      @settings = IncomingMailProcessor::Settings.new
      @deprecated_settings = IncomingMailProcessor::DeprecatedSettings.new

      config.symbolize_keys.each do |key, value|
        if IncomingMailProcessor::Settings.members.map(&:to_sym).include?(key)
          self.settings.send("#{key}=", value)
        elsif IncomingMailProcessor::DeprecatedSettings.members.map(&:to_sym).include?(key)
          logger.warn("deprecated setting sent to IncomingMessageProcessor: #{key}") if logger
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
        IncomingMailProcessor::MailboxAccount.new({
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


    def process_mailbox(mailbox, account)
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
            @error_reporter.log_error(self.class.error_report_category, {
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
      @error_reporter.log_exception(self.class.error_report_category, e, {})
    end

    def parse_message(raw_contents)
      message = Mail.new(raw_contents)
      errors = select_relevant_errors(message)

      # access some of the fields to make sure they don't raise errors when accessed
      message.subject

      return message, errors
    rescue => e
      @error_reporter.log_exception(self.class.error_report_category, e, {})
      nil
    end

    def select_relevant_errors(message)
      # message.errors is an array of arrays containing header parsing errors:
      # [["header-name", "header-value", parser_exception], ...]
      message.errors.select do |error|
        IncomingMessageProcessor::ImportantHeaders.include?(error[0])
      end
    end

    def process_message(message, account)
      tag = self.class.extract_address_tag(message, account)
      # TODO: Add bounce processing and handling of other email to the default notification address.
      return unless tag
      process_single(message, tag, account)
    rescue => e
      @error_reporter.log_exception(self.class.error_report_category, e,
        :from => message.from.try(:first),
        :to => message.to.to_s)
    end

    def self.extract_address_tag(message, account)
      addr, domain = account.address.split(/@/)
      regex = Regexp.new("#{Regexp.escape(addr)}\\+([^@]+)@#{Regexp.escape(domain)}")
      message.to.each do |address|
        if match = regex.match(address)
          return match[1]
        end
      end

      # if no match is found, return false
      # so that self.process message stops processing.
      false
    end
  end
end
