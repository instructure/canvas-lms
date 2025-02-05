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

class ErrorReport < ActiveRecord::Base
  belongs_to :user
  belongs_to :account
  serialize :http_env
  # misc key/value pairs with more details on the error
  serialize :data, type: Hash

  before_save :guess_email
  before_save :truncate_enormous_fields

  # Define a custom callback for external notification of an error report.
  define_callbacks :on_send_to_external

  def send_to_external
    truncate_fields_for_external
    run_callbacks(:on_send_to_external)
  end

  def truncate_enormous_fields
    self.message = message.truncate(1024, omission: "...<truncated>") if message
    data["exception_message"] = data["exception_message"].truncate(1024, omission: "...<truncated>") if data["exception_message"]
  end

  class Reporter
    IGNORED_CATEGORIES = %w[404 ActionDispatch::RemoteIp::IpSpoofAttackError Turnitin::Errors::SubmissionNotScoredError PG::ConnectionBad].freeze

    include ActiveSupport::Callbacks
    define_callbacks :on_log_error

    attr_reader :opts, :exception

    def self.hostname
      @cached_hostname ||= Socket.gethostname
    end

    def log_error(category, opts)
      opts[:category] = category.to_s.presence || "default"
      return if IGNORED_CATEGORIES.include? category

      @opts = opts
      # sanitize invalid encodings
      @opts[:message] = Utf8Cleaner.strip_invalid_utf8(@opts[:message]) if @opts[:message]
      if @opts[:exception_message]
        @opts[:exception_message] = Utf8Cleaner.strip_invalid_utf8(@opts[:exception_message])
      end
      @opts[:hostname] = self.class.hostname
      @opts[:pid] = Process.pid
      run_callbacks :on_log_error
      create_error_report(opts)
    end

    def log_exception(category, exception, opts)
      category ||= exception.class.name

      @exception = exception
      message = exception.to_s
      backtrace = Array(exception.backtrace)
      limit = 10
      while (exception = exception.cause)
        limit -= 1
        break if limit == 0

        cause = exception.to_s
        message += " caused by #{cause}"
        new_backtrace = Array(exception.backtrace)
        # remove the common lines of the backtrace, and separate it so you can see
        # the error handling
        backtrace = (new_backtrace - backtrace) + ["<Caused>"] + backtrace
      end
      opts[:message] ||= message
      opts[:backtrace] = backtrace.join("\n")
      opts[:exception_message] = message
      log_error(category, opts)
    end

    def create_error_report(opts)
      GuardRail.activate(:primary) do
        begin
          report = ErrorReport.new
          report.assign_data(opts)
          unless Shard.current.in_current_region?
            report = nil
            raise "Out of region error report received"
          end

          report.save!
          Rails.logger.info("Created ErrorReport ID #{report.global_id}")
        rescue => e
          Rails.logger.error("Failed creating ErrorReport: #{e.inspect}")
          Rails.logger.error("Original error: #{opts[:message]}")
          Rails.logger.error("Original exception: #{opts[:exception_message]}") if opts[:exception_message]
          @exception&.backtrace&.each do |line|
            Rails.logger.error("Trace: #{line}")
          end
        end
        report
      end
    end
  end

  def self.configure_to_ignore(error_classes)
    @classes_to_ignore ||= []
    @classes_to_ignore += error_classes
  end

  def self.configured_to_ignore?(class_name)
    (@classes_to_ignore || []).include?(class_name)
  end

  # returns the new error report
  def self.log_error(category, opts = {})
    Reporter.new.log_error(category, opts)
  end

  # returns the new error report
  def self.log_exception(category, exception, opts = {})
    Reporter.new.log_exception(category, exception, opts)
  end

  def self.log_captured(type, exception, error_report_info)
    if exception.is_a?(String) || exception.is_a?(Symbol)
      log_error(exception, error_report_info)
    else
      type = exception.class.name if type == :default
      log_exception(type, exception, error_report_info)
    end
  end

  def self.log_exception_from_canvas_errors(exception, data)
    return nil if configured_to_ignore?(exception.class.to_s)

    tags = data.fetch(:tags, {})
    extras = data.fetch(:extra, {})
    account_id = tags[:account_id]
    domain_root_account = account_id ? Account.where(id: account_id).first : nil
    error_report_info = tags.merge(extras)
    type = tags.fetch(:type, :default)

    if domain_root_account
      domain_root_account.shard.activate do
        ErrorReport.log_captured(type, exception, error_report_info)
      end
    else
      (exception.try(:current_shard) || Shard.current).activate do
        ErrorReport.log_captured(type, exception, error_report_info)
      end
    end
  end

  PROTECTED_FIELDS = %i[id created_at updated_at data].freeze

  # assigns data attributes to the column if there's a column with that name,
  # otherwise goes into the general data hash
  def assign_data(data = {})
    self.data ||= {}
    data.each do |k, v|
      if respond_to?(:"#{k}=") && !ErrorReport::PROTECTED_FIELDS.include?(k.to_sym)
        send(:"#{k}=", v)
      else
        # dup'ing because some strings come in from Rack as frozen sometimes,
        # depending on the web server, and our invalid utf-8 stripping breaks on that
        self.data[k.to_s] = v.is_a?(String) ? v.dup : v
      end
    end
  end

  def backtrace=(val)
    if !val || val.length < self.class.maximum_text_length
      super
    else
      super(val[0, self.class.maximum_text_length])
    end
  end

  def subject=(val)
    if !val || val.length < self.class.maximum_text_length
      super
    else
      super(val[0, self.class.maximum_text_length])
    end
  end

  def comments=(val)
    if !val || val.length < self.class.maximum_text_length
      super
    else
      super(val[0, self.class.maximum_text_length])
    end
  end

  def url=(val)
    val ? super(LoggingFilter.filter_uri(val)) : super
  end

  def safe_url?
    uri = URI.parse(url)
    ["http", "https"].include?(uri.scheme)
  rescue
    false
  end

  def guess_email
    self.email = nil if email && email.empty?
    self.email ||= user&.email
    unless self.email
      domain = HostUrl.outgoing_email_domain.gsub(/[^a-zA-Z0-9]/, "-")
      # example.com definitely won't exist
      self.email = "unknown-#{domain}@instructure.example.com"
    end
    self.email
  end

  # delete old error reports before a given date
  # returns the number of destroyed error reports
  def self.destroy_error_reports(before_date)
    where("created_at<?", before_date).in_batches(of: 10_000).delete_all
  end

  def self.categories
    distinct_values("category")
  end

  private

  def truncate_fields_for_external
    # Truncate fields that are too long for external systems to handle
    # 255 characters is still quite generous for a subject line
    # If url is populated it will remain preserved in its entirety in the http_env as HTTP_REFERER
    self.url = truncate_query_params_in_url(url) if url.present?
    self.subject = subject.truncate(self.class.maximum_string_length) if subject.present?
  end

  def truncate_query_params_in_url(url, max_length = self.class.maximum_string_length)
    return url if url.length <= max_length

    uri = URI.parse(url)
    base_url = "#{uri.scheme}://#{uri.host}#{uri.path}" # preserve the scheme, host, and path
    remaining_length = max_length - base_url.length - 1 # 1 for the "?" character

    if uri.query
      truncated_query = uri.query[0, remaining_length]
      "#{base_url}?#{truncated_query}"
    else
      base_url
    end
  end
end
