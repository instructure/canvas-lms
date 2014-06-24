module GroupCategories

  class ParamsPolicy
    attr_reader :group_category, :context

    def initialize(category, category_context)
      @group_category = category
      @context = category_context
    end

    def populate_with(args, populate_opts={})
      params = Params.new(args, populate_opts)
      group_category.name = (params.name || group_category.name)
      group_category.self_signup = params.self_signup
      group_category.auto_leader = params.auto_leader
      group_category.group_limit = params.group_limit
      if context.is_a?(Course)
        group_category.create_group_count = params.create_group_count
        group_category.assign_unassigned_members = params.assign_unassigned_members
      end
      group_category
    end

  end

end
