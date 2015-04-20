# encoding: utf-8

require 'tempfile'

# This provides many of the helper hooks
# that rubocop itself uses inside it's gem tests, along
# with some hooks for inspecting messages generated from offenses
# to make tests more focused on the cop conditions they're building
module CopHelper
  def inspect_source_file(cop, source)
    Tempfile.open('tmp') { |f| inspect_source(cop, source, f) }
  end

  def inspect_source(cop, source, file = nil)
    if source.is_a?(Array) && source.size == 1
      fail "Don't use an array for a single line of code: #{source}"
    end
    RuboCop::Formatter::DisabledConfigFormatter.config_to_allow_offenses = {}
    processed_source = parse_source(source, file)
    fail 'Error parsing example code' unless processed_source.valid_syntax?
    _investigate(cop, processed_source)
  end

  def parse_source(source, file = nil)
    source = source.join($RS) if source.is_a?(Array)

    if file && file.respond_to?(:write)
      file.write(source)
      file.rewind
      file = file.path
    end

    RuboCop::ProcessedSource.new(source, file)
  end

  def autocorrect_source_file(cop, source)
    Tempfile.open('tmp') { |f| autocorrect_source(cop, source, f) }
  end

  def autocorrect_source(cop, source, file = nil)
    cop.instance_variable_get(:@options)[:auto_correct] = true
    processed_source = parse_source(source, file)
    _investigate(cop, processed_source)

    corrector =
      RuboCop::Cop::Corrector.new(processed_source.buffer, cop.corrections)
    corrector.rewrite
  end

  def _investigate(cop, processed_source)
    forces = RuboCop::Cop::Force.all.each_with_object([]) do |klass, instances|
      next unless cop.join_force?(klass)
      instances << klass.new([cop])
    end

    commissioner =
      RuboCop::Cop::Commissioner.new([cop], forces, raise_error: true)
    commissioner.investigate(processed_source)
    commissioner
  end
end

module RuboCop
  module Cop
    # This re-opens the internal rubocop class just to get some hooks in
    # for inspecting offenses more tersely in specs
    class Cop
      def messages
        offenses.sort.map(&:message)
      end

      def highlights
        offenses.sort.map { |o| o.location.source }
      end
    end
  end
end

RSpec.configure do |config|
  config.include CopHelper
end
