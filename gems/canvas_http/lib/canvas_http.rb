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

require "uri"
require "ipaddr"
require "resolv"
require "canvas_http/circuit_breaker"
require "logger"

module CanvasHttp
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 30

  def self.blocked_ip_ranges
    @blocked_ip_ranges || [
      "127.0.0.1/8",
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      "fd00::/8"
    ]
  end

  def self.blocked_ip_ranges=(range)
    @blocked_ip_ranges = range
  end

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

  class ResponseTooLargeError < CanvasHttp::Error; end

  def self.put(...)
    CanvasHttp.request(Net::HTTP::Put, ...)
  end

  def self.delete(...)
    CanvasHttp.request(Net::HTTP::Delete, ...)
  end

  def self.head(...)
    CanvasHttp.request(Net::HTTP::Head, ...)
  end

  def self.get(...)
    CanvasHttp.request(Net::HTTP::Get, ...)
  end

  def self.post(...)
    CanvasHttp.request(Net::HTTP::Post, ...)
  end

  def self.patch(...)
    CanvasHttp.request(Net::HTTP::Patch, ...)
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
                   streaming: false, body: nil, content_type: nil, redirect_spy: nil, max_response_body_length: nil)
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
      add_form_data(request, form_data, multipart:, streaming:) if form_data
      request.body = body if body
      request.content_type = content_type if content_type

      http.verify_hostname = false # temporary; remove once all offenders have been fixed

      curr_cert = 0
      num_certs = nil
      http.verify_callback = lambda do |preverify_ok, x509_store_context| # temporary; remove once all offenders have been fixed
        Sentry.with_scope do |scope|
          scope.set_tags(verify_host: "#{uri.host}:#{uri.port}")

          valid = preverify_ok
          error = valid ? "" : x509_store_context.error_string
          num_certs ||= x509_store_context.chain.length

          # only check the last certificate (aka the peer certificate)
          # We can't have OpenSSL and Net::HTTP check this without failing, so manually check it
          if (curr_cert += 1) == num_certs && valid && !(valid = OpenSSL::SSL.verify_certificate_identity(x509_store_context.current_cert, uri.host))
            error = "Hostname mismatch"
          end

          unless valid
            scope.set_tags(verify_error: error)
            Sentry.capture_message("Certificate verify failed: #{error}", level: :warning)
          end

          true # never fail 🦸
        end
      end
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
          url_str = response["Location"]
          logger.info("CANVAS_HTTP CONSUME REDIRECT | url: #{url_str} | elapsed: #{elapsed_time} s")
          redirect_limit -= 1
        else
          logger.info("CANVAS_HTTP RESOLVE RESPONSE | url: #{url_str} | elapsed: #{elapsed_time} s")
          if block_given?
            yield response
          elsif max_response_body_length
            read_body_max_length(response, max_response_body_length)
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

  def self.read_body_max_length(response, max_length)
    body = nil
    response.read_body do |chunk|
      body ||= +""
      raise ResponseTooLargeError if body.length + chunk.length > max_length

      body << chunk
    end
    response.body = body
  end

  def self.add_form_data(request, form_data, multipart:, streaming:)
    if multipart
      if streaming
        request.body_stream, header = LegacyMultipart::Post.prepare_query_stream(form_data)
        request.content_length = request.body_stream.size
      else
        request.body, header = LegacyMultipart::Post.prepare_query(form_data)
      end
      request.content_type = header["Content-type"]
    elsif form_data.is_a?(String)
      request.body = form_data
      request.content_type = "application/x-www-form-urlencoded"
    else
      request.set_form_data(form_data)
    end
  end

  # returns [normalized_url_string, URI] if valid, raises otherwise
  def self.validate_url(value, host: nil, scheme: nil, allowed_schemes: %w[http https], check_host: false)
    value = value.strip
    raise ArgumentError if value.empty?

    uri = nil
    begin
      uri = URI.parse(value)
    rescue URI::InvalidURIError => e
      if e.message.include?("URI must be ascii only")
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
    raise InsecureUriError if check_host && insecure_host?(uri.host)

    [value, uri]
  end

  def self.insecure_host?(host)
    return false if blocked_ip_ranges.empty?

    resolved_addrs = Resolv.getaddresses(host)
    unless resolved_addrs.any?
      # this is actually a different condition than the host being insecure,
      # and having separate telemetry is helpful for understanding transient failures.
      raise UnresolvableUriError, "#{host} cannot be resolved to any address"
    end

    ip_addrs = resolved_addrs.filter_map do |ip|
      ::IPAddr.new(ip)
    rescue IPAddr::InvalidAddressError
      # this should never happen, Resolv should only be passing back IPs, but
      # let's make sure we can see if the impossible occurs
      logger.warn("CANVAS_HTTP WARNING | host: #{host} | invalid_ip: #{ip}")
      nil
    end
    unless ip_addrs.any?
      raise UnresolvableUriError, "#{host} resolves to only unparseable IPs..."
    end

    blocked_ip_ranges.each do |range|
      addr_range = ::IPAddr.new(range)
      ip_addrs.any? do |addr|
        if addr_range.include?(addr)
          logger.warn("CANVAS_HTTP WARNING insecure address | host: #{host} | insecure_address: #{addr} | range: #{range}")
          return true
        end
      end
    end
    false
  end

  # returns a Net::HTTP connection object for the given URI object
  def self.connection_for_uri(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.ssl_timeout = http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT
    # Don't rely on net/http's internal retries, since they swallow errors in a
    # way that can't be detected when streaming responses, leading to duplicate
    # data
    http.max_retries = 0
    http
  end

  def self.logger
    (@logger.respond_to?(:call) ? @logger.call : @logger) || default_logger
  end

  def self.default_logger
    @_default_logger ||= Logger.new($stdout)
  end

  class << self
    attr_writer :logger
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
    basename = basename.slice(0, 100)
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
