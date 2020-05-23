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
require 'brotli'

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
        return if (local_files - previous_manifest).empty? # nothing to change
        opts = {in_threads: 16, progress: 'uploading to S3'}
        if block_given?
          opts[:finish] = -> (_, i, _) { yield (100.0 * i / local_files.count) }
        end
        Parallel.each(local_files, opts) { |file| upload_file(file) }
        # success - we can push the manifest
        push_manifest
      end

      # tl;dr store a list of assets for a given tag on the bucket itself
      # so we don't have to make 10,000 s3 get calls every time to make sure they're all still there
      def manifest_path
        tag = ENV['MANIFEST_TAG']
        tag && "manifests/#{tag}.json"
      end

      def previous_manifest
        return [] unless manifest_path
        @manifest ||= begin
          s3_obj = bucket.object(manifest_path)
          s3_obj.exists? ? JSON.parse(s3_obj.get.body.read) : []
        end
      end

      def push_manifest
        return unless manifest_path
        bucket.object(manifest_path).put(body: JSON.dump(local_files))
      end

      def fingerprinted?(path)
        /-[0-9a-fA-F]{10,32}$/.match(path.basename(path.extname).to_s)
      end

      def mime_for(path)
        ext = path.extname[1..-1]
        # Mime::Type.lookup_by_extension doesn't have some types (like svg), so fall back to others
        content_type = Mime::Type.lookup_by_extension(ext) || Rack::Mime.mime_type(".#{ext}") || MIME::Types.type_for(ext).first
        content_type = 'text/css; charset=utf-8' if content_type == 'text/css'
        content_type
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
        return if previous_manifest.include?(remote_path)

        local_path = Pathname.new("#{Rails.public_path}/#{remote_path}")
        return if (local_path.extname == '.gz') || local_path.directory?
        options = options_for(local_path)
        {'br' => 'br/', 'gzip' => ''}.each do |compression_type, path_prefix|
          remote_path_with_prefix = path_prefix + remote_path
          s3_object = mutex.synchronize { bucket.object(remote_path_with_prefix) }
          if s3_object.exists?
            log("skipping already existing #{compression_type} file #{remote_path_with_prefix}")
          else
            s3_object.put(options.merge(body: handle_compression(local_path, options, compression_type)))
          end
        end
      end

      def log(msg)
        full_msg = "#{self.class} - #{msg}"
        Rails.logger ? Rails.logger.debug(full_msg) : puts(full_msg)
      end

      def handle_compression(file, options, compression_algorithm='gzip')
        contents = file.binread
        if file.size > 150 # compressing small files is not worth it
          compressed = if compression_algorithm == 'br'
            Brotli.deflate(contents, quality: 11)
          elsif compression_algorithm == 'gzip'
            ActiveSupport::Gzip.compress(contents, Zlib::BEST_COMPRESSION)
          end
          compression = 100 - (100.0 * compressed.size / file.size).round
          # if we couldn't compress more than 5%, the gzip/brotli decoding cost to the
          # client makes it not worth serving compressed
          if compression > 5
            options[:content_encoding] = compression_algorithm
            log "uploading #{compression_algorithm}'ed #{file}. was: #{file.size} now: #{compressed.size} saved: #{compression}%"
            return compressed
          end
        end
        log "uploading un-#{compression_algorithm}'ed #{file}"
        contents
      end
    end
  end
end
