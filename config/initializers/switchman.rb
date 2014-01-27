unless CANVAS_RAILS2  
  Switchman::Shard.class_eval do
    class << self
      alias :birth :default
    end
  end

  ::Shard = Switchman::Shard

  Switchman::DefaultShard.class_eval do
    def settings
      {}
    end
  end
end