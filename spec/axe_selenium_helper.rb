# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require 'axe-selenium'
require 'axe-rspec'
require 'rspec/core/formatters/base_text_formatter'

module AxeSelenium
  RULES = [:wcag2a, :wcag2aa, :section508].freeze
  SKIP = [:'color-contrast', :'duplicate-id'].freeze

  def self.install!
    ::RSpec::Expectations::ExpectationTarget.prepend AxeRSpecAuditor
    ::Axe::Matchers::BeAxeClean.prepend AxeMatcherAuditor
    ::RSpec::Core::Formatters::BaseTextFormatter.prepend AxeResultsReporter
    configure_rspec_hooks
  end

  def self.configure_rspec_hooks
    RSpec.configure do |config|
      config.before(:each) do
        AxeSelenium::AxeHelper.reset_example_counter
      end

      config.before(:suite) do
        AxeSelenium::AxeHelper.reset_total_counter
      end

      config.after(:each) do
        results = AxeSelenium::AxeHelper.detailed_results
        unless AxeSelenium::AxeHelper.example_passed?
          raise RSpec::Expectations::ExpectationNotMetError, results
        end
      end
    end
  end

  module AxeResultsReporter
    def dump_summary(summary)
      $stderr.puts AxeSelenium::AxeHelper.summarize_results unless AxeSelenium::AxeHelper.suite_passed?

      super
    end
  end

  module AxeMatcherAuditor
    def matches?(page)
      audit(page)
      # Since we want to compile our failures here rather than failing after the first violation,
      #  we'll return true each time instead of returning `audit.passed?` and retrieve the results
      #  to compile from audit
      true
    end
  end

  module AxeRSpecAuditor
    def to(matcher=nil, message=nil, &block)
      AxeSelenium::AxeHelper.assert_axe
      super
    end

    def not_to(matcher=nil, message=nil, &block)
      AxeSelenium::AxeHelper.assert_axe
      super
    end
  end

  class AxeHelper
    @example_summary = {}
    @total_summary = {}
    @called_by = {}

    def self.assert_axe
      driver = SeleniumDriverSetup.driver
      if driver
        axe_matcher = Axe::Matchers::BeAxeClean.new
        axe_matcher.according_to AxeSelenium::RULES
        axe_matcher.skipping AxeSelenium::SKIP

        # Always assert that driver's current page _is_ axe compliant
        RSpec::Expectations::PositiveExpectationHandler.handle_matcher(driver, axe_matcher)

        call_stack = caller.select{|line| line =~ /selenium.*_spec\.rb/}.first(5)
        violations = axe_matcher.audit([]).results.violations
        violations.each do |v|
          v.nodes.each do |node|
            error_summary = node.failure_messages.flatten.join("\n")
            rule_description = "#{v.description} - Severity: #{v.impact}"
            @example_summary[rule_description] ||= Set.new()
            @example_summary[rule_description] << error_summary
            @called_by[rule_description] ||= Set.new()
            @called_by[rule_description] << call_stack
          end
        end
        add_example_runs_to_total
      end
    end

    def self.add_example_runs_to_total
      @example_summary.each do |desc, instances|
        @total_summary[desc] ||= Set.new()
        @total_summary[desc].merge(instances)
      end
    end

    def self.reset_example_counter
      @example_summary = {}
      @called_by = {}
    end

    def self.reset_total_counter
      @total_summary = {}
    end

    def self.example_passed?
      @example_summary.empty?
    end

    def self.suite_passed?
      @total_summary.empty?
    end

    def self.summarize_results
      general_summary = "Found #{@total_summary.keys.count} distinct violations"
      error_summary = @total_summary.map do |k, v|
        " - #{k}: #{v.count} violation(s)"
      end
      "\n#{general_summary}\n#{error_summary.join("\n")}\n"
    end

    def self.detailed_results
      @example_summary.map do |k,v|
        error_description = "#{k}\n\n"
        indented_errors = v.to_a.map{|i| i.indent(2)}
        call_stack = "Violations Found In:\n" + @called_by[k].to_a.flatten.map{|s| "  #{s.split(':in')[0]}"}.join("\n")
        error_description + "#{indented_errors.join("\n\n")}\n\n" + call_stack + "\n\n"
      end.join("\n")
    end
  end
end
