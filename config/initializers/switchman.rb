unless CANVAS_RAILS2  
  Switchman::Shard.class_eval do
    class << self
      alias :birth :default
    end

    self.primary_key = "id"
    serialize :settings, Hash

    before_save :encrypt_settings

    def settings
      s = super
      if s.nil?
        self.settings = s = {}
      elsif !s.is_a?(Hash)
        s = s.unserialize
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
  end

  ::Shard = Switchman::Shard
  ::DatabaseServer = Switchman::DatabaseServer

  Switchman::DefaultShard.class_eval do
    attr_writer :settings

    def settings
      {}
    end
  end
end
