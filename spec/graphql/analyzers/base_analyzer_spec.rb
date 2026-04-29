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

describe Analyzers::BaseAnalyzer do
  let(:analyzer) { described_class.new(instance_double(GraphQL::Query)) }

  let(:node) { instance_double(GraphQL::Language::Nodes::AbstractNode) }
  let(:visitor) { instance_double(GraphQL::Analysis::Visitor) }
  let(:field_defn) { instance_double(GraphQL::Schema::Field) }
  let(:input_hash) { { "some_key" => "some_value" } }

  before do
    analyzer.instance_variable_set(:@query, instance_double(GraphQL::Query, operation_name: "TestOp"))
  end

  describe "#argument_value" do
    context "when input responds to to_h" do
      let(:input) { double("InputObject", to_h: input_hash) } # rubocop:disable RSpec/VerifiedDoubles -- we specifically want a made up object

      before do
        allow(visitor).to receive(:field_definition).and_return(field_defn)
        allow(visitor).to receive(:arguments_for).with(node, field_defn).and_return(input: input_hash)
      end

      it "returns the argument value from input" do
        result = analyzer.send(:argument_value, node, visitor, "some_key")
        expect(result).to eq("some_value")
      end
    end

    context "when input does not respond to to_h" do
      let(:input) { "invalid input" }

      before do
        allow(visitor).to receive(:field_definition).and_return(field_defn)
        allow(visitor).to receive(:arguments_for).with(node, field_defn).and_return(input:)
      end

      it "logs a warning to Sentry and returns nil" do
        expect(Sentry).to receive(:with_scope).and_yield(instance_double(Sentry::Scope, set_context: nil))
        expect(Sentry).to receive(:capture_message).with("Base Analyzer: unable to process input", level: :warning)

        result = analyzer.send(:argument_value, node, visitor, "some_key")
        expect(result).to be_nil
      end
    end
  end

  describe "#log_to_sentry" do
    it "logs a message to Sentry with context" do
      fake_scope = instance_double(Sentry::Scope, set_context: nil)
      expect(Sentry).to receive(:with_scope).and_yield(fake_scope)
      expect(Sentry).to receive(:capture_message).with("Test message", level: :warning)

      analyzer.send(:log_to_sentry, "Test message", foo: "bar")

      expect(fake_scope).to have_received(:set_context).with("graphql", hash_including(foo: "bar", operation_name: "TestOp"))
    end
  end
end
