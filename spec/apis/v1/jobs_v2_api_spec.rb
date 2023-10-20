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
    api_call(:get,
             "/api/v1/jobs2/queued/by_tag",
             { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag" },
             {},
             {},
             expected_status: 401)
  end

  it "requires site admin for list" do
    api_call(:get,
             "/api/v1/jobs2/running",
             { controller: "jobs_v2", action: "list", format: "json", bucket: "running" },
             {},
             {},
             expected_status: 401)
  end

  it "requries site admin for lookup" do
    api_call(:get,
             "/api/v1/jobs2/123",
             { controller: "jobs_v2", action: "lookup", format: "json", id: "123" },
             {},
             {},
             expected_status: 401)
  end

  context "as site admin" do
    before :once do
      site_admin_user
    end

    describe "queued jobs" do
      before :once do
        Kernel.delay(run_at: 1.hour.ago).pp
        Kernel.delay(run_at: 2.hours.ago).p
        @queued_job_id = Delayed::Job.last.id

        # fake a held job to make sure it does appear
        Kernel.delay(run_at: 1.day.ago).pp
        Delayed::Job.last.update locked_by: Delayed::Backend::Base::ON_HOLD_LOCKED_BY
        @held_job_id = Delayed::Job.last.id

        # fake a running job to be sure it doesn't appear
        Kernel.delay(run_at: 3.hours.ago).puts
        Delayed::Job.last.update locked_by: "foo", locked_at: 1.hour.ago
      end

      it "scopes the query to the current account" do
        Kernel.delay(run_at: 1.hour.ago, account_id: Account.default).pp
        Kernel.delay(run_at: 1.hour.ago, account_id: Account.default).pp

        json = api_call(:get,
                        "/api/v1/jobs2/queued",
                        { controller: "jobs_v2", action: "list", format: "json", bucket: "queued", scope: "account" })
        expect(json.size).to eq 2
      end

      context "sharding" do
        specs_require_sharding

        before do
          @shard1.activate do
            Kernel.delay(run_at: 1.hour.ago).pp
            Kernel.delay(run_at: 1.hour.ago).pp

            @a1 = Account.create!
          end

          Shard.default.activate do
            Kernel.delay(run_at: 1.hour.ago).pp
            Kernel.delay(run_at: 1.hour.ago).pp
          end
        end

        it "scopes the query to the current shard" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued",
                          { controller: "jobs_v2", action: "list", format: "json", bucket: "queued", scope: "shard" },
                          {},
                          {},
                          { domain_root_account: @a1 })
          expect(json.size).to eq 2
        end

        it "scopes the query to the current cluster" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued",
                          { controller: "jobs_v2", action: "list", format: "json", bucket: "queued", scope: "cluster" },
                          {},
                          {},
                          { domain_root_account: @a1 })
          expect(json.size).to eq 4
        end
      end

      describe "grouped by tag" do
        it "returns queued jobs sorted by oldest" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued/by_tag",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag" },
                          {},
                          {},
                          expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["tag"]).to eq "Kernel.pp"
          expect(json[0]["count"]).to eq 2
          expect(json[0]["info"].seconds).to be_within(1.minute).of(1.day)
          expect(json[1]["tag"]).to eq "Kernel.p"
          expect(json[1]["count"]).to eq 1
          expect(json[1]["info"].seconds).to be_within(1.minute).of(2.hours)
        end

        it "sorts by tag" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued/by_tag?order=tag",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag", order: "tag" },
                          {},
                          {},
                          expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["tag"]).to eq "Kernel.p"
          expect(json[1]["tag"]).to eq "Kernel.pp"
        end

        it "sorts by count" do
          Kernel.delay(run_at: 2.days.ago).puts
          json = api_call(:get,
                          "/api/v1/jobs2/queued/by_tag?order=count",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag", order: "count" },
                          {},
                          {},
                          expected_status: 200)
          expect(json.size).to eq 3
          expect(json[0]["tag"]).to eq "Kernel.pp"
        end

        it "paginates" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued/by_tag?per_page=1",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag", per_page: "1" },
                          {},
                          {},
                          expected_status: 200)
          expect(json.pluck("tag")).to eq ["Kernel.pp"]
          links = Api.parse_pagination_links(response.headers["Link"])
          next_link = links.find { |link| link[:rel] == "next" }
          json = api_call(:get,
                          next_link[:uri].path,
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "tag", per_page: "1", page: "2" },
                          {},
                          {},
                          expected_status: 200)
          expect(json.pluck("tag")).to eq ["Kernel.p"]
        end
      end

      describe "by_strand" do
        before :once do
          Kernel.delay(strand: "foo", run_at: 1.hour.ago).puts
          Kernel.delay(strand: "bar", run_at: 2.hours.ago).puts
          Kernel.delay(strand: "bar", run_at: 30.minutes.ago).p
        end

        it "groups by strand" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued/by_strand?order=group",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "strand", order: "group" },
                          {},
                          {},
                          expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["strand"]).to eq "bar"
          expect(json[0]["count"]).to eq 2
          expect(json[0]["info"].seconds).to be_within(1.minute).of(2.hours)
          expect(json[1]["strand"]).to eq "foo"
          expect(json[1]["count"]).to eq 1
          expect(json[1]["info"].seconds).to be_within(1.minute).of(1.hour)
        end

        it "searches by strand" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued/by_strand/search?term=bar",
                          { controller: "jobs_v2", action: "search", format: "json", bucket: "queued", group: "strand", term: "bar" })
          expect(json).to eq({ "bar" => 2 })
        end

        describe "orphaned strands" do
          before :once do
            Delayed::Job.where(strand: "bar").update_all(next_in_strand: false, max_concurrent: 2)
          end

          it "flags orphaned strands" do
            json = api_call(:get,
                            "/api/v1/jobs2/queued/by_strand",
                            { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "strand", order: "info" })
            expect(json[0]["strand"]).to eq "bar"
            expect(json[0]["orphaned"]).to be true
            expect(json[1]["strand"]).to eq "foo"
            expect(json[1]["orphaned"]).to be false
          end

          it "unstucks orphaned strands" do
            json = api_call(:put,
                            "/api/v1/jobs2/unstuck",
                            { controller: "jobs_v2", action: "unstuck", format: "json", strand: "bar" })
            expect(json).to eq({ "status" => "OK", "count" => 2 })
            expect(Delayed::Job.where(strand: "bar").pluck(:next_in_strand)).to eq([true, true])
          end

          it "returns status 'blocked' if a strand blocker exists" do
            Delayed::Job.create!(payload_object: Delayed::PerformableMethod.new(Kernel, :sleep, args: [0]),
                                 source: "JobsMigrator::StrandBlocker",
                                 strand: "bar",
                                 next_in_strand: false)
            json = api_call(:put,
                            "/api/v1/jobs2/unstuck",
                            { controller: "jobs_v2", action: "unstuck", format: "json", strand: "bar" })
            expect(json).to eq({ "status" => "blocked" })
          end

          it "returns 0 if the strand isn't stuck" do
            json = api_call(:put,
                            "/api/v1/jobs2/unstuck",
                            { controller: "jobs_v2", action: "unstuck", format: "json", strand: "foo" })
            expect(json).to eq({ "status" => "OK", "count" => 0 })
          end

          it "returns status 404 if the strand doesn't exist" do
            api_call(:put,
                     "/api/v1/jobs2/unstuck",
                     { controller: "jobs_v2", action: "unstuck", format: "json", strand: "nope" },
                     {},
                     {},
                     { expected_status: 404 })
          end
        end
      end

      describe "by_singleton" do
        before :once do
          Kernel.delay(singleton: "foobar2000", run_at: 1.hour.ago).puts
          Kernel.delay(singleton: "zombo20001", run_at: 22.hours.ago).puts
        end

        it "groups by singleton" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued/by_singleton?order=info",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "singleton", order: "info" },
                          {},
                          {},
                          expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["singleton"]).to eq "zombo20001"
          expect(json[0]["count"]).to eq 1
          expect(json[0]["info"].seconds).to be_within(1.minute).of(22.hours)
          expect(json[1]["singleton"]).to eq "foobar2000"
          expect(json[1]["count"]).to eq 1
          expect(json[1]["info"].seconds).to be_within(1.minute).of(1.hour)
        end

        it "searches by singleton" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued/by_singleton/search?term=2000",
                          { controller: "jobs_v2", action: "search", format: "json", bucket: "queued", group: "singleton", term: "2000" })
          expect(json.to_a).to eq([["foobar2000", 1], ["zombo20001", 1]])
        end

        describe "orphaned singletons" do
          before :once do
            Delayed::Job.where(singleton: "zombo20001").update_all(next_in_strand: false)
          end

          it "flags orphaned singletons" do
            json = api_call(:get,
                            "/api/v1/jobs2/queued/by_singleton",
                            { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "queued", group: "singleton", order: "info" })
            expect(json[0]["singleton"]).to eq "zombo20001"
            expect(json[0]["orphaned"]).to be true
            expect(json[1]["singleton"]).to eq "foobar2000"
            expect(json[1]["orphaned"]).to be false
          end

          it "unstucks orphaned singletons" do
            json = api_call(:put,
                            "/api/v1/jobs2/unstuck",
                            { controller: "jobs_v2", action: "unstuck", format: "json", singleton: "zombo20001" })
            expect(json).to eq({ "status" => "OK", "count" => 1 })
            expect(Delayed::Job.find_by(singleton: "zombo20001")).to be_next_in_strand
          end

          it "returns status 'blocked' if a blocker exists" do
            Delayed::Job.create!(payload_object: Delayed::PerformableMethod.new(Kernel, :sleep, args: [0]),
                                 source: "JobsMigrator::StrandBlocker",
                                 singleton: "zombo20001",
                                 locked_by: Delayed::Backend::Base::ON_HOLD_BLOCKER,
                                 next_in_strand: false)
            json = api_call(:put,
                            "/api/v1/jobs2/unstuck",
                            { controller: "jobs_v2", action: "unstuck", format: "json", singleton: "zombo20001" })
            expect(json).to eq({ "status" => "blocked" })
          end

          it "returns 0 when unstucking a non-stuck singleton" do
            json = api_call(:put,
                            "/api/v1/jobs2/unstuck",
                            { controller: "jobs_v2", action: "unstuck", format: "json", singleton: "foobar2000" })
            expect(json).to eq({ "status" => "OK", "count" => 0 })
          end

          it "returns status 404 if no job with the given strand exists" do
            api_call(:put,
                     "/api/v1/jobs2/unstuck",
                     { controller: "jobs_v2", action: "unstuck", format: "json", singleton: "nope" },
                     {},
                     {},
                     { expected_status: 404 })
          end
        end
      end

      describe "ungrouped" do
        it "lists queued jobs" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued?order=tag",
                          { controller: "jobs_v2", action: "list", format: "json", bucket: "queued", order: "tag" })
          expect(json.size).to eq 3
          expect(json[0]["tag"]).to eq "Kernel.p"
          expect(json[0]["info"].seconds).to be_within(1.minute).of(2.hours)
          expect(json[1]["tag"]).to eq "Kernel.pp"
          expect(json[2]["tag"]).to eq "Kernel.pp"
        end

        it "filters by tag" do
          json = api_call(:get,
                          "/api/v1/jobs2/queued?tag=Kernel.pp",
                          { controller: "jobs_v2", action: "list", format: "json", bucket: "queued", tag: "Kernel.pp" })
          expect(json.size).to eq 2
          expect(json[0]["info"].seconds).to be_within(1.minute).of(1.day)
        end
      end

      it "searches queued tags" do
        json = api_call(:get,
                        "/api/v1/jobs2/queued/by_tag/search?term=p",
                        { controller: "jobs_v2", action: "search", format: "json", bucket: "queued", group: "tag", term: "p" })
        expect(json).to eq({ "Kernel.pp" => 2, "Kernel.p" => 1 })
      end

      it "finds a held job by id" do
        json = api_call(:get,
                        "/api/v1/jobs2/#{@held_job_id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: @held_job_id.to_s })
        item = json.find { |row| row["id"] == @held_job_id }
        expect(item["tag"]).to eq "Kernel.pp"
        expect(item["bucket"]).to eq "queued"
      end

      it "finds a queued job by id" do
        json = api_call(:get,
                        "/api/v1/jobs2/#{@queued_job_id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: @queued_job_id.to_s })
        item = json.find { |row| row["id"] == @queued_job_id }
        expect(item["tag"]).to eq "Kernel.p"
        expect(item["bucket"]).to eq "queued"
      end
    end

    describe "running jobs" do
      before :once do
        # fake some running jobs
        Kernel.delay.pp
        Delayed::Job.last.update locked_at: 1.hour.ago, locked_by: "me"
        Kernel.delay.pp
        Delayed::Job.last.update locked_at: 2.hours.ago, locked_by: "me"

        Kernel.delay.p
        Delayed::Job.last.update locked_at: 30.minutes.ago, locked_by: "foo"

        # and a fake held job, to ensure it doesn't appear here
        Kernel.delay.puts
        Delayed::Job.last.update locked_by: Delayed::Backend::Base::ON_HOLD_LOCKED_BY
      end

      it "groups by tag" do
        json = api_call(:get,
                        "/api/v1/jobs2/running/by_tag",
                        { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "running", group: "tag" },
                        {},
                        {},
                        expected_status: 200)
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
          json = api_call(:get,
                          "/api/v1/jobs2/running/by_strand?order=strand",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "running", group: "strand", order: "strand" },
                          {},
                          {},
                          expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["strand"]).to eq "barfood"
          expect(json[0]["count"]).to eq 1
          expect(json[0]["info"].seconds).to be_within(1.minute).of(30.minutes)
          expect(json[1]["strand"]).to eq "foo"
          expect(json[1]["count"]).to eq 2
          expect(json[1]["info"].seconds).to be_within(1.minute).of(2.hours)
        end

        it "searches by strand" do
          json = api_call(:get,
                          "/api/v1/jobs2/running/by_strand/search?term=foo",
                          { controller: "jobs_v2", action: "search", format: "json", bucket: "running", group: "strand", term: "foo" })
          expect(json).to eq({ "foo" => 2, "barfood" => 1 })
        end
      end

      it "lists running jobs" do
        json = api_call(:get,
                        "/api/v1/jobs2/running",
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

        Kernel.delay(strand: "foo", singleton: "singletonB").pp
        Delayed::Job.last.update locked_at: 1.hour.ago, locked_by: "me"
        Kernel.delay(strand: "foo", singleton: "singletonA").pp
        Delayed::Job.last.update locked_at: 1.hour.ago, locked_by: "me"
        Kernel.delay(strand: "foo", singleton: "singletonC").pp
        Delayed::Job.last.update locked_at: 1.hour.ago, locked_by: "me"

        json = api_call(:get,
                        "/api/v1/jobs2/running",
                        { controller: "jobs_v2", action: "list", format: "json", bucket: "running", order: "strand_singleton" })
        expect(json.size).to eq 6
        expect(json.pluck("strand")).to eq ["barfood", "foo", "foo", "foo", nil, nil]
        expect(json.pluck("singleton")).to eq [nil, "singletonA", "singletonB", "singletonC", nil, nil]
      end

      it "searches running tags" do
        json = api_call(:get,
                        "/api/v1/jobs2/running/by_tag/search?term=p",
                        { controller: "jobs_v2", action: "search", format: "json", bucket: "running", group: "tag", term: "p" })
        expect(json).to eq({ "Kernel.pp" => 2, "Kernel.p" => 1 })
      end

      it "finds a job by id" do
        job = Delayed::Job.where(locked_by: "foo").take
        json = api_call(:get,
                        "/api/v1/jobs2/#{job.id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: job.to_param })
        item = json.find { |row| row["id"] == job.id }
        expect(item["tag"]).to eq "Kernel.p"
        expect(item["bucket"]).to eq "running"
      end
    end

    describe "future" do
      before :once do
        Kernel.delay(run_at: 1.hour.from_now).pp
        Kernel.delay(run_at: 1.day.from_now).p
      end

      it "groups by tag" do
        json = api_call(:get,
                        "/api/v1/jobs2/future/by_tag",
                        { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "future", group: "tag" },
                        {},
                        {},
                        expected_status: 200)
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
          Kernel.delay(run_at: 1.hour.from_now, strand: "foo").puts
          Kernel.delay(run_at: 2.hours.from_now, strand: "foo").puts
          Kernel.delay(run_at: 1.day.from_now, strand: "bar").puts
        end

        it "groups by strand" do
          json = api_call(:get,
                          "/api/v1/jobs2/future/by_strand?order=strand",
                          { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "future", group: "strand", order: "strand" },
                          {},
                          {},
                          expected_status: 200)
          expect(json.size).to eq 2
          expect(json[0]["strand"]).to eq "bar"
          expect(json[0]["count"]).to eq 1
          expect(Time.zone.parse(json[0]["info"])).to be_within(1.minute).of(1.day.from_now)
          expect(json[1]["strand"]).to eq "foo"
          expect(json[1]["count"]).to eq 2
          expect(Time.zone.parse(json[1]["info"])).to be_within(1.minute).of(1.hour.from_now)
        end

        it "searches by strand" do
          json = api_call(:get,
                          "/api/v1/jobs2/future/by_strand/search?term=foo",
                          { controller: "jobs_v2", action: "search", format: "json", bucket: "future", group: "strand", term: "foo" })
          expect(json).to eq({ "foo" => 2 })
        end
      end

      it "filters by start_date" do
        start_date = 6.hours.from_now.iso8601
        json = api_call(:get,
                        "/api/v1/jobs2/future/by_tag?start_date=#{start_date}",
                        { controller: "jobs_v2", action: "grouped_info", format: "json", bucket: "future", group: "tag", start_date: },
                        {},
                        {},
                        expected_status: 200)
        expect(json.size).to eq 1
        expect(json[0]["tag"]).to eq "Kernel.p"
        expect(json[0]["count"]).to eq 1
      end

      it "lists future jobs" do
        json = api_call(:get,
                        "/api/v1/jobs2/future",
                        { controller: "jobs_v2", action: "list", format: "json", bucket: "future" })
        expect(json.size).to eq 2
        expect(json[0]["tag"]).to eq "Kernel.pp"
        expect(Time.zone.parse(json[0]["info"])).to be_within(1.minute).of(1.hour.from_now)
        expect(json[1]["tag"]).to eq "Kernel.p"
        expect(Time.zone.parse(json[1]["info"])).to be_within(1.minute).of(1.day.from_now)
      end

      it "searches future tags" do
        json = api_call(:get,
                        "/api/v1/jobs2/future/by_tag/search?term=p",
                        { controller: "jobs_v2", action: "search", format: "json", bucket: "future", group: "tag", term: "p" })
        expect(json).to eq({ "Kernel.pp" => 1, "Kernel.p" => 1 })
      end

      it "finds a job by id" do
        job = Delayed::Job.last
        json = api_call(:get,
                        "/api/v1/jobs2/#{job.id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: job.to_param })
        item = json.find { |row| row["id"] == job.id }
        expect(item["tag"]).to eq "Kernel.p"
        expect(item["bucket"]).to eq "future"
      end
    end

    describe "failed" do
      before :once do
        Timecop.travel(1.day.ago) do
          Kernel.delay.raise "uh oh"
          run_jobs
        end

        Timecop.travel(1.hour.ago) do
          Kernel.delay.raise "oops"
          run_jobs
        end
      end

      it "groups by tag" do
        json = api_call(:get,
                        "/api/v1/jobs2/failed/by_tag",
                        { controller: "jobs_v2", action: "grouped_info", bucket: "failed", format: "json", group: "tag" },
                        {},
                        {},
                        expected_status: 200)
        expect(json.size).to eq 1
        expect(json[0]["tag"]).to eq "Kernel.raise"
        expect(json[0]["count"]).to eq 2
        expect(Time.zone.parse(json[0]["info"])).to be_within(1.minute).of(1.hour.ago)
      end

      it "lists failed jobs" do
        json = api_call(:get,
                        "/api/v1/jobs2/failed",
                        { controller: "jobs_v2", action: "list", format: "json", bucket: "failed" })
        expect(json.size).to eq 2
        expect(json[0]["tag"]).to eq "Kernel.raise"
        expect(Time.zone.parse(json[0]["info"])).to be_within(1.minute).of(1.hour.ago)
        expect(json[1]["tag"]).to eq "Kernel.raise"
        expect(Time.zone.parse(json[1]["info"])).to be_within(1.minute).of(1.day.ago)
      end

      it "filters by end_date" do
        end_date = 6.hours.ago.iso8601
        json = api_call(:get,
                        "/api/v1/jobs2/failed?end_date=#{end_date}",
                        { controller: "jobs_v2", action: "list", format: "json", bucket: "failed", end_date: },
                        {},
                        {},
                        expected_status: 200)
        expect(json.size).to eq 1
        expect(json[0]["tag"]).to eq "Kernel.raise"
        expect(Time.zone.parse(json[0]["info"])).to be_within(1.minute).of(1.day.ago)
      end

      it "searches failed tags" do
        json = api_call(:get,
                        "/api/v1/jobs2/failed/by_tag/search?term=ais",
                        { controller: "jobs_v2", action: "search", format: "json", bucket: "failed", group: "tag", term: "ais" })
        expect(json).to eq({ "Kernel.raise" => 2 })
      end

      it "finds a failed job by id" do
        job = Delayed::Job::Failed.last
        json = api_call(:get,
                        "/api/v1/jobs2/#{job.id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: job.to_param })
        item = json.find { |row| row["id"] == job.id }
        expect(item["tag"]).to eq "Kernel.raise"
        expect(item["bucket"]).to eq "failed"
      end

      it "finds a failed job by original_job_id" do
        job = Delayed::Job::Failed.last
        json = api_call(:get,
                        "/api/v1/jobs2/#{job.original_job_id}",
                        { controller: "jobs_v2", action: "lookup", format: "json", id: job.original_job_id.to_s })
        item = json.find { |row| row["original_job_id"] == job.original_job_id }
        expect(item["tag"]).to eq "Kernel.raise"
        expect(item["bucket"]).to eq "failed"
      end
    end

    describe "manage" do
      before :once do
        2.times { Kernel.delay(n_strand: "foobar").p }
      end

      it "updates max_concurrent and priority" do
        expect(Delayed::Job.where(strand: "foobar", next_in_strand: true).count).to eq 1
        json = api_call(:put,
                        "/api/v1/jobs2/manage",
                        { controller: "jobs_v2", action: "manage", format: "json" },
                        { strand: "foobar", max_concurrent: 11, priority: 23 })
        expect(json["count"]).to eq 2
        expect(Delayed::Job.where(strand: "foobar").pluck(:max_concurrent)).to eq([11, 11])
        expect(Delayed::Job.where(strand: "foobar").pluck(:priority)).to eq([23, 23])
        expect(Delayed::Job.where(strand: "foobar", next_in_strand: true).count).to eq 2
      end

      it "requires manage_jobs permission" do
        account_admin_user_with_role_changes(account: Account.site_admin,
                                             role_changes: { view_jobs: true, manage_jobs: false })
        api_call(:put,
                 "/api/v1/jobs2/manage",
                 { controller: "jobs_v2", action: "manage", format: "json" },
                 { strand: "foobar", max_concurrent: 11, priority: 23 },
                 {},
                 { expected_status: 401 })
      end
    end

    describe "requeue" do
      before :once do
        Kernel.delay.raise "uh oh"
        run_jobs
      end

      it "requeues a failed job" do
        fj = Delayed::Job::Failed.last
        json = api_call(:post,
                        "/api/v1/jobs2/#{fj.id}/requeue",
                        { controller: "jobs_v2", action: "requeue", format: "json", id: fj.to_param })
        job = Delayed::Job.find(json["id"])
        expect(job.handler).to eq fj.handler
        expect(fj.reload.requeued_job_id).to eq job.id
      end
    end

    describe "unstuck" do
      specs_require_sharding

      it "queues a job to run the unstucker" do
        json = api_call(:put,
                        "/api/v1/jobs2/unstuck",
                        { controller: "jobs_v2", action: "unstuck", format: "json" })
        expect(json["status"]).to eq "pending"
        progress_id = json["progress"]["id"]
        expect(progress_id).to be_present
        progress = Progress.find(progress_id)
        expect(progress).to be_queued
        expect(SwitchmanInstJobs::JobsMigrator).to receive(:unblock_strands).and_return(nil)
        run_jobs
        expect(progress.reload).to be_completed
      end
    end

    context "throttling" do
      before :once do
        3.times { Kernel.delay(shard_id: 101).print }
        2.times { Kernel.delay(shard_id: 101).printf }
        Kernel.delay(shard_id: 102).printf
      end

      describe "throttle_check" do
        it "lists counts" do
          json = api_call(:get,
                          "/api/v1/jobs2/throttle/check?term=Kernel.print",
                          { controller: "jobs_v2",
                            action: "throttle_check",
                            format: "json",
                            term: "Kernel.print" })
          expect(json).to eq({ "matched_jobs" => 6, "matched_tags" => 2 })
        end

        it "filters by shard if given" do
          json = api_call(:get,
                          "/api/v1/jobs2/throttle/check?term=Kernel.print&shard_id=101",
                          { controller: "jobs_v2",
                            action: "throttle_check",
                            format: "json",
                            term: "Kernel.print",
                            shard_id: 101 })
          expect(json).to eq({ "matched_jobs" => 5, "matched_tags" => 2 })
        end
      end

      describe "throttle" do
        it "throttles selected jobs" do
          json = api_call(:put,
                          "/api/v1/jobs2/throttle?term=Kernel.print&shard_id=101&max_concurrent=2",
                          { controller: "jobs_v2",
                            action: "throttle",
                            format: "json",
                            term: "Kernel.print",
                            shard_id: 101,
                            max_concurrent: 2 })
          expect(json["job_count"]).to eq 5
          expect(Delayed::Job.where(strand: json["new_strand"], next_in_strand: true).count).to eq 2
          expect(Delayed::Job.where(shard_id: 102).where.not(strand: nil).count).to eq 0
        end
      end
    end

    context "global admin" do
      specs_require_sharding

      before :once do
        Shard.default.update delayed_jobs_shard_id: Shard.default.id

        @shard1.update delayed_jobs_shard_id: @shard2.id
        @shard1.activate do
          2.times do
            Kernel.delay(next_in_strand: false, strand: "sadness").p
          end
          Kernel.delay(locked_by: "fake", locked_at: 1.hour.ago).p
          @shard1.update jobs_held: true
        end

        @shard2.update delayed_jobs_shard_id: @shard2.id
        @shard2.activate do
          a = Account.create! name: "jobs2"
          a.account_domains.create! host: "jobs2.127.0.0.1.xip.io"

          Kernel.delay(next_in_strand: false, singleton: "misery").p
          Kernel.delay(run_at: 1.day.ago).p
          Kernel.delay(run_at: 1.day.from_now).p
          @shard2.update block_stranded: true
        end
      end

      before do
        if Switchman::Shard.instance_variable_defined?(:@jobs_scope_empty)
          Switchman::Shard.remove_instance_variable(:@jobs_scope_empty)
        end
        allow(HostUrl).to receive(:default_host).and_return("www.example.com")
      end

      it "enumerates job clusters" do
        json = api_call(:get,
                        "/api/v1/jobs2/clusters?per_page=2",
                        { controller: "jobs_v2", action: "clusters", format: "json", per_page: 2 })
        expect(json.pluck("id")).to match_array([Shard.default.id, @shard2.id])
      end

      it "retrieves stats from a job cluster" do
        json = api_call(:get,
                        "/api/v1/jobs2/clusters?job_shards[]=#{@shard2.id}",
                        { controller: "jobs_v2", action: "clusters", format: "json", job_shards: [@shard2.to_param] })
        expect(json).to eq [{
          "id" => @shard2.id,
          "database_server_id" => "1",
          "block_stranded_shard_ids" => [@shard2.id],
          "jobs_held_shard_ids" => [@shard1.id],
          "domain" => "jobs2.127.0.0.1.xip.io",
          "counts" => {
            "queued" => 1,
            "running" => 1,
            "future" => 1,
            "blocked" => 3
          }
        }]
      end

      it "lists stuck strands in a cluster" do
        json = api_call(:get,
                        "/api/v1/jobs2/stuck/strands?job_shard=#{@shard2.id}",
                        { controller: "jobs_v2", action: "stuck_strands", format: "json", job_shard: @shard2.to_param })
        expect(json).to eq([{ "name" => "sadness", "count" => 2 }])
      end

      it "lists stuck singletons in a cluster" do
        json = api_call(:get,
                        "/api/v1/jobs2/stuck/singletons?job_shard=#{@shard2.id}",
                        { controller: "jobs_v2", action: "stuck_singletons", format: "json", job_shard: @shard2.to_param })
        expect(json).to eq([{ "name" => "misery", "count" => 1 }])
      end
    end
  end
end
