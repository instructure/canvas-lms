require 'spec_helper'
require_relative "./shared_constants"

describe TatlTael::Linters::RubySpecsLinter do
  let(:linter_class) { described_class }

  shared_examples "comments" do |raw_changes, msg|
    let(:changes) { raw_changes.map { |c| double(c) } }
    let(:linter) { described_class.new(changes) }

    it "comments" do
      allow(linter_class).to receive(:new)
        .with(changes)
        .and_return(linter)
      result = linter.run.select { |comment| comment[:message] == msg }
      expect(result.size).to eq(1)
      expect(result.first[:message]).to eq(msg)
    end
  end

  shared_examples "does not comment" do |raw_changes|
    let(:changes) { raw_changes.map { |c| double(c) } }
    let(:linter) { described_class.new(changes) }

    it "does not comment" do
      allow(linter_class).to receive(:new)
        .with(changes)
        .and_return(linter)
      expect(linter.run).to be_empty
    end
  end

  shared_examples "change combos" do |change_path, spec_path, msg|
    context "not deletion" do
      context "no spec changes" do
        include_examples "comments",
                         [{path: change_path, status: "added"}],
                         msg
      end
      context "has spec non deletions" do
        include_examples "does not comment",
                         [{path: change_path, status: "modified"},
                          {path: spec_path, status: "added"}]
      end
      context "has spec deletions" do
        include_examples "comments",
                         [{path: change_path, status: "added"},
                          {path: spec_path, status: "deleted"}],
                         msg
      end
    end
    context "deletion" do
      include_examples "does not comment",
                       [{path: change_path, status: "deleted"}]
    end
  end

  describe "ensure ruby specs" do
    context "app" do
      include_examples "change combos",
                       Consts::APP_RB_PATH,
                       Consts::APP_RB_SPEC_PATH,
                       TatlTael::Linters::RubySpecsLinter::RUBY_NO_SPECS_MSG
    end

    context "lib" do
      include_examples "change combos",
                       Consts::LIB_RB_PATH,
                       Consts::LIB_RB_SPEC_PATH,
                       TatlTael::Linters::RubySpecsLinter::RUBY_NO_SPECS_MSG
    end
  end

  context "unnecessary selenium specs" do
    context "has selenium specs" do
      context "needs public js specs" do
        context "has no public js specs" do
          include_examples "comments",
                           [{path: Consts::SELENIUM_SPEC_PATH, status: "added"},
                            {path: Consts::PUBLIC_JS_PATH, status: "added"}],
                           TatlTael::Linters::RubySpecsLinter::BAD_SELENIUM_SPEC_MSG
        end

        context "has public js specs" do
          include_examples "does not comment",
                           [{path: Consts::SELENIUM_SPEC_PATH, status: "added"},
                            {path: Consts::PUBLIC_JS_PATH, status: "added"},
                            {path: Consts::PUBLIC_JS_SPEC_PATH, status: "added"}]
        end
      end

      context "needs coffee specs" do
        context "has no coffee specs" do
          include_examples "comments",
                           [{path: Consts::SELENIUM_SPEC_PATH, status: "added"},
                            {path: Consts::APP_COFFEE_PATH, status: "added"}],
                           TatlTael::Linters::RubySpecsLinter::BAD_SELENIUM_SPEC_MSG
        end

        context "has coffee specs" do
          include_examples "does not comment",
                           [{path: Consts::SELENIUM_SPEC_PATH, status: "added"},
                            {path: Consts::APP_COFFEE_PATH, status: "added"},
                            {path: Consts::COFFEE_SPEC_PATH, status: "added"}]
        end
      end

      context "needs jsx specs" do
        context "has no jsx specs" do
          include_examples "comments",
                           [{path: Consts::SELENIUM_SPEC_PATH, status: "added"},
                            {path: Consts::APP_JSX_PATH, status: "added"}],
                           TatlTael::Linters::RubySpecsLinter::BAD_SELENIUM_SPEC_MSG
        end

        context "has jsx specs" do
          include_examples "does not comment",
                           [{path: Consts::SELENIUM_SPEC_PATH, status: "added"},
                            {path: Consts::APP_JSX_PATH, status: "added"},
                            {path: Consts::JSX_SPEC_PATH, status: "added"}]
        end
      end

      context "needs ruby specs" do
        context "has no ruby specs" do
          include_examples "comments",
                           [{path: Consts::SELENIUM_SPEC_PATH, status: "added"},
                            {path: Consts::APP_RB_PATH, status: "added"}],
                           TatlTael::Linters::RubySpecsLinter::BAD_SELENIUM_SPEC_MSG

          # has selenium specs only
          include_examples "comments",
                           [{path: Consts::SELENIUM_SPEC_PATH, status: "added"},
                            {path: Consts::APP_RB_PATH, status: "added"}],
                           TatlTael::Linters::RubySpecsLinter::RUBY_ONLY_SELENIUM_MSG
        end

        context "has ruby specs" do
          include_examples "does not comment",
                           [{path: Consts::SELENIUM_SPEC_PATH, status: "added"},
                            {path: Consts::APP_RB_PATH, status: "added"},
                            {path: Consts::APP_RB_SPEC_PATH, status: "added"}]
        end
      end
    end

    context "has no selenium specs" do
      include_examples "does not comment",
                       [{path: Consts::PUBLIC_VENDOR_JS_PATH, status: "added"}]
    end
  end
end
