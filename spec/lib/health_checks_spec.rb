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

describe HealthChecks do
  let(:success_response) { Net::HTTPSuccess.new(Net::HTTPOK, "200", "OK") }

  it "passes the basic readiness checks" do
    readiness_result = described_class.process_readiness_checks(false)

    expect(readiness_result.keys.sort).to eq %i[common_css common_js consul filesystem ha_cache jobs postgresql rev_manifest vault]
    expect(readiness_result.values.pluck(:status).uniq).to eq [true]
  end

  it "fails the postgresql readiness check" do
    allow(Account.connection).to receive(:active?).and_return(false)
    readiness_result = described_class.process_readiness_checks(false)

    expect(readiness_result.keys.sort).to eq %i[common_css common_js consul filesystem ha_cache jobs postgresql rev_manifest vault]
    expect(readiness_result[:postgresql][:status]).to eq false
  end

  context "process_deep_checks" do
    it "passes the default_shard check" do
      expect(described_class.process_deep_checks[:critical][:default_shard][:status]).to eq true
    end

    it "passes the InstFS check" do
      allow(CanvasHttp).to receive(:get).with(any_args).and_return(success_response)
      allow(InstFS).to receive(:app_host).and_return("https://www.example.com")
      allow(InstFS).to receive(:enabled?).and_return(true)

      expect(described_class.process_deep_checks[:critical][:inst_fs][:status]).to eq true
    end

    it "passes the Redis check" do
      expect(described_class.process_deep_checks[:critical][:redis][:status]).to eq true
    end

    it "passes the rich content service check" do
      allow(CanvasHttp).to receive(:get).with(any_args).and_return(success_response)
      allow(Services::RichContent).to receive(:service_settings).and_return({ RICH_CONTENT_APP_HOST: "rce.instructure.com" })

      expect(described_class.process_deep_checks[:critical][:rich_content_service][:status]).to eq true
    end

    it "passes the mathman check" do
      allow(CanvasHttp).to receive(:get).with(any_args).and_return(success_response)
      allow(MathMan).to receive(:url_for).and_return("www.example.com")
      allow(MathMan).to receive(:use_for_svg?).and_return(true)

      expect(described_class.process_deep_checks[:critical][:mathman][:status]).to eq true
    end

    it "passes the live events check" do
      allow(LiveEvents::Client).to receive(:config).and_return({})
      allow(LiveEvents).to receive(:send).and_return(Class.new do
        def stream_client
          Class.new do
            def put_records(...)
              ["RECORDS"]
            end
          end.new
        end

        def stream_name
          "STREAM_NAME"
        end
      end.new)

      expect(described_class.process_deep_checks[:critical][:live_events][:status]).to eq true
    end

    it "passes the page view checks" do
      allow(CanvasHttp).to receive(:get).with(any_args).and_return(success_response)
      allow(ConfigFile).to receive(:load).and_call_original
      allow(ConfigFile).to receive(:load)
        .with("pv4").and_return({ "uri" => "https://pv4.instructure.com/api/123/" })
      allow(PageView).to receive(:pv4?).and_return({})

      expect(described_class.process_deep_checks[:secondary][:pv4][:status]).to eq true
    end

    it "passes the canvadocs checks" do
      allow(CanvasHttp).to receive(:get).with(any_args).and_return(success_response)
      allow(Canvadocs).to receive(:enabled?).and_return(true)
      allow(Canvadocs).to receive(:config)
        .and_return({ "base_url" => "https://canvadocs.instructure.com/" })

      expect(described_class.process_deep_checks[:secondary][:canvadocs][:status]).to eq true
    end

    it "passes the screencap check" do
      allow(CutyCapt).to receive(:enabled?).and_return(true)
      allow(CutyCapt).to receive(:screencap_service).and_return(Class.new do
        def snapshot_url_to_file(...)
          true
        end
      end.new)

      expect(described_class.process_deep_checks[:secondary][:screencap][:status]).to eq true
    end

    it "passes the notification_queue check" do
      allow(Account.site_admin).to receive(:feature_enabled?).with(:notification_service).and_return(true)
      allow(Services::NotificationService).to receive(:process).and_return(true)

      expect(described_class.process_deep_checks[:secondary][:notification_queue][:status]).to eq true
    end

    it "passes the release_notes check" do
      allow(ReleaseNote).to receive(:enabled?).and_return(true)
      allow(ReleaseNote.ddb_client).to receive(:update_item).and_return(true)

      expect(described_class.process_deep_checks[:secondary][:release_notes][:status]).to eq true
    end

    it "passes the incoming_mail check" do
      allow(IncomingMailProcessor::IncomingMessageProcessor).to receive(:run_periodically?).and_return(true)
      allow(IncomingMailProcessor::IncomingMessageProcessor).to receive(:healthy?).and_return(true)

      expect(described_class.process_deep_checks[:secondary][:incoming_mail][:status]).to eq true
    end
  end

  it "reports metrics to statsd" do
    allow(InstStatsd::Statsd).to receive(:gauge)
    allow(InstStatsd::Statsd).to receive(:timing)

    allow(HealthChecks).to receive(:process_readiness_checks).and_return(
      {
        readiness_check_name_error: { time: 1, status: false },
        readiness_check_name_success: { time: 2, status: true },
      }
    )

    allow(HealthChecks).to receive(:process_deep_checks).and_return(
      {
        deep: {
          deep_check_name_error: { time: 3, status: false },
          deep_check_name_success: { time: 4, status: true },
        }
      }
    )

    HealthChecks.send_to_statsd

    expect(InstStatsd::Statsd).to have_received(:gauge).with("canvas.health_checks.status", 0, tags: { type: :deep, key: :deep_check_name_error })
    expect(InstStatsd::Statsd).to have_received(:gauge).with("canvas.health_checks.status", 0, tags: { type: :readiness, key: :readiness_check_name_error })
    expect(InstStatsd::Statsd).to have_received(:gauge).with("canvas.health_checks.status", 1, tags: { type: :deep, key: :deep_check_name_success })
    expect(InstStatsd::Statsd).to have_received(:gauge).with("canvas.health_checks.status", 1, tags: { type: :readiness, key: :readiness_check_name_success })
    expect(InstStatsd::Statsd).to have_received(:timing).with("canvas.health_checks.response_time_ms", 1, tags: { type: :readiness, key: :readiness_check_name_error })
    expect(InstStatsd::Statsd).to have_received(:timing).with("canvas.health_checks.response_time_ms", 2, tags: { type: :readiness, key: :readiness_check_name_success })
    expect(InstStatsd::Statsd).to have_received(:timing).with("canvas.health_checks.response_time_ms", 3, tags: { type: :deep, key: :deep_check_name_error })
    expect(InstStatsd::Statsd).to have_received(:timing).with("canvas.health_checks.response_time_ms", 4, tags: { type: :deep, key: :deep_check_name_success })
  end
end
