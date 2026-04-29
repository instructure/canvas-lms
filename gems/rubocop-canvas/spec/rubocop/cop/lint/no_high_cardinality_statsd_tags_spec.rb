# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe RuboCop::Cop::Lint::NoHighCardinalityStatsdTags do
  subject(:cop) { described_class.new }

  context "distributed_increment" do
    it "flags user_id tag" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { user_id: current_user.global_id })
      RUBY
      expect(offenses.size).to eq(1)
      expect(offenses.first.message).to match(/High-cardinality tag detected/)
      expect(offenses.first.severity.name).to eq(:error)
    end

    it "flags domain tag" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { domain: "example.com" })
      RUBY
      expect(offenses.size).to eq(1)
      expect(offenses.first.severity.name).to eq(:error)
    end

    it "allows cluster tag" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { cluster: "test" })
      RUBY
      expect(offenses.size).to eq(0)
    end

    it "allows cluster tag with dynamic value from shard" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { cluster: Shard.current.database_server&.id || "unknown" })
      RUBY
      expect(offenses.size).to eq(0)
    end
  end

  context "increment" do
    it "flags account_id tag" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.increment("metric", tags: { account_id: account.id })
      RUBY
      expect(offenses.size).to eq(1)
      expect(offenses.first.severity.name).to eq(:error)
    end

    it "allows status tag" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.increment("metric", tags: { status: "active" })
      RUBY
      expect(offenses.size).to eq(0)
    end
  end

  context "gauge" do
    it "flags email tag" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.gauge("metric", 1, tags: { email: "user@example.com" })
      RUBY
      expect(offenses.size).to eq(1)
      expect(offenses.first.severity.name).to eq(:error)
    end

    it "allows type tag" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.gauge("metric", 1, tags: { type: user.class.name })
      RUBY
      expect(offenses.size).to eq(0)
    end
  end

  context "timing" do
    it "flags course_id tag" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.timing("metric", 100, tags: { course_id: course.id })
      RUBY
      expect(offenses.size).to eq(1)
      expect(offenses.first.severity.name).to eq(:error)
    end

    it "allows environment tag" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.timing("metric", 100, tags: { environment: "production" })
      RUBY
      expect(offenses.size).to eq(0)
    end
  end

  context "count" do
    it "flags global_id tag" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.count("metric", 1, tags: { global_id: user.global_id })
      RUBY
      expect(offenses.size).to eq(1)
      expect(offenses.first.severity.name).to eq(:error)
    end
  end

  context "pattern matching" do
    it "flags any tag ending with _id" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { assignment_id: 123 })
      RUBY
      expect(offenses.size).to eq(1)
    end
  end

  context "safe ID patterns" do
    it "allows shard_id key with literal value" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { shard_id: 123 })
      RUBY
      expect(offenses.size).to eq(0)
    end

    it "allows shard_id with shard.id" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { shard_id: shard.id })
      RUBY
      expect(offenses.size).to eq(0)
    end

    it "allows shard.id as value with non-shard_id key" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { foo: shard.id })
      RUBY
      expect(offenses.size).to eq(0)
    end
  end

  context "specific high-cardinality keys" do
    it "flags host" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { host: "example.com" })
      RUBY
      expect(offenses.size).to eq(1)
    end

    it "flags hostname" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { hostname: "server1.example.com" })
      RUBY
      expect(offenses.size).to eq(1)
    end

    it "flags ip" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { ip: "192.168.1.1" })
      RUBY
      expect(offenses.size).to eq(1)
    end

    it "flags ip_address" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { ip_address: "10.0.0.1" })
      RUBY
      expect(offenses.size).to eq(1)
    end

    it "flags timestamp" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { timestamp: Time.now.to_i })
      RUBY
      expect(offenses.size).to eq(1)
    end

    it "flags time" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { time: DateTime.now })
      RUBY
      expect(offenses.size).to eq(1)
    end
  end

  context "method call detection" do
    it "flags .global_id calls" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { foo: user.global_id })
      RUBY
      expect(offenses.size).to eq(1)
    end

    it "flags .id calls on objects" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { foo: account.id })
      RUBY
      expect(offenses.size).to eq(1)
    end
  end

  context "safe patterns" do
    it "allows string literals" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { cluster: "test", env: "production" })
      RUBY
      expect(offenses.size).to eq(0)
    end

    it "allows class.name" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { type: asset.class.name })
      RUBY
      expect(offenses.size).to eq(0)
    end

    it "allows multiple safe tags" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: {
          cluster: "test",
          environment: "prod",
          type: "migration",
          status: "success"
        })
      RUBY
      expect(offenses.size).to eq(0)
    end

    it "allows ternary with safe values" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", tags: { cluster: Shard.current.database_server&.id || "unknown" })
      RUBY
      expect(offenses.size).to eq(0)
    end
  end

  context "no tags" do
    it "allows calls without tags" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric")
      RUBY
      expect(offenses.size).to eq(0)
    end

    it "allows calls with non-tags hash" do
      offenses = inspect_source(<<~RUBY)
        InstStatsd::Statsd.distributed_increment("metric", { sample_rate: 0.5 })
      RUBY
      expect(offenses.size).to eq(0)
    end
  end
end
