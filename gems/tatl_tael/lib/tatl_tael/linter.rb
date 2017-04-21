module TatlTael
  module Linters
    class BaseLinter
      class << self
        def inherited(subclass)
          Linters.linters << subclass unless subclass.name =~ /SimpleLinter/
        end
      end

      attr_reader :changes
      def initialize(changes)
        @changes = changes
      end

      ### core
      def changes_matching(statuses: %w[added modified], # excludes "deleted",
                           include_regexes: [/./], # include everything
                           exclude_regexes: []) # don't exclude anything
        changes.select do |change|
          statuses.include?(change.status) &&
            include_regexes.any? { |regex| change.path =~ regex } &&
            exclude_regexes.all? { |regex| change.path !~ regex }
        end
      end

      # convenience
      def changes_exist?(query)
        !changes_matching(query).empty?
      end
    end

    class << self
      def linters
        @linters ||= []
      end

      def comments(changes)
        [
          SimpleLinter.comments(changes),
          run_linters(changes)
        ].flatten.compact
      end

      def run_linters(changes)
        @linter_results ||= linters.map do |linter_class|
          linter_class.new(changes).run
        end.flatten.compact
      end
    end
  end
end

Dir[File.dirname(__FILE__) + "/linters/*_linter.rb"].each { |file| require file }
