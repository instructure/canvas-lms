# frozen_string_literal: true

require 'spec_helper'
require_relative "../shared_constants"
require_relative "../shared_linter_examples"

describe TatlTael::Linters::Simple::CoffeeSpecsLinter do
  let(:config) { TatlTael::Linters.config_for_linter(described_class) }

  context "coffee changes" do
    include_examples "change combos",
                     Consts::APP_COFFEE_PATH,
                     Consts::COFFEE_SPEC_PATH

    context "with jsx spec changes" do
      include_examples "change combos",
                       Consts::APP_COFFEE_PATH,
                       Consts::JSX_SPEC_PATH
    end
  end
end
