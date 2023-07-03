# frozen_string_literal: true

require "spec_helper"
require_relative "shared_constants"

describe TatlTael::Linters::SimpleLinter do
  let(:config_message) { "blarghishfarbin" }
  let(:config) do
    {
      "Severity" => "warn",
      "Message" => config_message,
      "Precondition" => {
        "Statuses" => %w[added deleted],
        "Include" => ["**/yarg/**"],
        "Allowlist" => ["**/yarg/blargh/**"],
      }
    }
  end
  let(:pretty_config) { TatlTael::Linters.underscore_and_symbolize_keys(config) }
  let(:changes) { double }

  let(:simple_linter) { described_class.new(config: pretty_config, changes:) }

  describe "#run" do
    context "precondition NOT met" do
      before do
        allow(simple_linter).to receive(:precondition_met?).and_return(false)
      end

      it "returns nothing" do
        expect(simple_linter.run).to be_nil
      end
    end

    context "precondition met" do
      before do
        allow(simple_linter).to receive(:precondition_met?).and_return(true)
      end

      context "requirement met" do
        before do
          allow(simple_linter).to receive(:requirement_met?).and_return(true)
        end

        it "returns nothing" do
          expect(simple_linter.run).to be_nil
        end
      end

      context "requirement NOT met" do
        let(:comment) do
          {
            severity: "warn",
            cover_message: true,
            message: config_message
          }
        end

        before do
          allow(simple_linter).to receive(:requirement_met?).and_return(false)
        end

        it "returns comment" do
          expect(simple_linter.run).to match(hash_including(comment))
        end
      end
    end
  end

  describe "#precondition_met?" do
    context "changes exist for the precondition query" do
      before do
        allow(simple_linter).to receive(:changes_exist?)
          .with(pretty_config[:precondition])
          .and_return(true)
      end

      it "returns true" do
        expect(simple_linter.precondition_met?).to be_truthy
      end
    end

    context "changes DO NOT exist for the precondition query" do
      before do
        allow(simple_linter).to receive(:changes_exist?)
          .with(pretty_config[:precondition])
          .and_return(false)
      end

      it "returns false" do
        expect(simple_linter.precondition_met?).to be_falsey
      end
    end
  end

  describe "#requirement_met?" do
    context "no requirement query in config" do
      it "returns false" do
        expect(simple_linter.requirement_met?).to be_falsey
      end
    end

    context "requirement query exists in config" do
      let(:requirement) do
        {
          "Statuses" => %w[modified deleted],
          "Include" => ["**/reeee/**"],
          "Allowlist" => ["**/reeee/blarghy/**"],
        }
      end
      let(:config_with_requirement) { config.merge("Requirement" => requirement) }
      let(:config_with_pretty_requirement) do
        TatlTael::Linters.underscore_and_symbolize_keys(config_with_requirement)
      end
      let(:simple_linter) do
        described_class.new(config: config_with_pretty_requirement,
                            changes:)
      end

      context "changes exist for the requirement query" do
        before do
          allow(simple_linter).to receive(:changes_exist?)
            .with(config_with_pretty_requirement[:requirement])
            .and_return(true)
        end

        it "returns true" do
          expect(simple_linter.requirement_met?).to be_truthy
        end
      end

      context "changes DO NOT exist for the requirement query" do
        before do
          allow(simple_linter).to receive(:changes_exist?)
            .with(config_with_pretty_requirement[:requirement])
            .and_return(false)
        end

        it "returns false" do
          expect(simple_linter.requirement_met?).to be_falsey
        end
      end
    end
  end
end
