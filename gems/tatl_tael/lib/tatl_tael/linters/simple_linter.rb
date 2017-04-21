require_relative "../support/regex"

module TatlTael
  module Linters
    class SimpleLinter < BaseLinter
      include Regex
      attr_reader :config, :comment

      COMMENT_DEFAULTS = {
        severity: "warn",
        cover_message: true
      }.freeze

      def initialize(config:, changes:)
        @config = config
        @comment = COMMENT_DEFAULTS.merge({ message: config[:message] })
        @changes = changes
      end

      def run
        comment if precondition_met? && !requirement_met?
      end

      def precondition_met?
        changes_exist?(config[:precondition])
      end

      def requirement_met?
        config[:requirement] && changes_exist?(config[:requirement])
      end

      ERB_REGEX = /app\/views\/.*\.erb$/

      def self.comments(changes)
        configs.flat_map do |config|
          new({ config: config, changes: changes }).run
        end.compact
      end

      def self.configs
        [
          {
            name: "CoffeeSpecsLinter",
            precondition: {
              include_regexes: [COFFEE_REGEX],
              exclude_regexes: [COFFEE_REGEX_EXCLUDE],
            },
            requirement: {
              include_regexes: [
                COFFEE_SPEC_REGEX,
                JSX_SPEC_REGEX
              ],
            },
            message: "Your commit includes coffee changes,"\
                   " but does not include coffee or jsx specs."\
                   " Please add some to verify your changes."
          },
          {
            name: "JsxSpecsLinter",
            precondition: {include_regexes: [JSX_REGEX]},
            requirement: {include_regexes: [JSX_SPEC_REGEX]},
            message: "Your commit includes coffee changes,"\
                   " but does not include coffee or jsx specs."\
                   " Please add some to verify your changes."
          },
          {
            name: "PublicJsSpecsLinter",
            precondition: {
              include_regexes: [PUBLIC_JS_REGEX],
              exclude_regexes: [PUBLIC_JS_REGEX_EXCLUDE],
            },
            requirement: {include_regexes: [PUBLIC_JS_SPEC_REGEX]},
            message: "Your commit includes changes to public/javascripts,"\
                   " but does not include specs (coffee or jsx)."\
                   " Please add some to verify your changes."\
                   " Even $.fn.crazyMethods can and should be tested"\
                   " (and not via selenium)."
          },
          {
            name: "NewErbLinter",
            precondition: {
              include_regexes: [ERB_REGEX],
              statuses: %w[added]
            },
            message: "Your commit includes new ERB files,"\
                  " which has been a no-no in Canvas since 2011."\
                  " All new UI should be built in React on top of documented APIs.\n"\
                  "Maybe try doing something like this in your controller instead:\n\n"\
                  "    @page_title = t('Your Page Title')\n"\
                  "    @body_classes << 'whatever-classes you-want-to-add-to-body'\n"\
                  "    js_bundle :your_js_bundle\n"\
                  "    css_bundle :any_css_bundles_you_want\n"\
                  "    js_env({whatever: 'you need to put in window.ENV'})\n"\
                  "    render :text => \"\".html_safe, :layout => true"
          }
        ]
      end
    end
  end
end
