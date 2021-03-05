# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'uri'
require 'ipaddr'
require 'resolv'
require 'canvas_http/circuit_breaker'
require 'logger'

module CanvasHttp
  class Error < ::StandardError
    attr_reader :body

    def initialize(body = nil)
      super
      @body = body
    end
  end

  class TooManyRedirectsError < CanvasHttp::Error; end
  class InvalidResponseCodeError < CanvasHttp::Error
    attr_reader :code
    def initialize(code, body = nil)
      super(body)
      @code = code
    end
  end
  class RelativeUriError < CanvasHttp::Error; end
  class InsecureUriError < CanvasHttp::Error; end
  class UnresolvableUriError < CanvasHttp::Error; end
  class CircuitBreakerError < CanvasHttp::Error; end

  def self.put(*args, **kwargs, &block)
    CanvasHttp.request(Net::HTTP::Put, *args, **kwargs, &block)
  end

  def self.delete(*args, **kwargs, &block)
    CanvasHttp.request(Net::HTTP::Delete, *args, **kwargs, &block)
  end

  def self.head(*args, **kwargs, &block)
    CanvasHttp.request(Net::HTTP::Head, *args, **kwargs, &block)
  end

  def self.get(*args, **kwargs, &block)
    CanvasHttp.request(Net::HTTP::Get, *args, **kwargs, &block)
  end

  def self.post(*args, **kwargs, &block)
    CanvasHttp.request(Net::HTTP::Post, *args, **kwargs, &block)
  end

  # Use this helper method to do HTTP GET requests. It knows how to handle
  # HTTPS urls, and follows redirects to a given depth.
  #
  # Returns the Net::HTTPResponse object, not just the raw response body. If a
  # block is passed in, the response will also be yielded to the block without
  # the body having been read yet -- this allows for streaming the response
  # rather than reading it all into memory.
  #
  # redirect_spy allows you to see redirects as they happen. it accepts one
  # parameter, which is the redirect response.
  #
  # Eventually it may be expanded to optionally do cert verification as well.
  def self.request(request_class, url_str, other_headers = {}, redirect_limit: 3, form_data: nil, multipart: false,
    streaming: false, body: nil, content_type: nil, redirect_spy: nil)
    last_scheme = nil
    last_host = nil
    current_host = nil
    request_cost = 0
    logger.info("CANVAS_HTTP START REQUEST CHAIN | method: #{request_class} | url: #{url_str}")
    loop do
      raise(TooManyRedirectsError) if redirect_limit <= 0

      _, uri = CanvasHttp.validate_url(url_str, host: last_host, scheme: last_scheme, check_host: true) # uses the last host and scheme for relative redirects
      current_host = uri.host
      raise CircuitBreakerError if CircuitBreaker.tripped?(current_host)
      http = CanvasHttp.connection_for_uri(uri)

      request = request_class.new(uri.request_uri, other_headers)
      add_form_data(request, form_data, multipart: multipart, streaming: streaming) if form_data
      request.body = body if body
      request.content_type = content_type if content_type

      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      logger.info("CANVAS_HTTP INITIATE REQUEST | url: #{url_str}")
      start_time = Time.now
      http.request(request) do |response|
        end_time = Time.now
        elapsed_time = (end_time - start_time) # seconds
        request_cost += elapsed_time
        if response.is_a?(Net::HTTPRedirection) && !response.is_a?(Net::HTTPNotModified)
          redirect_spy.call(response) if redirect_spy.is_a?(Proc)
          last_host = uri.host
          last_scheme = uri.scheme
          url_str = response['Location']
          logger.info("CANVAS_HTTP CONSUME REDIRECT | url: #{url_str} | elapsed: #{elapsed_time} s")
          redirect_limit -= 1
        else
          logger.info("CANVAS_HTTP RESOLVE RESPONSE | url: #{url_str} | elapsed: #{elapsed_time} s")
          if block_given?
            yield response
          else
            # have to read the body before we exit this block, and
            # close the connection
            response.body
          end
          return response
        end
      end
    end
  rescue Net::ReadTimeout, Net::OpenTimeout
    CircuitBreaker.trip_if_necessary(current_host)
    raise
  ensure
    increment_cost(request_cost)
  end

  def self.add_form_data(request, form_data, multipart:, streaming:)
    if multipart
      if streaming
        request.body_stream, header = Multipart::Post.new.prepare_query_stream(form_data)
        request.content_length = request.body_stream.size
      else
        request.body, header = Multipart::Post.new.prepare_query(form_data)
      end
      request.content_type = header['Content-type']
    elsif form_data.is_a?(String)
      request.body = form_data
      request.content_type = 'application/x-www-form-urlencoded'
    else
      request.set_form_data(form_data)
    end
  end

  # returns [normalized_url_string, URI] if valid, raises otherwise
  def self.validate_url(value, host: nil, scheme: nil, allowed_schemes: %w{http https}, check_host: false)
    value = value.strip
    raise ArgumentError if value.empty?
    uri = nil
    begin
      uri = URI.parse(value)
    rescue URI::InvalidURIError => e
      if e.message =~ /URI must be ascii only/
        uri = URI.parse(Addressable::URI.normalized_encode(value).chomp("/"))
        value = uri.to_s
      else
        raise
      end
    end
    uri.host ||= host
    unless uri.scheme
      scheme ||= "http"
      if uri.host
        uri.scheme = scheme
        value = uri.to_s
      else
        value = "#{scheme}://#{value}"
      end
      uri = URI.parse(value) # it's still a URI::Generic
    end
    raise ArgumentError if !allowed_schemes.nil? && !allowed_schemes.include?(uri.scheme.downcase)
    raise(RelativeUriError) if uri.host.nil? || uri.host.strip.empty?
    raise InsecureUriError if check_host && self.insecure_host?(uri.host)

    return value, uri
  end

  def self.insecure_host?(host)
    return unless filters = self.blocked_ip_filters
    resolved_addrs = Resolv.getaddresses(host)
    unless resolved_addrs.any?
      # this is actually a different condition than the host being insecure,
      # and having separate telemetry is helpful for understanding transient failures.
      if host =~ /inst-fs/
        resolution_output = `dig #{host}`
        logger.warn("INST_FS_RESOLUTION_FAILURE: #{resolution_output}")
      end
      raise UnresolvableUriError, "#{host} cannot be resolved to any address"
    end
    ip_addrs = resolved_addrs.map do |ip|
      ::IPAddr.new(ip)
    rescue IPAddr::InvalidAddressError
      # this should never happen, Resolv should only be passing back IPs, but
      # let's make sure we can see if the impossible occurs
      logger.warn("CANVAS_HTTP WARNING | host: #{host} | invalid_ip: #{ip}")
      nil
    end.compact
    unless ip_addrs.any?
      raise UnresolvableUriError, "#{host} resolves to only unparseable IPs..."
    end

    filters.each do |filter|
      addr_range = ::IPAddr.new(filter)
      ip_addrs.any? do |addr|
        if addr_range.include?(addr)
          logger.warn("CANVAS_HTTP WARNING insecure address | host: #{host} | insecure_address: #{addr} | filter: #{filter}")
          return true
        end
      end
    end
    false
  end

  # returns a Net::HTTP connection object for the given URI object
  def self.connection_for_uri(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.ssl_timeout = http.open_timeout = open_timeout
    http.read_timeout = read_timeout
    return http
  end

  def self.open_timeout
    @open_timeout.respond_to?(:call) ? @open_timeout.call : @open_timeout || 5
  end

  def self.read_timeout
    @read_timeout.respond_to?(:call) ? @read_timeout.call : @read_timeout || 30
  end

  def self.blocked_ip_filters
    @blocked_ip_filters.respond_to?(:call) ? @blocked_ip_filters.call : @blocked_ip_filters
  end

  def self.logger
    (@logger.respond_to?(:call) ? @logger.call : @logger) || default_logger
  end

  def self.default_logger
    @_default_logger ||= Logger.new(STDOUT)
  end

  class << self
    attr_writer :open_timeout, :read_timeout, :blocked_ip_filters, :logger
    attr_accessor :cost

    def reset_cost!
      self.cost = 0
    end

    def increment_cost(amount)
      self.cost ||= 0
      self.cost += amount
    end
  end

  # returns a tempfile with a filename based on the uri (same extension, if
  # there was an extension)
  def self.tempfile_for_uri(uri)
    basename = File.basename(uri.path)
    basename, ext = basename.split(".", 2)
    basename = basename.slice(0,100)
    tmpfile = if ext
                Tempfile.new([basename, ext])
              else
                Tempfile.new(basename)
              end
    tmpfile.set_encoding(Encoding::BINARY) if tmpfile.respond_to?(:set_encoding)
    tmpfile.binmode
    tmpfile
  end
end
