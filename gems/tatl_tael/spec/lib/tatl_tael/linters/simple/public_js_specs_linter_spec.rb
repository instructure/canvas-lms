require 'spec_helper'
require_relative "../shared_constants"
require_relative "../shared_linter_examples"

describe TatlTael::Linters::Simple::PublicJsSpecsLinter do
  let(:config) { TatlTael::Linters.config_for_linter(described_class) }

  include_examples "change combos",
                   Consts::PUBLIC_JS_PATH,
                   Consts::PUBLIC_JS_SPEC_PATH

  context "in excluded public sub dirs" do
    context "bower" do
      include_examples "does not comment",
                       [{path: Consts::PUBLIC_BOWER_JS_PATH, status: "added"}]
    end
    context "mediaelement" do
      include_examples "does not comment",
                       [{path: Consts::PUBLIC_ME_JS_PATH, status: "added"}]
    end
    context "vendor" do
      include_examples "does not comment",
                       [{path: Consts::PUBLIC_VENDOR_JS_PATH, status: "added"}]
    end
  end
end
