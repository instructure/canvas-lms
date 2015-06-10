module RuboCop::Canvas
  module MigrationTags
    def on_send(node)
      receiver, method_name, *args = *node
      return unless !receiver && method_name == :tag
      @tags = args.map { |n| n.children.first }
    end

    def tags
      @tags || []
    end
  end
end
