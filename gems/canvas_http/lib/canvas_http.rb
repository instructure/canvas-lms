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

  # Use this helper method to do HTTP GET requests. It knows how to handle
  # HTTPS urls, and follows redirects to a given depth.
  #
  # Returns the Net::HTTPResponse object, not just the raw response body. If a
  # block is passed in, the response will also be yielded to the block without
  # the body having been read yet -- this allows for streaming the response
  # rather than reading it all into memory.
  #
  # Eventually it may be expanded to optionally do cert verification as well.
  #
  # TODO: this doesn't yet handle relative redirects (relative Location HTTP
  # header), which actually isn't even technically allowed by the HTTP spec.
  # But everybody allows and handles it.
  def self.get(url_str, other_headers = {}, redirect_limit = 3)
    loop do
      raise(TooManyRedirectsError) if redirect_limit <= 0

      _, uri = CanvasHttp.validate_url(url_str)
      http = CanvasHttp.connection_for_uri(uri)
      request = Net::HTTP::Get.new(uri.request_uri, other_headers)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.request(request) do |response|
        case response
          when Net::HTTPRedirection
            url_str = response['Location']
            redirect_limit -= 1
          else
          if block_given?
            yield response
          else
            response.body
          end
          return response
        end
      end
    end
  end

  # returns [normalized_url_string, URI] if valid, raises otherwise
  def self.validate_url(value)
    value = value.strip
    raise ArgumentError if value.empty?
    uri = URI.parse(value)
    unless uri.scheme
      value = "http://#{value}"
      uri = URI.parse(value)
    end
    raise ArgumentError unless %w(http https).include?(uri.scheme.downcase)
    raise(RelativeUriError) if uri.host.nil? || uri.host.strip.empty?
    return value, uri
  end

  # returns a Net::HTTP connection object for the given URI object
  def self.connection_for_uri(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    return http
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
