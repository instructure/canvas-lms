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
#

describe Analyzers::ConversationComplexityAnalyzer do
  let(:current_user) { instance_double(User, uuid: "user-123") }

  let(:query_context) { { current_user: } }

  let(:subject_double) do
    instance_double(GraphQL::Query,
                    selected_operation_name: operation_name,
                    context: query_context)
  end

  let(:analyzer) { described_class.new(subject_double) }

  before do
    analyzer.instance_variable_set(:@query, instance_double(GraphQL::Query, operation_name: "TestOp"))
    allow(Account.site_admin).to receive(:feature_enabled?).with(:create_conversation_graphql_rate_limit).and_return(true)
  end

  describe "#initialize" do
    let(:operation_name) { "CreateConversation" }

    it "initializes recipient score and user UUID" do
      expect(analyzer.instance_variable_get(:@recipient_score)).to eq(0)
      expect(analyzer.instance_variable_get(:@user_uuid)).to eq("user-123")
    end
  end

  describe "#on_enter_field" do
    let(:operation_name) { "CreateConversation" }
    let(:node) { instance_double(GraphQL::Language::Nodes::OperationDefinition, name: "createConversation") }
    let(:visitor) { instance_double(GraphQL::Analysis::AST::Visitor) }
    let(:field_defn) { instance_double(GraphQL::Schema::Field) }

    before do
      allow(visitor).to receive(:field_definition).and_return(field_defn)
    end

    it "adds score based on recipient types" do
      recipients = %w[course_123 group_456 custom]

      allow(analyzer).to receive(:argument_value).with(node, visitor, :recipients).and_return(recipients)

      allow(GraphQLTuning).to receive(:create_conversation_rate_limit).with(:course_score).and_return(50)
      allow(GraphQLTuning).to receive(:create_conversation_rate_limit).with(:group_score).and_return(30)

      analyzer.on_enter_field(node, nil, visitor)

      expect(analyzer.instance_variable_get(:@recipient_score)).to eq(50 + 30 + 1)
    end

    it "logs to Sentry if recipients is not an array" do
      allow(analyzer).to receive(:argument_value).and_return("bad input")

      expect(Sentry).to receive(:with_scope).and_yield(instance_double(Sentry::Scope, set_context: nil))
      expect(Sentry).to receive(:capture_message).with("Conversation Complexity Analyzer: unable to process recipients", level: :warning)

      analyzer.on_enter_field(node, nil, visitor)
    end

    context "when feature is disabled" do
      before do
        allow(Account.site_admin).to receive(:feature_enabled?).with(:create_conversation_graphql_rate_limit).and_return(false)
      end

      it "does not modify recipient score" do
        expect(analyzer.instance_variable_get(:@recipient_score)).to eq(0)
        analyzer.on_enter_field(node, nil, visitor)
        expect(analyzer.instance_variable_get(:@recipient_score)).to eq(0)
      end
    end
  end

  describe "#result" do
    let(:operation_name) { "CreateConversation" }
    let(:redis) { instance_double(Redis) }
    let(:key) { "conversation_message_limit:user-123" }

    before do
      analyzer.instance_variable_set(:@recipient_score, 200)
      allow(Canvas).to receive_messages(redis_enabled?: true, redis:)
    end

    it "increments Redis key and sets TTL if missing" do
      allow(redis).to receive(:incrby).with(key, 200).and_return(1000)
      allow(redis).to receive(:ttl).with(key).and_return(-1)
      expect(redis).to receive(:expire).with(key, 600)

      expect(Rails.logger).to receive(:info).with("TTL was missing or expired, reset to 10 minutes")
      expect(Rails.logger).to receive(:info).with("Recipient score: 1000 for key: #{key}")

      expect(analyzer.result).to be_nil
    end

    it "returns a GraphQL::AnalysisError if score exceeds limit" do
      allow(redis).to receive(:incrby).with(key, 200).and_return(11_000)
      allow(redis).to receive(:ttl).with(key).and_return(500)

      expect(Rails.logger).to receive(:info)
      expect(Sentry).to receive(:with_scope).and_yield(instance_double(Sentry::Scope, set_context: nil))
      expect(Sentry).to receive(:capture_message).with(
        "GraphQL: CreateConversation rate limit exceeded",
        level: :warning
      )

      result = analyzer.result
      expect(result).to be_a(GraphQL::AnalysisError)
      expect(result.message).to eq("Rate limit exceeded.")
    end

    context "when feature is disabled" do
      before do
        allow(Account.site_admin).to receive(:feature_enabled?).with(:create_conversation_graphql_rate_limit).and_return(false)
      end

      it "does not increment Redis key or return an error" do
        expect(redis).not_to receive(:incrby)
        expect(analyzer.result).to be_nil
      end
    end
  end
end
