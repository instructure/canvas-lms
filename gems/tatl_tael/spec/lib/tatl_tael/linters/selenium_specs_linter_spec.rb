# frozen_string_literal: true

require "spec_helper"
require_relative "shared_constants"
require_relative "shared_linter_examples"

describe TatlTael::Linters::SeleniumSpecsLinter do
  let(:linter_class) { described_class }
  let(:config) { TatlTael::Linters.config_for_linter(described_class) }

  context "unnecessary selenium specs" do
    context "has selenium specs" do
      context "needs public js specs" do
        context "has no public js specs" do
          include_examples "comments",
                           [{ path: Consts::SELENIUM_SPEC_PATH, status: "added" },
                            { path: Consts::PUBLIC_JS_PATH, status: "added" }],
                           :unnecessary_selenium_specs
        end

        context "has public js specs" do
          include_examples "does not comment",
                           [{ path: Consts::SELENIUM_SPEC_PATH, status: "added" },
                            { path: Consts::PUBLIC_JS_PATH, status: "added" },
                            { path: Consts::PUBLIC_JS_SPEC_PATH, status: "added" }]
        end
      end

      context "needs jsx specs" do
        context "has no jsx specs" do
          include_examples "comments",
                           [{ path: Consts::SELENIUM_SPEC_PATH, status: "added" },
                            { path: Consts::APP_JSX_PATH, status: "added" }],
                           :unnecessary_selenium_specs
        end

        context "has jsx specs" do
          include_examples "does not comment",
                           [{ path: Consts::SELENIUM_SPEC_PATH, status: "added" },
                            { path: Consts::APP_JSX_PATH, status: "added" },
                            { path: Consts::JSX_SPEC_PATH, status: "added" }]
        end
      end

      context "needs ruby specs" do
        context "has no ruby specs" do
          include_examples "comments",
                           [{ path: Consts::SELENIUM_SPEC_PATH, status: "added" },
                            { path: Consts::APP_RB_PATH, status: "added" }],
                           :unnecessary_selenium_specs

          # has selenium specs only
          include_examples "comments",
                           [{ path: Consts::SELENIUM_SPEC_PATH, status: "added" },
                            { path: Consts::APP_RB_PATH, status: "added" }],
                           :ruby_changes_with_only_selenium
        end

        context "has ruby specs" do
          include_examples "does not comment",
                           [{ path: Consts::SELENIUM_SPEC_PATH, status: "added" },
                            { path: Consts::APP_RB_PATH, status: "added" },
                            { path: Consts::APP_RB_SPEC_PATH, status: "added" }]
        end
      end
    end

    context "has no selenium specs" do
      include_examples "does not comment",
                       [{ path: Consts::PUBLIC_VENDOR_JS_PATH, status: "added" }]
    end
  end
end
