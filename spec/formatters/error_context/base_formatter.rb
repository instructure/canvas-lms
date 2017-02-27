require "rspec/core/formatters/base_formatter"

# Base formatter that doesn't do anything in and of itself, except gather
# error context-y stuff for subclasses. If you have multiple such
# formatters, it creates/reuses a single ErrorSummary for each example.
#
# Stuff it tracks:
#  * previous specs and their results
#  * rails log during the spec
#  * js errors (selenium)
#  * screenshots (selenium)
#  * video capture (selenium + xvfb)
module ErrorContext
  class BaseFormatter < ::RSpec::Core::Formatters::BaseFormatter

    attr_reader :summary

    def example_started(notification)
      @summary = ErrorSummary.start(notification.example)
    end

    def example_finished(*)
      ErrorSummary.finish
    end

    def errors_path
      @summary.errors_path
    end

    def self.inherited(klass)
      ::RSpec::Core::Formatters.register klass,
        :example_started,
        :example_failed,
        :example_pending,
        :example_passed

      # TODO: once https://github.com/rspec/rspec-core/pull/2387 lands,
      # remove this and change the register call to use example_finished.
      # Note that these are not just aliases, since the subclass might
      # redefine example_finished in its body
      klass.class_eval do
        def example_failed(notification)
          example_finished(notification)
        end

        def example_pending(notification)
          example_finished(notification)
        end

        def example_passed(notification)
          example_finished(notification)
        end
      end
    end
  end

  class ErrorSummary
    class << self
      # In the case of loads of specs failing, don't generate error pages
      # beyond a certain point
      MAX_FAILURES_TO_RECORD = 20
      attr_writer :num_failures
      def num_failures
        @num_failures ||= 0
      end

      def start(example)
        @summary ||= begin
          summary = new(example)
          summary.start
          summary
        end
        @summary
      end

      def finish
        return unless @summary
        note_recent_spec_run @summary.example
        @summary.finish
        @summary = nil
      end

      def note_recent_spec_run(example)
        recent_spec_runs << {
          location: example.location_rerun_argument,
          exception: example.exception,
          pending: example.pending
        }
        self.num_failures += 1 if example.exception
      end

      def discard_remaining?
        num_failures > MAX_FAILURES_TO_RECORD
      end

      def recent_spec_runs
        @recent_spec_runs ||= []
      end

      def base_error_path
        @base_error_path ||= ENV.fetch("ERROR_CONTEXT_BASE_PATH", Rails.root.join("log", "spec_failures"))
      end
    end

    attr_reader :example

    def initialize(example)
      @example = example
    end

    def discard?
      !example.exception || ErrorSummary.discard_remaining?
    end

    def selenium?
      return @selenium unless @selenium.nil?
      @selenium = defined?(SeleniumDependencies) && example.example_group.include?(SeleniumDependencies)
    end

    def start
      Rails.logger.capture_messages!
      start_capturing_video! if capture_video? && !ErrorSummary.discard_remaining?
    end

    def finish
      if discard?
        discard_video! if capturing_video?
      else
        save_screenshot! if capture_screenshot?
        save_video! if capturing_video?
      end
    end

    def capturing_video?
      @capturing_video
    end

    def start_capturing_video!
      @capturing_video = true
      SeleniumDriverSetup.headless.video.start_capture
    end

    def save_screenshot!
      SeleniumDriverSetup.driver.save_screenshot(File.join(errors_path, screenshot_name))
    end

    def save_video!
      SeleniumDriverSetup.headless.video.stop_and_save(File.join(errors_path, screen_capture_name))
    end

    def discard_video!
      SeleniumDriverSetup.headless.video.stop_and_discard
    end

    def log_messages
      Rails.logger.captured_messages
    end

    def capture_screenshot?
      selenium?
    end

    def capture_video?
      selenium? && SeleniumDriverSetup.run_headless?
    end

    def js_errors
      return unless selenium?

      @js_errors ||= begin
        js_errors = SeleniumDriverSetup.js_errors

        # ignore "mutating the [[Prototype]] of an object" js errors
        mutating_prototype_error = "mutating the [[Prototype]] of an object"

        js_errors.reject! do |error|
          error["errorMessage"].start_with? mutating_prototype_error
        end

        js_errors
      end
    end

    def spec_path
      @spec_path ||= example.location_rerun_argument.sub(/\A[.\/]+/, "")
    end

    def errors_path
      @errors_path ||= begin
        errors_path = File.join(ErrorSummary.base_error_path, spec_path)
        FileUtils.mkdir_p(errors_path)
        errors_path
      end
    end

    def screenshot_name
      "screenshot.png" if capture_screenshot? && !discard?
    end

    def screen_capture_name
      "capture.mp4" if capture_video? && !discard?
    end
  end
end
