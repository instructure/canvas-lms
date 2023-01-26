# frozen_string_literal: true

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

require "parallel"

module Canvas
  module Cdn
    class S3Uploader
      attr_accessor :bucket, :config, :mutex, :verbose

      def initialize(folder = "dist", verbose: false)
        require "aws-sdk-s3"
        @folder = folder
        @verbose = verbose
        @config = Canvas::Cdn.config
        @s3 = Aws::S3::Resource.new(access_key_id: config.aws_access_key_id,
                                    secret_access_key: config.aws_secret_access_key,
                                    region: config.region)
        @bucket = @s3.bucket(config.bucket)
        @mutex = Mutex.new
      end

      def local_files
        @local_files ||= Dir.chdir(Rails.public_path) { Dir["#{@folder}/**/**"] }
      end

      def upload!
        upload_files = local_files - previous_manifest

        return if upload_files.empty? # nothing to change

        opts = { in_threads: 16, progress: "uploading to S3" }
        if block_given?
          opts[:finish] = ->(_, i, _) { yield (100.0 * i / upload_files.count) }
        end
        log("will upload #{upload_files.count} / #{local_files.count} files") if @verbose
        Parallel.each(upload_files, opts) { |file| upload_file(file) }
        # success - we can push the manifest
        push_manifest
      end

      # tl;dr store a list of assets for a given tag on the bucket itself
      # so we don't have to make 10,000 s3 get calls every time to make sure they're all still there
      def manifest_path
        tag = ENV["MANIFEST_TAG"]
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
        ext = path.extname[1..]
        # Mime::Type.lookup_by_extension doesn't have some types (like svg), so fall back to others
        content_type = Mime::Type.lookup_by_extension(ext) || Rack::Mime.mime_type(".#{ext}") || MIME::Types.type_for(ext).first
        content_type = "text/css; charset=utf-8" if content_type == "text/css"
        content_type
      end

      def options_for(path)
        options = { acl: "public-read", content_type: mime_for(path).to_s }
        if fingerprinted?(path)
          options[:cache_control] = "public, max-age=#{1.year}"
        end

        options
      end

      def upload_file(remote_path)
        return if previous_manifest.include?(remote_path)

        local_path = Pathname.new("#{Rails.public_path}/#{remote_path}")
        return if (local_path.extname == ".gz") || local_path.directory?

        s3_object = mutex.synchronize { bucket.object(remote_path) }
        return log("skipping already existing #{remote_path}") if s3_object.exists?

        time = Benchmark.measure do
          s3_object.put(options_for(local_path).merge(body: local_path.binread))
        end

        log("uploaded #{remote_path} (#{local_path.size}) in #{time.real}s") if @verbose
      end

      def log(msg)
        full_msg = "#{self.class} - #{msg}"
        Rails.logger ? Rails.logger.debug(full_msg) : puts(full_msg)
      end
    end
  end
end
