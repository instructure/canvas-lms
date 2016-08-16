Rails.application.config.after_initialize do
  Switchman.cache = -> { MultiCache.cache }

  # WillPaginate needs to allow args to Relation#to_a
  WillPaginate::ActiveRecord::RelationMethods.class_eval do
    def to_a(*args)
      if current_page.nil? then super # workaround for Active Record 3.0
      else
        ::WillPaginate::Collection.create(current_page, limit_value) do |col|
          col.replace super
          col.total_entries ||= total_entries
        end
      end
    end
  end

  module Canvas
    module Shard
      module ClassMethods
        def current(category=:default)
          if category == :delayed_jobs
            active_shards[category] || super(:default).delayed_jobs_shard
          else
            super
          end
        end

        def activate!(categories)
          if !@skip_delayed_job_auto_activation && !categories[:delayed_jobs] &&
              categories[:default] && categories[:default] != active_shards[:default] # only activate if it changed
            skip_delayed_job_auto_activation do
              categories[:delayed_jobs] = categories[:default].delayed_jobs_shard
            end
          end
          super
        end

        def skip_delayed_job_auto_activation
          was = @skip_delayed_job_auto_activation
          @skip_delayed_job_auto_activation = true
          yield
        ensure
          @skip_delayed_job_auto_activation = was
        end
      end

      module IncludedClassMethods
        def birth
          default
        end
      end

      def clear_cache
        self.class.connection.after_transaction_commit { super }
      end

      def settings
        return {} unless self.class.columns_hash.key?('settings')
        s = super
        unless s.is_a?(Hash) || s.nil?
          s = s.unserialize(s.value)
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

      def delayed_jobs_shard
        shard = Switchman::Shard.lookup(self.delayed_jobs_shard_id) if self.read_attribute(:delayed_jobs_shard_id)
        shard || self.database_server.try(:delayed_jobs_shard, self)
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
  end

  Switchman::Shard.prepend(Canvas::Shard)
  Switchman::Shard.singleton_class.prepend(Canvas::Shard::ClassMethods)
  Switchman::Shard.singleton_class.include(Canvas::Shard::IncludedClassMethods)

  Switchman::Shard.class_eval do
    self.primary_key = "id"
    reset_column_information # make sure that the id column object knows it is the primary key

    serialize :settings, Hash

    # the default shard was already loaded, but didn't deserialize it
    if default.is_a?(self) && default.instance_variable_get(:@attributes)['settings'].is_a?(String)
      settings = serialized_attributes['settings'].load(default.read_attribute('settings'))
      default.settings = settings
    end

    before_save :encrypt_settings

    delegate :in_current_region?, to: :database_server

    scope :in_region, ->(region) do
      servers = DatabaseServer.all.select { |db| db.in_region?(region) }.map(&:id)
      if servers.include?(Shard.default.database_server.id)
        where("database_server_id IN (?) OR database_server_id IS NULL", servers)
      else
        where(database_server_id: servers)
      end
    end

    scope :in_current_region, -> do
      @current_region_scope ||=
        if !ApplicationController.region || DatabaseServer.all.all? { |db| !db.config[:region] }
          all
        else
          in_region(ApplicationController.region)
        end
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

    def self.regions
      @regions ||= all.map { |db| db.config[:region] }.compact.uniq.sort
    end

    def in_region?(region)
      !config[:region] || config[:region] == region
    end

    def in_current_region?
      unless instance_variable_defined?(:@in_current_region)
        @in_current_region = !config[:region] || !ApplicationController.region || config[:region] == ApplicationController.region
      end
      @in_current_region
    end

    def self.send_in_each_region(klass, method, enqueue_args = {}, *args)
      klass.send(method, *args)
      regions = Set.new
      regions << Shard.current.database_server.config[:region]
      all.each do |db|
        next if regions.include?(db.config[:region]) || !db.config[:region]
        next if db.shards.empty?
        regions << db.config[:region]
        db.shards.first.activate do
          klass.send_later_enqueue_args(method, enqueue_args, *args)
        end
      end
    end
  end

  Switchman.config[:on_fork_proc] = -> { Canvas.reconnect_redis }

  Object.send(:remove_const, :Shard) if defined?(::Shard)
  Object.send(:remove_const, :DatabaseServer) if defined?(::DatabaseServer)
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

    def in_region?(region)
      true
    end

    def in_current_region?
      true
    end
  end

  Delayed::Backend::ActiveRecord::Job.class_eval do
    self.shard_category = :delayed_jobs
  end

  Shard.default.delayed_jobs_shard.activate!(:delayed_jobs)

  if !Shard.default.is_a?(Shard) && Switchman.config[:force_sharding] && !ENV['SKIP_FORCE_SHARDING']
    raise 'Sharding is supposed to be set up, but is not! Use SKIP_FORCE_SHARDING=1 to ignore'
  end

  if !CANVAS_RAILS4_0 && Shard.default.is_a?(Shard)
    # otherwise the serialized settings attribute method won't be properly defined
    Shard.define_attribute_methods
    Shard.default.instance_variable_set(:@attributes, Shard.attributes_builder.build_from_database(Shard.default.attributes_before_type_cast))
  end
end
