# frozen_string_literal: true

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

describe SentryExtensions::Tracing::ActiveRecordSubscriber do
  def initialize_sentry
    Sentry.init do |config|
      config.release = "beta"
      config.dsn = "http://12345:67890@sentry.localdomain:3000/sentry/42"
      config.transport.transport_class = Sentry::DummyTransport
      # for sending events synchronously
      config.background_worker_threads = 0
      config.capture_exception_frame_locals = true
      yield(config) if block_given?
    end

    # Duplicate the setup the railtie would have done
    # https://github.com/getsentry/sentry-ruby/blob/ce10521b937697ead5ce00e7f6dbd96bf523755e/sentry-rails/lib/sentry/rails/railtie.rb#L110-L117
    if Sentry.configuration.tracing_enabled?
      subscribers = Sentry.configuration.rails.tracing_subscribers
      Sentry::Rails::Tracing.register_subscribers(subscribers)
      Sentry::Rails::Tracing.subscribe_tracing_events
      Sentry::Rails::Tracing.patch_active_support_notifications
    end
  end

  def perform_transaction(sampled: true)
    transaction = Sentry::Transaction.new(sampled:, hub: Sentry.get_current_hub)
    Sentry.get_current_scope.set_span(transaction)

    yield

    transaction.finish
    transaction
  end

  let(:transport) do
    Sentry.get_current_client.transport
  end

  context "when transaction is recorded" do
    before do
      initialize_sentry do |config|
        config.traces_sample_rate = 1.0
        config.rails.tracing_subscribers = [described_class]
      end
    end

    it "records database query events" do
      perform_transaction { User.all.to_a }

      expect(transport.events.count).to eq(1)

      transaction = transport.events.first.to_hash
      expect(transaction[:type]).to eq("transaction")
      expect(transaction[:spans].count).to eq(1)

      span = transaction[:spans][0]
      expect(span[:op]).to eq("db.sql.active_record")
      expect(span[:description]).to eq(User.all.to_sql)
      expect(span[:trace_id]).to eq(transaction.dig(:contexts, :trace, :trace_id))
    end

    it "normalizes raw database queries" do
      perform_transaction { User.where(name: "Taylor Swift").to_a }

      expect(transport.events.count).to eq(1)

      span = transport.events.first.to_hash[:spans][0]
      expect(span[:description]).to eq(User.where(name: "Taylor Swift").to_sql.gsub("'Taylor Swift'", "$1"))
    end

    it "provides fallback description when normalization fails" do
      perform_transaction do
        payload = {
          name: "SQL",
          sql: "bad query",
          connection_id: "1"
        }
        payload[Sentry::Rails::Tracing::START_TIMESTAMP_NAME] = Time.now

        ActiveSupport::Notifications.instrument("sql.active_record", payload)
      end

      expect(transport.events.count).to eq(1)

      span = transport.events.first.to_hash[:spans][0]
      expect(span[:description]).to eq("<sql hidden; error during normalization>")
    end

    context "when sharded" do
      it "normalizes shard-prefixed database queries" do
        query = '1::SELECT "users".* FROM "public"."users" WHERE "users"."name" = $1'

        perform_transaction do
          payload = {
            name: "SQL",
            sql: query,
            connection_id: "1"
          }
          payload[Sentry::Rails::Tracing::START_TIMESTAMP_NAME] = Time.now

          ActiveSupport::Notifications.instrument("sql.active_record", payload)
        end

        expect(transport.events.count).to eq(1)

        span = transport.events.first.to_hash[:spans][0]
        expect(span[:description]).to eq(query)
      end
    end
  end

  context "when transaction is not recorded" do
    before do
      initialize_sentry
    end

    it "doesn't record spans" do
      transaction = perform_transaction(sampled: false) { User.all.to_a }

      expect(transport.events.count).to eq(0)
      expect(transaction.span_recorder.spans).to eq([transaction])
    end
  end
end
