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

unless defined? Bundler
  # we selinimize outside of bundler for great speed. but there may be
  # multiple versions of this gem installed though (especially if someone
  # is upgrading). such haax :o
  aws_sdk_s3_version = File.read(File.expand_path(File.dirname(__FILE__) + '/../../../../Gemfile.d/app.rb'))
    .lines
    .grep(/aws-sdk-s3/)[0]
    .sub(/.*'(\d+.*?)'.*\n/, '\1')
  gem "aws-sdk-s3", aws_sdk_s3_version
end
require "json"
require "aws-sdk-s3"
require "fileutils"
require "tmpdir"
require 'yaml'

module Selinimum
  module StatStore
    class << self
      S3_PREFIX = "canvas-lms"

      # download stats for the requested sha (and possibly infer the best/
      # closest sha if sha is nil)
      def fetch_stats(sha)
        return unless s3_enabled?

        if sha
          sha = Git.normalize_sha(sha)
        else
          sha = closest_sha
        end
        return unless sha # :(

        json_path = Dir.mktmpdir("selinimum")
        download_stats(sha, json_path)
        {sha: sha, json_path: json_path}
      end

      # once we've downloaded stat files, load them up into memory and
      # merge into a single hash
      def load_stats(directory)
        Dir["#{directory}/*.json"].inject({}) do |result, file|
          result.merge JSON.parse(File.read(file)) do |_, oldval, newval|
            oldval.concat newval
          end
        end
      end

      # find the closest ancestor commit that has spec stats stored in S3
      # (within reason)
      def closest_sha
        recent_shas = Git.recent_shas
        available_shas = Set.new(all_shas)
        recent_shas.detect { |sha| available_shas.include?(sha) }
      end

      def download_stats(sha, dest)
        data = s3.object(S3_PREFIX + "/builds/" + sha).get.body.read

        # legacy, fetch individual json files
        # TODO: remove me in ~200 commits once the old data falls out
        if data == "ok"
          return download_raw_data(sha, dest)
        end

        File.open("#{dest}/all.json", "wb") do |file|
          file.write(data)
        end
      end

      # download all the json files stored under canvas-lms/data/<SHA>/
      def download_raw_data(sha, dest)
        prefix = S3_PREFIX + "/data/" + sha + "/"
        objects = s3.objects(prefix: prefix, delimiter: '/')

        objects.each do |object|
          file_name = object.key.sub(prefix, "")
          File.open("#{dest}/#{file_name}", "wb") do |file|
            file.write object.get.body.read
          end
        end
      end

      # upload stats generated in a given test run
      def save_stats(data, batch_name)
        suffix = Time.now.utc.strftime("%Y%m%d%H%M%S")
        suffix += "-#{batch_name}" if batch_name

        if batch_name
          # in jenkins land, a given build can have lots of data files (cuz
          # parallelization). so we track overall build completion/success
          # separately once everything is done. e.g. if one thread has
          # failures, the whole dataset is unreliable, so we don't finalize
          save_file("data/#{Git.head}/stats-#{suffix}.json", data.to_json)
        else
          finalize!(data)
        end
      end

      def finalize!(data = nil)
        sha = Git.head
        data ||= begin
          dest = Dir.mktmpdir("selinimum")
          download_raw_data(sha, dest)
          load_stats(dest)
        end
        save_file("builds/#{sha}", data.to_json)
      end

      def save_file(filename, data)
        save_file_locally(filename, data)
        s3.object("#{S3_PREFIX}/#{filename}").put(body: data)
      end

      def save_file_locally(filename, data)
        filename = "tmp/selinimum/#{filename}"
        FileUtils.mkdir_p(File.dirname(filename))
        File.open(filename, "w") { |f| f.write data }
      end

      # get all the SHAs w/ finalized stats
      def all_shas
        prefix = S3_PREFIX + "/builds/"
        s3.objects(prefix: prefix, delimiter: '/').
          map { |obj| obj.key.sub(prefix, "") }
      end

      def s3_enabled?
        s3_config[:access_key_id] && s3_config[:access_key_id] != "access_key"
      end

      def s3_config
        @s3_config ||= begin
          config = {
            access_key_id: ENV["SELINIMUM_AWS_ID"],
            secret_access_key: ENV["SELINIMUM_AWS_SECRET"],
            bucket_name: ENV.fetch("SELINIMUM_AWS_BUCKET"),
            region: ENV["SELINIMUM_AWS_REGION"] || 'us-east-1'
          }
          config[:endpoint] = ENV["SELINUMUM_AWS_ENDPOINT"] if ENV["SELINUMUM_AWS_ENDPOINT"]
            # fall back to the canvas s3 creds, if provided
          yml_file = "config/amazon_s3.yml"

          if File.exist?(yml_file)
            yml_config = YAML.load_file(yml_file)[ENV["RAILS_ENV"]] || {}
            config[:access_key_id] ||= yml_config["access_key_id"]
            config[:secret_access_key] ||= yml_config["secret_access_key"]
            config[:region] ||= yml_config["region"]
            config[:endpoint] ||= yml_config["endpoint"] if yml_config["endpoint"]
          end
          config
        end
      end

      def s3
        @s3 ||= begin
          config = s3_config.dup
          bucket_name = config.delete(:bucket_name)
          Aws::S3::Resource.new(config).bucket(bucket_name)
        end
      end
    end
  end
end
