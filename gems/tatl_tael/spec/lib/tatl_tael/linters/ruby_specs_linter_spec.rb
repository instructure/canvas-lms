# frozen_string_literal: true

require "spec_helper"
require_relative "shared_constants"
require_relative "shared_linter_examples"

describe TatlTael::Linters::RubySpecsLinter do
  let(:linter_class) { described_class }
  let(:config) { TatlTael::Linters.config_for_linter(described_class) }

  describe "ensure ruby specs" do
    context "app" do
      include_examples "change combos with msg key",
                       Consts::APP_RB_PATH,
                       Consts::APP_RB_SPEC_PATH,
                       :ruby_changes_with_no_ruby_specs
    end

    context "lib" do
      include_examples "change combos with msg key",
                       Consts::LIB_RB_PATH,
                       Consts::LIB_RB_SPEC_PATH,
                       :ruby_changes_with_no_ruby_specs
    end
  end
end
