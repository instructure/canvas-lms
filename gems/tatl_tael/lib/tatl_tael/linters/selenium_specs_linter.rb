# frozen_string_literal: true

module TatlTael
  module Linters
    # TODO: inherit from SimpleLinter
    class SeleniumSpecsLinter < BaseLinter
      attr_reader :comment

      def initialize(config:, changes:, auto_correct: false)
        super
        @comment = {
          message: config[:message],
          severity: config[:severity],
          cover_message: true
        }
      end

      def run
        comment if unnecessary_selenium_specs?
      end

      def unnecessary_selenium_specs?
        selenium_specs? && needs_non_selenium_specs?
      end

      # TODO: turn into a "Simple" linter
      # Precondition:
      #   Include: config[:globs][:selenium_spec]
      # RequireOne:
      def selenium_specs?
        changes_exist?(include: config[:globs][:selenium_spec])
      end

      def needs_non_selenium_specs?
        missing_public_js_specs? ||
          missing_jsx_specs? ||
          missing_ruby_specs?
      end

      ### public js specs
      def missing_public_js_specs?
        needs_public_js_specs? && !public_js_specs?
      end

      def needs_public_js_specs?
        changes_exist?(include: config[:globs][:public_js],
                       allowlist: config[:globs][:public_js_allowlist])
      end

      def public_js_specs?
        changes_exist?(include: config[:globs][:public_js_spec])
      end

      ### jsx specs
      def missing_jsx_specs?
        needs_jsx_specs? && !jsx_specs?
      end

      def needs_jsx_specs?
        changes_exist?(include: config[:globs][:jsx])
      end

      def jsx_specs?
        changes_exist?(include: config[:globs][:jsx_spec])
      end

      ### ruby specs (non selenium)
      def missing_ruby_specs?
        needs_ruby_specs? && !ruby_specs?
      end

      def needs_ruby_specs?
        changes_exist?(include: config[:globs][:ruby])
      end

      def ruby_specs?
        changes_exist?(include: config[:globs][:ruby_spec],
                       allowlist: config[:globs][:selenium_spec])
      end
    end
  end
end
