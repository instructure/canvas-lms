# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

# this datafixup is not intended to have a corresponding migration. it will be
# manually applied
module DataFixup
  class ImportInstfsAttachments
    def self.run(queue, options = {})
      raise ArgumentError unless InstFS.enabled?
      raise ArgumentError if queue.empty?

      new(options).run(queue)
    end

    def initialize(options = {})
      raise ArgumentError unless options[:run_at] && options[:run_duration_hours]

      @min_sleep_duration = options[:min_sleep_duration] || 0
      @run_until = options[:run_at].advance(hours: options[:run_duration_hours])
      @next_options = options.merge(run_at: options[:run_at].advance(days: 1))
    end

    def run(queue)
      until run_expired?
        shard_id, source = queue.first
        elapsed = import_batch(shard_id, source)
        queue.shift
        break if queue.empty?

        sleep(sleep_duration(elapsed))
      end
      reenqueue_job(queue) unless queue.empty?
      InstStatsd::Statsd.increment("import_instfs_attachments.job_runs.count")
    end

    def run_expired?
      Time.now >= @run_until
    end

    def import_batch(shard_id, key)
      InstStatsd::Statsd.time("import_instfs_attachments.import_batch.time") do
        lines = read_source(key)
        started = Time.now
        Shard.find(shard_id).activate do
          InstStatsd::Statsd.time("import_instfs_attachments.import_batch.transaction.time") do
            Attachment.transaction do
              lines.each { |json| import_line(json) }
            end
          end
        end
        InstStatsd::Statsd.increment("import_instfs_attachments.import_batch.count")
        Time.now - started
      end
    end

    # wrap up the uuid so it can be passed to InstFS.authenticated_url, which
    # expects something with these methods
    class Source
      def initialize(uuid)
        @instfs_uuid = uuid
        @display_name = nil
        @filename = nil
      end
      attr_reader :instfs_uuid, :display_name, :filename
    end

    def read_source(key)
      InstStatsd::Statsd.time("import_instfs_attachments.import_batch.read_source.time") do
        tempfile = Tempfile.new("instfs_import_attachments", Dir.tmpdir)
        tempfile.binmode
        url = InstFS.authenticated_url(Source.new(key))
        CanvasHttp.get(url) do |response|
          raise "fetching #{url} failed: #{response.code}" unless response.code.to_i == 200

          response.read_body(tempfile)
        end
        tempfile.rewind
        tempfile.readlines.map(&:chomp)
      end
    end

    # sanity safety check
    KEY_VALUE_PATTERN = '\s*"\d+"\s*:\s*"[0-9a-f-]+"\s*'
    JSON_LINE_PATTERN = /^\s*{#{KEY_VALUE_PATTERN}(?:,#{KEY_VALUE_PATTERN})*}\s*$/
    def valid_import_json?(line)
      line =~ JSON_LINE_PATTERN
    end

    def import_line(line)
      return if line.empty?
      raise unless valid_import_json?(line)

      sql = "UPDATE attachments SET instfs_uuid=trim('\"' FROM batch.value::text) FROM json_each('#{line}'::json) AS batch WHERE CAST(batch.key AS BIGINT)=attachments.id"
      InstStatsd::Statsd.time("import_instfs_attachments.import_line.time") do
        Attachment.connection.execute(sql)
      end
      InstStatsd::Statsd.increment("import_instfs_attachments.import_line.count")
    end

    def sleep_duration(elapsed)
      [elapsed, @min_sleep_duration].max
    end

    def reenqueue_job(queue)
      self.class.delay(run_at: @next_options[:run_at]).run(queue, @next_options) # rubocop:disable Datafixup/StrandDownstreamJobs
    end
  end
end
