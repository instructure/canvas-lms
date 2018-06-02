#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
      module IncludedClassMethods
        def birth
          default
        end
      end

      def settings
        return {} unless self.class.columns_hash.key?('settings')
        s = super
        s = YAML.load(s) if s.is_a?(String) # no idea. it seems that sometimes rails forgets this column is serialized
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

      def encrypt_settings
        s = self.settings.dup
        if (encryption_key = s.delete(:encryption_key))
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
        if !default.is_a?(Switchman::Shard)
          # sharding isn't set up? maybe we're in tests, or a somehow degraded environment
          # either way there's only one shard, and we always want to see it
          [default]
        elsif !ApplicationController.region || DatabaseServer.all.all? { |db| !db.config[:region] }
          all
        else
          in_region(ApplicationController.region)
        end
    end
  end

  Switchman::DatabaseServer.class_eval do
    def self.regions
      @regions ||= all.map { |db| db.config[:region] }.compact.uniq.sort
    end

    def in_region?(region)
      !config[:region] || (region.is_a?(Array) ? region.include?(config[:region]) : config[:region] == region)
    end

    def in_current_region?
      unless instance_variable_defined?(:@in_current_region)
        @in_current_region = !config[:region] || !ApplicationController.region || config[:region] == ApplicationController.region
      end
      @in_current_region
    end

    def self.send_in_each_region(klass, method, enqueue_args = {}, *args)
      run_current_region_asynchronously = enqueue_args.delete(:run_current_region_asynchronously)
      regions = Set.new
      unless run_current_region_asynchronously
        klass.send(method, *args)
        regions << Shard.current.database_server.config[:region]
      end

      all.each do |db|
        next if (regions.include?(db.config[:region]) || !db.config[:region])
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

    def in_region?(_region)
      true
    end

    def in_current_region?
      true
    end
  end

  if !Shard.default.is_a?(Shard) && Switchman.config[:force_sharding] && !ENV['SKIP_FORCE_SHARDING']
    raise 'Sharding is supposed to be set up, but is not! Use SKIP_FORCE_SHARDING=1 to ignore'
  end

  if Shard.default.is_a?(Shard)
    # otherwise the serialized settings attribute method won't be properly defined
    Shard.define_attribute_methods
    Shard.default.instance_variable_set(:@attributes, Shard.attributes_builder.build_from_database(Shard.default.attributes_before_type_cast))
  end
end
