unless CANVAS_RAILS2  
  Switchman::Shard.class_eval do
    class << self
      alias :birth :default

      def current_with_delayed_jobs(category=:default)
        if category == :delayed_jobs
          active_shards[category] || current_without_delayed_jobs(:default).delayed_jobs_shard
        else
          current_without_delayed_jobs(category)
        end
      end
      alias_method_chain :current, :delayed_jobs

      def activate_with_delayed_jobs!(categories)
        if !categories[:delayed_jobs] && categories[:default]
          categories[:delayed_jobs] = categories[:default].delayed_jobs_shard
        end
        activate_without_delayed_jobs!(categories)
      end
    end

    self.primary_key = "id"
    reset_column_information # make sure that the id column object knows it is the primary key

    serialize :settings, Hash
    # the default shard was already loaded, but didn't deserialize it
    if default.is_a?(self)
      settings = ActiveRecord::AttributeMethods::Serialization::Attribute.new(serialized_attributes['settings'],
                                                                   default.read_attribute('settings'),
                                                                   :serialized).unserialize
      default.settings = settings
    end

    before_save :encrypt_settings

    def settings
      s = super
      unless s.is_a?(Hash) || s.nil?
        s = s.unserialize
      end
      if s.nil?
        self.settings = s = {}
      end

      salt = s.delete(:encryption_key_salt)
      secret = s.delete(:encryption_key_enc)
      if secret || salt
        if secret && salt
          s[:encryption_key] = Canvas::Security.decrypt_password(secret, salt, 'shard_encryption_key')
        end
        self.settings = s
      end

      s
    end

    def encrypt_settings
      s = self.settings.dup
      if encryption_key = s.delete(:encryption_key)
        secret, salt = Canvas::Security.encrypt_password(encryption_key, 'shard_encryption_key')
        s[:encryption_key_enc] = secret
        s[:encryption_key_salt] = salt
      end
      if s != self.settings
        self.settings = s
      end
      s
    end

    def delayed_jobs_shard
      shard = Shard.lookup(self.delayed_jobs_shard_id) if self.read_attribute(:delayed_jobs_shard_id)
      shard || self.database_server.delayed_jobs_shard(self)
    end
  end

  Switchman::DatabaseServer.class_eval do
    def delayed_jobs_shard(shard = nil)
      return shard if self.config[:delayed_jobs_shard] == 'self'
      dj_shard = self.config[:delayed_jobs_shard] &&
        Shard.lookup(self.config[:delayed_jobs_shard])
      # have to avoid recursion for the default shard asking for the default shard's dj shard
      dj_shard ||= shard if shard.default?
      dj_shard ||= Shard.default.delayed_jobs_shard
      dj_shard
    end
  end

  ::Shard = Switchman::Shard
  ::DatabaseServer = Switchman::DatabaseServer

  Switchman::DefaultShard.class_eval do
    attr_writer :settings

    def settings
      {}
    end

    def delayed_jobs_shard
      self
    end
  end

  Delayed::Backend::ActiveRecord::Job.class_eval do
    self.shard_category = :delayed_jobs
  end

  Shard.default.delayed_jobs_shard.activate!(:delayed_jobs)
end
