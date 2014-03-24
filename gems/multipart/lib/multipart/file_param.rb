module Multipart
  class FileParam
    attr_accessor :k, :filename, :content

    def initialize(k, filename, content)
      @k = k
      @filename = filename || "file.csv"
      @content = content
    end

    def to_multipart
      #return "Content-Disposition: form-data; name=\"#{CGI::escape(k)}\"; filename=\"#{filename}\"\r\n" + "Content-Transfer-Encoding: binary\r\n" + "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + content + "\r\n "
      # Don't escape mine
      return "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" + "Content-Transfer-Encoding: binary\r\n" + "Content-Type: #{MIME::Types.type_for(@filename).first}\r\n\r\n" + content + "\r\n"
    end
  end
end