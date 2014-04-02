module Canvas
  class APIArraySerializer < ActiveModel::ArraySerializer
    include Canvas::APISerialization

    def initialize(object, options={})
      super(object, options)
      @controller = options.fetch(:controller)
      @sideloads  = options.fetch(:includes, [])
    end

    def serializer_for(item)
      serializer_class = @each_serializer || ActiveModel::Serializer.serializer_for(item) || ActiveModel::DefaultSerializer
      serializer_class.new(item, scope: scope, controller: @controller, includes: @sideloads)
    end

    def serializable_object
      super.map! { |hash| stringify!(hash) }
    end
  end
end
