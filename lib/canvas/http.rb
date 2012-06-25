require 'uri'

module Canvas::HTTP
  # Use this helper method to do HTTP GET requests. It knows how to handle
  # HTTPS urls, and follows redirects to a given depth.
  #
  # Returns the Net::HTTPResponse object, not just the raw response body.
  #
  # Eventually it may be expanded to optionally do cert verification as well.
  #
  # TODO: this doesn't yet handle relative redirects (relative Location HTTP
  # header), which actually isn't even technically allowed by the HTTP spec.
  # But everybody allows and handles it.
  def self.get(url_str, other_headers = {}, redirect_limit = 3)
    loop do
      raise "redirect limit reached" if redirect_limit <= 0

      uri = url_str.is_a?(URI) ? url_str : URI.parse(url_str)
      request = Net::HTTP::Get.new(uri.path, other_headers)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      response = http.request(request)

      case response
      when Net::HTTPRedirection
        url_str = response['Location']
        redirect_limit -= 1
      else
        return response
      end
    end
  end

  # Download a URL using a GET request and return a new un-saved Attachment
  # with the data at that URL. Tries to detect the correct content_type as
  # well.
  #
  # Returns nil on failure.
  def self.clone_url_as_attachment(url)
    url, uri = CustomValidations.validate_url(url)
    http_response = Canvas::HTTP.get(url)
    if http_response.code.to_i == 200
      body = StringIO.new(http_response.body)
      attachment = Attachment.new(:uploaded_data => body, :filename => File.basename(uri.path))
      attachment.content_type = File.mime_type?(body)
      return attachment
    else
      return nil
    end
  rescue ArgumentError, URI::InvalidURIError
    return nil
  end
end
