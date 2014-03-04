module Canvas
  class APIArraySerializer < ActiveModel::ArraySerializer
    include Canvas::APISerialization
    def serializable_object
      super.map! { |hash| stringify!(hash) }
    end
  end
end
