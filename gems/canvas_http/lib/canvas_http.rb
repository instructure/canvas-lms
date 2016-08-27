require 'uri'

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
  def self.request(request_class, url_str, other_headers = {}, redirect_limit: 3, form_data: nil, multipart: false)
    last_scheme = nil
    last_host = nil

    loop do
      raise(TooManyRedirectsError) if redirect_limit <= 0

      _, uri = CanvasHttp.validate_url(url_str, host: last_host, scheme: last_scheme) # uses the last host and scheme for relative redirects
      http = CanvasHttp.connection_for_uri(uri)

      multipart_query = nil
      if form_data && multipart
        multipart_query, multipart_headers = Multipart::Post.new.prepare_query(form_data)
        other_headers = other_headers.merge(multipart_headers)
      end

      request = request_class.new(uri.request_uri, other_headers)
      add_form_data(request, form_data) if form_data && !multipart

      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      args = [request]
      args << multipart_query if multipart
      http.request(*args) do |response|
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

  def self.add_form_data(request, form_data)
    if form_data.is_a?(String)
      request.body = form_data
      request.content_type = 'application/x-www-form-urlencoded'
    else
      request.set_form_data(form_data)
    end
  end

  # returns [normalized_url_string, URI] if valid, raises otherwise
  def self.validate_url(value, host: nil, scheme: nil, allowed_schemes: %w{http https})
    value = value.strip
    raise ArgumentError if value.empty?
    uri = URI.parse(value)
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

    return value, uri
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

  class << self
    attr_writer :open_timeout, :read_timeout
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
