#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'parallel'
require 'digest'

module Canvas
  module Cdn
    class S3Uploader

      attr_accessor :bucket, :config, :mutex

      def initialize(folder='dist')
        require 'aws-sdk-s3'
        @folder = folder
        @config = Canvas::Cdn.config
        @s3 = Aws::S3::Resource.new(access_key_id: config.aws_access_key_id,
                          secret_access_key: config.aws_secret_access_key,
                          region: config.region)
        @bucket = @s3.bucket(config.bucket)
        @mutex = Mutex.new
      end

      def local_files
        @local_files ||= Dir.chdir(Rails.public_path) { Dir["#{@folder}/**/**"]}
      end

      def upload!
        opts = {in_threads: 32, progress: 'uploading to S3'}
        if block_given?
          opts[:finish] = -> (_, i, _) { yield (100.0 * i / local_files.count) }
        end
        Parallel.each(local_files, opts) { |file| upload_file(file) }
      end

      def fingerprinted?(path)
        /-[0-9a-fA-F]{10,32}$/.match(path.basename(path.extname).to_s)
      end

      def mime_for(path)
        ext = path.extname[1..-1]
        # Mime::Type.lookup_by_extension doesn't have some types (like svg), so fall back to others
        Mime::Type.lookup_by_extension(ext) || Rack::Mime.mime_type(".#{ext}") || MIME::Types.type_for(ext).first
      end

      def options_for(path)
        options = { acl: 'public-read', content_type: mime_for(path).to_s }
        if fingerprinted?(path)
          options.merge!({
            cache_control: "public, max-age=#{1.year}"
          })
        end

        options
      end

      def ungzipped_body(s3_object)
        if s3_object.content_encoding == "gzip"
          ActiveSupport::Gzip.decompress(s3_object.get.body.string)
        else
          s3_object.get.body.string
        end
      end

      def ignore?(local_path)
        files_not_to_upload = [
          /dist\/rev-manifest.json/,
          /brandable_css\/brandable_css_bundles_with_deps.json/,
          /brandable_css\/brandable_css_file_checksums.json/,
          /webpack-manifest.json/
        ]

        (local_path.extname == '.gz') ||
        local_path.directory? ||
        files_not_to_upload.any? {|e| e.match? local_path.to_s}
      end

      def upload_file(remote_path)
        local_path = Pathname.new("#{Rails.public_path}/#{remote_path}")
        return if ignore?(local_path)
        options = options_for(local_path)
        body = handle_compression(local_path, options)
        s3_object = mutex.synchronize { bucket.object(remote_path) }
        if s3_object.exists?
          files_match = # quickest check
                        %("#{Digest::MD5.hexdigest(body)}") == s3_object.etag ||
                        # check actual contents in case it was just gzip encoded differently
                        local_path.read == ungzipped_body(s3_object)

          if files_match
            return log("skipping already existing #{remote_path}")
          else
            raise "There is a already a file named #{s3_object.key} in the s3 bucket, \
                  But its contents don't match what you are trying upload. \
                  If a file's contents change, its name MUST change. \
                  Otherwise, you'll run into all kinds of caching issues in production."
          end
        end
        s3_object.put(options.merge(body: body))
      end

      def log(msg)
        Rails.logger.debug "#{self.class} - #{msg}"
      end

      def handle_compression(file, options)
        if file.size > 150 # gzipping small files is not worth it
          gzipped = ActiveSupport::Gzip.compress(file.read, Zlib::BEST_COMPRESSION)
          compression = 100 - (100.0 * gzipped.size / file.size).round
          # if we couldn't compress more than 5%, the gzip decoding cost to the
          # client makes it is not worth serving gzipped
          if compression > 5
            options[:content_encoding] = 'gzip'
            return gzipped
          end
        end
        file.read
      end

    end
  end
end
