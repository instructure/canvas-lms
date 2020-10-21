module TatlTael
  module Linters
    # TODO: inherit from SimpleLinter
    class RubySpecsLinter < BaseLinter
      attr_reader :comment

      def initialize(config:, changes:, auto_correct: false)
        super
        @comment = {
          message: comment_msg,
          severity: config[:severity],
          cover_message: true
        }
      end

      def comment_msg
        return unless missing_ruby_specs?
        if selenium_specs?
          config[:messages][:ruby_changes_with_only_selenium]
        else
          config[:messages][:ruby_changes_with_no_ruby_specs]
        end
      end

      def run
        comment if comment_msg
      end

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

      def selenium_specs?
        changes_exist?(include: config[:globs][:selenium_spec])
      end
    end
  end
end
