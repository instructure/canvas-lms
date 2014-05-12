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
  # Setup callback to default behavior.
  if CANVAS_RAILS2
    on_send_to_external :send_via_email_or_post
  else
    set_callback :on_send_to_external, :send_via_email_or_post
  end

  attr_accessible

  def send_to_external
    run_callbacks(:on_send_to_external)
  end

  class Reporter
    include ActiveSupport::Callbacks
    define_callbacks :on_log_error

    attr_reader :opts, :exception

    def log_error(category, opts)
      opts[:category] = category.to_s.presence || 'default'
      @opts = opts
      # sanitize invalid encodings
      @opts[:message] = Utf8Cleaner.strip_invalid_utf8(@opts[:message]) if @opts[:message]
      @opts[:exception_message] = Utf8Cleaner.strip_invalid_utf8(@opts[:exception_message]) if @opts[:exception_message]
      CanvasStatsd::Statsd.increment("errors.all")
      CanvasStatsd::Statsd.increment("errors.#{category}")
      run_callbacks :on_log_error
      create_error_report(opts)
    end

    def log_exception(category, exception, opts)
      category ||= exception.class.name
      opts[:message] ||= exception.to_s
      opts[:backtrace] = exception.backtrace.try(:join, "\n")
      opts[:exception_message] = exception.to_s
      @exception = exception
      log_error(category, opts)
    end

    def create_error_report(opts)
      Shackles.activate(:master) do
        report = ErrorReport.new
        report.assign_data(opts)
        begin
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

  # returns the new error report
  def self.log_error(category, opts = {})
    Reporter.new.log_error(category, opts)
  end

  # returns the new error report
  def self.log_exception(category, exception, opts = {})
    Reporter.new.log_exception(category, exception, opts)
  end

  # assigns data attributes to the column if there's a column with that name,
  # otherwise goes into the general data hash
  def assign_data(data = {})
    self.data ||= {}
    data.each do |k,v|
      if respond_to?(:"#{k}=")
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

  USEFUL_ENV = [
    "HTTP_ACCEPT",
    "HTTP_ACCEPT_ENCODING",
    "HTTP_HOST",
    "HTTP_REFERER",
    "HTTP_USER_AGENT",
    "PATH_INFO",
    "QUERY_STRING",
    "REMOTE_HOST",
    "REQUEST_METHOD",
    "REQUEST_PATH",
    "REQUEST_URI",
    "SERVER_NAME",
    "SERVER_PORT",
    "SERVER_PROTOCOL",
  ]
  def self.useful_http_env_stuff_from_request(request)
    stuff = request.env.slice(*USEFUL_ENV)
    stuff['REMOTE_ADDR'] = request.remote_ip # ActionController::Request#remote_ip has proxy smarts
    stuff['QUERY_STRING'] = LoggingFilter.filter_query_string("?" + stuff['QUERY_STRING'])
    stuff['REQUEST_URI'] = request.url unless CANVAS_RAILS2
    stuff['REQUEST_URI'] = LoggingFilter.filter_uri(stuff['REQUEST_URI'])
    stuff['path_parameters'] = LoggingFilter.filter_params(request.path_parameters.dup).inspect # params rails picks up from the url
    stuff['query_parameters'] = LoggingFilter.filter_params(request.query_parameters.dup).inspect # params rails picks up from the query string
    stuff['request_parameters'] = LoggingFilter.filter_params(request.request_parameters.dup).inspect # params from forms
    stuff
  end

  def self.categories
    distinct('category')
  end

  # Send the error report based on configuration either via a POST or email to an external location.
  def send_via_email_or_post
    error_report = self
    config = Canvas::Plugin.find('error_reporting').try(:settings) || {}

    message_type = (error_report.backtrace || "").split("\n").first.match(/\APosted as[^_]*_([A-Z]*)_/)[1] rescue nil
    message_type ||= "ERROR"

    body = %{From #{error_report.email}, #{(error_report.user.name rescue "")}
#{message_type} #{error_report.comments + "\n" if error_report.comments}
#{"url: " + error_report.url + "\n" if error_report.url }

#{"user_id: " + (error_report.user_id.to_s) + "\n" if error_report.user_id}
error_id: #{error_report.id}

#{error_report.message + "\n" if error_report.message}
}

    if config[:action] == 'post' && config[:url] && config[:subject_param] && config[:body_param]
      params = {}
      params[config[:subject_param]] = error_report.subject
      params[config[:body_param]] = body
      Net::HHTP.post_form(URI.parse(config[:url]), params)
    elsif config[:action] == 'email' && config[:email]
      Message.create!(
        :to => config[:email],
        :from => "#{error_report.email}",
        :subject => "#{error_report.subject} (#{message_type})",
        :body => body,
        :delay_for => 0,
        :context => error_report
      )
    end
  end
  private :send_via_email_or_post

end
