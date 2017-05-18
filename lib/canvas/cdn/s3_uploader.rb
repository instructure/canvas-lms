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

module Canvas
  module Cdn
    class S3Uploader

      attr_accessor :bucket, :config, :mutex

      def initialize(folder='dist')
        require 'aws-sdk'
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
        opts = {in_threads: 16, progress: 'uploading to S3'}
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

      def upload_file(remote_path)
        local_path = Pathname.new("#{Rails.public_path}/#{remote_path}")
        return if (local_path.extname == '.gz') || local_path.directory?
        s3_object = mutex.synchronize { bucket.object(remote_path) }
        return log("skipping already existing #{remote_path}") if s3_object.exists?
        options = options_for(local_path)
        s3_object.put(options.merge(body: handle_compression(local_path, options)))
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
            log "uploading gzipped #{file}. was: #{file.size} now: #{gzipped.size} saved: #{compression}%"
            return gzipped
          end
        end
        log "uploading ungzipped #{file}"
        file.read
      end

    end
  end
end
