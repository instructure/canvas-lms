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

module CanvasHttp
  class Error < ::StandardError; end
  class TooManyRedirectsError < CanvasHttp::Error; end
  class InvalidResponseCodeError < CanvasHttp::Error
    attr_reader :code
    def initialize(code)
      super()
      @code = code
    end
  end
  class RelativeUriError < ArgumentError; end
  class InsecureUriError < ArgumentError; end

  def self.put(*args, &block)
    CanvasHttp.request(Net::HTTP::Put, *args, &block)
  end

  def self.delete(*args, &block)
    CanvasHttp.request(Net::HTTP::Delete, *args, &block)
  end

  def self.head(*args, &block)
    CanvasHttp.request(Net::HTTP::Head, *args, &block)
  end

  def self.get(*args, &block)
    CanvasHttp.request(Net::HTTP::Get, *args, &block)
  end

  def self.post(*args, &block)
    CanvasHttp.request(Net::HTTP::Post, *args, &block)
  end

  # Use this helper method to do HTTP GET requests. It knows how to handle
  # HTTPS urls, and follows redirects to a given depth.
  #
  # Returns the Net::HTTPResponse object, not just the raw response body. If a
  # block is passed in, the response will also be yielded to the block without
  # the body having been read yet -- this allows for streaming the response
  # rather than reading it all into memory.
  #
  # Eventually it may be expanded to optionally do cert verification as well.
  def self.request(request_class, url_str, other_headers = {}, redirect_limit: 3, form_data: nil, multipart: false,
    streaming: false, body: nil, content_type: nil)
    last_scheme = nil
    last_host = nil

    loop do
      raise(TooManyRedirectsError) if redirect_limit <= 0

      _, uri = CanvasHttp.validate_url(url_str, host: last_host, scheme: last_scheme, check_host: true) # uses the last host and scheme for relative redirects
      http = CanvasHttp.connection_for_uri(uri)

      request = request_class.new(uri.request_uri, other_headers)
      add_form_data(request, form_data, multipart: multipart, streaming: streaming) if form_data
      request.body = body if body
      request.content_type = content_type if content_type

      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.request(request) do |response|
        if response.is_a?(Net::HTTPRedirection) && !response.is_a?(Net::HTTPNotModified)
          last_host = uri.host
          last_scheme = uri.scheme
          url_str = response['Location']
          redirect_limit -= 1
        else
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
    uri = begin
            URI.parse(value)
          rescue URI::InvalidURIError => e
            return URI.parse(Addressable::URI.normalized_encode(value).chomp("/")) if e.message =~ /URI must be ascii only/
            raise e
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
    addrs = Resolv.getaddresses(host).map { |ip| ::IPAddr.new(ip) rescue nil}.compact
    return true unless addrs.any?

    filters.any? do |filter|
      addr_range = ::IPAddr.new(filter) rescue nil
      addr_range && addrs.any?{|addr| addr_range.include?(addr)}
    end
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

  class << self
    attr_writer :open_timeout, :read_timeout, :blocked_ip_filters
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
