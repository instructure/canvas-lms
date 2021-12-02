# frozen_string_literal: true

require 'spec_helper'
require_relative "../shared_constants"
require_relative "../shared_linter_examples"

describe TatlTael::Linters::Simple::JsxSpecsLinter do
  let(:config) { TatlTael::Linters.config_for_linter(described_class) }

  include_examples "change combos",
                   Consts::APP_JSX_PATH,
                   Consts::JSX_SPEC_PATH
end
