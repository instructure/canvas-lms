require 'spec_helper'
require_relative "./shared_constants"

describe TatlTael::Linters::SimpleLinter do
  let(:config_message) { "blarghishfarbin" }
  let(:config) do
    {
      message: config_message,
      precondition: double
    }
  end
  let(:changes) { double }

  let(:simple_linter) { described_class.new(config: config, changes: changes) }

  describe "#run" do
    context "precondition NOT met" do
      before :each do
        allow(simple_linter).to receive(:precondition_met?).and_return(false)
      end

      it "returns nothing" do
        expect(simple_linter.run).to be_nil
      end
    end

    context "precondition met" do
      before :each do
        allow(simple_linter).to receive(:precondition_met?).and_return(true)
      end

      context "requirement met" do
        before :each do
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

        before :each do
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
      before :each do
        allow(simple_linter).to receive(:changes_exist?)
          .with(config[:precondition])
          .and_return(true)
      end

      it "returns true" do
        expect(simple_linter.precondition_met?).to be_truthy
      end
    end

    context "changes DO NOT exist for the precondition query" do
      before :each do
        allow(simple_linter).to receive(:changes_exist?)
          .with(config[:precondition])
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
      let(:requirement) { double("requirement") }
      let(:config_with_requirement) { config.merge(requirement: requirement) }
      let(:simple_linter) do 
        described_class.new(config: config_with_requirement,
                                                changes: changes) 
      end

      context "changes exist for the requirement query" do
        before :each do
          allow(simple_linter).to receive(:changes_exist?)
            .with(requirement)
            .and_return(true)
        end

        it "returns true" do
          expect(simple_linter.requirement_met?).to be_truthy
        end
      end

      context "changes DO NOT exist for the requirement query" do
        before :each do
          allow(simple_linter).to receive(:changes_exist?)
            .with(requirement)
            .and_return(false)
        end

        it "returns false" do
          expect(simple_linter.requirement_met?).to be_falsey
        end
      end
    end
  end

  describe ".comments" do
    let(:simple_linter_class) { described_class }
    let(:configs) do
      simple_linter_class.configs.select { |config| config[:name] == linter }
    end
    let(:config) { configs.first }
    let(:linter_comment) do
      {
        severity: "warn",
        cover_message: true,
        message: config[:message]
      }
    end

    before(:each) do
      allow(simple_linter_class).to receive(:configs).and_return(configs)
    end

    shared_examples "comments" do |raw_changes|
      let(:changes) { raw_changes.map { |c| double(c) } }
      let(:linter_config) { { config: config, changes: changes } }
      let(:simple_linter) { described_class.new(linter_config) }

      it "comments" do
        allow(simple_linter_class).to receive(:new)
          .with(hash_including(linter_config))
          .and_return(simple_linter)
        result = simple_linter_class.comments(changes)
        expect(result.size).to eq(1)
        expect(result.first).to match(hash_including(linter_comment))
      end
    end

    shared_examples "does not comment" do |raw_changes|
      let(:changes) { raw_changes.map { |c| double(c) } }
      let(:linter_config) { {config: config, changes: changes} }
      let(:simple_linter) { described_class.new(linter_config) }

      it "does not comment" do
        allow(simple_linter_class).to receive(:new)
          .with(hash_including(linter_config))
          .and_return(simple_linter)
        expect(simple_linter_class.comments(changes)).to be_empty
      end
    end

    shared_examples "change combos" do |change_path, spec_path|
      context "not deletion" do
        context "no spec changes" do
          include_examples "comments",
                           [{ path: change_path, status: "added" }]
        end
        context "has spec non deletions" do
          include_examples "does not comment",
                           [{ path: change_path, status: "modified" },
                            { path: spec_path, status: "added" }]
        end
        context "has spec deletions" do
          include_examples "comments",
                           [{ path: change_path, status: "added" },
                            { path: spec_path, status: "deleted" }]
        end
      end
      context "deletion" do
        include_examples "does not comment",
                         [{ path: change_path, status: "deleted" }]
      end
    end

    describe "CoffeeSpecsLinter" do
      let(:linter) { "CoffeeSpecsLinter" }

      context "coffee changes" do
        include_examples "change combos",
                         Consts::APP_COFFEE_PATH,
                         Consts::COFFEE_SPEC_PATH

        context "bundles" do
          include_examples "does not comment",
                           [{path: Consts::APP_COFFEE_BUNDLE_PATH, status: "added"}]
        end

        context "with jsx spec changes" do
          include_examples "change combos",
                           Consts::APP_COFFEE_PATH,
                           Consts::JSX_SPEC_PATH
        end
      end
    end

    describe "PublicJsSpecsLinter" do
      let(:linter) { "PublicJsSpecsLinter" }

      include_examples "change combos",
                       Consts::PUBLIC_JS_PATH,
                       Consts::PUBLIC_JS_SPEC_PATH

      context "in excluded public sub dirs" do
        context "bower" do
          include_examples "does not comment",
                           [{ path: Consts::PUBLIC_BOWER_JS_PATH, status: "added" }]
        end
        context "mediaelement" do
          include_examples "does not comment",
                           [{ path: Consts::PUBLIC_ME_JS_PATH, status: "added" }]
        end
        context "vendor" do
          include_examples "does not comment",
                           [{ path: Consts::PUBLIC_VENDOR_JS_PATH, status: "added" }]
        end
      end
    end

    describe "JsxSpecsLinter" do
      let(:linter) { "JsxSpecsLinter" }

      include_examples "change combos",
                       Consts::APP_JSX_PATH,
                       Consts::JSX_SPEC_PATH
    end

    describe "NewErbLinter" do
      let(:linter) { "NewErbLinter" }

      context "app views erb additions exist" do
        include_examples "comments", [{path: Consts::APP_ERB_PATH, status: "added"}]
      end

      context "other erb additions exist" do
        include_examples "does not comment", [{path: Consts::OTHER_ERB_PATH, status: "added"}]
      end

      context "erb non additions exist" do
        include_examples "does not comment", [{path: Consts::APP_ERB_PATH, status: "modified"}]
      end

      context "no erb changes exist" do
        include_examples "does not comment", [{path: Consts::PUBLIC_VENDOR_JS_PATH, status: "added"}]
      end
    end
  end
end
