#encoding:ASCII-8BIT

Rack::Utils.key_space_limit = 128.kilobytes # default is 64KB

if CANVAS_RAILS2
  module Rack
    module Utils
      module Multipart

        # this monkeypatch backports https://github.com/rack/rack/commit/acffe8ef5ea6de74fe306f2dd908b7681a21aaad
        # and also fixes the bug described in the comment by deleting lines 547 through 552 in the above commit
        def self.parse_multipart(env)
          unless env['CONTENT_TYPE'] =~
              %r|\Amultipart/.*boundary=\"?([^\";,]+)\"?|n
            nil
          else
            boundary = "--#{$1}"

            params = {}
            buf = ""
            content_length = env['CONTENT_LENGTH'].to_i
            input = env['rack.input']
            input.rewind

            boundary_size = Utils.bytesize(boundary) + EOL.size
            bufsize = 16384

            content_length -= boundary_size

            read_buffer = ''

            status = input.read(boundary_size, read_buffer)
            raise EOFError, "bad content body"  unless status == boundary + EOL

            rx = /(?:#{EOL})?#{Regexp.quote boundary}(#{EOL}|--)/n

            max_key_space = Utils.key_space_limit
            bytes = 0

            loop {
              head = nil
              body = ''
              filename = content_type = name = nil

              until head && buf =~ rx
                if !head && i = buf.index(EOL+EOL)
                  head = buf.slice!(0, i+2) # First \r\n
                  buf.slice!(0, 2)          # Second \r\n

                  filename = head[/Content-Disposition:.* filename=(?:"((?:\\.|[^\"])*)"|([^;\s]*))/ni, 1]
                  content_type = head[/Content-Type: (.*)#{EOL}/ni, 1]
                  name = head[/Content-Disposition:.*\s+name="?([^\";]*)"?/ni, 1] || head[/Content-ID:\s*([^#{EOL}]*)/ni, 1]

                  if name
                    bytes += name.size
                    if bytes > max_key_space
                      raise RangeError, "exceeded available parameter key space"
                    end
                  end

                  if filename
                    body = Tempfile.new("RackMultipart")
                    body.binmode  if body.respond_to?(:binmode)
                  end

                  next
                end

                # Save the read body part.
                if head && (boundary_size+4 < buf.size)
                  body << buf.slice!(0, buf.size - (boundary_size+4))
                end

                c = input.read(bufsize < content_length ? bufsize : content_length, read_buffer)
                raise EOFError, "bad content body"  if c.nil? || c.empty?
                buf << c
                content_length -= c.size
              end

              # Save the rest.
              if i = buf.index(rx)
                body << buf.slice!(0, i)
                buf.slice!(0, boundary_size+2)

                content_length = -1  if $1 == "--"
              end

              if filename == ""
                # filename is blank which means no file has been selected
                data = nil
              elsif filename
                body.rewind

                # Take the basename of the upload's original filename.
                # This handles the full Windows paths given by Internet Explorer
                # (and perhaps other broken user agents) without affecting
                # those which give the lone filename.
                filename =~ /^(?:.*[:\\\/])?(.*)/m
                filename = $1

                data = {:filename => filename, :type => content_type,
                        :name => name, :tempfile => body, :head => head}
              else
                data = body
              end

              Utils.normalize_params(params, name, data) unless data.nil?

              # break if we're at the end of a buffer, but not if it is the end of a field
              break if (buf.empty? && $1 != EOL) || content_length == -1
            }

            input.rewind

            params
          end
        end

      end
    end
  end
end