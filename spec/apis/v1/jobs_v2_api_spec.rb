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

  it "requires site admin for grouped_info" do
    api_call(:get, "/api/v1/jobs2/queued/by_tag",
             { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag" },
             {}, {}, expected_status: 401)
  end

  it "requires site admin for list" do
    api_call(:get, "/api/v1/jobs2/running",
             { controller: "jobs_v2", action: "list", format: "json", bucket: "running" },
             {}, {}, expected_status: 401)
  end

  it "requries site admin for lookup" do
    api_call(:get, "/api/v1/jobs2/123",
             { controller: "jobs_v2", action: "lookup", format: "json", id: "123" },
             {}, {}, expected_status: 401)
  end

  context "as site admin" do
    before :once do
      site_admin_user
    end

    describe "queued jobs" do
      before :once do
        ::Kernel.delay(run_at: 1.hour.ago).pp
        ::Kernel.delay(run_at: 2.hours.ago).p
        @queued_job_id = Delayed::Job.last.id

        # fake a held job to make sure it does appear
        ::Kernel.delay(run_at: 1.day.ago).pp
        Delayed::Job.last.update locked_by: ::Delayed::Backend::Base::ON_HOLD_LOCKED_BY
        @held_job_id = Delayed::Job.last.id

        # fake a running job to be sure it doesn't appear
        ::Kernel.delay(run_at: 3.hours.ago).puts
        Delayed::Job.last.update locked_by: "foo", locked_at: 1.hour.ago
      end

      it "scopes the query to the current account" do
        ::Kernel.delay(run_at: 1.hour.ago, account_id: Account.default).pp
        ::Kernel.delay(run_at: 1.hour.ago, account_id: Account.default).pp

        json = api_call(:get, "/api/v1/jobs2/queued",
                        { controller: "jobs_v2", action: "list", format: "json", bucket: "queued", scope: "account" })
        expect(json.size).to eq 2
      end

      context "sharding" do
        specs_require_sharding

        before do
          @shard1.activate do
            ::Kernel.delay(run_at: 1.hour.ago).pp
            ::Kernel.delay(run_at: 1.hour.ago).pp

            @a1 = Account.create!
          end

          Shard.default.activate do
            ::Kernel.delay(run_at: 1.hour.ago).pp
            ::Kernel.delay(run_at: 1.hour.ago).pp
          end
        end

        it "scopes the query to the current shard" do
          json = api_call(:get, "/api/v1/jobs2/queued",
                          { controller: "jobs_v2", action: "list", format: "json", bucket: "queued", scope: "shard" },
                          {}, {}, { domain_root_account: @a1 })
          expect(json.size).to eq 2
        end

        it "scopes the query to the current cluster" do
          json = api_call(:get, "/api/v1/jobs2/queued",
                          { controller: "jobs_v2", action: "list", format: "json", bucket: "queued", scope: "cluster" },
                          {}, {}, { domain_root_account: @a1 })
          expect(json.size).to eq 4
        end
      end

      describe "grouped by tag" do
        it "returns queued jobs sorted by oldest" do
          json = api_call(:get, "/api/v1/jobs2/queued/by_tag",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag" },
                          {}, {}, expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["tag"]).to eq "Kernel.pp"
          expect(json[0]["count"]).to eq 2
          expect(json[0]["info"].seconds).to be_within(1.minute).of(1.day)
          expect(json[1]["tag"]).to eq "Kernel.p"
          expect(json[1]["count"]).to eq 1
          expect(json[1]["info"].seconds).to be_within(1.minute).of(2.hours)
        end

        it "sorts by tag" do
          json = api_call(:get, "/api/v1/jobs2/queued/by_tag?order=tag",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag", order: "tag" },
                          {}, {}, expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["tag"]).to eq "Kernel.p"
          expect(json[1]["tag"]).to eq "Kernel.pp"
        end

        it "sorts by count" do
          ::Kernel.delay(run_at: 2.days.ago).puts
          json = api_call(:get, "/api/v1/jobs2/queued/by_tag?order=count",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag", order: "count" },
                          {}, {}, expected_status: 200)
          expect(json.size).to eq 3
          expect(json[0]["tag"]).to eq "Kernel.pp"
        end

        it "paginates" do
          json = api_call(:get, "/api/v1/jobs2/queued/by_tag?per_page=1",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag", per_page: "1" },
                          {}, {}, expected_status: 200)
          expect(json.map { |e| e["tag"] }).to eq ["Kernel.pp"]
          links = Api.parse_pagination_links(response.headers["Link"])
          next_link = links.find { |link| link[:rel] == "next" }
          json = api_call(:get, next_link[:uri].path,
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag", per_page: "1", page: "2" },
                          {}, {}, expected_status: 200)
          expect(json.map { |e| e["tag"] }).to eq ["Kernel.p"]
        end
      end

      describe "by_strand" do
        before :once do
          ::Kernel.delay(strand: "foo", run_at: 1.hour.ago).puts
          ::Kernel.delay(strand: "bar", run_at: 2.hours.ago).puts
          ::Kernel.delay(strand: "bar", run_at: 30.minutes.ago).p
        end

        it "groups by strand" do
          json = api_call(:get, "/api/v1/jobs2/queued/by_strand?order=group",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "strand", order: "group" },
                          {}, {}, expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["strand"]).to eq "bar"
          expect(json[0]["count"]).to eq 2
          expect(json[0]["info"].seconds).to be_within(1.minute).of(2.hours)
          expect(json[1]["strand"]).to eq "foo"
          expect(json[1]["count"]).to eq 1
          expect(json[1]["info"].seconds).to be_within(1.minute).of(1.hour)
        end

        it "searches by strand" do
          json = api_call(:get, "/api/v1/jobs2/queued/by_strand/search?term=bar",
                          { controller: "jobs_v2", action: "search", format: "json", bucket: "queued", group: "strand", term: "bar" })
          expect(json).to eq({ "bar" => 2 })
        end
      end

      describe "by_singleton" do
        before :once do
          ::Kernel.delay(singleton: "foobar2000", run_at: 1.hour.ago).puts
          ::Kernel.delay(singleton: "zombo20001", run_at: 22.hours.ago).puts
        end

        it "groups by singleton" do
          json = api_call(:get, "/api/v1/jobs2/queued/by_singleton?order=info",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "singleton", order: "info" },
                          {}, {}, expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["singleton"]).to eq "zombo20001"
          expect(json[0]["count"]).to eq 1
          expect(json[0]["info"].seconds).to be_within(1.minute).of(22.hours)
          expect(json[1]["singleton"]).to eq "foobar2000"
          expect(json[1]["count"]).to eq 1
          expect(json[1]["info"].seconds).to be_within(1.minute).of(1.hour)
        end

        it "searches by singleton" do
          json = api_call(:get, "/api/v1/jobs2/queued/by_singleton/search?term=2000",
                          { controller: "jobs_v2", action: "search", format: "json", bucket: "queued", group: "singleton", term: "2000" })
          expect(json.to_a).to eq([["foobar2000", 1], ["zombo20001", 1]])
        end
      end

      describe "ungrouped" do
        it "lists queued jobs" do
          json = api_call(:get, "/api/v1/jobs2/queued?order=tag",
                          { controller: "jobs_v2", action: "list", format: "json", bucket: "queued", order: "tag" })
          expect(json.size).to eq 3
          expect(json[0]["tag"]).to eq "Kernel.p"
          expect(json[0]["info"].seconds).to be_within(1.minute).of(2.hours)
          expect(json[1]["tag"]).to eq "Kernel.pp"
          expect(json[2]["tag"]).to eq "Kernel.pp"
        end

        it "filters by tag" do
          json = api_call(:get, "/api/v1/jobs2/queued?tag=Kernel.pp",
                          { controller: "jobs_v2", action: "list", format: "json", bucket: "queued", tag: "Kernel.pp" })
          expect(json.size).to eq 2
          expect(json[0]["info"].seconds).to be_within(1.minute).of(1.day)
        end
      end

      it "searches queued tags" do
        json = api_call(:get, "/api/v1/jobs2/queued/by_tag/search?term=p",
                        { controller: "jobs_v2", action: "search", format: "json", bucket: "queued", group: "tag", term: "p" })
        expect(json).to eq({ "Kernel.pp" => 2, "Kernel.p" => 1 })
      end

      it "finds a held job by id" do
        json = api_call(:get, "/api/v1/jobs2/#{@held_job_id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: @held_job_id.to_s })
        item = json.find { |row| row["id"] == @held_job_id }
        expect(item["tag"]).to eq "Kernel.pp"
        expect(item["bucket"]).to eq "queued"
      end

      it "finds a queued job by id" do
        json = api_call(:get, "/api/v1/jobs2/#{@queued_job_id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: @queued_job_id.to_s })
        item = json.find { |row| row["id"] == @queued_job_id }
        expect(item["tag"]).to eq "Kernel.p"
        expect(item["bucket"]).to eq "queued"
      end
    end

    describe "running jobs" do
      before :once do
        # fake some running jobs
        ::Kernel.delay.pp
        Delayed::Job.last.update locked_at: 1.hour.ago, locked_by: "me"
        ::Kernel.delay.pp
        Delayed::Job.last.update locked_at: 2.hours.ago, locked_by: "me"

        ::Kernel.delay.p
        Delayed::Job.last.update locked_at: 30.minutes.ago, locked_by: "foo"

        # and a fake held job, to ensure it doesn't appear here
        ::Kernel.delay.puts
        Delayed::Job.last.update locked_by: ::Delayed::Backend::Base::ON_HOLD_LOCKED_BY
      end

      it "groups by tag" do
        json = api_call(:get, "/api/v1/jobs2/running/by_tag",
                        { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "running", group: "tag" },
                        {}, {}, expected_status: 200)
        expect(json.size).to eq 2
        expect(json[0]["tag"]).to eq "Kernel.pp"
        expect(json[0]["count"]).to eq 2
        expect(json[0]["info"].seconds).to be_within(1.minute).of(2.hours)
        expect(json[1]["tag"]).to eq "Kernel.p"
        expect(json[1]["count"]).to eq 1
        expect(json[1]["info"].seconds).to be_within(1.minute).of(30.minutes)
      end

      describe "by_strand" do
        before :once do
          Delayed::Job.where(tag: "Kernel.pp").update_all(strand: "foo")
          Delayed::Job.where(tag: "Kernel.p").update_all(strand: "barfood")
        end

        it "groups by strand" do
          json = api_call(:get, "/api/v1/jobs2/running/by_strand?order=strand",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "running", group: "strand", order: "strand" },
                          {}, {}, expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["strand"]).to eq "barfood"
          expect(json[0]["count"]).to eq 1
          expect(json[0]["info"].seconds).to be_within(1.minute).of(30.minutes)
          expect(json[1]["strand"]).to eq "foo"
          expect(json[1]["count"]).to eq 2
          expect(json[1]["info"].seconds).to be_within(1.minute).of(2.hours)
        end

        it "searches by strand" do
          json = api_call(:get, "/api/v1/jobs2/running/by_strand/search?term=foo",
                          { controller: "jobs_v2", action: "search", format: "json", bucket: "running", group: "strand", term: "foo" })
          expect(json).to eq({ "foo" => 2, "barfood" => 1 })
        end
      end

      it "lists running jobs" do
        json = api_call(:get, "/api/v1/jobs2/running",
                        { controller: "jobs_v2", action: "list", format: "json", bucket: "running" })
        expect(json.size).to eq 3
        expect(json[0]["tag"]).to eq "Kernel.pp"
        expect(json[0]["info"].seconds).to be_within(1.minute).of(2.hours)
        expect(json[1]["tag"]).to eq "Kernel.pp"
        expect(json[1]["info"].seconds).to be_within(1.minute).of(1.hour)
        expect(json[2]["tag"]).to eq "Kernel.p"
        expect(json[2]["info"].seconds).to be_within(1.minute).of(30.minutes)
      end

      it "orders running jobs by strand_singleton" do
        Delayed::Job.where(tag: "Kernel.p").update_all(strand: "barfood")

        ::Kernel.delay(strand: "foo", singleton: "singletonB").pp
        Delayed::Job.last.update locked_at: 1.hour.ago, locked_by: "me"
        ::Kernel.delay(strand: "foo", singleton: "singletonA").pp
        Delayed::Job.last.update locked_at: 1.hour.ago, locked_by: "me"
        ::Kernel.delay(strand: "foo", singleton: "singletonC").pp
        Delayed::Job.last.update locked_at: 1.hour.ago, locked_by: "me"

        json = api_call(:get, "/api/v1/jobs2/running",
                        { controller: "jobs_v2", action: "list", format: "json", bucket: "running", order: "strand_singleton" })
        expect(json.size).to eq 6
        expect(json.map { |x| x["strand"] }).to eq ["barfood", "foo", "foo", "foo", nil, nil]
        expect(json.map { |x| x["singleton"] }).to eq [nil, "singletonA", "singletonB", "singletonC", nil, nil]
      end

      it "searches running tags" do
        json = api_call(:get, "/api/v1/jobs2/running/by_tag/search?term=p",
                        { controller: "jobs_v2", action: "search", format: "json", bucket: "running", group: "tag", term: "p" })
        expect(json).to eq({ "Kernel.pp" => 2, "Kernel.p" => 1 })
      end

      it "finds a job by id" do
        job = Delayed::Job.where(locked_by: "foo").take
        json = api_call(:get, "/api/v1/jobs2/#{job.id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: job.to_param })
        item = json.find { |row| row["id"] == job.id }
        expect(item["tag"]).to eq "Kernel.p"
        expect(item["bucket"]).to eq "running"
      end
    end

    describe "future" do
      before :once do
        ::Kernel.delay(run_at: 1.hour.from_now).pp
        ::Kernel.delay(run_at: 1.day.from_now).p
      end

      it "groups by tag" do
        json = api_call(:get, "/api/v1/jobs2/future/by_tag",
                        { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "future", group: "tag" },
                        {}, {}, expected_status: 200)
        expect(json.size).to eq 2
        expect(json[0]["tag"]).to eq "Kernel.pp"
        expect(json[0]["count"]).to eq 1
        expect(Time.zone.parse(json[0]["info"])).to be_within(1.minute).of(1.hour.from_now)
        expect(json[1]["tag"]).to eq "Kernel.p"
        expect(Time.zone.parse(json[1]["info"])).to be_within(1.minute).of(1.day.from_now)
        expect(json[1]["count"]).to eq 1
      end

      describe "by_strand" do
        before :once do
          ::Kernel.delay(run_at: 1.hour.from_now, strand: "foo").puts
          ::Kernel.delay(run_at: 2.hours.from_now, strand: "foo").puts
          ::Kernel.delay(run_at: 1.day.from_now, strand: "bar").puts
        end

        it "groups by strand" do
          json = api_call(:get, "/api/v1/jobs2/future/by_strand?order=strand",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "future", group: "strand", order: "strand" },
                          {}, {}, expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["strand"]).to eq "bar"
          expect(json[0]["count"]).to eq 1
          expect(Time.zone.parse(json[0]["info"])).to be_within(1.minute).of(1.day.from_now)
          expect(json[1]["strand"]).to eq "foo"
          expect(json[1]["count"]).to eq 2
          expect(Time.zone.parse(json[1]["info"])).to be_within(1.minute).of(1.hour.from_now)
        end

        it "searches by strand" do
          json = api_call(:get, "/api/v1/jobs2/future/by_strand/search?term=foo",
                          { controller: "jobs_v2", action: "search", format: "json", bucket: "future", group: "strand", term: "foo" })
          expect(json).to eq({ "foo" => 2 })
        end
      end

      it "lists future jobs" do
        json = api_call(:get, "/api/v1/jobs2/future",
                        { controller: "jobs_v2", action: "list", format: "json", bucket: "future" })
        expect(json.size).to eq 2
        expect(json[0]["tag"]).to eq "Kernel.pp"
        expect(Time.zone.parse(json[0]["info"])).to be_within(1.minute).of(1.hour.from_now)
        expect(json[1]["tag"]).to eq "Kernel.p"
        expect(Time.zone.parse(json[1]["info"])).to be_within(1.minute).of(1.day.from_now)
      end

      it "searches future tags" do
        json = api_call(:get, "/api/v1/jobs2/future/by_tag/search?term=p",
                        { controller: "jobs_v2", action: "search", format: "json", bucket: "future", group: "tag", term: "p" })
        expect(json).to eq({ "Kernel.pp" => 1, "Kernel.p" => 1 })
      end

      it "finds a job by id" do
        job = Delayed::Job.last
        json = api_call(:get, "/api/v1/jobs2/#{job.id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: job.to_param })
        item = json.find { |row| row["id"] == job.id }
        expect(item["tag"]).to eq "Kernel.p"
        expect(item["bucket"]).to eq "future"
      end
    end

    describe "failed" do
      before :once do
        Timecop.travel(1.day.ago) do
          ::Kernel.delay.raise "uh oh"
          run_jobs
        end

        Timecop.travel(1.hour.ago) do
          ::Kernel.delay.raise "oops"
          run_jobs
        end
      end

      it "groups by tag" do
        json = api_call(:get, "/api/v1/jobs2/failed/by_tag",
                        { controller: "jobs_v2", action: "grouped_info", bucket: "failed", format: "json", group: "tag" },
                        {}, {}, expected_status: 200)
        expect(json.size).to eq 1
        expect(json[0]["tag"]).to eq "Kernel.raise"
        expect(json[0]["count"]).to eq 2
        expect(Time.zone.parse(json[0]["info"])).to be_within(1.minute).of(1.hour.ago)
      end

      it "lists failed jobs" do
        json = api_call(:get, "/api/v1/jobs2/failed",
                        { controller: "jobs_v2", action: "list", format: "json", bucket: "failed" })
        expect(json.size).to eq 2
        expect(json[0]["tag"]).to eq "Kernel.raise"
        expect(Time.zone.parse(json[0]["info"])).to be_within(1.minute).of(1.hour.ago)
        expect(json[1]["tag"]).to eq "Kernel.raise"
        expect(Time.zone.parse(json[1]["info"])).to be_within(1.minute).of(1.day.ago)
      end

      it "searches failed tags" do
        json = api_call(:get, "/api/v1/jobs2/failed/by_tag/search?term=ais",
                        { controller: "jobs_v2", action: "search", format: "json", bucket: "failed", group: "tag", term: "ais" })
        expect(json).to eq({ "Kernel.raise" => 2 })
      end

      it "finds a failed job by id" do
        job = Delayed::Job::Failed.last
        json = api_call(:get, "/api/v1/jobs2/#{job.id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: job.to_param })
        item = json.find { |row| row["id"] == job.id }
        expect(item["tag"]).to eq "Kernel.raise"
        expect(item["bucket"]).to eq "failed"
      end

      it "finds a failed job by original_job_id" do
        job = Delayed::Job::Failed.last
        json = api_call(:get, "/api/v1/jobs2/#{job.original_job_id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: job.original_job_id.to_s })
        item = json.find { |row| row["original_job_id"] == job.original_job_id }
        expect(item["tag"]).to eq "Kernel.raise"
        expect(item["bucket"]).to eq "failed"
      end
    end
  end
end
