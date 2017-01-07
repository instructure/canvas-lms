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

require 'iconv'

class ErrorReport < ActiveRecord::Base
  belongs_to :user
  belongs_to :account
  serialize :http_env
  # misc key/value pairs with more details on the error
  serialize :data, Hash

  before_save :guess_email

  # Define a custom callback for external notification of an error report.
  define_callbacks :on_send_to_external

  attr_accessible

  def send_to_external
    run_callbacks(:on_send_to_external)
  end

  class Reporter
    include ActiveSupport::Callbacks
    define_callbacks :on_log_error

    attr_reader :opts, :exception

    def self.hostname
      @cached_hostname ||= Socket.gethostname
    end

    def log_error(category, opts)
      opts[:category] = category.to_s.presence || 'default'
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
      message = exception.to_s rescue exception.class.name
      backtrace = Array(exception.backtrace)
      limit = 10
      while (exception = exception.cause)
        limit -= 1
        break if limit == 0
        cause = exception.to_s rescue exception.class.name
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
      Shackles.activate(:master) do
        begin
          report = ErrorReport.new
          report.assign_data(opts)
          report.save!
          Rails.logger.info("Created ErrorReport ID #{report.global_id}")
        rescue => e
          Rails.logger.error("Failed creating ErrorReport: #{e.inspect}")
          Rails.logger.error("Original error: #{opts[:message]}")
          Rails.logger.error("Original exception: #{opts[:exception_message]}") if opts[:exception_message]
          @exception.backtrace.each do |line|
            Rails.logger.error("Trace: #{line}")
          end if @exception
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
      ErrorReport.log_captured(type, exception, error_report_info)
    end
  end

  PROTECTED_FIELDS = [:id, :created_at, :updated_at, :data].freeze

  # assigns data attributes to the column if there's a column with that name,
  # otherwise goes into the general data hash
  def assign_data(data = {})
    self.data ||= {}
    data.each do |k,v|
      if respond_to?(:"#{k}=") && !ErrorReport::PROTECTED_FIELDS.include?(k.to_sym)
        self.send(:"#{k}=", v)
      else
        # dup'ing because some strings come in from Rack as frozen sometimes,
        # depending on the web server, and our invalid utf-8 stripping breaks on that
        self.data[k.to_s] = v.is_a?(String) ? v.dup : v
      end
    end
  end

  def backtrace=(val)
    if !val || val.length < self.class.maximum_text_length
      write_attribute(:backtrace, val)
    else
      write_attribute(:backtrace, val[0,self.class.maximum_text_length])
    end
  end

  def comments=(val)
    if !val || val.length < self.class.maximum_text_length
      write_attribute(:comments, val)
    else
      write_attribute(:comments, val[0,self.class.maximum_text_length])
    end
  end

  def url=(val)
    write_attribute(:url, LoggingFilter.filter_uri(val))
  end

  def guess_email
    self.email = nil if self.email && self.email.empty?
    self.email ||= self.user.email rescue nil
    unless self.email
      domain = HostUrl.outgoing_email_domain.gsub(/[^a-zA-Z0-9]/, '-')
      # example.com definitely won't exist
      self.email = "unknown-#{domain}@instructure.example.com"
    end
    self.email
  end

  # delete old error reports before a given date
  # returns the number of destroyed error reports
  def self.destroy_error_reports(before_date)
    self.where("created_at<?", before_date).delete_all
  end

  def self.categories
    distinct_values('category')
  end
end
