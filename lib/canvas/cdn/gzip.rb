if CANVAS_RAILS3
  # TODO: once we upgrade to rails 4, we can remove this
  # file and use ActiveSupport::Gzip.compress in S3Uploader instead.
  # from: https://github.com/rails/rails/blob/d59a877da44848d28960ec9038056344a5c31c0d/activesupport/lib/active_support/gzip.rb

  require 'zlib'
  require 'stringio'

  module Canvas
    module Cdn
      # A convenient wrapper for the zlib standard library that allows
      # compression/decompression of strings with gzip.
      #
      #   gzip = ActiveSupport::Gzip.compress('compress me!')
      #   # => "\x1F\x8B\b\x00o\x8D\xCDO\x00\x03K\xCE\xCF-(J-.V\xC8MU\x04\x00R>n\x83\f\x00\x00\x00"
      #
      #   ActiveSupport::Gzip.decompress(gzip)
      #   # => "compress me!"
      module Gzip
        class Stream < StringIO
          def initialize(*)
            super
            set_encoding "BINARY"
          end
          def close; rewind; end
        end

        # Compresses a string using gzip.
        def self.compress(source, level=Zlib::DEFAULT_COMPRESSION, strategy=Zlib::DEFAULT_STRATEGY)
          output = Stream.new
          gz = Zlib::GzipWriter.new(output, level, strategy)
          gz.write(source)
          gz.close
          output.string
        end
      end
    end
  end
end
