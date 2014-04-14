module Importers
  class DiscussionTopicOptions
    attr_reader :options

    BOOLEAN_KEYS = [:pinned, :require_initial_post]

    def initialize(options = {})
      @options = options.with_indifferent_access
      @options[:missing_links] = []
      @options[:messages]    ||= @options[:posts]
    end

    def [](key)
      BOOLEAN_KEYS.include?(key) ? !!@options[key] : @options[key]
    end

    def []=(key, value)
      @options[key] = BOOLEAN_KEYS.include?(key) ? !!value : value
    end

    def importable?
      !(options[:migration_id] && options[:topics_to_import] &&
        !options[:topics_to_import][options[:migration_id]])
    end

    def message
      return options[:description] if options[:description].present?
      return options[:text] if options[:text].present?
    end

    def delayed_post_at
      options[:delayed_post_at] || options[:start_date]
    end

    def due_date
      options[:due_date] || options[:grading][:due_date]
    end
  end
end
