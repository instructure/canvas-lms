require 'uri'

module Canvas::HTTP
  class Error < ::Exception; end
  class TooManyRedirectsError < Canvas::HTTP::Error; end
  class InvalidResponseCodeError < Canvas::HTTP::Error
    attr_reader :code
    def initialize(code)
      super()
      @code = code
    end
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
  #
  # TODO: this doesn't yet handle relative redirects (relative Location HTTP
  # header), which actually isn't even technically allowed by the HTTP spec.
  # But everybody allows and handles it.
  def self.get(url_str, other_headers = {}, redirect_limit = 3)
    loop do
      raise(TooManyRedirectsError) if redirect_limit <= 0

      url, uri = CustomValidations.validate_url(url_str)
      request = Net::HTTP::Get.new(uri.request_uri, other_headers)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
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

  # Download a URL using a GET request and return a new un-saved Attachment
  # with the data at that URL. Tries to detect the correct content_type as
  # well.
  #
  # This handles large files well.
  #
  # Pass an existing attachment in opts[:attachment] to use that, rather than
  # creating a new attachment.
  def self.clone_url_as_attachment(url, opts = {})
    _, uri = CustomValidations.validate_url(url)

    Canvas::HTTP.get(url) do |http_response|
      if http_response.code.to_i == 200
        tmpfile = tempfile_for_uri(uri)
        # net/http doesn't make this very obvious, but read_body can take any
        # object that responds to << as the destination of the body, and it'll
        # stream in chunks rather than reading the whole body into memory (as
        # long as you use the block form of http.request, which
        # Canvas::HTTP.get does)
        http_response.read_body(tmpfile)
        tmpfile.rewind
        attachment = opts[:attachment] || Attachment.new(:filename => File.basename(uri.path))
        attachment.filename ||= File.basename(uri.path)
        attachment.uploaded_data = tmpfile
        if attachment.content_type.blank? || attachment.content_type == "unknown/unknown"
          attachment.content_type = http_response.content_type
        end
        return attachment
      else
        raise InvalidResponseCodeError.new(http_response.code.to_i)
      end
    end
  end

  # returns a tempfile with a filename based on the uri (same extension, if
  # there was an extension)
  def self.tempfile_for_uri(uri)
    basename = File.basename(uri.path)
    basename, ext = basename.split(".", 2)
    if ext
      Tempfile.new([basename, ext])
    else
      Tempfile.new(basename)
    end
  end
end
