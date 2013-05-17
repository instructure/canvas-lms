module Mail
  class Message
    raise 'delete this file' if Mail::VERSION.version > '2.5.3'

    # We override parse_message because the version of it in v2.5.3 breaks on
    # message bodies start start with whitespace.
    def parse_message
      header_part, body_part = raw_source.lstrip.split(/#{CRLF}#{CRLF}|#{CRLF}#{WSP}*#{CRLF}(?!#{WSP})/m, 2)
      self.header = header_part
      self.body   = body_part
    end
  end
end
