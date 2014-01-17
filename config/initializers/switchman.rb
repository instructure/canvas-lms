unless CANVAS_RAILS2  
  Switchman::Shard.class_eval do
    class << self
      alias :birth :default
    end

    self.primary_key = "id"
    serialize :settings, Hash

    def settings
      v = super
      v = v.unserialize unless v.is_a?(Hash)
      v || {}
    end
  end

  ::Shard = Switchman::Shard

  Switchman::DefaultShard.class_eval do
    attr_writer :settings

    def settings
      {}
    end
  end
end