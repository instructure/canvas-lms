#
# Copyright (C) 2020 - present Instructure, Inc.
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

require File.expand_path('../sharding_spec_helper', File.dirname( __FILE__ ))

describe 'PeriodicJobs' do
  describe ".with_each_shard_by_database_in_region" do
    class FakeJob
      def self.some_method_to_run(arg1="other arg")
        # no-op
      end
    end

    it "inserts jobs without jitter" do
      expect(Delayed::Job.count).to eq(0)
      PeriodicJobs.with_each_shard_by_database_in_region(FakeJob, :some_method_to_run, "SOME ARGUMENT")
      expect(Delayed::Job.count > 0).to eq(true)
      expect(Delayed::Job.last.run_at <= Time.zone.now).to eq(true)
    end

    it "inserts jobs WITH jitter" do
      expect(Delayed::Job.count).to eq(0)
      PeriodicJobs.with_each_shard_by_database_in_region(FakeJob, :some_method_to_run,  "SOME ARGUMENT", jitter: 2.hours)
      expect(Delayed::Job.count > 0).to eq(true)
      expect(Delayed::Job.last.run_at > Time.zone.now).to eq(true)
    end

    it "inserts jobs WITH jitter and no args" do
      expect(Delayed::Job.count).to eq(0)
      PeriodicJobs.with_each_shard_by_database_in_region(FakeJob, :some_method_to_run, jitter: 2.hours)
      expect(Delayed::Job.count > 0).to eq(true)
      expect(Delayed::Job.last.run_at > Time.zone.now).to eq(true)
    end
  end

  describe ".compute_run_at" do
    it "Defaults to the current time" do
      Timecop.freeze do
        expect(PeriodicJobs.compute_run_at(jitter: nil, local_offset: false)).to eq(Time.zone.now)
      end
    end

    it "Assumes database servers without a timezone are in the server timezone" do
      Timecop.freeze do
        expect(PeriodicJobs.compute_run_at(jitter: nil, local_offset: true)).to eq(Time.zone.now)
      end
    end

    it "Schedules jobs in the future when local nighttime is in the future" do
      begin
        old_tz = Shard.current.database_server.config[:timezone]
        # Picked because it doesn't have DST
        Shard.current.database_server.config[:timezone] = 'America/Phoenix'
        Timecop.freeze do
          expect(PeriodicJobs.compute_run_at(jitter: nil, local_offset: true)).to eq(Time.zone.now + 7.hours)
        end
      ensure
        Shard.current.database_server.config[:timezone] = old_tz
      end
    end

    it "Schedules jobs in the future when local nighttime is in the past" do
      begin
        old_tz = Shard.current.database_server.config[:timezone]
        # Picked because it doesn't have DST
        Shard.current.database_server.config[:timezone] = 'Africa/Nairobi'
        Timecop.freeze do
          expect(PeriodicJobs.compute_run_at(jitter: nil, local_offset: true)).to eq(Time.zone.now + 21.hours)
        end
      ensure
        Shard.current.database_server.config[:timezone] = old_tz
      end
    end
  end
end