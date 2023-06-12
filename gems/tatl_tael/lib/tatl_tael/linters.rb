# frozen_string_literal: true

require "yaml"

module TatlTael
  module Linters
    class BaseLinter
      class << self
        def inherited(subclass)
          super
          Linters.linters << subclass unless subclass.name&.include?("SimpleLinter")
        end
      end

      attr_reader :changes
      attr_reader :config
      attr_reader :auto_correct

      def initialize(config:, changes:, auto_correct: false)
        @changes = changes
        @config = config
        @auto_correct = auto_correct
      end

      ### core
      def changes_matching(statuses: %w[added modified], # excludes "deleted",
                           include: ["*"], # include everything
                           allowlist: []) # don't allowlist anything
        changes.select do |change|
          statuses.include?(change.status) &&
            include.any? { |pattern| File.fnmatch(pattern, change.path) } &&
            allowlist.all? { |pattern| !File.fnmatch(pattern, change.path) }
        end
      end

      # convenience
      def changes_exist?(query)
        !changes_matching(**query).empty?
      end
    end

    class << self
      def linters
        @linters ||= []
      end

      DEFAULT_CONFIG_PATH = File.join(File.dirname(__FILE__), "../../config/default.yml")
      def config
        @config ||= if YAML::VERSION < "4.0"
                      YAML.load_file(DEFAULT_CONFIG_PATH)
                    else
                      YAML.load_file(DEFAULT_CONFIG_PATH, permitted_classes: [Symbol, Regexp])
                    end
      end

      def config_for_linter(linter_class)
        # example linter_class.to_s: "TatlTael::Linters::Simple::CoffeeSpecsLinter"
        # example resulting base_config_key: "Simple/CoffeeSpecsLinter"
        base_config_key = linter_class.to_s
                                      .sub(to_s, "") # rm "TatlTael::Linters"
                                      .sub("::", "")
                                      .gsub("::", "/")
        underscore_and_symbolize_keys(config[base_config_key])
      end

      def comments(changes:, auto_correct: false)
        @comments ||= linters.map do |linter_class|
          linter_class.new(
            config: config_for_linter(linter_class),
            changes:,
            auto_correct:
          ).run
        end.flatten.compact
      end

      def underscore_and_symbolize_keys(hash)
        if hash.is_a? Hash
          return hash.each_with_object({}) do |(k, v), memo|
            memo[underscore(k).to_sym] = underscore_and_symbolize_keys(v)
          end
        end

        if hash.is_a? Array
          return hash.each_with_object([]) do |v, memo|
            memo << underscore_and_symbolize_keys(v)
          end
        end

        hash
      end

      def underscore(string)
        # borrowed from AS underscore, since we may not have it
        string.gsub(/([A-Z\d]+)([A-Z][a-z])/, "\\1_\\2")
              .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
              .tr("-", "_")
              .downcase
      end
    end
  end
end

Dir[File.dirname(__FILE__) + "/linters/**/*_linter.rb"].each { |file| require file }
