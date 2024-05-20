# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#

describe InfoController do
  include_context "cdn registry stubs"

  describe "GET 'health_check'" do
    it "works" do
      get "health_check"
      expect(response).to be_successful
      expect(response.body).to eq "canvas ok"
    end

    it "respond_toes json" do
      request.accept = "application/json"
      allow(Canvas).to receive(:revision).and_return("Test Proc")
      get "health_check"
      expect(response).to be_successful
      json = response.parsed_body
      expect(json).to have_key("installation_uuid")
      json.delete("installation_uuid")
      expect(json).to eq({
                           "status" => "canvas ok",
                           "revision" => "Test Proc",
                           "asset_urls" => {
                             "common_css" => "/dist/brandable_css/new_styles_normal_contrast/bundles/common-#{BrandableCSS.cache_for("bundles/common", "new_styles_normal_contrast")[:combinedChecksum]}.css",
                             "common_js" => "/dist/webpack-dev/main-1234.js",
                             "revved_url" => "/dist/mock_revved_url"
                           }
                         })
    end
  end

  describe "GET 'health_prognosis'" do
    it "works if partitions are up to date" do
      # just in case
      Quizzes::QuizSubmissionEventPartitioner.process
      SimplyVersioned::Partitioner.process
      Messages::Partitioner.process

      get "health_prognosis"
      expect(response).to be_successful
    end

    it "fails if partitions haven't been running" do
      # stick a Version into last partition
      last_partition = CanvasPartman::PartitionManager.create(Version).partition_tables.last
      v_id = (last_partition.sub("versions_", "").to_i * Version.partition_size) + 1

      # don't have to make a real version anymore, just an object that _could_ make a version
      Course.create.wiki_pages.create!(id: v_id, title: "t")

      Timecop.freeze(4.years.from_now) do # and jump forward a ways
        get "health_prognosis"
        expect(response).to be_server_error
        body = response.body
        %w[messages_partition quizzes_submission_events_partition versions_partition].each do |type|
          expect(body).to include(type)
        end
      end
    end
  end

  describe "GET 'readiness'" do
    before do
      allow(Account.connection).to receive(:verify!).and_return(true)
      allow(MultiCache.cache).to receive(:fetch).and_call_original
      allow(MultiCache.cache).to receive(:fetch).with("readiness").and_return(nil)
      allow(Delayed::Job.connection).to receive(:verify!).and_return(true)
    end

    it "responds with 200 if all system components are alive and serving" do
      get "readiness"
      expect(response).to be_successful
      json = response.parsed_body
      expect(json["status"]).to eq 200
    end

    it "responds with 503 if a system component is considered down" do
      allow(Delayed::Job.connection).to receive(:verify!).and_raise(PG::UnableToSend)
      get "readiness"
      expect(response).to have_http_status :service_unavailable
      json = response.parsed_body
      expect(json["status"]).to eq 503
    end

    context "when the secondary is not connected" do
      let(:secondary_connection) { GuardRail.activate(:secondary) { Account.connection } }

      it "responds with 503" do
        allow(secondary_connection).to receive(:verify!) do
          raise ActiveRecord::ConnectionNotEstablished if GuardRail.current == :secondary # double check, in case we're sharing connections

          true
        end

        get "readiness"
        expect(response).to have_http_status :service_unavailable
        json = response.parsed_body
        expect(json["status"]).to eq 503
      end
    end

    it "catchs any exceptions thrown and logs them as errors" do
      allow(MultiCache.cache).to receive(:fetch).with("readiness").and_raise(Redis::TimeoutError)
      expect(Canvas::Errors).to receive(:capture_exception).once
      get "readiness"
      expect(response).to have_http_status :service_unavailable
      components = response.parsed_body["components"]
      ha_cache = components.find { |c| c["name"] == "ha_cache" }
      expect(ha_cache["status"]).to eq 503
    end

    it "catchs any timeouts thrown and logs them as warnings" do
      allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      expect(Canvas::Errors).to receive(:capture_exception)
        .at_least(:once)
        .with(:readiness_health_check, "Timeout::Error", :warn)
      get "readiness"
      expect(response).to have_http_status :service_unavailable
      json = response.parsed_body
      expect(json["status"]).to eq 503
    end

    it "returns all dependent system components in json response" do
      get "readiness"
      expect(response).to be_successful
      components = response.parsed_body["components"]
      expect(components.pluck("name")).to eq %w[
        common_css common_js consul filesystem jobs postgresql ha_cache rev_manifest vault
      ]
      expect(components.pluck("status")).to eq [200, 200, 200, 200, 200, 200, 200, 200, 200]
    end
  end

  describe "GET 'internal/readiness'", type: :routing do
    it "routes /internal/readiness to the info controller" do
      expect(get("/internal/readiness")).to route_to("info#readiness")
    end
  end

  describe "GET 'deep'" do
    let(:success_response) { Net::HTTPSuccess.new(Net::HTTPOK, "200", "OK") }

    before do
      allow(Account.connection).to receive(:verify!).and_return(true)
      allow(MultiCache.cache).to receive(:fetch).and_call_original
      allow(MultiCache.cache).to receive(:fetch).with("readiness").and_return(nil)
      allow(Delayed::Job.connection).to receive(:verify!).and_return(true)
      allow(Shard.connection).to receive(:verify!).and_return(true)
      allow(Canvadocs).to receive_messages(enabled?: true, config: { "base_url" => "https://canvadocs.instructure.com/" })
      allow(PageView).to receive(:pv4?).and_return(true)
      allow(ConfigFile).to receive(:load).and_call_original
      allow(ConfigFile).to receive(:load)
        .with("pv4").and_return({ "uri" => "https://pv4.instructure.com/api/123/" })
      allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with("rich-content-service")
        .and_return(DynamicSettings::FallbackProxy.new({ "app-host" => "rce.instructure.com" }))
      allow(CanvasHttp).to receive(:get).with(any_args).and_return(success_response)
      allow(IncomingMailProcessor::IncomingMessageProcessor).to receive_messages(run_periodically: true, healthy?: true)
    end

    it "renders readiness check within json response" do
      get "deep"
      expect(response).to be_successful
      json = response.parsed_body
      expect(json).to have_key("readiness")
      expect(json["readiness"]["components"].count).to be > 0
    end

    it "reports to statsd upon loading the deep endpoint" do
      allow(InstStatsd::Statsd).to receive(:gauge)
      allow(InstStatsd::Statsd).to receive(:timing)
      allow(Shard.current).to receive(:database_server_id).and_return("C1")

      get "deep"
      expect(response).to be_successful
      expect(InstStatsd::Statsd).to have_received(:gauge).with("canvas.health_checks.status", 1, tags: { type: :readiness, key: :common_css, cluster: "C1" })
    end

    it "responds with 503 if a readiness system component is considered down" do
      allow(Delayed::Job.connection).to receive(:verify!).and_raise(PG::UnableToSend)
      get "deep"
      expect(response).to have_http_status :service_unavailable
      json = response.parsed_body
      expect(json["status"]).to eq 503
    end

    it "returns 503 if critical dependency check fails and readiness response is 200" do
      allow(Shard.connection).to receive(:verify!).and_raise(PG::UnableToSend)
      get "deep"
      expect(response).to have_http_status :service_unavailable
      json = response.parsed_body
      expect(json["status"]).to eq 503
    end

    it "catches any secondary dependency check exceptions without failing the deep check" do
      allow(CanvasHttp).to receive(:get)
        .with("https://canvadocs.instructure.com/readiness")
        .and_raise(Timeout::Error)
      expect(Canvas::Errors).to receive(:capture_exception)
        .once
        .with(:deep_health_check, "Timeout::Error", :warn)
      get "deep"
      expect(response).to have_http_status :ok
      secondary = response.parsed_body["secondary"]
      canvadocs = secondary.find { |c| c["name"] == "canvadocs" }
      expect(canvadocs["status"]).to eq 503
    end

    it "catches any timeouts thrown and logs them as warnings" do
      allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      expect(Canvas::Errors).to receive(:capture_exception)
        .at_least(:once)
        .with(:deep_health_check, "Timeout::Error", :warn)
      get "deep"
      expect(response).to have_http_status :service_unavailable
      json = response.parsed_body
      expect(json["status"]).to eq 503
    end

    it "returns critical dependencies in json response" do
      get "deep"
      expect(response).to be_successful
      critical = response.parsed_body["critical"]
      critical.each do |dep|
        expect(dep["name"]).to be_truthy
        expect(dep["status"]).to eq 200
      end
    end

    it "returns secondary dependencies in json response" do
      get "deep"
      expect(response).to be_successful
      secondary = response.parsed_body["secondary"]
      secondary.each do |dep|
        expect(dep["name"]).to be_truthy
        expect(dep["status"]).to eq 200
      end
    end

    it "returns secondary dependencies in json response only if enabled" do
      allow(Canvadocs).to receive(:enabled?).and_return(false)
      allow(PageView).to receive(:pv4?).and_return(false)
      get "deep"
      expect(response).to be_successful
      secondary = response.parsed_body["secondary"]
      expect(secondary).to eq []
    end
  end

  describe "GET 'help_links'" do
    it "works" do
      get "help_links"
      expect(response).to be_successful
    end

    it "sets the locale for translated help link text from the current user" do
      user = User.create!(locale: "es")
      user_session(user)
      # create and save account instance so that we don't invoke I18n's
      # localizer lambda in a request filter prior to loading necessary
      # users, accounts, context etc.
      Account.default
      get "help_links"

      expect(response.parsed_body.find { |x| x["text"] == "Busque en las guías de Canvas" }).not_to be_nil
    end

    it "filters the links based on the current user's role" do
      account = Account.create!
      allow(account.help_links_builder).to receive(:default_links).and_return([
                                                                                {
                                                                                  available_to: ["student"],
                                                                                  text: "Ask Your Instructor a Question",
                                                                                  subtext: "Questions are submitted to your instructor",
                                                                                  url: "#teacher_feedback",
                                                                                  is_default: "true"
                                                                                },
                                                                                {
                                                                                  available_to: %w[user student teacher admin observer unenrolled],
                                                                                  text: "Search the Canvas Guides",
                                                                                  subtext: "Find answers to common questions",
                                                                                  url: "https://community.canvaslms.test/t5/Canvas/ct-p/canvas",
                                                                                  is_default: "true"
                                                                                },
                                                                                {
                                                                                  available_to: %w[user student teacher admin observer unenrolled],
                                                                                  text: "Report a Problem",
                                                                                  subtext: "If Canvas misbehaves, tell us about it",
                                                                                  url: "#create_ticket",
                                                                                  is_default: "true"
                                                                                }
                                                                              ])
      allow(LoadAccount).to receive(:default_domain_root_account).and_return(account)
      admin = account_admin_user active_all: true
      user_session(admin)

      get "help_links"
      links = json_parse(response.body)
      expect(links.count { |link| link[:text] == "Ask Your Instructor a Question" }).to eq 0
    end
  end

  describe "GET 'web-app-manifest'" do
    it "works" do
      get "web_app_manifest"
      expect(response).to be_successful
    end

    it "returns icon path correct" do
      get "web_app_manifest"
      manifest = json_parse(response.body)
      src = manifest["icons"].first["src"]
      expect(src).to eq("/dist/images/apple-touch-icon-1234.png")
    end
  end
end
