class GraphQLTypeTester
  def initialize(type, test_object, user=nil)
    @type = type.is_a?(GraphQL::ObjectType) ? type : CanvasSchema.types[type]
    @obj = test_object
    @current_user = user
    @context = {current_user: @current_user}

    @type.fields.each { |name, field|
      # can't do id because the builtin relay helper provided by GraphQL::Relay
      # references the schema by grabbing it off ctx.query (which obv doesn't
      # exist)
      #
      # if we felt strongly about being able to run "id" we will want to not
      # use the builtin helper
      next if name == "id"

      if respond_to?(name)
        raise "error: trying to overwrite existing method #{name}"
      end

      define_singleton_method name do |ctx={}|
        args = ctx.delete(:args) || {}
        field.resolve(@obj, args, @context.merge(ctx))
      end
    }
  end
end
