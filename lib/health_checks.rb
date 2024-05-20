# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module HealthChecks
  extend ApplicationHelper

  class << self
    def process_readiness_checks(is_deep_check)
      readiness_checks
        .transform_values { |v| component_check(v, is_deep_check) }
    end

    def process_deep_checks
      critical = critical_checks
                 .transform_values { |v| execute_deep_check(v) }
                 .transform_values { |v| component_check(v, true) }

      secondary = secondary_checks
                  .transform_values { |v| execute_deep_check(v) }
                  .transform_values { |v| component_check(v, true) }

      { critical:, secondary: }
    end

    def send_to_statsd(result = nil, additional_tags = {})
      result ||= process_deep_checks.merge({ readiness: process_readiness_checks(true) })

      result.each do |check_type, check_values|
        check_values.each do |check_name, check_results|
          tags = { type: check_type, key: check_name, **additional_tags }

          InstStatsd::Statsd.timing("canvas.health_checks.response_time_ms", check_results[:time], tags:)
          InstStatsd::Statsd.gauge("canvas.health_checks.status", check_results[:status] ? 1 : 0, tags:)
        end
      end
    end

    private

    def readiness_checks
      {
        # ensures brandable_css_bundles_with_deps exists, returns a string (path), treated as truthy
        common_css: -> { !!css_url_for("common") },
        # ensures webpack worked; returns a string, treated as truthy
        common_js: -> { Canvas::Cdn.registry.scripts_available? },
        # returns a PrefixProxy instance, treated as truthy
        consul: -> { DynamicSettings.find(tree: :private)[:readiness, failsafe: nil].nil? },
        # returns the value of the block <integer>, treated as truthy
        filesystem: lambda do
          !!Tempfile.open("readiness", ENV["TMPDIR"] || Dir.tmpdir) { |f| f.write("readiness") }
        end,
        # returns a boolean
        jobs: lambda do
                Delayed::Job.connection.verify!
                true
              end,
        # returns a boolean
        postgresql: lambda do
                      Account.connection.verify!
                      GuardRail.activate(:secondary) { Account.connection.verify! }
                      true
                    end,
        # nil response treated as truthy
        ha_cache: -> { MultiCache.cache.fetch("readiness").nil? },
        # ensures `gulp rev` has ran; returns a string, treated as truthy
        rev_manifest: -> { Canvas::Cdn.registry.statics_available? },
        # ensures we retrieved something back from Vault; returns a boolean
        vault: -> { !Canvas::Vault.read("#{Canvas::Vault.kv_mount}/data/secrets").nil? }
      }
    end

    def critical_checks
      ret = {
        default_shard: lambda do
                         Shard.connection.verify!
                         true
                       end
      }

      if InstFS.enabled?
        ret[:inst_fs] = lambda do
          CanvasHttp
            .get(URI.join(InstFS.app_host, "/readiness").to_s)
            .is_a?(Net::HTTPSuccess)
        end
      end

      if Canvas.redis_enabled?
        ret[:redis] = lambda do
          nodes = Canvas.redis.try(:ring)&.nodes || Array.wrap(Canvas.redis)
          nodes.all? { |node| node.get("deep_check").nil? }
        end
      end

      if Services::RichContent.send(:service_settings)[:RICH_CONTENT_APP_HOST]
        ret[:rich_content_service] = lambda do
          CanvasHttp
            .get(
              URI::HTTPS.build(
                host: Services::RichContent.send(:service_settings)[:RICH_CONTENT_APP_HOST],
                path: "/readiness"
              ).to_s
            ).is_a?(Net::HTTPSuccess)
        end
      end

      if MathMan.use_for_svg?
        ret[:mathman] = lambda do
          CanvasHttp
            .get(MathMan.url_for(latex: "x", target: :svg))
            .is_a?(Net::HTTPSuccess)
        end
      end

      if LiveEvents::Client.config
        ret[:live_events] = lambda do
          !LiveEvents.send(:client).stream_client.put_records(
            records: [
              {
                data: {
                  attributes: {
                    event_name: "noop",
                    event_time: Time.now.utc.iso8601(3)
                  },
                  body: {}
                }.to_json,
                partition_key: rand(1000).to_s
              }
            ],
            stream_name: LiveEvents.send(:client).stream_name
          ).nil?
        end
      end

      if DynamicSettings.config.present?
        ret[:consul] = lambda do
          DynamicSettings.find(tree: :private)["health_check", ttl: 0.1]
          true
        end
      end

      ret
    end

    def secondary_checks
      ret = {}
      if PageView.pv4?
        ret[:pv4] = lambda do
          CanvasHttp
            .get(URI.join(ConfigFile.load("pv4")["uri"], "/health_check").to_s)
            .is_a?(Net::HTTPSuccess)
        end
      end

      if Canvadocs.enabled?
        ret[:canvadocs] = lambda do
          CanvasHttp
            .get(URI.join(Canvadocs.config["base_url"], "/readiness").to_s)
            .is_a?(Net::HTTPSuccess)
        end
      end

      if CutyCapt.enabled? && CutyCapt.screencap_service
        ret[:screencap] = lambda do
          Tempfile.create("example.png", encoding: "ascii-8bit") do |f|
            CutyCapt.screencap_service.snapshot_url_to_file("about:blank", f)
          end
        end
      end

      if Account.site_admin.feature_enabled?(:notification_service)
        ret[:notification_queue] = lambda do
          !Services::NotificationService.process(Account.site_admin.global_id, nil, "noop", "nobody").nil?
        end
      end

      if ReleaseNote.enabled?
        ret[:release_notes] = lambda do
          !ReleaseNote.ddb_client.update_item(
            table_name: ReleaseNote.ddb_table_name,
            key: { "PartitionKey" => "healthcheck",
                   "RangeKey" => "canvas" }
          ).nil?
        end
      end

      if IncomingMailProcessor::IncomingMessageProcessor.run_periodically?
        ret[:incoming_mail] = lambda do
          IncomingMailProcessor::IncomingMessageProcessor.healthy?
        end
      end

      ret
    end

    def execute_deep_check(proc)
      Thread.new do
        Thread.current.report_on_exception = false
        proc.call
      end
    end

    def component_check(component, is_deep_check)
      status = false
      message = "service is up"
      exception_type = is_deep_check ? :deep_health_check : :readiness_health_check
      timeout = Setting.get("healthcheck_timelimit", 5.seconds.to_s).to_f
      response_time_ms =
        Benchmark.ms do
          Timeout.timeout(timeout, Timeout::Error) do
            status = component.is_a?(Thread) ? component.value : component.call
          end
        rescue Timeout::Error => e
          message = e.message
          Canvas::Errors.capture_exception(exception_type, e.message, :warn)
        rescue => e
          message = e.message
          Canvas::Errors.capture_exception(exception_type, e, :error)
        end

      { status:, message:, time: response_time_ms }
    end
  end
end
