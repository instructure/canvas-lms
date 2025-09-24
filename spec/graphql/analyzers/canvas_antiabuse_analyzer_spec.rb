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

describe Analyzers::CanvasAntiabuseAnalyzer do
  let(:subject_double) { instance_double(GraphQL::Query) }
  let(:analyzer) { described_class.new(subject_double) }

  before do
    analyzer.instance_variable_set(:@query, instance_double(GraphQL::Query, operation_name: "TestOp"))
  end

  describe "#on_leave_field" do
    let(:node) do
      instance_double(
        GraphQL::Language::Nodes::Field,
        alias: node_alias,
        directives:
      )
    end

    context "when node has an alias and directives" do
      let(:node_alias) { "myAlias" }
      let(:directives) do
        [instance_double(GraphQL::Language::Nodes::Directive),
         instance_double(GraphQL::Language::Nodes::Directive)]
      end

      it "increments alias and directive counts" do
        analyzer.on_leave_field(node, nil, nil)

        expect(analyzer.instance_variable_get(:@alias_count)).to eq(1)
        expect(analyzer.instance_variable_get(:@directive_count)).to eq(2)
      end
    end

    context "when node has no alias or directives" do
      let(:node_alias) { nil }
      let(:directives) { [] }

      it "does not increment counts" do
        analyzer.on_leave_field(node, nil, nil)

        expect(analyzer.instance_variable_get(:@alias_count)).to eq(0)
        expect(analyzer.instance_variable_get(:@directive_count)).to eq(0)
      end
    end
  end

  describe "#result" do
    before do
      allow(GraphQLTuning).to receive_messages(max_query_aliases: 5, max_query_directives: 3)
    end

    context "when alias count exceeds max" do
      before do
        analyzer.instance_variable_set(:@alias_count, 6)
      end

      it "returns an alias limit analysis error and logs to Sentry" do
        expect(Sentry).to receive(:with_scope).and_yield(instance_double(Sentry::Scope, set_context: nil))
        expect(Sentry).to receive(:capture_message).with(
          "GraphQL: max query aliases exceeded",
          level: :warning
        )

        result = analyzer.result
        expect(result).to be_a(GraphQL::AnalysisError)
        expect(result.message).to eq("max query aliases exceeded")
      end
    end

    context "when directive count exceeds max" do
      before do
        analyzer.instance_variable_set(:@directive_count, 4)
      end

      it "returns a directive limit analysis error and logs to Sentry" do
        expect(Sentry).to receive(:with_scope).and_yield(instance_double(Sentry::Scope, set_context: nil))
        expect(Sentry).to receive(:capture_message).with(
          "GraphQL: max query directives exceeded",
          level: :warning
        )

        result = analyzer.result
        expect(result).to be_a(GraphQL::AnalysisError)
        expect(result.message).to eq("max query directives exceeded")
      end
    end

    context "when counts are within limits" do
      before do
        analyzer.instance_variable_set(:@alias_count, 2)
        analyzer.instance_variable_set(:@directive_count, 1)
      end

      it "returns nil" do
        expect(analyzer.result).to be_nil
      end
    end
  end
end
