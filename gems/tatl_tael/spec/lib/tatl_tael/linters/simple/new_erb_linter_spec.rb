# frozen_string_literal: true

require 'spec_helper'
require_relative "../shared_constants"
require_relative "../shared_linter_examples"

describe TatlTael::Linters::Simple::NewErbLinter do
  let(:config) { TatlTael::Linters.config_for_linter(described_class) }

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