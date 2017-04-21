require_relative "../support/regex"

module TatlTael
  module Linters
    class RubySpecsLinter < BaseLinter
      include Regex

      SEVERITY = "warn".freeze
      COMMENT_DEFAULTS = {
        severity: SEVERITY,
        cover_message: true
      }.freeze

      RUBY_ONLY_SELENIUM_MSG = "Your commit includes ruby changes,"\
                               " but does not include non-selenium specs (model, controller, etc)."\
                               " Please add some to verify your changes.".freeze
      RUBY_NO_SPECS_MSG = "Your commit includes ruby changes,"\
                          " but does not include ruby specs."\
                          " Please add some to verify your changes.".freeze
      BAD_SELENIUM_SPEC_MSG = "Your commit modifies selenium specs,"\
                              " when your changes might be more appropriately"\
                              " tested at a lower level (see above)."\
                              " Please limit your selenium specs to happy-path scenarios.".freeze

      def run
        comments = []

        if missing_ruby_specs?
          comments << if selenium_specs?
            RUBY_ONLY_SELENIUM_MSG
                      else
            RUBY_NO_SPECS_MSG
                      end
        end
        comments << BAD_SELENIUM_SPEC_MSG if unnecessary_selenium_specs?

        comments.map { |comment| COMMENT_DEFAULTS.merge({ message: comment }) }
      end

      def missing_ruby_specs?
        needs_ruby_specs? && !ruby_specs?
      end

      RUBY_REGEX = /(app|lib)\/.*\.rb$/
      def needs_ruby_specs?
        changes_exist?(include_regexes: [RUBY_REGEX])
      end

      RUBY_SPEC_REGEX = /(spec|spec_canvas|test)\/.*\.rb$/
      SELENIUM_SPEC_REGEX = /(spec|spec_canvas|test)\/selenium\//
      def ruby_specs?
        changes_exist?(include_regexes: [RUBY_SPEC_REGEX],
                       exclude_regexes: [SELENIUM_SPEC_REGEX])
      end

      def selenium_specs?
        changes_exist?(include_regexes: [SELENIUM_SPEC_REGEX])
      end

      def unnecessary_selenium_specs?
        selenium_specs? && needs_non_selenium_specs?
      end

      def needs_non_selenium_specs?
        missing_public_js_specs? ||
          missing_coffee_specs? ||
          missing_jsx_specs? ||
          missing_ruby_specs?
      end

      ### public js specs
      def missing_public_js_specs?
        needs_public_js_specs? && !public_js_specs?
      end

      def needs_public_js_specs?
        changes_exist?(include_regexes: [PUBLIC_JS_REGEX],
                       exclude_regexes: [PUBLIC_JS_REGEX_EXCLUDE])
      end

      def public_js_specs?
        changes_exist?(include_regexes: [PUBLIC_JS_SPEC_REGEX])
      end

      ### coffee specs
      def missing_coffee_specs?
        needs_coffee_specs? && !coffee_specs?
      end

      def needs_coffee_specs?
        changes_exist?(include_regexes: [COFFEE_REGEX],
                       exclude_regexes: [COFFEE_REGEX_EXCLUDE])
      end

      def coffee_specs?
        changes_exist?(include_regexes: [COFFEE_SPEC_REGEX, JSX_SPEC_REGEX])
      end

      ### jsx specs
      def missing_jsx_specs?
        needs_jsx_specs? && !jsx_specs?
      end

      def needs_jsx_specs?
        changes_exist?(include_regexes: [JSX_REGEX])
      end

      def jsx_specs?
        changes_exist?(include_regexes: [JSX_SPEC_REGEX])
      end
    end
  end
end
