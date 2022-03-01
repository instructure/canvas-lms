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
#

require_relative "../api_spec_helper"

describe "Jobs V2 API", type: :request do
  include Api

  describe "#queued_tags" do
    it "requires site admin" do
      api_call(:get, "/api/v1/jobs/tags/queued",
               { controller: "jobs_v2", action: "queued_tags", format: "json" },
               {}, {}, expected_status: 401)
    end

    context "as site admin" do
      before :once do
        site_admin_user

        ::Kernel.delay(run_at: 1.hour.ago).sleep(1)
        ::Kernel.delay(run_at: 2.hours.ago).p
        ::Kernel.delay(run_at: 1.day.ago).sleep(1)

        # fake a held job to make sure it does appear
        Delayed::Job.last.update locked_by: ::Delayed::Backend::Base::ON_HOLD_LOCKED_BY

        # fake a running job and a held job to be sure it doesn't appear
        ::Kernel.delay(run_at: 3.hours.ago).puts
        Delayed::Job.last.update locked_by: "foo", locked_at: 1.hour.ago
      end

      it "returns queued jobs sorted by oldest" do
        json = api_call(:get, "/api/v1/jobs/tags/queued",
                        { controller: "jobs_v2", action: "queued_tags", format: "json" },
                        {}, {}, expected_status: 200)
        expect(json.size).to eq 2
        expect(json[0]["tag"]).to eq "Kernel.sleep"
        expect(json[0]["count"]).to eq 2
        expect(Time.zone.parse(json[0]["min_run_at"])).to be_within(1.minute).of(1.day.ago)
        expect(json[1]["tag"]).to eq "Kernel.p"
        expect(json[1]["count"]).to eq 1
        expect(Time.zone.parse(json[1]["min_run_at"])).to be_within(1.minute).of(2.hours.ago)
      end

      it "sorts by tag" do
        json = api_call(:get, "/api/v1/jobs/tags/queued?order=tag",
                        { controller: "jobs_v2", action: "queued_tags", format: "json", order: "tag" },
                        {}, {}, expected_status: 200)
        expect(json.size).to eq 2
        expect(json[0]["tag"]).to eq "Kernel.p"
        expect(json[1]["tag"]).to eq "Kernel.sleep"
      end

      it "sorts by count" do
        ::Kernel.delay(run_at: 2.days.ago).puts
        json = api_call(:get, "/api/v1/jobs/tags/queued?order=count",
                        { controller: "jobs_v2", action: "queued_tags", format: "json", order: "count" },
                        {}, {}, expected_status: 200)
        expect(json.size).to eq 3
        expect(json[0]["tag"]).to eq "Kernel.sleep"
      end

      it "paginates" do
        json = api_call(:get, "/api/v1/jobs/tags/queued?per_page=1",
                        { controller: "jobs_v2", action: "queued_tags", format: "json", per_page: "1" },
                        {}, {}, expected_status: 200)
        expect(json.map { |e| e["tag"] }).to eq ["Kernel.sleep"]
        links = Api.parse_pagination_links(response.headers["Link"])
        next_link = links.find { |link| link[:rel] == "next" }
        json = api_call(:get, next_link[:uri].path,
                        { controller: "jobs_v2", action: "queued_tags", format: "json", per_page: "1", page: "2" },
                        {}, {}, expected_status: 200)
        expect(json.map { |e| e["tag"] }).to eq ["Kernel.p"]
      end
    end
  end

  describe "#running_tags" do
    before :once do
      site_admin_user

      # fake some running jobs
      ::Kernel.delay.sleep 1
      Delayed::Job.last.update locked_at: 1.hour.ago, locked_by: "me"
      ::Kernel.delay.sleep 1
      Delayed::Job.last.update locked_at: 2.hours.ago, locked_by: "me"

      ::Kernel.delay.p
      Delayed::Job.last.update locked_at: 30.minutes.ago, locked_by: "foo"

      # and a fake held job, to ensure it doesn't appear here
      ::Kernel.delay.puts
      Delayed::Job.last.update locked_by: ::Delayed::Backend::Base::ON_HOLD_LOCKED_BY
    end

    it "returns running jobs" do
      json = api_call(:get, "/api/v1/jobs/tags/running",
                      { controller: "jobs_v2", action: "running_tags", format: "json" },
                      {}, {}, expected_status: 200)
      expect(json.size).to eq 2
      expect(json[0]["tag"]).to eq "Kernel.sleep"
      expect(json[0]["count"]).to eq 2
      expect(Time.zone.parse(json[0]["first_locked_at"])).to be_within(1.minute).of(2.hours.ago)
      expect(json[1]["tag"]).to eq "Kernel.p"
      expect(json[1]["count"]).to eq 1
      expect(Time.zone.parse(json[1]["first_locked_at"])).to be_within(1.minute).of(30.minutes.ago)
    end
  end

  describe "#future_tags" do
    before :once do
      site_admin_user

      ::Kernel.delay(run_at: 1.hour.from_now).sleep(1)
      ::Kernel.delay(run_at: 1.day.from_now).p
    end

    it "returns future tags sorted by next up" do
      json = api_call(:get, "/api/v1/jobs/tags/future",
                      { controller: "jobs_v2", action: "future_tags", format: "json" },
                      {}, {}, expected_status: 200)
      expect(json.size).to eq 2
      expect(json[0]["tag"]).to eq "Kernel.sleep"
      expect(json[0]["count"]).to eq 1
      expect(Time.zone.parse(json[0]["next_run_at"])).to be_within(1.minute).of(1.hour.from_now)
      expect(json[1]["tag"]).to eq "Kernel.p"
      expect(Time.zone.parse(json[1]["next_run_at"])).to be_within(1.minute).of(1.day.from_now)
      expect(json[1]["count"]).to eq 1
    end
  end

  describe "#failed_tags" do
    before :once do
      site_admin_user

      Timecop.travel(1.day.ago) do
        ::Kernel.delay.raise "uh oh"
        run_jobs
      end

      Timecop.travel(1.hour.ago) do
        ::Kernel.delay.raise "oops"
        run_jobs
      end
    end

    it "returns failed jobs sorted by most recent" do
      json = api_call(:get, "/api/v1/jobs/tags/failed",
                      { controller: "jobs_v2", action: "failed_tags", format: "json" },
                      {}, {}, expected_status: 200)
      expect(json.size).to eq 1
      expect(json[0]["tag"]).to eq "Kernel.raise"
      expect(json[0]["count"]).to eq 2
      expect(Time.zone.parse(json[0]["last_failed_at"])).to be_within(1.minute).of(1.hour.ago)
    end
  end
end
