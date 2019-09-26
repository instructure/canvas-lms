module KnapsackExtensions
  module ExcludeTests
    def all_tests
      @all_tests_without_excludes ||=
        begin
          files = super
          exclude_regex_str = ENV['KNAPSACK_EXCLUDE_REGEX']
          if exclude_regex_str.present?
            exclude_regex = ::Regexp.new(exclude_regex_str)
            files.reject!{|f| f.match(exclude_regex)}
          end
          files
        end
    end
  end
  Knapsack::Distributors::BaseDistributor.prepend(ExcludeTests)
end
