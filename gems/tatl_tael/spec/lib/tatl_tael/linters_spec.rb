# frozen_string_literal: true

require 'spec_helper'

describe TatlTael::Linters do
  describe TatlTael::Linters::BaseLinter do
    describe ".inherited" do
      context "not a simple linter" do
        class FooLinter < TatlTael::Linters::BaseLinter
        end

        it "saves the subclass" do
          expect(TatlTael::Linters.linters).to include(FooLinter)
        end
      end

      context "simple linter" do
        it "saves the subclass" do
          expect(TatlTael::Linters.linters).not_to include(TatlTael::Linters::SimpleLinter)
        end
      end
    end

    describe "#changes_matching" do
      Change = Struct.new(:status, :path)

      let(:config) { {} }
      let(:base_linter) { TatlTael::Linters::BaseLinter.new(config: config, changes: changes) }

      before :each do
        allow(base_linter).to receive(:changes)
          .and_return(changes)
      end

      context "filtering by statuses" do
        let(:added_change_path) { "path/to/foo" }
        let(:added_change) { Change.new("added", added_change_path) }
        let(:deleted_change_path) { "path/to/deleted" }
        let(:deleted_change) { Change.new("deleted", deleted_change_path) }
        let(:modified_change_path) { "path/to/mod" }
        let(:modified_change) { Change.new("modified", modified_change_path) }

        let(:changes) { [added_change, deleted_change, modified_change] }

        it "defaults to added and modified changes" do
          expect(base_linter.changes_matching).to match([added_change, modified_change])
        end

        context "deleted" do
          let(:query) { {statuses: ["deleted"]} }

          it "returns deleted changes" do
            expect(base_linter.changes_matching(**query)).to match([deleted_change])
          end
        end
      end

      context "filtering by includes" do
        let(:added_change_path) { "path/to/foo" }
        let(:added_change) { Change.new("added", added_change_path) }
        let(:modified_change_path) { "path/to/mod" }
        let(:modified_change) { Change.new("modified", modified_change_path) }

        let(:changes) { [added_change, modified_change] }

        it "defaults to include all" do
          expect(base_linter.changes_matching).to match(changes)
        end

        context "includes exist" do
          let(:query) { {include: ["**/zoo", "**/foo", "**/bar"]} }

          it "returns the changes that match any of the includes" do
            expect(base_linter.changes_matching(**query)).to match([added_change])
          end
        end
      end

      context "filtering by allowlist" do
        let(:added_change_path) { "path/to/foo" }
        let(:added_change) { Change.new("added", added_change_path) }
        let(:modified_change_path) { "path/to/mod" }
        let(:modified_change) { Change.new("modified", modified_change_path) }

        let(:changes) { [added_change, modified_change] }

        it "defaults to exclude none" do
          expect(base_linter.changes_matching).to match(changes)
        end

        context "include_regexes exist" do
          let(:query) { {allowlist: ["**/zoo", "**/foo", "**/bar"]} }

          it "returns the changes that don't match any of the allowlists" do
            expect(base_linter.changes_matching(**query)).to match([modified_change])
          end
        end
      end
    end

    describe "#changes_exist?" do
      let(:changes) { double }
      let(:query) do
        {
          include_regexes: [/.js/],
          exclude_regexes: [/^public/]
        }
      end
      let(:config) { {} }
      let(:base_linter) { TatlTael::Linters::BaseLinter.new(config: config, changes: changes) }

      before :each do
        allow(base_linter).to receive(:changes_matching)
          .with(hash_including(query))
          .and_return(changes)
      end


      context "changes exist matching the query" do
        before :each do
          allow(changes).to receive(:empty?).and_return(false)
        end

        it "returns true" do
          expect(base_linter.changes_exist?(query)).to be_truthy
        end
      end

      context "changes DO NOT exist matching the query" do
        before :each do
          allow(changes).to receive(:empty?).and_return(true)
        end

        it "returns false" do
          expect(base_linter.changes_exist?(query)).to be_falsey
        end
      end
    end
  end

  let(:linters) { TatlTael::Linters }
  let(:changes) { double }

  describe ".comments" do
    class BarLinter < TatlTael::Linters::BaseLinter
      def run
        [[], [nil], "1"]
      end
    end
    class ZooLinter < TatlTael::Linters::BaseLinter
      def run
        [nil, "2", "3"]
      end
    end

    let(:saved_linters) { [BarLinter, ZooLinter] }

    it "collects linter comments" do
      expect(linters).to receive(:linters).and_return(saved_linters)
      expect(linters.comments(changes: changes)).to match(%w[1 2 3])
    end
  end
end